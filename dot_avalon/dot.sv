module dot(input logic clk, input logic rst_n,
           // slave (CPU-facing)
           output logic slave_waitrequest,
           input logic [3:0] slave_address,
           input logic slave_read, output logic [31:0] slave_readdata,
           input logic slave_write, input logic [31:0] slave_writedata,
           // master (memory-facing)
           input logic master_waitrequest,
           output logic [31:0] master_address,
           output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
           output logic master_write, output logic [31:0] master_writedata);

    enum {Sload, Scocked1, Sfire1, Scocked2, Sfire2} state;
    logic [31:0] words_used, vec1_data, vec1_addr, vec2_addr;

    logic [31:0] parameters [0:4];

    assign slave_waitrequest = (state != Sload);
    assign master_read = ((state == Scocked1) | (state == Scocked2));
    assign master_write = 0;

    logic [63:0] dataMult;
    assign dataMult = {{32{vec1_data[31]}},vec1_data} * {{32{master_readdata[31]}},master_readdata};

    logic signed [31:0] sum;
    assign slave_readdata = sum;


    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= Sload;
        end else begin
            case (state)
                Sload: begin
                    if (slave_write) begin
                        case(slave_address)
                            4'd0: begin
                                words_used <= 1;
                                vec2_addr <= parameters[2];
                                vec1_addr <= parameters[1];
                                master_address <= parameters[1];
                                sum <= 0;
                                state <= Scocked1;
                            end

                            4'd2, 4'd3, 4'd5: begin
                                parameters[slave_address-1] <= slave_writedata;
                            end
                        endcase
                    end else begin
                        state <= Sload;
                    end
                end

                 /* Wait for the SDRAM to accept a read request to the first vector*/
                Scocked1: begin
                    if(!master_waitrequest) begin
                        state <= Sfire1;
                    end else begin
                        state <= Scocked1;
                    end
                end

                /* Wait for the SDRAM to assert data is valid and stores it*/
                Sfire1: begin
                    if(master_readdatavalid) begin
                        vec1_data <= master_readdata;
                        master_address <= vec2_addr;
                        state <= Scocked2;
                    end else begin
                        state <= Sfire1;
                    end
                end

                /* Wait for the SDRAM to accept a read request to the second vector*/
                Scocked2: begin
                    if(!master_waitrequest) begin
                        state <= Sfire2;
                    end else begin
                        state <= Scocked2;
                    end
                end

                /* Wait for the SDRAM to assert data, updates sum, and addresses*/
                Sfire2: begin
                    if(master_readdatavalid) begin
                        sum <= sum + dataMult[47:16];
                        if (words_used == parameters[4]) begin
                            state <= Sload;
                        end else begin
                            words_used <= words_used + 1;
                            vec2_addr <= vec2_addr + 4;
                            vec1_addr <= vec1_addr + 4;
                            master_address <= vec1_addr + 4;
                            state <= Scocked1;
                        end
                    end else begin
                        state <= Sfire2;
                    end
                end
            endcase
        end
    end

endmodule: dot
