/*
  Author: Jung Gyu Min.
  Affiliation: EPIC Lab
  Description: SoC-level Top module, instancing RISCV_TOP, Memories, Bus, peripherals.
*/
module RVCORE_TOP #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200,
    parameter AWIDTH = 10
)(
    input wire clk,
    input wire rst,
    input wire FPGA_SERIAL_RX,
    output wire FPGA_SERIAL_TX,
    input wire TEST_BIOS,

    output wire [15:0] EXT_HADDR,
    output wire EXT_HSEL,
    output wire EXT_HWRITE,
    output wire [3:0] EXT_HSIZE,
    output wire [31:0] EXT_HWDATA,
    input wire [31:0] EXT_HRDATA,
    input wire EXT_HREADYOUT
);

    //-----------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------
    localparam BASEADDR_MEM            = 32'h1000_0000;
    localparam BASEADDR_BIOS           = 32'h4000_0000;
    localparam BASEADDR_CLK_COUNTER    = 32'h8000_0010;
    localparam BASEADDR_UART           = 32'h8000_0000;
    localparam BASEADDR_CUSTOM         = 32'h8001_0000;

    wire [31:0] imem_doutb;
    wire [31:0] IMEM_ADDR;
    wire [31:0] IMEM_DOUT;
    wire [31:0] imem_addr_Q;

    wire [31:0] bios_douta;

    wire RF_WE;
    wire [4:0] RF_RA1, RF_RA2, RF_WA;
    wire [31:0] RF_WD;
    wire [31:0] RF_RD1, RF_RD2;

    wire CRF_WE;
    wire [4:0] CRF_RA1, CRF_RA2, CRF_WA;
    wire [31:0] CRF_WD;
    wire [31:0] CRF_RD1, CRF_RD2;

    wire [31:0] rd1_temp, rd2_temp;
    wire [31:0] crd1_temp, crd2_temp;
    wire [31:0] clock_c;


    wire [31:0] DMEM_DIN;
    wire [3:0] DMEM_WEA;
    wire DMEM_EN;
    wire [31:0] DMEM_ADDR;
    wire [31:0] DMEM_DOUT;

    //MEM PORT 0
    wire [31:0] PORT0_DIN;
    wire [3:0] PORT0_WEA;
    wire PORT0_EN;
    wire [AWIDTH-1:0] PORT0_ADDR;
    wire [31:0] PORT0_DOUT;

    // //MEM PORT 1
    // wire [31:0] PORT1_DIN;
    // wire [3:0] PORT1_WEA;
    // wire PORT1_EN;
    // wire [AWIDTH-1:0] PORT1_ADDR;
    // wire [31:0] PORT1_DOUT;

    //MEM PORT 2
    wire [31:0] PORT2_DIN;
    wire [3:0] PORT2_WEA;
    wire PORT2_EN;
    wire [AWIDTH-1:0] PORT2_ADDR;
    wire [31:0] PORT2_DOUT;

    //MEM PORT 3
    wire [31:0] PORT3_DIN;
    wire [3:0] PORT3_WEA;
    wire PORT3_EN;
    wire [AWIDTH-1:0] PORT3_ADDR;
    wire [31:0] PORT3_DOUT;

    //MEM PORT 4
    wire [31:0] PORT4_DIN;
    wire [3:0] PORT4_WEA;
    wire PORT4_EN;
    wire [AWIDTH-1:0] PORT4_ADDR;
    wire [31:0] PORT4_DOUT;

    //MEM PORT 5
    wire [31:0] PORT5_DIN;
    wire [3:0] PORT5_WEA;
    wire PORT5_EN;
    wire [AWIDTH-1:0] PORT5_ADDR;
    wire [31:0] PORT5_DOUT;

    // AHB wires
    // Core AHB
    wire [31:0]      DMEM_HADDR;
    wire             DMEM_HWRITE;
    wire [31:0]      DMEM_HWDATA;
    wire [1:0]       DMEM_HTRANS;
    wire [2:0]       DMEM_HSIZE;
    wire [31:0]      DMEM_HRDATA;
    wire             DMEM_HREADY;
    wire             DMEM_HRESP;
    
    // MEM PORT 0
    wire             PORT0_HSEL;
    wire             PORT0_HREADYOUT;
    wire [31:0]      PORT0_HRDATA;
    wire             PORT0_HRESP;
    // MEM PORT 1
    wire             PORT1_HSEL;
    wire             PORT1_HREADYOUT;
    wire [31:0]      PORT1_HRDATA;
    wire             PORT1_HRESP;
    // MEM PORT 2
    wire             PORT2_HSEL;
    wire             PORT2_HREADYOUT;
    wire [31:0]      PORT2_HRDATA;
    wire             PORT2_HRESP;
    // MEM PORT 3
    wire             PORT3_HSEL;
    wire             PORT3_HREADYOUT;
    wire [31:0]      PORT3_HRDATA;
    wire             PORT3_HRESP;
    // MEM PORT 4
    wire             PORT4_HSEL;
    wire             PORT4_HREADYOUT;
    wire [31:0]      PORT4_HRDATA;
    wire             PORT4_HRESP;
    // MEM PORT 5
    wire             PORT5_HSEL;
    wire             PORT5_HREADYOUT;
    wire [31:0]      PORT5_HRDATA;
    wire             PORT5_HRESP;

    wire [31:0] bios_douta_print,bios_douta_test;
    wire [31:0] PORT2_DOUT_print,PORT2_DOUT_test;

