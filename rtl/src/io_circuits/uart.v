module uart #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200)
(
    input wire clk,
    input wire reset,

    input wire [7:0] data_in,
    input wire data_in_valid,
    output wire data_in_ready,

    output wire [7:0] data_out,
    output wire data_out_valid,
    input wire data_out_ready,

    input wire serial_in,
    output wire serial_out
);
    reg serial_in_reg, serial_out_reg;
    wire serial_out_tx;
    assign serial_out = serial_out_reg;
    always @ (posedge clk) begin
        serial_out_reg <= reset ? 1'b1 : serial_out_tx;
        serial_in_reg <= reset ? 1'b1 : serial_in;
    end

    uart_transmitter #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uatransmit (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_in_ready(data_in_ready),
        .serial_out(serial_out_tx)
    );

    uart_receiver #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uareceive (
        .clk(clk),
        .reset(reset),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .data_out_ready(data_out_ready),
        .serial_in(serial_in_reg)
    );
endmodule



module uart_mmio_wrapper #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200,
    parameter AWIDTH = 16)
(
    input wire clk,
    input wire reset,
//MMIO
    input wire [31:0] UART_DIN,
    input wire [3:0] UART_WEA,
    input wire UART_EN,
    input wire [AWIDTH-1:0] UART_ADDR,
    output wire [31:0] UART_DOUT,
//MODULE IO
    input wire serial_in,
    output wire serial_out
);
    wire data_in_ready,data_out_valid,data_in_valid,data_out_ready;
    wire [7:0] data_in, data_out;

    wire [AWIDTH-1:0] UART_ADDR_Q;



	PipeReg #(AWIDTH) FF_uart_address_module(.CLK(clk), .RST(1'b0), .EN(1'b1), .D(UART_ADDR), .Q(UART_ADDR_Q));

    assign UART_DOUT = (UART_ADDR_Q == {AWIDTH{1'b0}}) ? {30'b0, data_out_valid, data_in_ready}:
                        (UART_ADDR_Q == {{(AWIDTH-1){1'b0}}, 1'b1}) ? {24'b0, data_out} : 32'hFACE;

    wire [7:0] DATA_IN_Q, DATA_IN_D;
    PipeReg #(8) FF_data_in(.CLK(clk), .RST(reset), .EN(1'b1), .D(DATA_IN_D), .Q(DATA_IN_Q));
    assign DATA_IN_D = UART_EN&(UART_WEA[0]|UART_WEA[1]|UART_WEA[2]|UART_WEA[3]) ? UART_DIN[7:0] : DATA_IN_Q;
    assign data_in = DATA_IN_Q;


    wire DATA_IN_VALID_Q, DATA_IN_VALID_D;
    PipeReg #(1) FF_data_in_valid(.CLK(clk), .RST(reset), .EN(1'b1), .D(DATA_IN_VALID_D), .Q(DATA_IN_VALID_Q));
    assign DATA_IN_VALID_D = UART_EN&(UART_WEA[0]|UART_WEA[1]|UART_WEA[2]|UART_WEA[3])&(UART_ADDR[1:0]==2'b10);
    assign data_in_valid = DATA_IN_VALID_Q; 


    wire DATA_OUT_READY_Q, DATA_OUT_READY_D;
    PipeReg #(1) FF_data_out_ready(.CLK(clk), .RST(reset), .EN(1'b1), .D(DATA_OUT_READY_D), .Q(DATA_OUT_READY_Q));
    assign DATA_OUT_READY_D =  UART_EN&(!(UART_WEA[0]|UART_WEA[1]|UART_WEA[2]|UART_WEA[3]))&(UART_ADDR[1:0]==2'b01); 
    assign data_out_ready = DATA_OUT_READY_Q;




    uart #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) on_chip_uart (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_out_ready(data_out_ready),
        .serial_in(serial_in),

        .data_in_ready(data_in_ready),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .serial_out(serial_out)
    );


endmodule
