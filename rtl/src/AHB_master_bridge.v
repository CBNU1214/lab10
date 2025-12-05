module AHB_master_bridge (
    input wire clk,
    input wire reset,
    // AHB 
    output wire [31:0]       HADDR,
    output wire              HWRITE,
    output wire [31:0]       HWDATA,
    output wire [1:0]        HTRANS,
    output wire [2:0]        HSIZE,
    input  wire              HREADY,
    input  wire              HRESP,
    input  wire [31:0]       HRDATA,
    // Core
    input  wire [31:0]       CORE_DIN,
    input  wire [3:0]        CORE_WEA,
    input  wire [31:0]       CORE_ADDR,
    input  wire              CORE_EN,
    output wire [31:0]       CORE_DOUT
);

    wire [2:0] SIZE;

    assign SIZE = (CORE_WEA[3] + CORE_WEA[2] + CORE_WEA[1] + CORE_WEA[0]);
    assign HADDR     = CORE_ADDR;
    assign HWRITE    = (CORE_WEA[3] | CORE_WEA[2] | CORE_WEA[1] | CORE_WEA[0]);
    PipeReg #(32) FF_HWDATA(.CLK(clk), .RST(reset), .EN(1'b1), .D(CORE_DIN), .Q(HWDATA));
    assign HTRANS    = (CORE_EN) ? 2'b10 : 2'b00;
    assign HSIZE     = (SIZE == 3'b100) ? 3'b010 : // 4 bytes
                       (SIZE == 3'b010) ? 3'b001 : // 2 bytes
                       (SIZE == 3'b001) ? 3'b000 : // 1 byte
                                          3'b010;  // 4 bytes
    assign CORE_DOUT = HRDATA;

endmodule
