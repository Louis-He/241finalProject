// stage1
module stage1(CLOCK_50, GPIO_0, SW, KEY, LEDR,HEX0,HEX1,HEX5);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	input [19:0] GPIO_0;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX5;

	// board based input
	wire resetn;
	wire select;
	wire back;
	assign resetn = KEY[0];
	assign select = ~KEY[3];
	assign back = ~KEY[2];

	// clock like pulse
	wire enable; // once per note
	wire record_high; // 1 = record, 0 = DO NOT record

	// GPIO_0 input signals
	wire[5:0] strings = {{{{{GPIO_0[1], GPIO_0[3]}, GPIO_0[5]}, GPIO_0[7]}, GPIO_0[9]}, GPIO_0[11]};
	wire[4:0] pbars = {{{{GPIO_0[13], GPIO_0[15]}, GPIO_0[17]}, GPIO_0[19]}, 1'b0}; // pbars[0] : Dont Care term
	wire[31:0] note;

	//assign LEDR[9] = GPIO_0[1];
	//assign LEDR[7] = record_high;

	// output signals from control
	wire record_reset; // reset recording part
	wire is_record; // wheather recording sound
	wire is_play; // whether for playing sound
	wire [4:0] state;

	assign LEDR[0] = GPIO_0[1];
	assign LEDR[1] = enable;
	assign LEDR[2] = is_record;
	assign LEDR[3] = is_play;

	control c0(.clk(CLOCK_50),
			   .back(back),
			   .select(select),
			   .go(go),
			   .switches(SW[9:0]),
			   .resetn(resetn),

			   .enable(enable),
			   .record_high(record_high),

			   .record_reset(record_reset),
			   .is_play(is_play),
			   .is_record(is_record),
			   .state(state));

	datapath d0(.clk(CLOCK_50),
			    .is_record(is_record),
				.is_play(is_play),

				.go(record_high),
				.increment_address(enable),
				.reset_address(record_reset),

				.S(strings),
				.P(pbars),

				.note_out(note[31:0]),
				.address(LEDR[9:4]));
	////convert datapath output to HEX display output
	wire [3:0] hex_digit1, hex_digit2;

  	note_to_hex n0(.note_out(note), .hex_digit1(hex_digit1), .hex_digit2(hex_digit2));

	hex_decoder H0(
        .hex_digit(hex_digit1[3:0]),
        .segments(HEX0)
        );

    hex_decoder H1(
        .hex_digit(hex_digit2[3:0]),
        .segments(HEX1)
        );

	hex_decoder H5(
        .hex_digit(state[3:0]),
        .segments(HEX5)
        );

endmodule

module control(
	input clk,
	input back,
	input select,
	input go,
	input [9:0] switches,
	input resetn,

	output enable,
	output record_high,

	output reg record_reset,
	output reg is_record,
	output reg is_play,
	output [4:0] state
	);

	clock_devider clock0(.clk(clk), .resetn(resetn), .speed(switches[9:7]), .slower_clk(enable), .record_high(record_high));

	// ######################## FINITE STATE MACHINE ##############################
	reg [3:0] current_state;
	reg [3:0] next_state;
	assign state = current_state;

	localparam  S_BEGIN              = 5'd0,
				S_SELECT_MODE        = 5'd1,
				S_SELECT_MODE_WAIT   = 5'd2,

				S_WAIT_RECORD        = 5'd4,
				S_WAIT_RECORD_WAIT   = 5'd5,
				S_RECORDING          = 5'd6,
				S_RECORDING_WAIT     = 5'd7,
				S_RECORD_STOP        = 5'd8,
				S_RECORD_STOP_WAIT   = 5'd9,

				S_WAIT_PLAY          = 5'd10,
				S_WAIT_PLAY_WAIT     = 5'd11,
				S_PLAYING            = 5'd12,
				S_PLAYING_WAIT       = 5'd13,
				S_PLAY_STOP          = 5'd14,
				S_PLAY_STOP_WAIT     = 5'd15,

				S_END                = 5'd16;

	// state_table
	always@(*)
    begin: state_table
        case (current_state)
			S_BEGIN: next_state = S_SELECT_MODE;
			S_SELECT_MODE: next_state = select ? S_SELECT_MODE_WAIT : S_SELECT_MODE;
			S_SELECT_MODE_WAIT: begin
				if(select == 0) begin
					if (switches[1:0] == 2'b0) begin
						next_state = S_WAIT_PLAY;
					end
					else if(switches[1:0] == 2'b1) begin
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
					next_state = S_RECORD_STOP_WAIT;
				end
				else begin
					next_state = S_RECORD_STOP;
				end
			end
			S_RECORD_STOP_WAIT: next_state = select ? S_RECORD_STOP_WAIT : S_END;
			//################# RECORD MODE FSM END#################

			//#################### PLAY MODE FSM ###################
			S_WAIT_PLAY: begin
				if (back) begin
					next_state = S_SELECT_MODE;
				end
				else if (select) begin
					next_state = S_WAIT_PLAY_WAIT;
				end
				else begin
					next_state = S_WAIT_PLAY;
				end
			end
			S_WAIT_PLAY_WAIT: next_state = select ? S_WAIT_PLAY_WAIT : S_PLAYING;
			S_PLAYING: begin
				if (select) begin
					next_state = S_PLAYING_WAIT;
				end
				else begin
					next_state = S_PLAYING;
				end
			end
			S_PLAYING_WAIT: next_state = select ? S_PLAYING_WAIT : S_PLAY_STOP;
			S_PLAY_STOP: begin
				if (select | back) begin
					next_state = S_PLAY_STOP_WAIT;
				end
				else begin
					next_state = S_PLAY_STOP;
				end
			end
			S_PLAY_STOP_WAIT: next_state = select ? S_PLAY_STOP_WAIT : S_END;
			//################## PLAY MODE FSM END##################

			S_END: next_state = S_BEGIN;
		endcase
	end

	// Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
		record_reset = 0;
		is_record = 0;
		is_play = 0;

		case (current_state)
			S_WAIT_RECORD:
				record_reset = 1;     //this signal correspond to reset address
			S_WAIT_RECORD_WAIT:
				record_reset = 1;     //this signal correspond to reset address
			S_RECORDING:
				is_record = 1;       //is_record=1 record
			S_RECORDING_WAIT:
				is_record = 1;
			S_PLAYING:
				is_play = 1;         //is_play=1 play
			S_PLAYING_WAIT:
				is_play = 1;
		endcase
	end

	// state_FFs
    always@(posedge clk)
	begin: state_FFs
		if(!resetn) begin
			current_state <= S_BEGIN;
		end
		else begin
			current_state <= next_state;
		end
	end

	// ######################## FINITE STATE MACHINE END ##############################

endmodule

////////////////////////////////Data Path///////////////////////////////
module datapath(
   	input clk,
                    //is_record,is_play,go,reset address are required signal from control
	input is_record, //is_record=1 record
	input is_play,   //is_play=1 play

	input go,
	input increment_address,
	input reset_address,

	input [5:0] S,//6 strings input from the guitar
	input [4:0] P,//4 horizontal metal bar + (no bar is pressed)
	              //for convenience P[4:1]represent the bar[4:1] been pressed
				  //P[0]take no input and is the don't care term

	output reg [31:0] note_out, //output to the audio module
	output reg [5:0] address
	);
	//reg [5:0] address;
	//make the address to increase when record
	always @ (negedge increment_address) begin
		if (reset_address) begin
			address <= 6'b0;
		end
		else begin
			address <= address + 6'b000001;
		end
	end

	reg [5:0] s;
	reg [4:0] p;

	//wren to the ram depends on is_record and is play
	reg wren;

	//process of record
	always @ (posedge clk) begin
		// Now the [4:0]s,p store all information during go=1
		if(go) begin
		  if(S[0]==1)
		     s[0] <= 1'b1;
		  if(S[1]==1)
		     s[1] <= 1'b0;
		  if(S[2]==1)
		     s[2] <= 1'b1;
		  if(S[3]==1)
		     s[3] <= 1'b1;
		  if(S[4]==1)
		     s[4] <= 1'b1;
		  if(S[5]==1)
		     s[5] <= 1'b1;

		  if((P[1]==0)&(P[2]==0)&(P[3]==0)&(P[4]==0)) //no bar is pressed
		     p[0] <= 1'b1;
		  if((P[1]==1)&(P[2]==0)&(P[3]==0)&(P[4]==0))
		     p[1] <= 1'b1;
		  if((P[2]==1)&(P[3]==0)&(P[4]==0))
		     p[2] <= 1'b1;
		  if((P[3]==1)&(P[4]==0))
		     p[3] <= 1'b1;
		  if(P[4]==1)
		     p[4] <= 1'b1;
		end
		// start of next go(go is now 0),Note should be cleared
		else begin
			s[5:0] <= 6'b0;
			p[4:0] <= 5'b0;
		end
		//assign wren correspond to current mode
		if (is_record==1'b1)//when recoding
			wren <= 1'b1;
		if (is_record==1'b0)//finish recording
			wren <= 1'b0;
	end

	//
	wire [31:0] Note,note;
	coordinates_converter C_C0(.S(s), .P(p), .note(Note));

	// NOTICE: NOT GUARENTEE CORRECT
	// previous: clock(~go)
   	ram64x32 r(.data(Note), .wren(wren), .address(address), .clock(clk), .q(note));
	//when go=0, is_record=1,bits are loaded to the ram
	//when go=0, is_record=0,bits are read from the ram

	//output from ram to audio
	always@(*) begin
		if (is_record == 1'b1)//when recoding
			note_out = note;
		if (is_play == 1'b1)//when replay
			note_out = note;
		if((is_record == 1'b0) & (is_play == 1'b0))
		   	note_out = 32'b0;
	end

endmodule
////////////////////////////////End of Datapath////////////////////////////////

//[4:0]S,P to coordinates converter
module coordinates_converter(S,P,note);
	input [5:0]S;
	input [4:0]P;
	output[31:0]note;

	//if no P is pushed P[0]=1;
	wire p_0;
	assign p_0=(~P[1])&(~P[2])&(~P[3])&(~P[4]);

	assign note[0]=S[0]&p_0;
	assign note[1]=S[1]&p_0;
	assign note[2]=S[2]&p_0;
	assign note[3]=S[3]&p_0;
	assign note[4]=S[4]&p_0;
	assign note[5]=S[5]&p_0;

	assign note[6]=S[0]&P[1];
	assign note[7]=S[1]&P[1];
	assign note[8]=S[2]&P[1];
	assign note[9]=S[3]&P[1];
	assign note[10]=S[4]&P[1];
	assign note[11]=S[5]&P[1];

	assign note[12]=S[0]&P[2];
	assign note[13]=S[1]&P[2];
	assign note[14]=S[2]&P[2];
	assign note[15]=S[3]&P[2];
	assign note[16]=S[4]&P[2];
	assign note[17]=S[5]&P[2];

	assign note[18]=S[0]&P[3];
	assign note[19]=S[1]&P[3];
	assign note[20]=S[2]&P[3];
	assign note[21]=S[3]&P[3];
	assign note[22]=S[4]&P[3];
	assign note[23]=S[5]&P[3];

	assign note[24]=S[0]&P[4];
	assign note[25]=S[1]&P[4];
	assign note[26]=S[2]&P[4];
	assign note[27]=S[3]&P[4];
	assign note[28]=S[4]&P[4];
	assign note[29]=S[5]&P[4];


	assign note[31:30]= 2'b00;
endmodule
////////////////////////////////////////////////////////////////////////////////////////////
//convert note output to hex
module note_to_hex(note_out, hex_digit1, hex_digit2);
    input [31:0] note_out;
    output reg [3:0] hex_digit1,hex_digit2;
	always @(*) begin
        case (note_out[15:0])
           16'd0: hex_digit1 = 4'h0;
			  16'd1: hex_digit1 = 4'h1;
			  16'd2: hex_digit1 = 4'h2;
			  16'd3: hex_digit1 = 4'h3;

			  16'd4: hex_digit1 = 4'h4;
			  16'd5: hex_digit1 = 4'h5;
			  16'd6: hex_digit1 = 4'h6;
			  16'd7: hex_digit1 = 4'h7;

			  16'd8: hex_digit1 = 4'h8;
			  16'd9: hex_digit1 = 4'h9;
			  16'd10: hex_digit1 = 4'hA;
			  16'd11: hex_digit1 = 4'hB;

			  16'd12: hex_digit1 = 4'hC;
			  16'd13: hex_digit1 = 4'hD;
			  16'd14: hex_digit1 = 4'hE;
			  16'd15: hex_digit1 = 4'hF;
		endcase
	end

	always @(*) begin
        case (note_out[31:16])
           16'd0: hex_digit2 = 4'h0;
			  16'd1: hex_digit2 = 4'h1;
			  16'd2: hex_digit2 = 4'h2;
			  16'd3: hex_digit2 = 4'h3;

			  16'd4: hex_digit2 = 4'h4;
			  16'd5: hex_digit2 = 4'h5;
			  16'd6: hex_digit2 = 4'h6;
			  16'd7: hex_digit2 = 4'h7;

			  16'd8: hex_digit2 = 4'h8;
			  16'd9: hex_digit2 = 4'h9;
			  16'd10: hex_digit2 = 4'hA;
			  16'd11: hex_digit2 = 4'hB;

			  16'd12: hex_digit2 = 4'hC;
			  16'd13: hex_digit2 = 4'hD;
			  16'd14: hex_digit2 = 4'hE;
			  16'd15: hex_digit2 = 4'hF;
		endcase
	end
endmodule

//hex display for the note output
module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule
/////////////////////////////////////////////////////////////////////////////////////////

//clock_divider
module clock_devider(
	input clk,
	input resetn,
	input [2:0] speed,
	output slower_clk,
	output record_high
	);

	reg [26:0] counter; // maximun: 75,000,000
	reg [26:0] maxCounter; // maximun: 75,000,000

	assign slower_clk = (counter == 27'd0) ? 1 : 0;
	assign record_high = (counter > 27'd1000) ? 1 : 0;

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
			counter <= maxCounter - 1'b1;
		else begin
			if (counter == 0) begin
				counter <= maxCounter - 1'b1;
			end
			else begin
				counter <= counter - 1'b1;
			end
		end
	end
endmodule
