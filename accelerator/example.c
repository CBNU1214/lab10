#include "types.h"
#include "memory_map.h"
#include "ascii.h"
#include "uart.h"

#define BUF_LEN 128
#define IMG_WIDTH 5  // 이미지의 크기 설정
#define IMG_HEIGHT 5 // 이미지의 크기 설정
#define TOTAL_PIXELS (IMG_WIDTH * IMG_HEIGHT)

// 스위치 주소 (FPGA_TOP에서 12번지 = 0x80010030 매핑됨)
#define ADDR_SWITCHES ((volatile uint32_t*)0x80010030)

// =================================================================
// 소프트웨어 컨볼루션 연산 함수 (비교용)
// =================================================================
void software_convolution(uint32_t *input, uint32_t *output, uint32_t *kernel) {
    int x, y, kx, ky;
    int kernel_val, pixel_val;
    
    for (y = 0; y < IMG_HEIGHT; y++) {
        for (x = 0; x < IMG_WIDTH; x++) {
            uint32_t sum = 0;
            for (ky = -1; ky <= 1; ky++) {
                for (kx = -1; kx <= 1; kx++) {
                    int neighbor_x = x + kx;
                    int neighbor_y = y + ky;

                    // Zero Padding
                    if (neighbor_x < 0 || neighbor_x >= IMG_WIDTH || 
                        neighbor_y < 0 || neighbor_y >= IMG_HEIGHT) {
                        pixel_val = 0;
                    } else {
                        pixel_val = input[neighbor_y * IMG_WIDTH + neighbor_x];
                    }

                    int kernel_idx = (ky + 1) * 3 + (kx + 1);
                    kernel_val = kernel[kernel_idx];
                    sum += pixel_val * kernel_val;
                }
            }
            output[y * IMG_WIDTH + x] = sum;
        }
    }
}

// 타이머 함수
int __attribute__ ((noinline)) timer_count(uint32_t num) {
    uint32_t counter = CYCLE_COUNTER;
    COUNTER_RST = 1;
    uint32_t temp;
    for(int i = 0 ; i < num ; i ++) temp = CYCLE_COUNTER;
    counter -= temp;
    return counter;
}

int main(void)
{
    // 필터 정의
    uint32_t kernel_identity[9] = { 0, 0, 0, 0, 1, 0, 0, 0, 0 };
    uint32_t kernel_gaussian[9] = { 1, 2, 1, 2, 4, 2, 1, 2, 1 };

    int i;
    volatile uint32_t val_in, val_out;
    volatile uint32_t counter1, counter2;
    int8_t buffer[BUF_LEN];

    // 데이터를 저장할 버퍼
    uint32_t input_buffer[TOTAL_PIXELS];
    uint32_t hw_result_buffer[TOTAL_PIXELS];
    uint32_t sw_result_buffer[TOTAL_PIXELS];

    // 주소 매핑
    volatile uint32_t* addr_din    = (volatile uint32_t*)0x80010000;
    volatile uint32_t* addr_dout   = (volatile uint32_t*)0x80010004;
    volatile uint32_t* addr_clear  = (volatile uint32_t*)0x80010008;
    volatile uint32_t* addr_weight = (volatile uint32_t*)0x8001000C;
    
    // [추가] 상태 레지스터 주소 (13번지 = 0x34)
    volatile uint32_t* addr_status = (volatile uint32_t*)0x80010034;
    
    volatile uint32_t* addr_sw     = ADDR_SWITCHES;

    uwrite_int8s("\r\n=== FPGA Accelerator Demo ===\r\n");
    uwrite_int8s("Switch 0 (0->1): Run Identity Filter\r\n");
    uwrite_int8s("Switch 1 (0->1): Run Gaussian Filter\r\n");

    uint32_t prev_sw = *addr_sw;
    uint32_t curr_sw;
    uint32_t *selected_kernel = 0;
    char *filter_name = "";

    while (1) {
        curr_sw = *addr_sw;

        if ((curr_sw & 1) && !(prev_sw & 1)) {
            selected_kernel = kernel_identity;
            filter_name = "Identity Filter";
        }
        else if ((curr_sw & 2) && !(prev_sw & 2)) {
            selected_kernel = kernel_gaussian;
            filter_name = "Gaussian Filter";
        }
        else {
            prev_sw = curr_sw;
            continue;
        }

        uwrite_int8s("\r\n[Selected]: ");
        uwrite_int8s(filter_name);
        uwrite_int8s("\r\nSetting Weights...\r\n");

        // 1. 가중치 설정 및 초기화
        *addr_clear = 1;
        for(i=0; i<9; i++) *(addr_weight + i) = selected_kernel[i];

        // ---------------------------------------------------------
        // [STEP 1] 하드웨어 가속기 실행 (Status Check 포함)
        // ---------------------------------------------------------
        COUNTER_RST = 1;
        counter1 = CYCLE_COUNTER;

        for(i = 0; i < TOTAL_PIXELS + 10; i++)
        {
            val_in = i % 256;
            *addr_din = val_in;     // 입력

            // [중요] Status Register Polling (Done 신호 확인)
            // 비트 0이 'Done' 플래그이므로, 1이 될 때까지 대기
            // "Status Register를 확인하고 데이터를 읽는다"는 조건을 만족함
            while( (*addr_status & 0x1) == 0 );

            val_out = *addr_dout;   // 출력 읽기

            // 유효 픽셀만 버퍼에 저장
            if (i < TOTAL_PIXELS) {
                input_buffer[i] = val_in;
                hw_result_buffer[i] = val_out;
            }
        }
        
        counter2 = CYCLE_COUNTER;
        uint32_t hw_time = counter2 - counter1;

        // ---------------------------------------------------------
        // [STEP 2] 소프트웨어 실행
        // ---------------------------------------------------------
        COUNTER_RST = 1;
        counter1 = CYCLE_COUNTER;
        
        software_convolution(input_buffer, sw_result_buffer, selected_kernel);

        counter2 = CYCLE_COUNTER;
        uint32_t sw_time = counter2 - counter1;

        // ---------------------------------------------------------
        // [STEP 3] 결과 값 출력
        // ---------------------------------------------------------
        uwrite_int8s("\r\n--- 25 Pixel Results ---\r\n");
        for (i = 0; i < TOTAL_PIXELS; i++) {
            uwrite_int8s("idx: ");
            uwrite_int8s(uint32_to_ascii_hex(i, buffer, BUF_LEN));
            uwrite_int8s(" | In: ");
            uwrite_int8s(uint32_to_ascii_hex(input_buffer[i], buffer, BUF_LEN));
            uwrite_int8s(" -> Out: ");
            uwrite_int8s(uint32_to_ascii_hex(hw_result_buffer[i], buffer, BUF_LEN));
            uwrite_int8s("\r\n");
        }

        // ---------------------------------------------------------
        // [STEP 4] 속도 비교 결과 출력
        // ---------------------------------------------------------
        uwrite_int8s("--------------------------------\r\n");
        uwrite_int8s("Performance Comparison (Cycles):\r\n");
        
        uwrite_int8s("HW Cycles: ");
        uwrite_int8s(uint32_to_ascii_hex(hw_time, buffer, BUF_LEN));
        uwrite_int8s(" (With Polling)\r\n"); // Polling 시간 포함됨

        uwrite_int8s("SW Cycles: ");
        uwrite_int8s(uint32_to_ascii_hex(sw_time, buffer, BUF_LEN));
        uwrite_int8s("\r\n");
        
        uwrite_int8s("Done. Waiting for switch toggle...\r\n");

        prev_sw = curr_sw;
    }
    return 0;
}
