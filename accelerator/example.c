#include "types.h"
#include "memory_map.h"
#include "ascii.h"
#include "uart.h"

#define BUF_LEN 128

typedef void (*entry_t)(void);


int __attribute__ ((noinline)) timer_count(uint32_t num)
{
    uint32_t counter;

    counter = CYCLE_COUNTER;//CSR read by macro

    COUNTER_RST = 1; //CSR write by macro

    uint32_t temp;
    for(int i = 0 ; i < num ; i ++){
        temp = CYCLE_COUNTER;//CSR read by macro
    }
    counter -= temp;

    return counter;
}

int main(void)
{
    uint32_t data[10] = {35, 203, 224, 532, 871, 332, 4, 650, 1002, 999};

    uint32_t i;

    volatile uint32_t val1, val2;
    volatile uint32_t counter1, counter2;
    int8_t buffer[BUF_LEN];

    volatile uint32_t* addr_din = (volatile uint32_t*)0x80010000;
    volatile uint32_t* addr_dout = (volatile uint32_t*)0x80010004;
    volatile uint32_t* addr_clear = (volatile uint32_t*)0x80010008;

    COUNTER_RST = 1;
    counter1 = CYCLE_COUNTER;


    *addr_clear = 1;

    for(i = 0; i < 10; i++)
    {
        val1 = data[i];
        *addr_din = val1;
    }

    val2 = *addr_dout;


/*
    val2 = 0xFFFFFFFF;

    for(i = 0; i < 10; i++)
    {
        val1 = data[i];
  
        if(val1 < val2) val2 = val1;
    }
*/

    counter2 = CYCLE_COUNTER;

    uwrite_int8s("minimum value : ");
    uwrite_int8s(uint32_to_ascii_hex(val2,buffer,BUF_LEN));
    uwrite_int8s("\r\n");

    uwrite_int8s("computing time : ");
    uwrite_int8s(uint32_to_ascii_hex(counter2-counter1,buffer,BUF_LEN));
    uwrite_int8s("\r\n");

    uint32_t bios = ascii_hex_to_uint32("40000000");
    entry_t start = (entry_t) (bios);
    start();
    return 0;
}




