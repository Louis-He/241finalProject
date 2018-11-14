
module Audio_Demo (
//Input From top module
   note_out,
	// Inputs
	CLOCK_50,
	KEY,
	AUD_ADCDAT,

	// Bidirectionals
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,

	FPGA_I2C_SDAT,

	// Outputs
	AUD_XCK,
	AUD_DACDAT,

	FPGA_I2C_SCLK
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
////Input From top module
input		[31:0] note_out;

// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input				AUD_ADCDAT;

// Bidirectionals
inout				AUD_BCLK;
inout				AUD_ADCLRCK;
inout				AUD_DACLRCK;

inout				FPGA_I2C_SDAT;

// Outputs
output				AUD_XCK;
output				AUD_DACDAT;

output				FPGA_I2C_SCLK;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				audio_in_available;
wire		[31:0]	left_channel_audio_in;
wire		[31:0]	right_channel_audio_in;
wire				read_audio_in;

wire				audio_out_allowed;
wire		[31:0]	left_channel_audio_out;
wire		[31:0]	right_channel_audio_out;
wire				write_audio_out;

/////////////////////////////////////////////////////////////////////////////
////////////////////////START OF EDIT////////////////////////////////////////

reg [4:0] frequency;

//correspond frequency to each note_out
always @(*)
begin
	case(note_out)
		32'd1: frequency = 5'd0;
		32'd2: frequency = 5'd1;
		32'd4: frequency = 5'd2;
		32'd8: frequency = 5'd3;
		32'd16: frequency = 5'd4;
		32'd32: frequency = 5'd5;
		
		32'd64: frequency = 5'd6;
		32'd128: frequency = 5'd7;
		32'd256: frequency = 5'd8;
		32'd512: frequency = 5'd9;
		32'd1024: frequency = 5'd10;
		32'd2048: frequency = 5'd11;
		
		32'd4096: frequency = 5'd12;
		32'd8192: frequency = 5'd13;
		32'd16384: frequency = 5'd14;
		32'd32768: frequency = 5'd15;
		32'd65536: frequency = 5'd16;
		32'd131072: frequency = 5'd17;
		
		32'd262144: frequency = 5'd18;
		32'd524288: frequency = 5'd19;
		32'd1048576: frequency = 5'd20;
		32'd2097152: frequency = 5'd21;
		32'd4194304: frequency = 5'd22;
		32'd8388608: frequency = 5'd23;
		
		32'd16777216: frequency = 5'd24;
		32'd33554432: frequency = 5'd25;
		32'd67108864: frequency = 5'd26;
		32'd134217728: frequency = 5'd27;
		32'd268435456: frequency = 5'd28;
		32'd536870912: frequency= 5'd29;
		
	default: frequency= 5'd30;
	endcase
	
end
//


//correspond delay to each frequency
reg [18:0] delay_cnt;
reg [18:0] delay;
reg snd;

always @(*)
begin
	case(frequency)
		5'd0: delay =19'd606796;
		5'd1: delay =19'd454545;
		5'd2: delay =19'd340599;
		5'd3: delay =19'd255102;
		5'd4: delay =19'd202429;
		5'd5: delay =19'd218340;
		
		5'd6: delay =19'd572737;
		5'd7: delay =19'd429184;
		5'd8: delay =19'd321336;
		5'd9: delay =19'd240847;
		5'd10: delay =19'd191570;
		5'd11: delay =19'd143266;
		
		5'd12: delay =19'd540540;
		5'd13: delay =19'd404858;
		5'd14: delay =19'd303398;
		5'd15: delay =19'd227272;
		5'd16: delay =19'd180505;
		5'd17: delay =19'd135135;
		
		5'd18: delay =19'd510204;
		5'd19: delay =19'd382262;
		5'd20: delay =19'd287356;
		5'd21: delay =19'd214592;
		5'd22: delay =19'd170648;
		5'd23: delay =19'd127551;
		
		5'd24: delay =19'd485436;
		5'd25: delay =19'd362318;
		5'd26: delay =19'd270270;
		5'd27: delay =19'd202429;
		5'd28: delay =19'd160771;
		5'd29: delay =19'd120481;
		
	default: delay =19'd500000;
	endcase
	
end


//
always @(posedge CLOCK_50)
begin
	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end
	else delay_cnt <= delay_cnt + 1;

end


//control the voice
wire [31:0] sound1 = (note_out == 0) ? 0 : snd ? 32'd10000000 : -32'd10000000;
wire [31:0] sound = sound1;





/////////////////////////Fixed module DONT CHANGE/////////////////////////
assign read_audio_in			= audio_in_available & audio_out_allowed;
assign left_channel_audio_out	= left_channel_audio_in+sound;
assign right_channel_audio_out	= right_channel_audio_in+sound;
assign write_audio_out			= audio_in_available & audio_out_allowed;


Audio_Controller Audio_Controller (
	// Inputs
	.CLOCK_50						(CLOCK_50),
	.reset						(~KEY[0]),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),

	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),


	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)

);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK					(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT					(FPGA_I2C_SDAT),
	.CLOCK_50					(CLOCK_50),
	.reset						(~KEY[0])
);

endmodule
