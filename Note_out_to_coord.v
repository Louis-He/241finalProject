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
