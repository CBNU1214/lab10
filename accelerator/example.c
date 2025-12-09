#include "types.h"
#include "memory_map.h"
#include "ascii.h"
#include "uart.h"

#define BUF_LEN 128
#define DATA_SIZE 100 

typedef void (*entry_t)(void);

// =============================================================
// 1. Accelerator Address Mapping
// =============================================================
volatile uint32_t* addr_din   = (volatile uint32_t*)0x80010000;
volatile uint32_t* addr_dout  = (volatile uint32_t*)0x80010004;
volatile uint32_t* addr_clear = (volatile uint32_t*)0x80010008;
volatile uint32_t* addr_w0    = (volatile uint32_t*)0x8001000C;
volatile uint32_t* addr_w1    = (volatile uint32_t*)0x80010010;
volatile uint32_t* addr_w2    = (volatile uint32_t*)0x80010014;
volatile uint32_t* addr_sw    = (volatile uint32_t*)0x80010018; 
volatile uint32_t* addr_led   = (volatile uint32_t*)0x8001001C; 

// =============================================================
// 2. Helper Functions
// =============================================================
void delay_loop(uint32_t count) {
    volatile uint32_t i;
    for (i = 0; i < count; i++);
}

int main(void)
{
    uint32_t data[DATA_SIZE];
    uint32_t hw_result[DATA_SIZE];
    uint32_t sw_result[DATA_SIZE];
    uint32_t seed = 0x12345678;
    int8_t buffer[BUF_LEN];
    uint32_t i;
    volatile uint32_t counter_start, counter_end;
    uint32_t hw_cycles, sw_cycles;

    // ---------------------------------------------------------
    // 커널 정의 (4가지 모드)
    // ---------------------------------------------------------
    uint32_t k_mode0[3] = { 1, 2, 1 };                       // SW0: Smoothing
    uint32_t k_mode1[3] = { (uint32_t)-1, 2, (uint32_t)-1 }; // SW1: Edge Detection
    uint32_t k_mode2[3] = { 0, 1, 0 };                       // SW2: Identity
    uint32_t k_mode3[3] = { 1, 0, (uint32_t)-1 };            // SW3: Gradient

    uint32_t* k_selected = 0; 
    char* mode_name = "";

    // [변경점 1] 여기서 데이터를 미리 생성하지 않고 루프 안으로 옮깁니다.
    
    uwrite_int8s("\r\n==========================================\r\n");
    uwrite_int8s("   4-Switch Kernel Selector Demo          \r\n");
    uwrite_int8s("   SW[0]..SW[3] selects specific Kernel   \r\n");
    uwrite_int8s("==========================================\r\n");

    uint32_t prev_switch_val = 0xFFFFFFFF; 

    while (1) 
    {
        uint32_t raw_sw = *addr_sw;
        uint32_t current_sw = raw_sw & 0xF; 

        if (current_sw != prev_switch_val) 
        {
            delay_loop(100000); 
            raw_sw = *addr_sw;
            current_sw = raw_sw & 0xF;

            // LED 제어
            *addr_led = current_sw; 

            int valid_selection = 0;

            if (current_sw == 0) {
                uwrite_int8s("\r\n[IDLE] All switches OFF. Standing by...\r\n");
            }
            else {
                if (current_sw & 0x1) {      // SW 0
                    k_selected = k_mode0;
                    mode_name = "SW0: Smoothing (1, 2, 1)";
                    valid_selection = 1;
                }
                else if (current_sw & 0x2) { // SW 1
                    k_selected = k_mode1;
                    mode_name = "SW1: Edge Detect (-1, 2, -1)";
                    valid_selection = 1;
                }
                else if (current_sw & 0x4) { // SW 2
                    k_selected = k_mode2;
                    mode_name = "SW2: Identity (0, 1, 0)";
                    valid_selection = 1;
                }
                else if (current_sw & 0x8) { // SW 3
                    k_selected = k_mode3;
                    mode_name = "SW3: Gradient (1, 0, -1)";
                    valid_selection = 1;
                }
            }

            if (valid_selection) 
            {
                // =========================================================
                // [핵심 변경점] 새로운 입력 데이터 생성 (New Random Input)
                // =========================================================
                
                // 1. 현재 하드웨어 사이클 카운터(시간)를 시드에 섞음 (누르는 타이밍에 따라 달라짐)
                seed ^= CYCLE_COUNTER; 

                // 2. 새로운 난수 데이터 생성
                for (i = 0; i < DATA_SIZE; i++) {
                    seed = seed * 1664525 + 1013904223;
                    data[i] = seed >> 16; 
                }
                
                uwrite_int8s("\r\n------------------------------------------\r\n");
                uwrite_int8s("[INFO] New Random Data Generated!\r\n"); // 알림 메시지 추가
                uwrite_int8s("Running Mode -> ");
                uwrite_int8s((int8_t*)mode_name);
                uwrite_int8s("\r\n");

                // --- HW 실행 ---
                COUNTER_RST = 1;
                counter_start = CYCLE_COUNTER;

                *addr_clear = 1; 
                *addr_w0 = k_selected[0]; 
                *addr_w1 = k_selected[1]; 
                *addr_w2 = k_selected[2];

                for (i = 0; i < DATA_SIZE; i++) {
                    *addr_din = data[i];     
                    hw_result[i] = *addr_dout; 
                }
                counter_end = CYCLE_COUNTER;
                hw_cycles = counter_end - counter_start;

                // --- SW 실행 ---
                COUNTER_RST = 1;
                counter_start = CYCLE_COUNTER;

                uint32_t x0, x1 = 0, x2 = 0;
                for (i = 0; i < DATA_SIZE; i++) {
                    x0 = data[i];
                    sw_result[i] = (x0 * k_selected[0]) + (x1 * k_selected[1]) + (x2 * k_selected[2]);
                    x2 = x1; x1 = x0;
                }
                counter_end = CYCLE_COUNTER;
                sw_cycles = counter_end - counter_start;

                // --- 결과 출력 ---
                int error_count = 0;
                uwrite_int8s("[Idx]   [Input]     [HW Out]    [SW Out]\r\n");
                
                for (i = 0; i < DATA_SIZE; i++) {
                    if (hw_result[i] != sw_result[i]) error_count++;
                    
                    if (i < 5) { 
                        uwrite_int8s(" ");
                        uwrite_int8s(uint32_to_ascii_hex(i, buffer, BUF_LEN));
                        uwrite_int8s("    ");
                        uwrite_int8s(uint32_to_ascii_hex(data[i], buffer, BUF_LEN));
                        uwrite_int8s("    ");
                        uwrite_int8s(uint32_to_ascii_hex(hw_result[i], buffer, BUF_LEN));
                        uwrite_int8s("    ");
                        uwrite_int8s(uint32_to_ascii_hex(sw_result[i], buffer, BUF_LEN));
                        uwrite_int8s("\r\n");
                    }
                }

                if (error_count == 0) uwrite_int8s("Result: SUCCESS\r\n");
                else                  uwrite_int8s("Result: FAIL\r\n");
                
                uwrite_int8s("Cycles - HW: ");
                uwrite_int8s(uint32_to_ascii_hex(hw_cycles, buffer, BUF_LEN));
                uwrite_int8s(", SW: ");
                uwrite_int8s(uint32_to_ascii_hex(sw_cycles, buffer, BUF_LEN));
                uwrite_int8s("\r\n");
            }

            prev_switch_val = current_sw;
        }
    }
    
    return 0;
}
