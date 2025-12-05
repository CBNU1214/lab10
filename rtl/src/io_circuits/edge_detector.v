module edge_detector #(
    parameter width = 1
)(
    input clk,
    input [width-1:0] signal_in,
    output [width-1:0] edge_detect_pulse
);
    
    genvar i;
    reg [width-1:0] out = 0;
    assign edge_detect_pulse = out;
    reg [width-1:0] zeroin=0;
    
    generate
        for(i=0;i<width;i=i+1) begin:gen_ed
            always @(posedge clk) begin
                if(signal_in[i]==1&&out[i]==0&&zeroin[i]==0) begin
                    out[i]<=1;
                end
                else if(signal_in[i]==1&&out[i]==1) begin
                    out[i]<=0;
                    zeroin[i]<=1;
                end
                else if(signal_in[i]==0) begin
                    out[i]<=0;
                    zeroin[i]<=0;
                end
                else begin
                    out[i]<=0;
                end
            end
        end
    endgenerate
    //assign edge_detect_pulse = 0;
endmodule
