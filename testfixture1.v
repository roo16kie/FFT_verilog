`timescale 1ns/10ps
`define CYCLE     20                 // Modify your clock period here
//`define SDFFILE    "./FAS_syn.sdf"    // Modify your sdf file name
`define End_CYCLE  100000          // Modify cycle times once your design need more cycle times!

`define fft_fail_limit 48



module testfixture1;

reg   clk ;
reg   reset ;
reg data_valid; 
reg [15:0] data; // 8 integer + 8 fraction
wire [31:0] fft_d0, fft_d1, fft_d2, fft_d3, fft_d4, fft_d5, fft_d6, fft_d7;
wire fft_valid;

reg en;

reg [15:0] data_mem [0:1023];
initial $readmemh("./dat/Golden1_data.dat", data_mem);

reg [15:0] fftr_mem [0:1023];
initial $readmemh("./dat/Golden1_FFT_real.dat", fftr_mem);
reg [15:0] ffti_mem [0:1023];
initial $readmemh("./dat/Golden1_FFT_imag.dat", ffti_mem);

integer i, j ,k, l;
integer fft_fail;

fft fft(.clk(clk), .rst(reset), .data(data), .data_valid(data_valid), .fft_valid(fft_valid),
		.fft_d0(fft_d0), .fft_d1(fft_d1), .fft_d2(fft_d2), .fft_d3(fft_d3), 
		.fft_d4(fft_d4), .fft_d5(fft_d5), .fft_d6(fft_d6), .fft_d7(fft_d7));


/* `ifdef SDFFILE
initial $sdf_annotate(`SDFFILE, dff);
`endif */


initial begin
$fsdbDumpfile("FAS.fsdb");
$fsdbDumpvars;
end



initial begin
#0;
   clk         = 1'b0;
   reset       = 1'b0; 
   i = 0;   
   j = 0;  
   k = 0;
   l = 0;
   fft_fail = 0;
   
end

always begin #(`CYCLE/2) clk = ~clk; end

initial begin
	en = 0;
   #(`CYCLE*0.5)   reset = 1'b1; 
   #(`CYCLE*2); #0.5;   reset = 1'b0; en = 1;
end

// data input & ready
always@(negedge clk ) begin
	if (en) begin
		if (i >= 1024 )
		begin
			data <= 0;
			data_valid<=0;
		end
		else begin
			data <= data_mem[i];
			data_valid<=1;
			i <= i + 1;
		end
	end
end

//============================================================================================================
//============================================================================================================
//============================================================================================================
// FFT data output verify

reg [31:0] fft_rec [0:7];
always@(*) begin
fft_rec[0] = fft_d0;
fft_rec[1] = fft_d1;
fft_rec[2] = fft_d2;
fft_rec[3] = fft_d3;
fft_rec[4] = fft_d4;
fft_rec[5] = fft_d5;
fft_rec[6] = fft_d6;
fft_rec[7] = fft_d7;
end

reg [15:0] fft_cmp_r , fft_cmp_r1 , fft_cmp_r2 , fft_cmp_r3 ,fft_cmp_i , fft_cmp_i1 , fft_cmp_i2 , fft_cmp_i3 ;
reg [15:0] fft_cmp_r4 , fft_cmp_r5 , fft_cmp_r6, fft_cmp_r7, fft_cmp_i4 , fft_cmp_i5 , fft_cmp_i6, fft_cmp_i7 ;
reg [15:0] fftr_ver, ffti_ver;
reg [15:0] fftr_ver_, ffti_ver_;
reg [31:0] fft_cmp;

reg fftr_verify, ffti_verify;
always@(posedge clk) begin
	if (fft_valid) begin
		for (l=0; l<=7; l=l+1) begin
			fft_cmp = fft_rec[l];
			fftr_ver_= fftr_mem[k]; fftr_ver = fftr_ver_;
			ffti_ver_= ffti_mem[k]; ffti_ver = ffti_ver_;
			
			fft_cmp_r = fft_cmp[31:16]; 
			fft_cmp_r1 = fft_cmp_r-1; fft_cmp_r2 = fft_cmp_r; fft_cmp_r3 = fft_cmp_r+1;
			fft_cmp_r4 = fft_cmp_r-2; fft_cmp_r5 = fft_cmp_r+2; fft_cmp_r6 = fft_cmp_r-3; fft_cmp_r7 = fft_cmp_r+3;
			
			fft_cmp_i = fft_cmp[15:0];
			fft_cmp_i1 = fft_cmp_i-1; fft_cmp_i2 = fft_cmp_i; fft_cmp_i3 = fft_cmp_i+1;
			fft_cmp_i4 = fft_cmp_i-2; fft_cmp_i5 = fft_cmp_i+2; fft_cmp_i6 = fft_cmp_i-3; fft_cmp_i7 = fft_cmp_i+3;			

			fftr_verify = ((fftr_ver == fft_cmp_r2) || (fftr_ver == (fft_cmp_r3)) || (fftr_ver == (fft_cmp_r1)) || (fftr_ver == (fft_cmp_r4)) || (fftr_ver == (fft_cmp_r5)) || (fftr_ver == (fft_cmp_r6)) || (fftr_ver == (fft_cmp_r7)));
			ffti_verify = ((ffti_ver == fft_cmp_i2) || (ffti_ver == (fft_cmp_i3)) || (ffti_ver == (fft_cmp_i1)) || (ffti_ver == (fft_cmp_i4)) || (ffti_ver == (fft_cmp_i5)) || (ffti_ver == (fft_cmp_i6)) || (ffti_ver == (fft_cmp_i7)));
			if ( (!fftr_verify) || (!ffti_verify)|| (fft_cmp === 32'bx) || (fft_cmp === 32'bz)) begin
				$display("ERROR at FFT  ppoint number =%2d: The real response output %8h != expectd %8h " ,k, fft_cmp, {fftr_mem[k], ffti_mem[k]});
				$display("-----------------------------------------------------");
				fft_fail <= fft_fail + 1; 
			end
			else if ( l==7 ) begin
				if (fft_fail) $display("FFT dataout on pattern %d ~ %d, FAIL!!",  (k-8), k);
				else $display("FFT dataout on pattern %d ~ %d, PASS!!", (k-7), k);
			end
			k=k+1;
		end
	end
end





//============================================================================================================
//============================================================================================================
//============================================================================================================
// Final result verify

// Terminate the simulation, FAIL
initial  begin
 #(`CYCLE * `End_CYCLE);
 $display("-----------------------------------------------------");
 $display("Error!!! Somethings' wrong with your code ...!!");
 $display("-------------------------FAIL------------------------");
 $display("-----------------------------------------------------");
 $finish;
end


always@(*) begin
	if (fft_fail >= `fft_fail_limit) begin
		$display("-----------------------------------------------------\n");
 		$display("Error!!! There are more than %d errors for FFT output !", `fft_fail_limit);
 		$display("-------------------------FAIL------------------------\n");
		$finish;
	end	
end


// Terminate the simulation, PASS
initial begin
      wait(en);
      wait(fft_valid);
      wait(k>=1023);
      #(`CYCLE);     
      if ( !(fft_fail) ) begin
         $display("-----------------------------------------------------\n");
         $display("Congratulations! All data have been generated successfully!\n");
         $display("-------------------------PASS------------------------\n");
      #(`CYCLE/2); $finish;
      end
      else begin
      	 $display("-----------------------------------------------------\n");
         $display("Fail!! There are some error with your code!\n");
         $display("-------------------------FAIL------------------------\n");
      #(`CYCLE/2); $finish;
      end
end

endmodule
