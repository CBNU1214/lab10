
`timescale 1ns/1ns

// Dual-port RAM with synchronous read with write byte-enable
module SYNC_RAM_DP_WBE(q0, d0, addr0, en0, wbe0, q1, d1, addr1, en1, wbe1, clk);
  parameter DWIDTH = 8;             // Data width
  parameter AWIDTH = 8;             // Address width
  parameter DEPTH  = (1 << AWIDTH); // Memory depth
  parameter MIF_HEX = "";
  parameter MIF_BIN = "";

  input clk;
  input [DWIDTH-1:0]   d0;    // Data input
  input [AWIDTH-1:0]   addr0; // Address input
  input [DWIDTH/8-1:0] wbe0;  // write-byte-enable
  input                en0;
  output [DWIDTH-1:0]  q0;

  input [DWIDTH-1:0]   d1;    // Data input
  input [AWIDTH-1:0]   addr1; // Address input
  input [DWIDTH/8-1:0] wbe1;  // write-byte-enable
  input                en1;
  output [DWIDTH-1:0]  q1;

  (* ram_style = "block" *) reg [DWIDTH-1:0] mem [0:DEPTH-1];

  integer i;
  initial begin
    if (MIF_HEX != "") begin
      $readmemh(MIF_HEX, mem);
    end
    else if (MIF_BIN != "") begin
      $readmemb(MIF_BIN, mem);
    end
    else begin
      for (i = 0; i < DEPTH; i = i + 1) begin
        mem[i] = 0;
      end
    end
  end


  reg [DWIDTH-1:0] read_data0_reg;
  reg [DWIDTH-1:0] read_data1_reg;

  always @(posedge clk) begin
    if (en0) begin
      for (i = 0; i < 4; i = i+1) begin
        if (wbe0[i])
          mem[addr0][i*8 +: 8] <= d0[i*8 +: 8];
      end
      read_data0_reg <= mem[addr0];
    end
  end

  always @(posedge clk) begin
    if (en1) begin
      for (i = 0; i < 4; i = i+1) begin
        if (wbe1[i])
          mem[addr1][i*8 +: 8] <= d1[i*8 +: 8];
        end
      read_data1_reg <= mem[addr1];
    end
  end

  assign q0 = read_data0_reg;
  assign q1 = read_data1_reg;

endmodule // SYNC_RAM_DP_WBE

// POSITIVE EDGE-TRIGGERED FLIPFLOP (RST, WE)
module PipeReg #(parameter	BITWIDTH = 1) (
	input	wire						CLK,
	input	wire						RST,
	input	wire						EN,
	input	wire	[BITWIDTH-1 : 0]	D,
	output	reg		[BITWIDTH-1 : 0]	Q
);

	always @ (posedge CLK)
	begin 
		if (RST)		Q <= {BITWIDTH{1'b0}}; 
		else if (EN)	Q <= D;
	end

endmodule

module REG_FILE #(
    parameter DWIDTH = 32,
    parameter MDEPTH = 32,
    parameter AWIDTH = 5 
)  (
    input wire CLK,
    input wire WE,
	input wire RST,
    input wire [AWIDTH-1:0] RA1, RA2, WA,
    input wire [DWIDTH-1:0] WD,
    output wire [DWIDTH-1:0] RD1, RD2
);

    //Declare the register that will store the data
    reg [DWIDTH -1:0] RF [MDEPTH-1:0];

    //Define asynchronous read
    assign RD1 = RF[RA1];
    assign RD2 = RF[RA2];

    //Define synchronous write
    always @(posedge CLK) begin
        if(WE && (WA != {AWIDTH{1'b0}}))
		begin
            RF[WA] <= WD;
    	end
		
		else if (RST)
    	begin
			RF[0] <= 32'b0;
			RF[1] <= 32'b0;
			RF[2] <= 32'b0;
			RF[3] <= 32'b0;
			RF[4] <= 32'b0;
			RF[5] <= 32'b0;
			RF[6] <= 32'b0;
			RF[7] <= 32'b0;
			RF[8] <= 32'b0;
			RF[9] <= 32'b0;
			RF[10] <= 32'b0;
			RF[11] <= 32'b0;
			RF[12] <= 32'b0;
			RF[13] <= 32'b0;
			RF[14] <= 32'b0;
			RF[15] <= 32'b0;
			RF[16] <= 32'b0;
			RF[17] <= 32'b0;
			RF[18] <= 32'b0;
			RF[19] <= 32'b0;
			RF[20] <= 32'b0;
			RF[21] <= 32'b0;
			RF[22] <= 32'b0;
			RF[23] <= 32'b0;
			RF[24] <= 32'b0;
			RF[25] <= 32'b0;
			RF[26] <= 32'b0;
			RF[27] <= 32'b0;
			RF[28] <= 32'b0;
			RF[29] <= 32'b0;
			RF[30] <= 32'b0;
			RF[31] <= 32'b0;
    	end

		else
		begin
				RF[WA] <= RF [WA];
		end
    end

endmodule
