// module counter (
//     input clk,
//     input rst,
//     input en,
//     output [31:0] o
// );
//     reg [31:0] count;
//     assign o=count;
//     always @ (posedge clk) begin
//         if (rst) count <=0;
//         else if (en) count <= count+1;
//     end
// endmodule

module counter (
    input clk,
    input rst,
    input en,
    output [31:0] o
);
    wire [31:0] count_d, count_q;
    PipeReg #(32) FF_count(.CLK(clk), .RST(rst), .EN(en), .D(count_d), .Q(count_q));
    assign count_d=count_q+32'b1;
    assign o=count_q;
endmodule





//////////////////////


