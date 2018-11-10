// stage1
module stage1(CLOCK_50, SW, KEY, LEDR);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;

	wire resetn;
	wire select;
	wire back;
	assign resetn = KEY[0];
	assign select = ~KEY[3];
	assign back = ~KEY[2];

	wire enable;
	wire record_high;
	wire record_reset;
	wire ld_selection;

	control c0(.clk(CLOCK_50),
			   .back(back),
			   .select(select),
			   .go(go),
			   .switches(SW[9:0]),
			   .resetn(resetn),
			   .mode(mode),

			   .enable(enable),
			   .record_high(record_high),
			   .record_reset(record_reset),
			   .ld_selection(ld_selection),
			   .state(LEDR[4:0]));

	datapath d0(.clk(CLOCK_50),
				.switches(SW[9:0]),
				.resetn(resetn),
				.go(enable),

				.address(LEDR[5:0]));

endmodule

module control(
	input clk,
	input back,
	input select,
	input go,
	input [9:0] switches,
	input resetn,

	input mode,

	output enable,
	output record_high,

	output reg record_reset,
	output reg ld_selection,
	output reg [4:0] state
	);

	clock_devider clock0(.clk(clk), .resetn(resetn), .speed(switches[2:0]), .slower_clk(enable), .record_high(record_high));

	// ######################## FINITE STATE MACHINE ##############################
	reg [3:0] current_state;
	reg [3:0] next_state;

	localparam  S_BEGIN              = 5'd0,
				S_SELECT_MODE        = 5'd1,
				S_SELECT_MODE_WAIT   = 5'd2,

				S_WAIT_RECORD        = 5'd4,
				S_WAIT_RECORD_WAIT   = 5'd5,
				S_RECORDING          = 5'd6,
				S_RECORDING_WAIT     = 5'd7,
				S_RECORD_STOP        = 5'd8,
				S_END                = 5'd9;

	// state_table
	always@(*)
    begin: state_table
        case (current_state)
			S_BEGIN: next_state = S_SELECT_MODE;
			S_SELECT_MODE: next_state = select ? S_SELECT_MODE_WAIT : S_SELECT_MODE;
			S_SELECT_MODE_WAIT: begin
				if(select == 0) begin
					if(mode == 2'd1) begin
						next_state = S_WAIT_RECORD;
					end
					/*
					else if (condition) begin

					end
					*/
				end
				else
					next_state = S_SELECT_MODE_WAIT;
			end
			//################### RECORD MODE FSM #################
			S_WAIT_RECORD: begin
				if (back) begin
					next_state = S_SELECT_MODE;
				end
				else if (select) begin
					next_state = S_WAIT_RECORD_WAIT;
				end
				else begin
					next_state = S_WAIT_RECORD;
				end
			end
			S_WAIT_RECORD_WAIT: next_state = select ? S_WAIT_RECORD_WAIT : S_RECORDING;
			S_RECORDING: begin
				if (select) begin
					next_state = S_RECORDING_WAIT;
				end
				else begin
					next_state = S_RECORDING;
				end
			end
			S_RECORDING_WAIT: next_state = select ? S_RECORDING_WAIT : S_RECORD_STOP;
			S_RECORD_STOP: begin
				if (select | back) begin
					next_state = S_END;
				end
				else begin
					next_state = S_RECORD_STOP;
				end
			end
			S_END: next_state = S_BEGIN;
			//################# RECORD MODE FSM END#################
		endcase
	end

	// Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
		ld_selection = 0;
		record_reset = 0;

		case (current_state)
			S_SELECT_MODE:
				ld_selection = 1;
			S_WAIT_RECORD_WAIT:
				record_reset = 1;
		endcase
	end

	// state_FFs
    always@(posedge clk)
	begin: state_FFs


	end

	// ######################## FINITE STATE MACHINE END ##############################

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
	output slower_clk,
	output record_high
	);

	assign slower_clk = (counter == 0) ? 1 : 0;
	assign record_high = (counter < maxCounter - 27'd10000) ? 1 : 0;

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
