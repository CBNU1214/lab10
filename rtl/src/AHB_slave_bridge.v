module AHB_slave_bridge #(
    parameter AWIDTH = 16,
    parameter pending_cycle = 0 
)(
    input wire clk,
    input wire reset,
    // AHB 
    input  wire              HSEL,
    input  wire              HREADY,
    input  wire [31:0]       HADDR,
    input  wire              HWRITE,
    input  wire [31:0]       HWDATA,
    input  wire [2:0]        HSIZE,
    output wire              HREADYOUT,
    output wire              HRESP,
    output wire [31:0]       HRDATA,
    // MMIO
    output wire [31:0]       MMIO_DIN,
    output wire [3:0]        MMIO_WEA,
    output wire [AWIDTH-1:0] MMIO_ADDR,
    output wire              MMIO_EN,
    input  wire [31:0]       MMIO_DOUT
);

    wire [31:0] w_mem_DOUT;
    wire [31:0] w_mem_DIN;
    wire [AWIDTH-1:0] w_mem_ADDR;
    wire [3:0] w_mem_WEA;
    wire w_mem_EN;

    wire [3:0] WBE, WBE_Q;

    assign WBE[3] = (HSIZE == 3'b010 && HADDR[1:0] == 2'b00) 
                    || (HSIZE == 3'b001 && HADDR[1:0] == 2'b10)
                    || (HSIZE == 3'b000 && HADDR[1:0] == 2'b11);
    assign WBE[2] = (HSIZE == 3'b010 && HADDR[1:0] == 2'b00) 
                    || (HADDR[1:0] == 2'b10);
    assign WBE[1] = ((HSIZE == 3'b010 || HSIZE == 3'b001) && HADDR[1:0] == 2'b00) 
                    || (HADDR[1:0] == 2'b01);
    assign WBE[0] = (HADDR[1:0] == 2'b00);

    assign HRESP = 1'b0; // Always OK response
    
    
    
    wire [AWIDTH-3:0] HADDR_Q;
    wire HWRITE_Q, HSELREADY_Q;
    PipeReg #(AWIDTH-2) FF_HADDR(.CLK(clk), .RST(reset), .EN(1'b1), .D(HADDR[AWIDTH-1:2]), .Q(HADDR_Q));
    PipeReg #(1) FF_HWRITE(.CLK(clk), .RST(reset), .EN(1'b1), .D(HWRITE), .Q(HWRITE_Q));
    PipeReg #(4) FF_WBE(.CLK(clk), .RST(reset), .EN(1'b1), .D(WBE), .Q(WBE_Q));
    PipeReg #(1) FF_HSELREADY(.CLK(clk), .RST(reset), .EN(1'b1), .D(HSEL && HREADY), .Q(HSELREADY_Q));
    
    assign MMIO_DIN  = HWDATA;
    assign MMIO_WEA  = HWRITE_Q ? WBE_Q:  4'b0;
    assign MMIO_ADDR = HWRITE_Q ? HADDR_Q : HADDR[AWIDTH-1:2];
    assign MMIO_EN   = HWRITE_Q ? HSELREADY_Q : ((HSEL && HREADY) ? 1'b1 : 1'b0) ;
    assign HRDATA    = MMIO_DOUT;

    generate
        if (pending_cycle > 0) begin
            wire [31:0] count_d, count_q;
            PipeReg #(32) FF_count(.CLK(clk), .RST(reset), .EN(HSEL), .D(count_d), .Q(count_q));
            assign count_d   = (HSEL && HREADY) ? (count_q == 0) : count_q + HSEL;
            assign HREADYOUT = (count_q == 0 || count_q == pending_cycle + 1) ? 1'b1 : 1'b0;
        end else begin
            assign HREADYOUT = 1'b1;
        end
    endgenerate

endmodule
