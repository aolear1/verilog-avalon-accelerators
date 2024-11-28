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

    assign plot = write & (x < 160) & (y < 120) & (x >= 0) & (y >= 0);

    vga_adapter #( .RESOLUTION("160x120"), .MONOCHROME("TRUE"), .BITS_PER_COLOUR_CHANNEL(8) )
	vga(    .resetn(reset_n),
			.clock(clk),
			.colour(colour),
			.x(x),
			.y(y),
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

endmodule: vga_avalon
