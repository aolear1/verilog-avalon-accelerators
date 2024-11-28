module vga_avalon(input logic clk, input logic reset_n,
                  input logic [3:0] address,
                  input logic read, output logic [31:0] readdata,
                  input logic write, input logic [31:0] writedata,
                  output logic [7:0] vga_red, output logic [7:0] vga_grn, output logic [7:0] vga_blu,
                  output logic vga_hsync, output logic vga_vsync, output logic vga_clk);



    logic [7:0] x;
    logic [6:0] y;
    logic [9:0] vga_red_10, vga_blu_10, vga_grn_10;
    logic [7:0] colour;
    logic plot;

    assign x = writedata[23:16];
    assign y = writedata[30:24];
    assign colour = writedata[7:0];
    assign vga_red = vga_red_10[9:2];
    assign vga_blu = vga_blu_10[9:2];
    assign vga_grn = vga_grn_10[9:2];

    assign plot = write & (x < 160) & (y < 120);

    /*
    enum {Scocked, Sfire} state;
    logic [31:0] olddata;
    logic local_enable, new_vals;
    assign new_vals = (olddata !== writedata);
    assign local_enable = (address == 4'd0) & write & new_vals & (x < 160) & (y < 120);

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state <= Scocked;
            olddata <= writedata;
        end else begin
            case (state)

                Scocked: begin
                    if( local_enable) begin
                        plot <= 1'b1;
                        olddata <= writedata;
                        state <= Sfire;
                    end else begin
                        state <= Scocked;
                    end
                end

                Sfire: begin
                    if( local_enable) begin
                        olddata <= writedata;
                        state <= Sfire;
                    end else begin
                        plot <= 1'b0;
                        state <= Scocked;
                    end
                end
            endcase
        end
    end
    */

    vga_adapter #( .RESOLUTION("160x120"), .MONOCHROME("TRUE"), .BITS_PER_COLOUR_CHANNEL(3) )
	vga(    .resetn(reset_n),
			.clock(clk),
			.colour(colour/*olddata[7:0]*/),
			.x(x/*olddata[23:16]*/),
			.y(y/*olddata[30:24]*/),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(vga_red_10),
			.VGA_G(vga_grn_10),
			.VGA_B(vga_blu_10),
			.VGA_HS(vga_hsync),
			.VGA_VS(vga_vsync),
			.VGA_BLANK(),
			.VGA_SYNC(),
			.VGA_CLK(vga_clk));

    // NOTE: We will ignore the VGA_SYNC and VGA_BLANK signals.
    //       Either don't connect them or connect them to dangling wires.
    //       In addition, the VGA_{R,G,B} should be the upper 8 bits of the VGA module outputs.

endmodule: vga_avalon