//////////////// FIVE STAGE CORE

    wire    [3:0]   D_MEM_BE;
    wire            D_MEM_CSN;
	wire            D_MEM_WEN;

    RISCV_TOP_netlist  
     riscv_top1 (
		//General Signals
		.CLK          (clk),
		.RSTn         (~rst),
		//I-Memory Signals
		.I_MEM_CSN    (),
		.I_MEM_DOUT   (IMEM_DOUT),
		.I_MEM_ADDR   (IMEM_ADDR),
		//D-Memory Signals
		.D_MEM_CSN    (D_MEM_CSN),
		.D_MEM_DOUT     (DMEM_DOUT),
		.D_MEM_DI   (DMEM_DIN),
		.D_MEM_ADDR   (DMEM_ADDR),
		.D_MEM_WEN    (D_MEM_WEN),
		.D_MEM_BE     (D_MEM_BE),
		//RegFile Signals
		.RF_WE        (RF_WE),
		.RF_RA1       (RF_RA1),
		.RF_RA2       (RF_RA2),
		.RF_WA       (RF_WA),
		.RF_RD1       (RF_RD1),
		.RF_RD2       (RF_RD2),
		.RF_WD       (RF_WD),
        //RegFile Signals
		.CRF_WE        (CRF_WE),
		.CRF_RA1       (CRF_RA1),
		.CRF_RA2       (CRF_RA2),
		.CRF_WA       (CRF_WA),
		.CRF_RD1       (CRF_RD1),
		.CRF_RD2       (CRF_RD2),
		.CRF_WD       (CRF_WD)
	);

    assign DMEM_EN = ~D_MEM_CSN;
    assign DMEM_WEA[3] = D_MEM_BE[3] & ~D_MEM_WEN;
    assign DMEM_WEA[2] = D_MEM_BE[2] & ~D_MEM_WEN;
    assign DMEM_WEA[1] = D_MEM_BE[1] & ~D_MEM_WEN;
    assign DMEM_WEA[0] = D_MEM_BE[0] & ~D_MEM_WEN;

