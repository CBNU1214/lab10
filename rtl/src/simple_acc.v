module simple_acc (
    input wire          clk,
    input wire          rst,
    input wire [3:0]    addr,
    input wire          en,
    input wire          we,
    input wire [31:0]   din,    
    output wire [31:0]  dout  
);

    parameter IMG_WIDTH = 5;
    localparam SR_DEPTH = (2 * IMG_WIDTH) + 3; // 19

    // [1] 레지스터 선언
    reg [31:0] weights [0:8];
    reg [31:0] shift_reg [0:SR_DEPTH-1];
    reg [31:0] reg_Y;

    // 제어 신호 디코딩
    wire data_in     = en & we & (addr == 4'd0); // 픽셀 입력
    wire result_read = en & (addr == 4'd1);      // 결과 읽기
    wire clear_acc   = en & we & (addr == 4'd2); // 초기화
    wire weight_we   = en & we & (addr >= 4'd3) & (addr <= 4'd11);
    wire [3:0] weight_idx = addr - 4'd3;

    // 읽기 동기화
    wire result_read_ff;
    integer i;

    // =========================================================
    // [수정 1] 픽셀 위치 카운터 및 좌표 계산 추가
    // 0~63까지 세면서 현재 픽셀이 몇 번째 행, 몇 번째 열인지 파악
    // =========================================================
    reg [5:0] pix_cnt; // 0 ~ 63 (8x8 = 64 pixels)

    // 현재 입력되는 픽셀(p8)의 좌표
    wire [2:0] col = pix_cnt % 5; // x 좌표 (0~7)
    wire [2:0] row = pix_cnt / 5; // y 좌표 (0~7)

    // 윈도우 내 픽셀 유효성 검사 조건 (Zero Padding 로직)
    // 현재 입력(p8)을 기준으로 다른 픽셀들이 이미지 범위를 벗어나는지 확인
    wire valid_row_1 = (row >= 1); // 위쪽으로 1칸 유효?
    wire valid_row_2 = (row >= 2); // 위쪽으로 2칸 유효?
    wire valid_col_1 = (col >= 1); // 왼쪽으로 1칸 유효?
    wire valid_col_2 = (col >= 2); // 왼쪽으로 2칸 유효?

    // =========================================================
    // [수정 2] 3x3 윈도우 픽셀 추출 (Zero Padding MUX 적용)
    // 경계를 벗어난 픽셀은 강제로 0으로 만듦
    // =========================================================
    wire [31:0] p0, p1, p2, p3, p4, p5, p6, p7, p8;

    // Top Row (2줄 전 데이터) - row가 2 이상일 때만 유효
    assign p0 = (valid_row_2 && valid_col_2) ? shift_reg[2*IMG_WIDTH + 2] : 32'd0;
    assign p1 = (valid_row_2 && valid_col_1) ? shift_reg[2*IMG_WIDTH + 1] : 32'd0;
    assign p2 = (valid_row_2)                ? shift_reg[2*IMG_WIDTH + 0] : 32'd0;

    // Mid Row (1줄 전 데이터) - row가 1 이상일 때만 유효
    assign p3 = (valid_row_1 && valid_col_2) ? shift_reg[IMG_WIDTH + 2] : 32'd0;
    assign p4 = (valid_row_1 && valid_col_1) ? shift_reg[IMG_WIDTH + 1] : 32'd0;
    assign p5 = (valid_row_1)                ? shift_reg[IMG_WIDTH + 0] : 32'd0;

    // Bot Row (현재 줄 데이터) - 현재 행은 항상 유효하지만, 왼쪽 컬럼 검사는 필요
    assign p6 = (valid_col_2) ? shift_reg[2] : 32'd0;
    assign p7 = (valid_col_1) ? shift_reg[1] : 32'd0;
    assign p8 = shift_reg[0]; // 현재 입력 데이터 (항상 유효)

    // [3] 컨볼루션 연산 (MAC)
    wire [31:0] conv_sum;
    assign conv_sum = (weights[0] * p0) + (weights[1] * p1) + (weights[2] * p2) +
                      (weights[3] * p3) + (weights[4] * p4) + (weights[5] * p5) +
                      (weights[6] * p6) + (weights[7] * p7) + (weights[8] * p8);

    // [4] 순차 논리
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            reg_Y <= 0;
            pix_cnt <= 0; // 카운터 초기화
            for (i=0; i<SR_DEPTH; i=i+1) shift_reg[i] <= 0;
            for (i=0; i<9; i=i+1) weights[i] <= 0;
        end
        else if (data_in) begin
            // 1. 시프트 레지스터 업데이트
            shift_reg[0] <= din;
            for (i=1; i<SR_DEPTH; i=i+1) begin
                shift_reg[i] <= shift_reg[i-1];
            end
            
            // 2. 연산 결과 저장
            reg_Y <= conv_sum;

            // [수정] 픽셀 카운터 증가 (0~63 반복)
            if (pix_cnt == 24) pix_cnt <= 0;
            else pix_cnt <= pix_cnt + 1;
        end
        else if (clear_acc) begin
            reg_Y <= 0;
            pix_cnt <= 0; // 카운터 초기화
            for (i=0; i<SR_DEPTH; i=i+1) shift_reg[i] <= 0;
        end
        else if (weight_we) begin
            weights[weight_idx] <= din;
        end
    end

    // [5] 결과 출력
    PipeReg #(1) FF_LOAD_Y (.CLK(clk), .RST(1'b0), .EN(en), .D(result_read), .Q(result_read_ff));
    assign dout = (result_read_ff) ? reg_Y : 32'd0;

endmodule
