// stage1
module stage1(CLOCK_50, SW, KEY, LEDR);
	input CLOCK_50;
	input [9:0] SW;
	input [3:0] KEY;
	output [9:0] LEDR;

	wire resetn;
	wire enable;
	assign resetn = KEY[0];
	assign select = ~KEY[3];
	assign back = ~KEY[2];

	control c0(.clk(CLOCK_50),
			   .back(back),
			   .select(select),
			   .go(go),
			   .switches(SW[9:0]),
			   .resetn(resetn),
			   .mode(mode),

			   .enable(enable),
			   .record_high(LEDR[9]),
			   .ld_selection());

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

	output ld_selection
	);

	clock_devider clock0(.clk(clk), .resetn(resetn), .speed(switches[2:0]), .slower_clk(enable), .record_high(record_high));

	// ######################## FINITE STATE MACHINE ##############################
	reg [3:0] current_state;
	reg [3:0] next_state;

	localparam  S_BEGIN              = 5'd0,
				S_SELECT_MODE        = 5'd1,
				S_SELECT_MODE_WAIT   = 5'd2,

				S_RECORD_BEGIN       = 5'd3,
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
					if(mode == 2'd0) begin
						next_state = S_RECORD_BEGIN;
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
			S_RECORD_BEGIN: next_state = select ? S_RECORD_BEGIN : S_WAIT_RECORD;
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
			S_WAIT_RECORD_WAIT: next_state = select ? S_WAIT_RECORD : S_RECORDING;
			S_RECORDING: begin
				if (back) begin
					next_state = S_RECORD_BEGIN;
				end
				else if (select) begin
					next_state = S_RECORDING_WAIT;
				end
				else begin
					next_state = S_RECORDING;
				end
			end
			S_RECORDING_WAIT: next_state = select ? S_RECORDING_WAIT : S_RECORD_STOP;
			S_RECORD_STOP: begin
				if (select | back) begin
					next_state = S_SELECT_MODE;
				end
				else begin
					next_state = S_RECORD_STOP;
				end
			end
			//################# RECORD MODE FSM END#################
		endcase
	end

	// Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
		ld_selection = 0;

		case (current_state)
			S_SELECT_MODE:
				ld_selection = 1;

		endcase
	end

	// state_FFs
    always@(posedge clk)
	begin: state_FFs


	end

	// ######################## FINITE STATE MACHINE END ##############################

endmodule

////////////////////////////////Data Path/////////////////////////////// 
module datapath(
	input mode, //mode,record (1) OR play(0)
	input reset_address,
	input go,
	
	input [4:0]S,//input from the guitar
	input [4:0]P,

	output [31:0]note, //output to the audio module
	);
	
   reg [5:0] address;
	
	
	//make the address to increase when record
	always @ (posedge go) begin
		if (reset_address) begin
			address <= 0;
		end
		else begin
				address <= address + 1;
			end
		end
	end
//

	

	reg [4:0]s,p;
	//process of record
	always @ (posedge clk) begin
		if(go == 1'b1)begin
		  if(S[0]==1)
		     s[0]<= 1'b1;
		  if(S[1]==1)
		     s[1]<= 1'b1;
		  if(S[2]==1)
		     s[2]<= 1'b1;
		  if(S[3]==1)
		     s[3]<= 1'b1;
		  if(S[4]==1)
		     s[4]<= 1'b1;  

		  if(P[0]==1)
		     p[0]<= 1'b1;
		  if(P[1]==1)
		     p[1]<= 1'b1;
		  if(P[2]==1)
		     p[2]<= 1'b1;
		  if(P[3]==1)
		     p[3]<= 1'b1;
		  if(P[4]==1)
		     p[4]<= 1'b1; 
		end
	end
//Now the [4:0]s,p store all information during go=1


wire [31:0]Note;
coordinates_converter C_C0(.S(s),.P(p),.note(Note));
ram64x32 r(.data(Note), .wren(mode), .address(address), .clock(~go), .q(note));
//when go=0, mode=1,bits are loaded to the ram
//when go=0, mode=0,bits are read from the ram

endmodule
////////////////////////////////End of Datapath////////////////////////////////



//[4:0]S,P to coordinates converter
module coordinates_converter(S,P,note);
input [4:0]S,P;
output[31:0]note;

//if no P is pushed P_empty=1
assign P_empty = (~P[0])&(~P[1])&(~P[2])&(~P[3])&(~P[4]); 

assign note[0]=S[0]&P[0];
assign note[1]=S[1]&P[0];
assign note[2]=S[2]&P[0];
assign note[3]=S[3]&P[0];
assign note[4]=S[4]&P[0];

assign note[5]=S[0]&P[1];
assign note[6]=S[1]&P[1];
assign note[7]=S[2]&P[1];
assign note[8]=S[3]&P[1];
assign note[9]=S[4]&P[1];

assign note[10]=S[0]&P[2];
assign note[11]=S[1]&P[2];
assign note[12]=S[2]&P[2];
assign note[13]=S[3]&P[2];
assign note[14]=S[4]&P[2];

assign note[15]=S[0]&P[3];
assign note[16]=S[1]&P[3];
assign note[17]=S[2]&P[3];
assign note[18]=S[3]&P[3];
assign note[19]=S[4]&P[3];

assign note[20]=S[0]&P[4];
assign note[21]=S[1]&P[4];
assign note[22]=S[2]&P[4];
assign note[23]=S[3]&P[4];
assign note[24]=S[4]&P[4];

assign note[25]=S[0]&P_empty;
assign note[26]=S[1]&P_empty;
assign note[27]=S[2]&P_empty;
assign note[28]=S[3]&P_empty;
assign note[29]=S[4]&P_empty;


assign note[30:31]= 2'b00;
endmodule


//clock_divider
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