///////////////////////////////////////

    AHB_master_bridge CORE_AHB_bridge(
        .clk(clk),
        .reset(rst),
        // AHB BUS
        .HADDR(DMEM_HADDR),
        .HWRITE(DMEM_HWRITE),
        .HWDATA(DMEM_HWDATA),
        .HTRANS(DMEM_HTRANS),
        .HSIZE(DMEM_HSIZE),
        .HREADY(DMEM_HREADY),
        .HRESP(DMEM_HRESP),
        .HRDATA(DMEM_HRDATA),
        // Core
        .CORE_DIN(DMEM_DIN),
        .CORE_WEA(DMEM_WEA),
        .CORE_ADDR(DMEM_ADDR),
        .CORE_EN(DMEM_EN),
        .CORE_DOUT(DMEM_DOUT)
    );

    ahb_interconnect #(
    .DWIDTH               (32),
    .BASE_M1              (BASEADDR_MEM),
    .WIDTH_M1             (28),
    .ENABLE_M1            (1),
    .BASE_M3              (BASEADDR_BIOS),
    .WIDTH_M3             (28),
    .ENABLE_M3            (1),
    .BASE_M4              (BASEADDR_CLK_COUNTER),
    .WIDTH_M4             (4),
    .ENABLE_M4            (1),
    .BASE_M5              (BASEADDR_UART),
    .WIDTH_M5             (4),
    .ENABLE_M5            (1),
    .BASE_M6              (BASEADDR_CUSTOM),
    .WIDTH_M6             (16),
    .ENABLE_M6            (1)
  ) u_ahb_interconnect (
    // Outputs
    .HREADYS              (DMEM_HREADY),
    .HRESPS               (DMEM_HRESP),
    .HRDATAS              (DMEM_HRDATA),
    .HSELM0               (),
    .HSELM1               (PORT0_HSEL),
    .HSELM2               (),
    .HSELM3               (PORT2_HSEL),
    .HSELM4               (PORT3_HSEL),
    .HSELM5               (PORT4_HSEL),
    .HSELM6               (PORT5_HSEL),
    .HSELM7               (),
    .HSELM8               (),
    .HSELM9               (),
//    .HSELM10              (),
    // Inputs
    .HCLK                 (clk),
    .HRESETn              (~rst),
    .HADDRS               (DMEM_HADDR),
    .HRDATAM0             (32'h0),
    .HRDATAM1             (PORT0_HRDATA),
    .HRDATAM2             (32'h0),
    .HRDATAM3             (PORT2_HRDATA),
    .HRDATAM4             (PORT3_HRDATA),
    .HRDATAM5             (PORT4_HRDATA),
    .HRDATAM6             (PORT5_HRDATA),
    .HRDATAM7             (32'h0),
    .HRDATAM8             (32'h0),
    .HRDATAM9             (32'h0),
//    .HRDATAM10            (32'h0),
    .HREADYOUTM0          (1'b1),
    .HREADYOUTM1          (PORT0_HREADYOUT),
    .HREADYOUTM2          (1'b0),
    .HREADYOUTM3          (PORT2_HREADYOUT),
    .HREADYOUTM4          (PORT3_HREADYOUT),
    .HREADYOUTM5          (PORT4_HREADYOUT),
    .HREADYOUTM6          (PORT5_HREADYOUT),
    .HREADYOUTM7          (1'b0),
    .HREADYOUTM8          (1'b0),
    .HREADYOUTM9          (1'b0),
//    .HREADYOUTM10         (1'b0),
    .HRESPM0              (1'b0),
    .HRESPM1              (PORT0_HRESP),
    .HRESPM2              (1'b0),
    .HRESPM3              (PORT2_HRESP),
    .HRESPM4              (PORT3_HRESP),
    .HRESPM5              (PORT4_HRESP),
    .HRESPM6              (PORT5_HRESP),
    .HRESPM7              (1'b0),
    .HRESPM8              (1'b0),
    .HRESPM9              (1'b0)
//    .HRESPM10             (1'b0)`
 );


    // AHB slave bridges
    AHB_slave_bridge #(
        .AWIDTH(AWIDTH),
        .pending_cycle(0)
    ) PORT0_AHB_bridge(
        .clk(clk),
        .reset(rst),
        // AHB 
        .HSEL(PORT0_HSEL),
        .HREADY(DMEM_HREADY),
        .HADDR(DMEM_HADDR),
        .HWRITE(DMEM_HWRITE),
        .HWDATA(DMEM_HWDATA),
        .HSIZE(DMEM_HSIZE),
        .HREADYOUT(PORT0_HREADYOUT),
        .HRESP(PORT0_HRESP),
        .HRDATA(PORT0_HRDATA),
        // MMIO
        .MMIO_DIN(PORT0_DIN),
        .MMIO_WEA(PORT0_WEA),
        .MMIO_ADDR(PORT0_ADDR),
        .MMIO_EN(PORT0_EN),
        .MMIO_DOUT(PORT0_DOUT)
    );


    AHB_slave_bridge #(
        .AWIDTH(AWIDTH),
        .pending_cycle(0)
    ) PORT2_AHB_bridge(
        .clk(clk),
        .reset(rst),
        // AHB 
        .HSEL(PORT2_HSEL),
        .HREADY(DMEM_HREADY),
        .HADDR(DMEM_HADDR),
        .HWRITE(DMEM_HWRITE),
        .HWDATA(DMEM_HWDATA),
        .HSIZE(DMEM_HSIZE),
        .HREADYOUT(PORT2_HREADYOUT),
        .HRESP(PORT2_HRESP),
        .HRDATA(PORT2_HRDATA),
        // MMIO
        .MMIO_DIN(PORT2_DIN),
        .MMIO_WEA(PORT2_WEA),
        .MMIO_ADDR(PORT2_ADDR),
        .MMIO_EN(PORT2_EN),
        .MMIO_DOUT(PORT2_DOUT)
    );

    AHB_slave_bridge #(
        .AWIDTH(AWIDTH),
        .pending_cycle(0)
    ) PORT3_AHB_bridge(
        .clk(clk),
        .reset(rst),
        // AHB 
        .HSEL(PORT3_HSEL),
        .HREADY(DMEM_HREADY),
        .HADDR(DMEM_HADDR),
        .HWRITE(DMEM_HWRITE),
        .HWDATA(DMEM_HWDATA),
        .HSIZE(DMEM_HSIZE),
        .HREADYOUT(PORT3_HREADYOUT),
        .HRESP(PORT3_HRESP),
        .HRDATA(PORT3_HRDATA),
        // MMIO
        .MMIO_DIN(PORT3_DIN),
        .MMIO_WEA(PORT3_WEA),
        .MMIO_ADDR(PORT3_ADDR),
        .MMIO_EN(PORT3_EN),
        .MMIO_DOUT(PORT3_DOUT)
    );

    AHB_slave_bridge #(
        .AWIDTH(AWIDTH),
        .pending_cycle(0)
    ) PORT4_AHB_bridge(
        .clk(clk),
        .reset(rst),
        // AHB 
        .HSEL(PORT4_HSEL),
        .HREADY(DMEM_HREADY),
        .HADDR(DMEM_HADDR),
        .HWRITE(DMEM_HWRITE),
        .HWDATA(DMEM_HWDATA),
        .HSIZE(DMEM_HSIZE),
        .HREADYOUT(PORT4_HREADYOUT),
        .HRESP(PORT4_HRESP),
        .HRDATA(PORT4_HRDATA),
        // MMIO
        .MMIO_DIN(PORT4_DIN),
        .MMIO_WEA(PORT4_WEA),
        .MMIO_ADDR(PORT4_ADDR),
        .MMIO_EN(PORT4_EN),
        .MMIO_DOUT(PORT4_DOUT)
    );

/*
    AHB_slave_bridge #(
        .AWIDTH(AWIDTH),
        .pending_cycle(0)
    ) PORT5_AHB_bridge(
        .clk(clk),
        .reset(rst),
        // AHB 
        .HSEL(PORT5_HSEL),
        .HREADY(DMEM_HREADY),
        .HADDR(DMEM_HADDR),
        .HWRITE(DMEM_HWRITE),
        .HWDATA(DMEM_HWDATA),
        .HSIZE(DMEM_HSIZE),
        .HREADYOUT(PORT5_HREADYOUT),
        .HRESP(PORT5_HRESP),
        .HRDATA(PORT5_HRDATA),
        // MMIO
        .MMIO_DIN(PORT5_DIN),
        .MMIO_WEA(PORT5_WEA),
        .MMIO_ADDR(PORT5_ADDR),
        .MMIO_EN(PORT5_EN),
        .MMIO_DOUT(PORT5_DOUT)
    );
 */
    
    REG_FILE #(
    .DWIDTH(32),
    .MDEPTH(32),
    .AWIDTH(5) 
    ) rf (
    .CLK(clk),
    .WE(RF_WE),
	.RST(rst),
    .RA1(RF_RA1), 
    .RA2(RF_RA2),
    .WA(RF_WA),
    .WD(RF_WD),
    .RD1(rd1_temp),
    .RD2(rd2_temp)
    );

    assign RF_RD1 = (RF_RA1 == 5'b0) ? 32'b0 : rd1_temp;
    assign RF_RD2 = (RF_RA2 == 5'b0) ? 32'b0 : rd2_temp;


    REG_FILE #(
    .DWIDTH(32),
    .MDEPTH(32),
    .AWIDTH(5) 
    ) crf (
    .CLK(clk),
    .WE(CRF_WE),
	.RST(rst),
    .RA1(CRF_RA1), 
    .RA2(CRF_RA2),
    .WA(CRF_WA),
    .WD(CRF_WD),
    .RD1(crd1_temp),
    .RD2(crd2_temp)
    );

    assign CRF_RD1 = (CRF_RA1 == 5'b0) ? 32'b0 : crd1_temp;
    assign CRF_RD2 = (CRF_RA2 == 5'b0) ? 32'b0 : crd2_temp;

    
    SYNC_RAM_DP_WBE #(
        .AWIDTH(AWIDTH-2),
        .DWIDTH(32),
        .MIF_HEX("example.hex")
    ) mem (
        // dmem
        .q0(PORT0_DOUT),    // output
        .d0(PORT0_DIN),     // input
        .addr0(PORT0_ADDR), // input
        .wbe0(PORT0_WEA),    // input
        .en0(PORT0_EN),
        
        // imem (read-only)
        .q1(imem_doutb),    // output   UNUSED
        .d1(32'd0),     // input
        .addr1(IMEM_ADDR[AWIDTH-1:2]), // input
        .wbe1(4'b0),    // input
        .en1(1'b1),
        
        .clk(clk)
    );


    bios_mem_print bios_mem ( //for synth
        //INSTRUCTION PORT (READ ONLY)
        .ena(IMEM_ADDR[30]),
        .rst(rst),
        .addra(IMEM_ADDR[12:2]),
        .douta(bios_douta_print),

        //DATA PORT (READ ONLY)
        .enb(PORT2_EN),
        .addrb(PORT2_ADDR[10:0]),
        .doutb(PORT2_DOUT_print),

        .clk(clk)
    );


    bios_mem_test bios_mem_t ( //for synth
        //INSTRUCTION PORT (READ ONLY)
        .ena(IMEM_ADDR[30]),
        .rst(rst),
        .addra(IMEM_ADDR[12:2]),
        .douta(bios_douta_test),

        //DATA PORT (READ ONLY)
        .enb(PORT2_EN),
        .addrb(PORT2_ADDR[10:0]),
        .doutb(PORT2_DOUT_test),

        .clk(clk)
    );

    assign bios_douta = TEST_BIOS ? bios_douta_test : bios_douta_print;
    assign PORT2_DOUT = TEST_BIOS ? PORT2_DOUT_test : PORT2_DOUT_print;

	PipeReg #(32) FF_reg5(.CLK(clk), .RST(1'b0), .EN(1'b1), .D(IMEM_ADDR), .Q(imem_addr_Q));
	assign IMEM_DOUT = imem_addr_Q[30] ? bios_douta : imem_doutb ;


    //PERIPHERAL

    //COUNTERS
    counter clock_counter(
        .clk(clk),
        .rst((PORT3_EN&(PORT3_WEA[0]|PORT3_WEA[1]|PORT3_WEA[2]|PORT3_WEA[3]))|rst),//reset when writing to 32'h80000018 or reseting system
        .en(1'b1),
        .o(clock_c)
    );
    assign PORT3_DOUT = clock_c;

    wire PORT4_EN_UN;
    assign PORT4_EN_UN = PORT4_EN ;


    //UART
    uart_mmio_wrapper #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .AWIDTH(AWIDTH)
    ) on_chip_uart(
        .clk(clk),
        .reset(rst),
    //MMIO
        .UART_DIN(PORT4_DIN),
        .UART_WEA(PORT4_WEA),
        .UART_EN(PORT4_EN_UN),
        .UART_ADDR(PORT4_ADDR),
        .UART_DOUT(PORT4_DOUT),
    //MODULE IO
        .serial_in(FPGA_SERIAL_RX),
        .serial_out(FPGA_SERIAL_TX)
    );
    
    assign EXT_HADDR = DMEM_HADDR[15:0];
    assign EXT_HSEL = PORT5_HSEL;
    assign EXT_HWRITE = DMEM_HWRITE;
    assign EXT_HSIZE = DMEM_HSIZE;
    assign EXT_HWDATA = DMEM_HWDATA;
    assign PORT5_HRDATA = EXT_HRDATA;
    assign PORT5_HREADYOUT = EXT_HREADYOUT;

endmodule