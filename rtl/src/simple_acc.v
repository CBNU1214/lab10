module simple_acc (
    input wire          clk,
    input wire          rst,
    input wire [3:0]    addr,
    input wire          en,
    input wire          we,
    input wire [31:0]   din,      // Data input
    input wire [3:0]    switches, // [입력] 스위치 포트
    output wire [3:0]   leds,      // [출력] LED 포트 (생략되었던 부분)
    output wire [31:0]  dout 
);

    // =============================================================
    // 1. Internal Registers
    // =============================================================
    reg [31:0] reg_w0, reg_w1, reg_w2;
    reg [31:0] reg_x0, reg_x1;
    reg [31:0] reg_y;

    // [복구됨] LED 상태를 저장할 레지스터
    reg [3:0]  reg_leds;

    // =============================================================
    // 2. Control Signals (Address Decoding)
    // =============================================================
    // addr 0: Write Input Data (x[n]) & Trigger Compute
    wire write_din   = en & we & (addr == 4'd0);
    // addr 1: Read Output Result (y[n])
    wire read_dout   = en & ~we & (addr == 4'd1);
    // addr 2: Clear / Reset Internal State
    wire write_clear = en & we & (addr == 4'd2);
    // addr 3~5: Write Weights
    wire write_w0    = en & we & (addr == 4'd3);
    wire write_w1    = en & we & (addr == 4'd4);
    wire write_w2    = en & we & (addr == 4'd5);
    
    // addr 6: Read Switches (Memory Map: 0x80010018)
    wire read_sw     = en & ~we & (addr == 4'd6); 

    // [복구됨] addr 7: Write LEDs (Memory Map: 0x8001001C)
    wire write_leds  = en & we & (addr == 4'd7);

    // =============================================================
    // 3. Logic Implementation
    // =============================================================
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            reg_w0 <= 0; reg_w1 <= 0; reg_w2 <= 0;
            reg_x0 <= 0; reg_x1 <= 0;
            reg_y  <= 0;
            reg_leds <= 4'b0000; // 리셋 시 LED 끄기
        end
        else begin
            // Weight Configuration
            if (write_w0) reg_w0 <= din;
            if (write_w1) reg_w1 <= din;
            if (write_w2) reg_w2 <= din;

            // [복구됨] LED Register Update
            if (write_leds) reg_leds <= din[3:0];

            // Clear Logic
            if (write_clear) begin
                reg_x0 <= 0; reg_x1 <= 0;
                reg_y  <= 0;
            end
            // Compute Logic
            else if (write_din) begin
                reg_x0 <= din;
                reg_x1 <= reg_x0;
                reg_y <= (din * reg_w0) + (reg_x0 * reg_w1) + (reg_x1 * reg_w2);
            end
        end
    end

    // =============================================================
    // 4. Read Logic (Pipelined Read)
    // =============================================================
    wire load_dout_ff;
    PipeReg #(1) FF_LOAD (.CLK(clk), .RST(1'b0), .EN(en), .D(read_dout), .Q(load_dout_ff));

    wire load_sw_ff;
    PipeReg #(1) FF_LOAD_SW (.CLK(clk), .RST(1'b0), .EN(en), .D(read_sw), .Q(load_sw_ff));

    // MUX Output
    assign dout = (load_dout_ff) ? reg_y : 
                  (load_sw_ff)   ? {28'd0, switches} : 32'd0;

    // [복구됨] LED 포트 연결
    assign leds = reg_leds;

endmodule
