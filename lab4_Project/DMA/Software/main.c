#include <stdio.h>
#include "lt_24_utils.h"
#include "io.h"
#include "system.h"
#include <unistd.h>
#include <altera_up_avalon_adc.h>

#define ADC_MIN_VALUE 32768
#define ADC_MAX_VALUE 36863
#define LCD_MIN_VALUE 10
#define LCD_MAX_VALUE 110

alt_up_adc_dev* adc;

int main()
{
	lcd_setup();
	adc = alt_up_adc_open_dev(ADC_0_NAME);
	alt_up_adc_auto_enable(adc);

	usleep(1000);


	lcd_set_address_0(ONCHIP_MEMORY2_1_BASE);
	lcd_set_address_1(ONCHIP_MEMORY2_1_BASE + 8);
	lcd_start();
	IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, STATUS, 1);

	while(1) {
		usleep(6000);
		// get value from adc
		unsigned int value_0 = alt_up_adc_read(adc, 0);
		unsigned int out_0 = (((value_0 - ADC_MIN_VALUE) * (LCD_MAX_VALUE - LCD_MIN_VALUE)) / (ADC_MAX_VALUE - ADC_MIN_VALUE)) + LCD_MIN_VALUE;
		unsigned int value_1 = alt_up_adc_read(adc, 1);
		unsigned int out_1 = (((value_1 - ADC_MIN_VALUE) * (LCD_MAX_VALUE - LCD_MIN_VALUE)) / (ADC_MAX_VALUE - ADC_MIN_VALUE)) + LCD_MIN_VALUE;
		IOWR_32DIRECT(ONCHIP_MEMORY2_1_BASE, 0, out_0);
		IOWR_32DIRECT(ONCHIP_MEMORY2_1_BASE, 8, out_1);
		//printf("value0: %d\n", value_0);
	}

	return 0;
}
