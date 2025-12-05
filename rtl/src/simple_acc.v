module simple_acc (
    input wire          clk,
    input wire          rst,
    input wire [3:0]    addr,
    input wire          en,
    input wire          we,
    input wire [31:0]   din,    // Data input
    output wire [31:0]  dout
);

reg [31:0] reg_minimum;
wire [31:0] minimum_current;

wire data_in;
wire load_minimum;
wire load_minimum_ff;
wire clear_minimum;


assign minimum_current = (din < reg_minimum) ? din : reg_minimum;

assign data_in = en & we & (addr == 4'd0);
assign load_minimum = en & (addr == 4'd1);
assign clear_minimum = en & we & (addr == 4'd2);


// find minimum
always @(posedge clk, posedge rst) begin
    if (rst) reg_minimum <= 32'hFFFF_FFFF;
    else if (data_in) reg_minimum <= minimum_current;
    else if (clear_minimum) reg_minimum <= 32'hFFFF_FFFF;
end

// read data
PipeReg #(1) FF_LOAD (.CLK(clk), .RST(1'b0), .EN(en), .D(load_minimum), .Q(load_minimum_ff));

assign dout = (load_minimum_ff) ? reg_minimum : 32'd0;

endmodule