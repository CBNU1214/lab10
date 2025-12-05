module debouncer #(
    parameter width = 1,
    parameter sample_count_max = 25000,
    parameter pulse_count_max = 150,
    parameter wrapping_counter_width = $clog2(sample_count_max),
    parameter saturating_counter_width = $clog2(pulse_count_max))
(
    input clk,
    input [width-1:0] glitchy_signal,
    output [width-1:0] debounced_signal
);
    // Create your debouncer circuit
    // The debouncer takes in a bus of 1-bit synchronized, but glitchy signals
    // and should output a bus of 1-bit signals that hold high when their respective counter saturates

    // Remove this line once you create your synchronizer
    reg [8:0] saturating_counters [width-1:0];
    reg [15:0] pulse_generator_count = 16'd0;
    reg pulse_generator = 1'b0;
    reg [width-1:0] out_signal;

    assign debounced_signal = out_signal;

    always @(posedge clk) begin
        case ({16'b0, pulse_generator_count})
            sample_count_max: pulse_generator_count <= 16'd0;
            default: pulse_generator_count <= pulse_generator_count + 16'd1;
        endcase
        pulse_generator <= ({16'b0, pulse_generator_count} == sample_count_max);
    end

    
    generate
    genvar i;
        for(i = 0; i < width; i = i + 1) begin:create_saturating_counters
           
            always @(posedge clk) begin
                if (pulse_generator) begin
                    case (glitchy_signal[i])
                        1'b1: saturating_counters[i] <= saturating_counters[i] + 		      		       {8'b0, ({23'b0, saturating_counters[i]} != pulse_count_max)};
                        1'b0:  saturating_counters[i] <= 9'd0;
                    endcase   
                end
                out_signal[i] <= {23'b0,saturating_counters[i]} == pulse_count_max;
            end
        end
    endgenerate

    integer k;
    initial begin
        for(k = 0; k < width; k = k + 1) begin
            saturating_counters[k] = 9'd0;
            out_signal[k] = 1'b0;
        end
    end
endmodule
