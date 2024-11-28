module dotoptact(input logic clk, input logic rst_n,
           // slave (CPU-facing)
           output logic slave_waitrequest,
           input logic [3:0] slave_address,
           input logic slave_read, output logic [31:0] slave_readdata,
           input logic slave_write, input logic [31:0] slave_writedata,

           // master (SDRAM-facing)
           input logic master_waitrequest,
           output logic [31:0] master_address,
           output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
           output logic master_write, output logic [31:0] master_writedata,

           // master2 (SRAM-facing to bank0 and bank1)
           input logic master2_waitrequest,
           output logic [31:0] master2_address,
           output logic master2_read, input logic [31:0] master2_readdata, input logic master2_readdatavalid,
           output logic master2_write, output logic [31:0] master2_writedata);

    enum { Sload, Srequestread, Sread, Srequestbias, Sreadbias, Srequestwrite } state1, state2;

    logic [31:0] parameters [1:7];
    logic [31:0] sdram_addr, sram_addr, words_remaining;
    logic signed [63:0] sram_data, sdram_data, multiplied;
    logic signed [31:0] sum;

    assign master_read = state1 == Srequestread || state1 == Srequestbias;
    assign master_write = 0;
    assign master_writedata = 0;
    assign sdram_data = {{32{master_readdata[31]}},master_readdata};

    assign master2_read = state2 == Srequestread;
    assign master2_write = state1 == Srequestwrite;
    assign master2_writedata = (parameters[7] && sum < 0) ? 0 : sum;

    assign slave_waitrequest = state1 != Sload;
    assign multiplied = sram_data * sdram_data;
    assign slave_readdata = 0;

    /* This state machine reads/writes from/to the SDRAM and handles calculations. */
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state1 <= Sload;
        end else begin
            case(state1)
                Sload: begin
                    if (slave_write) begin
                        case(slave_address)
                            0: begin
                                state1 <= Srequestread;

                                master_address <= parameters[2];
                                master2_address <= parameters[3];
                                words_remaining <= parameters[5];

                                sum <= 0;
                            end

                            1, 2, 3, 4, 5, 7: begin
                                parameters[slave_address] <= slave_writedata;
                            end
                        endcase
                    end
                end

                Srequestread: begin
                    if (!master_waitrequest) begin
                        state1 <= Sread;
                    end
                end

                Sread: begin
                    if (master_readdatavalid) begin
                        sum <= sum + multiplied[47:16];

                        master2_address <= master2_address + 4;
                        words_remaining <= words_remaining - 1;

                        if (words_remaining == 1) begin
                            state1 <= Srequestbias;
                            master_address <= parameters[1];
                        end else begin
                            state1 <= Srequestread;
                            master_address <= master_address + 4;
                        end
                    end
                end

                Srequestbias: begin
                    if (!master_waitrequest) begin
                        state1 <= Sreadbias;
                    end
                end

                Sreadbias: begin
                    if (master_readdatavalid) begin
                        sum <= sum + master_readdata;
                        master2_address <= parameters[4];
                        state1 <= Srequestwrite;
                    end
                end

                Srequestwrite: begin
                    if (!master2_waitrequest) begin
                        state1 <= Sload;
                    end
                end
            endcase
        end
    end

    /* This state machine reads from SRAM and waits for the 1st state machine. */
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state2 <= Sload;
        end else begin
            case(state2)
                Sload: begin
                    if ((state1 == Sread && master_readdatavalid && words_remaining != 1) ||
                        (state1 == Sload && slave_write && slave_address == 0))
                    begin
                            state2 <= Srequestread;
                    end
                end

                Srequestread: begin
                    if (!master2_waitrequest) begin
                        state2 <= Sread;
                    end
                end

                Sread: begin
                    if (master2_readdatavalid) begin
                        state2 <= Sload;
                        sram_data <= {{32{master2_readdata[31]}},master2_readdata};
                    end
                end
            endcase
        end
    end

endmodule: dotoptact
