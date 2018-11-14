
module Audio_Demo (
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

	FPGA_I2C_SCLK,
	SW
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				CLOCK_50;
input		[3:0]	KEY;
input		[9:0]	SW;

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

// Internal Registers

reg [18:0] delay_cnt;
reg [18:0] delay_cnt2;
reg [18:0] delay;
reg [18:0] delay2;

reg snd;
reg snd2;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge CLOCK_50)
begin
	if(delay_cnt == delay) begin
		delay_cnt <= 0;
		snd <= !snd;
	end
	else delay_cnt <= delay_cnt + 1;

	if(delay_cnt2 == delay2) begin
		delay_cnt2 <= 0;
		snd2 <= !snd2;
	end
	else delay_cnt2 <= delay_cnt2 + 1;
end
/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

// assign delay = {SW[3:0], 15'd3000};
always @(*)
begin
	case(SW[3:0])
		3'd0: delay = 18'd0;
		3'd1: delay = 18'd191131;
		3'd2: delay = 18'd170242;
		3'd3: delay = 18'd151515;
		3'd4: delay = 18'd131926;
		3'd5: delay = 18'd127551;
		3'd6: delay = 18'd113636;
		3'd7: delay = 18'd101235;
	endcase
	case(SW[9:6])
		3'd0: delay = 18'd0;
		3'd1: delay = 18'd191131;
		3'd2: delay = 18'd170242;
		3'd3: delay = 18'd151515;
		3'd4: delay = 18'd131926;
		3'd5: delay = 18'd127551;
		3'd6: delay = 18'd113636;
		3'd7: delay = 18'd101235;
	endcase
end

wire [31:0] sound1 = (SW == 0) ? 0 : snd ? 32'd10000000 : -32'd10000000;
wire [31:0] sound2 = (SW == 0) ? 0 : snd ? 32'd10000000 : -32'd10000000;
wire [31:0] sound = sound1 + sound2;

assign read_audio_in			= audio_in_available & audio_out_allowed;

assign left_channel_audio_out	= left_channel_audio_in+sound;
assign right_channel_audio_out	= right_channel_audio_in+sound;
assign write_audio_out			= audio_in_available & audio_out_allowed;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

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
