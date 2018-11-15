// stage1
module stage1(CLOCK_50, GPIO_0, SW, KEY, LEDR, HEX0, HEX1, HEX5, VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B);   						//	VGA Blue[9:0]);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	input [21:0] GPIO_0;
	output [9:0] LEDR;
	output [6:0] HEX0, HEX1, HEX5;
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]


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
	wire[5:0] strings = {{{{{~GPIO_0[3], ~GPIO_0[5]}, ~GPIO_0[7]}, ~GPIO_0[9]}, ~GPIO_0[11]}, ~GPIO_0[13]};
	wire[4:0] pbars = {{{{~GPIO_0[15], ~GPIO_0[17]}, ~GPIO_0[19]}, ~GPIO_0[21]}, 1'b0}; // pbars[0] : Dont Care term
	wire[31:0] note;

	// output signals from control
	wire record_reset; // reset recording part
	wire is_record; // wheather recording sound
	wire is_play; // whether for playing sound
	wire [4:0] state;

	// signals and wires for VGA
	wire colour_out_note_background; // from RAM
	wire [5:0] colour_out_background; // from RAM
	wire [2:0] colour_out_arrow; // from RAM
	wire [5:0] colour_out_singlenotePic; // from RAM

	wire clearAllCounter;
	wire [3:0] ld_pic_NO;
	wire ld_plot;
	wire is_black;
	wire initializeX;
	wire initializeY;
	wire incrementX;
	wire incrementY;
	wire [7:0] initialX;
	wire [6:0] initialY;
	wire [7:0] counterX;
	wire [6:0] counterY;
	wire [7:0] x;
	wire [6:0] y;
	wire [2:0] colour;
	wire [14:0] draw_address;

	assign LEDR[9:0] = draw_address;

	control c0(.clk(CLOCK_50),
			   .back(back),
			   .select(select),
			   .go(go),
			   .switches(SW[9:0]),
			   .resetn(resetn),

			   .clearAllCounter(clearAllCounter),
			   .ld_pic_NO(ld_pic_NO),
			   .ld_plot(ld_plot),
			   .is_black(is_black),
		   	   .initializeX(initializeX),
			   .initializeY(initializeY),
		   	   .incrementX(incrementX),
		   	   .incrementY(incrementY),
		   	   .initialX(initialX),
		   	   .initialY(initialY),

			   .counterX(counterX),
			   .counterY(counterY),

			   .enable(enable),
			   .record_high(record_high),

			   .record_reset(record_reset),
			   .is_play(is_play),
			   .is_record(is_record),
			   .state(state));

	datapath d0(.clk(CLOCK_50),
				.resetn(resetn),
			    .is_record(is_record),
				.is_play(is_play),

				.go(record_high),
				.reset_address(record_reset),

				.S(strings),
				.P(pbars),

				.colour_in_note_background(colour_out_note_background),
				.colour_in_background(colour_out_background),

				.clearAllCounter(clearAllCounter),
				.ld_pic_NO(ld_pic_NO),
				.ld_plot(ld_plot),
				.is_black(is_black),
 		   	    .initializeX(initializeX),
 			    .initializeY(initializeY),
 		   	    .incrementX(incrementX),
 		   	    .incrementY(incrementY),
 		   	    .initialX(initialX),
 		   	    .initialY(initialY),

				.x(x),
				.y(y),
				.counterX(counterX),
 			    .counterY(counterY),
				.draw_address(draw_address),
				.colour(colour),

				.note_out(note[31:0]),
				.address());

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(ld_plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// VGA pictures
	single_note singlenotePic(.address(draw_address), .clock(CLOCK_50), .data(3'b000), .wren(1'b0), .q(colour_out_singlenotePic));
	arrow arrowPic(.address(draw_address), .clock(CLOCK_50), .data(3'b000), .wren(1'b0), .q(colour_out_arrow));
	note_background notePic(.address(draw_address), .clock(CLOCK_50), .data(1'b0), .wren(1'b0), .q(colour_out_note_background));
	background backgroundPic(.address(draw_address), .clock(CLOCK_50), .data(6'b000000), .wren(1'b0), .q(colour_out_background));

	////convert datapath output to HEX display output
	wire [3:0] hex_digit1, hex_digit2;

  	note_to_hex n0(.note_out(note), .hex_digit1(hex_digit1), .hex_digit2(hex_digit2));

	// HEX output
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
	/*
	hex_decoder H0(
        .hex_digit(note[3:0]),
        .segments(HEX0)
        );

    hex_decoder H1(
        .hex_digit(note[7:4]),
        .segments(HEX1)
        );

	hex_decoder H2(
        .hex_digit(note[11:8]),
        .segments(HEX2)
        );

    hex_decoder H3(
        .hex_digit(note[15:12]),
        .segments(HEX3)
        );

	hex_decoder H4(
        .hex_digit(note[19:16]),
        .segments(HEX4)
        );

	hex_decoder H5(
        .hex_digit(note[23:20]),
        .segments(HEX5)
        );
		*/
endmodule

module control(
	input clk,
	input back,
	input select,
	input go,
	input [9:0] switches,
	input resetn,

	// input signals for VGA
	input [7:0] counterX,
	input [6:0] counterY,

	// output signals for VGA
	output reg clearAllCounter,
	output reg [3:0] ld_pic_NO,
	output reg ld_plot,
	output reg is_black,
	output reg initializeX,
	output reg initializeY,
	output reg incrementX,
	output reg incrementY,
	output reg [7:0] initialX,
	output reg [6:0] initialY,

	output enable,
	output record_high,

	output reg record_reset,
	output reg is_record,
	output reg is_play,
	output [4:0] state
	);

	clock_devider clock0(.clk(clk), .resetn(resetn), .speed(switches[9:7]), .slower_clk(enable), .record_high(record_high));

	// ######################## FINITE STATE MACHINE ##############################
	// WHOLE FSM
	reg [4:0] current_state;
	reg [4:0] next_state;
	assign state = current_state;
	// parameter stable_table
	localparam  S_BEGIN                     = 5'd0,
			    S_PLOT_BACKGROUND_CLEAR     = 5'd1,
				S_PLOT_BACKGROUND           = 5'd2,
				S_SELECT_MODE               = 5'd3,
				S_SELECT_MODE_WAIT          = 5'd4,

				S_PLOT_NOTEBACKGROUND_CLEAR = 5'd5,
				S_PLOT_NOTEBACKGROUND       = 5'd6,

				S_WAIT_RECORD               = 5'd7,
				S_WAIT_RECORD_WAIT          = 5'd8,
				S_RECORDING                 = 5'd9,
				S_RECORDING_WAIT            = 5'd10,
				S_RECORD_STOP               = 5'd11,
				S_RECORD_STOP_WAIT          = 5'd12,

				S_WAIT_PLAY                 = 5'd13,
				S_WAIT_PLAY_WAIT            = 5'd14,
				S_PLAYING                   = 5'd15,
				S_PLAYING_WAIT              = 5'd16,
				S_PLAY_STOP                 = 5'd17,
				S_PLAY_STOP_WAIT            = 5'd18,

				S_END                       = 5'd19;
	// state_table
	always@(*)
    begin: state_table
        case (current_state)
			S_BEGIN: next_state = S_PLOT_BACKGROUND_CLEAR;
			S_PLOT_BACKGROUND_CLEAR: next_state = S_PLOT_BACKGROUND;
			S_PLOT_BACKGROUND: begin
				if(counterX == 8'd160 & counterY == 7'd120)
					next_state = S_SELECT_MODE;
				else
					next_state = S_PLOT_BACKGROUND;
			end
			S_SELECT_MODE: next_state = select ? S_SELECT_MODE_WAIT : S_SELECT_MODE;
			S_SELECT_MODE_WAIT: next_state = S_PLOT_BACKGROUND_CLEAR;
			S_PLOT_NOTEBACKGROUND_CLEAR: next_state = S_PLOT_NOTEBACKGROUND;
			S_PLOT_NOTEBACKGROUND: begin
				if(counterX == 8'd160 & counterY == 7'd120 ) begin
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
						else
							next_state = S_PLOT_NOTEBACKGROUND;
					end
				end
				else
					next_state = S_PLOT_NOTEBACKGROUND;
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

	// PLOT FSM
	reg [3:0] plot_current_state;
	reg [3:0] plot_next_state;
	// parameter plot_state_table
	localparam  P_INIT     = 4'd0;
	localparam  P_CLEAR    = 4'd1;
	localparam  P_PLOT     = 4'd2;
	// plot_state_table
	always@(*) begin: plot_state_table
		case(plot_current_state)
			P_INIT: plot_next_state = is_record ? P_CLEAR : P_INIT;
			P_CLEAR: plot_next_state = P_PLOT;
			P_PLOT: begin
				ld_pic_NO = 3'd2;
				ld_plot = 1'b1;
				initialX = 8'b00000000;
				initialY = 7'b0000000;
				if(counterX < 8'd159)
					incrementX = 1;
				else if(counterY < 7'd120) begin
					initializeX = 1;
					incrementY = 1;
			end
		endcase
	end

	// Output logic aka all of our datapath control signals
    always@(*) begin: enable_signals
		record_reset = 0;
		is_record = 0;
		is_play = 0;
		clearAllCounter = 0;
		ld_pic_NO = 3'd0;
		ld_plot = 0;
		is_black = 0;
		initializeX = 0;
		initializeY = 0;
		incrementX = 0;
		incrementY = 0;
		initialX = 8'b00000000;
		initialY = 7'b0000000;

		case (current_state)
			S_PLOT_BACKGROUND_CLEAR:
				clearAllCounter = 1;
			S_PLOT_BACKGROUND: begin
				ld_pic_NO = 3'd0;
				ld_plot = 1'b1;
				initialX = 8'b00000000;
				initialY = 7'b0000000;
				if(counterX < 8'd159)
					incrementX = 1;
				else if(counterY < 7'd120) begin
					initializeX = 1;
					incrementY = 1;
				end
			end
			S_PLOT_NOTEBACKGROUND_CLEAR:
				clearAllCounter = 1;
			S_PLOT_NOTEBACKGROUND: begin
				ld_pic_NO = 3'd1;
				ld_plot = 1'b1;
				initialX = 8'b00000000;
				initialY = 7'b0000000;
				if(counterX < 8'd159)
					incrementX = 1;
				else if(counterY < 7'd120) begin
					initializeX = 1;
					incrementY = 1;
				end
			end
			S_WAIT_RECORD:
				record_reset = 1;     //this signal correspond to reset address
			S_WAIT_RECORD_WAIT:
				record_reset = 1;     //this signal correspond to reset address
			S_RECORDING:
				is_record = 1;       //is_record=1 record
			S_RECORDING_WAIT:
				is_record = 1;
			S_WAIT_PLAY:
				record_reset = 1;
			S_WAIT_PLAY_WAIT:
				record_reset = 1;
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

module datapath(
   	input clk,
                    //is_record,is_play,go,reset address are required signal from control
	input resetn,
	input is_record, //is_record=1 record
	input is_play,   //is_play=1 play

	input go,
	input increment_address,
	input reset_address,

	input [5:0] S,//6 strings input from the guitar
	input [4:0] P,//4 horizontal metal bar + (no bar is pressed)
	              //for convenience P[4:1]represent the bar[4:1] been pressed
				  //P[0]take no input and is the don't care term

	// input signals for VGA
	input clearAllCounter,
	input [3:0] ld_pic_NO,
	input ld_plot,
	input is_black,
	input initializeX,
	input initializeY,
	input incrementX,
	input incrementY,
	input [7:0] initialX,
	input [6:0] initialY,

	input colour_in_note_background,
	input [5:0]colour_in_background,

	// output signals for VGA
	output reg [7:0] x,
	output reg [6:0] y,
	output reg [7:0] counterX,
	output reg [6:0] counterY,
	output reg [14:0] draw_address,
	output reg [2:0] colour,

	output reg [31:0] note_out, //output to the audio module
	output reg [5:0] address
	);
	//reg [5:0] address;
	//make the address to increase when record
	always @ (posedge go) begin
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
		if(~resetn | clearAllCounter) begin
			counterX <= 8'b0;
			x <= initialX;
			counterY <= 7'b0;
			y <= initialY;
			draw_address <= 15'b0 + 15'b1;
		end
		else begin
			// Now the [4:0]s,p store all information during go=1
			if(go) begin
			  if(S[0]==1)
			     s[0] <= 1'b1;
			  if(S[1]==1)
			     s[1] <= 1'b1;
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
			  else if((P[1]==1)&(P[2]==0)&(P[3]==0)&(P[4]==0))
			     p[1] <= 1'b1;
			  else if((P[2]==1)&(P[3]==0)&(P[4]==0))
			     p[2] <= 1'b1;
			  else if((P[3]==1)&(P[4]==0))
			     p[3] <= 1'b1;
			  else if(P[4]==1)
			     p[4] <= 1'b1;
			end
			// start of next go(go is now 0),Note should be cleared
			else begin
				s[5:0] <= 6'b0;
				p[4:0] <= 5'b0;
			end

			if (is_record==1'b1) //when recoding
				wren <= 1'b1;
			if (is_record==1'b0) //finish recording
				wren <= 1'b0;

			// VGA if statements
			if (ld_plot) begin
				draw_address <= draw_address + 1;
			end
			else begin
				draw_address <= 15'b0 - 1;
				x <= initialX;
				y <= initialY;
			end

			if (initializeX) begin
				x <= initialX;
				counterX <= 0;
			end
			if (initializeY) begin
				y <= initialY;
				counterY <= 0;
			end
			if (incrementX) begin
				x <= x + 1;
				counterX <= counterX + 1;
			end
			if (incrementY) begin
				y <= y + 1;
				counterY <= counterY + 1;
			end
			if (is_black)
				colour <= 3'b000;
			else if(ld_pic_NO == 3'd0)
				colour <= colour_in_background;
			else if(ld_pic_NO == 3'd1)
				colour <= {6{colour_in_note_background}};
		end
	end

	wire [31:0] Note,note;
	coordinates_converter C_C0(.S(s), .P(p), .note(Note)); //

   	ram64x32 r(.data(Note), .wren(wren), .address(address), .clock(~go), .q(note));
	//when go=0, is_record=1,bits are loaded to the ram
	//when go=0, is_record=0,bits are read from the ram

	//output from ram to audio
	always@(*) begin
		if (is_record == 1'b1)//when recoding
			note_out = note;
		if (is_play == 1'b1)//when replay
			note_out = note;
		if((is_record == 1'b0)&(is_play == 1'b0))
		   	note_out = 32'b0;
	end

endmodule

//[4:0]S,P to coordinates converter
module coordinates_converter(S, P, note);
	input [5:0] S;
	input [4:0] P;
	output[31:0] note;

	//if no P is pushed P[0]=1;
	wire p_0;
	assign p_0=((~P[1])&(~P[2])&(~P[3])&(~P[4]));

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

	assign note[31:30] = 2'b00;
endmodule

module note_to_hex(note_out, hex_digit1, hex_digit2);
    input [31:0] note_out;
    output reg [3:0] hex_digit1,hex_digit2;

	always @(*) begin
    case (note_out[15:0])
       	  16'b0000000000000001: hex_digit1 = 4'h0;
		  16'b0000000000000010: hex_digit1 = 4'h1;
		  16'b0000000000000100: hex_digit1 = 4'h2;
		  16'b0000000000001000: hex_digit1 = 4'h3;

		  16'b0000000000010000: hex_digit1 = 4'h4;
		  16'b0000000000100000: hex_digit1 = 4'h5;
		  16'b0000000001000000: hex_digit1 = 4'h6;
		  16'b0000000010000000: hex_digit1 = 4'h7;

		  16'b0000000100000000: hex_digit1 = 4'h8;
		  16'b0000001000000000: hex_digit1 = 4'h9;
		  16'b0000010000000000: hex_digit1 = 4'hA;
		  16'b0000100000000000: hex_digit1 = 4'hB;

		  16'b0001000000000000: hex_digit1 = 4'hC;
		  16'b0010000000000000: hex_digit1 = 4'hD;
		  16'b0100000000000000: hex_digit1 = 4'hE;
		  16'b1000000000000000: hex_digit1 = 4'hF;
		  default:hex_digit1 = 4'hF;
	endcase
	end
	always @(*) begin
    case (note_out[31:16])
       	  16'b0000000000000001: hex_digit2 = 4'h0;
		  16'b0000000000000010: hex_digit2 = 4'h1;
		  16'b0000000000000100: hex_digit2 = 4'h2;
		  16'b0000000000001000: hex_digit2 = 4'h3;

		  16'b0000000000010000: hex_digit2 = 4'h4;
		  16'b0000000000100000: hex_digit2 = 4'h5;
		  16'b0000000001000000: hex_digit2 = 4'h6;
		  16'b0000000010000000: hex_digit2 = 4'h7;

		  16'b0000000100000000: hex_digit2 = 4'h8;
		  16'b0000001000000000: hex_digit2 = 4'h9;
		  16'b0000010000000000: hex_digit2 = 4'hA;
		  16'b0000100000000000: hex_digit2 = 4'hB;

		  16'b0001000000000000: hex_digit2 = 4'hC;
		  16'b0010000000000000: hex_digit2 = 4'hD;
		  16'b0100000000000000: hex_digit2 = 4'hE;
		  16'b1000000000000000: hex_digit2 = 4'hF;
		  default:hex_digit2 = 4'hF;
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

//clock_divider
module clock_devider(
	input clk,
	input resetn,
	input [2:0] speed,
	output slower_clk,
	output reg record_high
	);

	reg [26:0] counter; // maximun: 75,000,000
	reg [26:0] maxCounter; // maximun: 75,000,000

	assign slower_clk = (counter == 27'd0) ? 1 : 0;
	// assign record_high = (counter > 27'd10000) ? 1 : 0;

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

		if (counter < 27'd10000)
			record_high <= 0;
		else
			record_high <= 1;
	end
endmodule


/////////////////////////////////THIS MODULE FOR NOTE OUT TO X Y COORD TO DISPLAY/////////////////////////////////
module Note_out_to_coord(note_out,X,Y);
	input [31:0] note_out; //note_out singal from datapath
	output reg[2:0] X; // metal bars
	output reg[2:0] Y;
	
	always @(*)
begin
	case(note_out)
		32'd1: begin
		       X = 3'd0; 
		       Y = 3'd0;
				 end 
		32'd2: begin
		       X = 3'd0; 
		       Y = 3'd1;
				 end 
		32'd4: begin
		       X = 3'd0; 
		       Y = 3'd2;
				 end 
		32'd8: begin
		       X = 3'd0; 
		       Y = 3'd3;
				 end 
		32'd16: begin
		       X = 3'd0; 
		       Y = 3'd4;
				 end  
		32'd32: begin
		       X = 3'd0;
				 Y=3'd5;
				 end 
///////////////////		
		32'd64: begin
		       X = 3'd1; 
				 Y=3'd0; 
				 end
		32'd128: begin
		        X = 3'd1;
				  Y=3'd1; 
				  end
		32'd256: begin
		         X = 3'd1;
					Y=3'd2;
				   end	
		32'd512: begin
					X = 3'd1; 
					Y=3'd3;
					end 
		32'd1024: begin
					X = 3'd1;
					Y=3'd4;
					end 
		32'd2048: begin
					X = 3'd1;
					Y=3'd5; 
					end
////////////////////		
		32'd4096:begin 
					X = 3'd2; 
					Y=3'd0;
					end
		32'd8192:begin 
					X = 3'd2; 
					Y=3'd1;
					end 
		32'd16384:begin 
					X = 3'd2; 
					Y=3'd2;
					end 
		32'd32768:begin 
					X = 3'd2;
					Y=3'd3;
					end 
		32'd65536:begin
					X = 3'd2; 
					Y=3'd4;
					end 
		32'd131072:begin 
					X = 3'd2; 
					Y=3'd5;
					end 
/////////////////////		
		32'd262144:begin 
					X = 3'd3;
					Y=3'd0;
					end 
		32'd524288:begin 
					X = 3'd3; 
					Y=3'd1;
					end 
		32'd1048576:begin
					X = 3'd3; 
					Y=3'd2;
					end 
		32'd2097152:begin
					X = 3'd3;
					Y=3'd3; 
					end
		32'd4194304:begin 
					X = 3'd3;
					Y=3'd4;
					end
		32'd8388608:begin
					X = 3'd3;
					Y=3'd5;
					end
//////////////////////		
		32'd16777216:begin
					X = 3'd4;
					Y=3'd0;
					end 
		32'd33554432:begin
					X = 3'd4;
					Y=3'd1;
					end 
		32'd67108864:begin
					X = 3'd4;
					Y=3'd2;
					end 
		32'd134217728:begin
					X = 3'd4;
					Y=3'd3;
					end 
		32'd268435456:begin
					X = 3'd4;
					Y=3'd4;
					end 
		32'd536870912:begin
					X = 3'd4;
					Y=3'd5;
					end
		
	default:begin
					X = 3'd0;
					Y=3'd0;
				end	
	endcase
end
	
	endmodule

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
