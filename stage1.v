// stage1
module stage1(CLOCK_50, SW, KEY, LEDR);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;

	wire resetn;
	resetn = KEY[0];

	contorl c0(.clk(CLOCK_50),
			   .switches(SW[9:0]),
			   .resetn(resetn),

			   .enable(LEDR[0]));

	datapath d0(.clk(CLOCK_50),
				.switches(SW[9:0]));

endmodule

module control(
	input clk,
	input [9:0] switches,
	input resetn,

	output enable
	);

	clock_devider(.clk(clk), .resetn(resetn), .speed(switches[2:0]), .slower_clk(enable));

endmodule

module datapath(
	input clk,
	input [9:0] switches,
	);

endmodule
//  RAM 64 words x 32 bits

module clock_devider(
	input clk,
	input resetn,
	input speed,
	output slower_clk
	);

	assign slower_clk = (counter == 0) ? 1 : 0;

	reg [26:0] counter; // maximun: 75,000,000
	reg [26:0] maxCounter; // maximun: 75,000,000

	// 000 : 40 nodes/min
	// 001 : 60 nodes/min
	// 002 : 80 nodes/min
	// 003 : 100 nodes/min
	// 004 : 120 nodes/min
	// 005 : 140 nodes/min
	// 006 : 180 nodes/min
	// 007 : 220 nodes/min
	always @ (*) begin
		if (speed == 3'd0)
			maxCounter = 27'd75000000;
		else if (speed == 3'd1)
			maxCounter = 27'd50000000;
		else if (speed == 3'd2)
			maxCounter = 27'd37500000;
		else if (speed == 3'd3)
			maxCounter = 27'd30000000;
		else if (speed == 3'd4)
			maxCounter = 27'd25000000;
		else if (speed == 3'd5)
			maxCounter = 27'd21428571;
		else if (speed == 3'd6)
			maxCounter = 27'd16666667;
		else if (speed == 3'd7)
			maxCounter = 27'd13636364;
	end

	always @ (posedge clk) begin
		if (~resetn)
			counter <= maxCounter - 1;
		else begin
			if (counter == 0) begin
				counter <= maxCounter - 1;
			end
			else begin
				counter <= counter - 1;
			end
		end
	end
endmodule
