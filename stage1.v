// stage1
module stage1(CLOCK_50, SW, KEY, LEDR);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;

	wire resetn;
	wire enable;
	assign resetn = KEY[0];

	control c0(.clk(CLOCK_50),
			   .switches(SW[9:0]),
			   .resetn(resetn),

			   .enable(enable));

	datapath d0(.clk(CLOCK_50),
				.switches(SW[9:0]),
				.resetn(resetn),
				.go(enable),

				.address(LEDR[5:0]));

endmodule

module control(
	input clk,
	input [9:0] switches,
	input resetn,

	output enable
	);

	clock_devider clock0(.clk(clk), .resetn(resetn), .speed(switches[2:0]), .slower_clk(enable));

endmodule

module datapath(
	input clk,
	input [9:0] switches,
	input resetn,
	input go,

	output reg [5:0] address
	);

	always @ (posedge clk) begin
		if (~resetn) begin
			address <= 0;
		end
		else begin
			if (go) begin
				address <= address + 1;
			end
		end
	end


endmodule
//  RAM 64 words x 32 bits

module clock_devider(
	input clk,
	input resetn,
	input [2:0] speed,
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
		case (speed)
			3'b000: maxCounter = 27'd75000000;
			3'b001: maxCounter = 27'd50000000;
			3'b010: maxCounter = 27'd37500000;
			3'b011: maxCounter = 27'd30000000;
			3'b100: maxCounter = 27'd25000000;
			3'b101: maxCounter = 27'd21428571;
			3'b110: maxCounter = 27'd16666667;
			3'b111: maxCounter = 27'd13636364;
			default: maxCounter = 27'd50000000;
		endcase
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
