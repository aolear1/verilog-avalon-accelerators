module wordcopy(input logic clk, input logic rst_n,
                // slave (CPU-facing)
                output logic slave_waitrequest,
                input logic [3:0] slave_address,
                input logic slave_read, output logic [31:0] slave_readdata,
                input logic slave_write, input logic [31:0] slave_writedata,
                // master (SDRAM-facing)
                input logic master_waitrequest,
                output logic [31:0] master_address,
                output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
                output logic master_write, output logic [31:0] master_writedata);

    enum { Sload, Sread, Smakereadrequest, Smakewriterequest } state;
    logic [31:0] src, dest, words_transferred;

    assign slave_waitrequest = state != Sload;
    assign master_read = state == Smakereadrequest;
    assign master_write = state == Smakewriterequest;
    assign slave_readdata = 32'd0;

    logic [31:0] parameters [0:2];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= Sload;
        end else begin
            case (state)
                /* Load various parameters from NIOS. */
                Sload: begin
                    if (slave_write) begin
                        case(slave_address)
                            4'd0: begin
                                words_transferred <= 1;
                                state <= Smakereadrequest;
                                dest <= parameters[0];
                                src <= parameters[1];
                                master_address <= parameters[1];
                            end

                            4'd1, 4'd2, 4'd3: begin
                                parameters[slave_address-1] <= slave_writedata;
                            end
                        endcase
                    end
                end

                /* Wait for the SDRAM to accept the request. */
                Smakereadrequest: begin
                    if (!master_waitrequest) begin
                        state <= Sread;
                    end
                end

                /* Wait for the SDRAM to assert data is valid. */
                Sread: begin
                    if (master_readdatavalid) begin
                        master_writedata <= master_readdata;
                        master_address <= dest;
                        state <= Smakewriterequest;
                    end
                end

                /* Wait for SDRAM to accept the request. */
                Smakewriterequest: begin
                    if (!master_waitrequest) begin
                        words_transferred <= words_transferred + 1;
                        src <= src + 4;
                        dest <= dest + 4;
                        master_address <= src + 4;

                        if (words_transferred == parameters[2]) begin
                            state <= Sload;
                        end else begin
                            state <= Smakereadrequest;
                        end
                    end
                end
            endcase
        end
    end
endmodule: wordcopy
