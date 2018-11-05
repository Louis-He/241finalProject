// stage1
module stage1(CLOCK_50, SW, KEY);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;

	contorl c0(.clk(CLOCK_50),
			   .switches(SW[9:0]));

	datapath d0(.clk(CLOCK_50),
				.switches(SW[9:0]));


endmodule

module control(
	input clk,
	input [9:0] switches,

	output 
	);

endmodule

module datapath(
	input clk,
	input [9:0] switches,
	);

endmodule
//  RAM 64 words x 32 bits
