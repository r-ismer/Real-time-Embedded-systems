#include <stdio.h>
#include <stdlib.h>
#include "system.h"
#include "io.h"
#include <stdint.h>
#include <altera_avalon_performance_counter.h>

// cutom instruction
#define ALT_CI_SWAPBIT_N 0x00
#define ALT_CI_SWAPBIT(A) __builtin_custom_ini(ALT_CI_SWAPBIT_N, (A))

#define NB_WORDS 10000 //number of words to process

//sofware implementation
void swapbit_soft(int index) {
	uint32_t data = IORD_32DIRECT(ONCHIP_MEMORY2_1_BASE, index*4);
	data = (data >> 24) |
			(data&(1 << 23) >> 15) |
			(data&(1 << 22) >> 13) |
			(data&(1 << 21) >> 11) |
			(data&(1 << 20) >> 9) |
			(data&(1 << 19) >> 7) |
			(data&(1 << 18) >> 5) |
			(data&(1 << 17) >> 3) |
			(data&(1 << 16) >> 1) |
			(data&(1 << 15) << 1) |
			(data&(1 << 14) << 3) |
			(data&(1 << 13) << 5) |
			(data&(1 << 12) << 7) |
			(data&(1 << 11) << 9) |
			(data&(1 << 10) << 11)|
			(data&(1 << 9) << 13) |
			(data&(1 << 8) << 15) |
			(data << 24);
	IOWR_32DIRECT(ONCHIP_MEMORY2_1_BASE, index*4, data);
}

//custom instruction
void swapbit_instr(int index) {
	uint32_t data = IORD_32DIRECT(ONCHIP_MEMORY2_1_BASE, index*4);
	data = ALT_CI_SWAPBIT(data);
	IOWR_32DIRECT(ONCHIP_MEMORY2_1_BASE, index*4, data);
}

//DMA
void swapbit_dma(int length) {
	IOWR_32DIRECT(SWAPBITDMA_0_BASE, 0*4, ONCHIP_MEMORY2_1_BASE); //source address
	IOWR_32DIRECT(SWAPBITDMA_0_BASE, 1*4, ONCHIP_MEMORY2_1_BASE); //destination address
	IOWR_32DIRECT(SWAPBITDMA_0_BASE, 2*4, length); //set the number of words to process
	IOWR_32DIRECT(SWAPBITDMA_0_BASE, 3*4, 1); //start

	while(!IORD_32DIRECT(SWAPBITDMA_0_BASE, 3*4)); //wait for the DMA to be done
}

//function to fill the Onchip memory with data
void fill_onchip(void) {
	for(int i=0; i<10000;i++) {
		IOWR_32DIRECT(ONCHIP_MEMORY2_1_BASE, i*4, i);
	}
}

//main function
int main()
{
	fill_onchip(); //to have some data to process

	/* ===== software profiling ===== */
	/*
	for(int i=0;i<NB_WORDS;i++) {
		int index = i%10000;
		//swapbit_soft(i); //software implementation
		//swapbit_instr(i); //custom instruction
	}*/
	//swapbit_dma(NB_WORDS); //dma, needs to be put in a loop if NB_WORDS > 10000



	/* ===== Hardware profiling ===== */
	PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
	PERF_START_MEASURING(PERFORMANCE_COUNTER_0_BASE);

	//== software and custom instruction ==
	/*
	PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE,1);
	for(int i=0;i<NB_WORDS;i++) {
		int index = i%10000;
		//swapbit_soft(i); //software implementation
		//swapbit_instr(i); //custom instruction
	}
	PERF_END(PERFORMANCE_COUNTER_0_BASE,1);*/

	//== DMA ==
	/*
	PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE,1);
	swapbit_dma(NB_WORDS);
	ERF_END(PERFORMANCE_COUNTER_0_BASE,1);*/

	//end hardware profiling and print results
	PERF_STOP_MEASURING(PERFORMANCE_COUNTER_0_BASE);
	perf_print_formatted_report(PERFORMANCE_COUNTER_0_BASE, ALT_CPU_FREQ, 1, "test");
	printf("done");
	return 0;
}
