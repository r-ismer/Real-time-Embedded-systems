#include <inttypes.h>
#include "system.h"
#include "io.h"
#include <stdio.h>
#include <unistd.h>
#include "altera_up_avalon_adc.h"
#include "altera_avalon_pio_regs.h"
#include <altera_avalon_performance_counter.h>

//colours
#define COLOR_0 0xF800
#define COLOR_1 0x07E0
#define COLOR_BG 0x0000

// Values to convert the ADC values to pixel values
#define ADC_MIN_VALUE 32768
#define ADC_MAX_VALUE 36863
#define LCD_MIN_VALUE 10
#define LCD_MAX_VALUE 110

//Pins of the LCD on the PIO
#define RD_N 19
#define CS_N 17
#define RES_N 20
#define LCS_ON 18
#define RS 16
#define WR_N 21

//LCD size
#define LCD_WIDTH 320
#define LCD_HEIGHT 240

void set_pin(uint32_t pin) {
	IOWR_ALTERA_AVALON_PIO_SET_BITS(PIO_0_BASE, 1 << pin);
}

void reset_pin(uint32_t pin) {
	IOWR_ALTERA_AVALON_PIO_CLEAR_BITS(PIO_0_BASE, 1 << pin);
}

//set data to the pins 0-15
void put_data(uint16_t data) {
    uint32_t port = IORD_32DIRECT(PIO_0_BASE, 0);
    IOWR_32DIRECT(PIO_0_BASE, 0, (port&(0xFFFF0000)) | data);
}

//write a command to the LCD
void LCD_WR_REG(uint32_t data) {
	reset_pin(RS);
	put_data(data);
	set_pin(WR_N);
	reset_pin(WR_N);
}

//write data to the LCD
void LCD_WR_DATA(uint32_t data) {
	set_pin(RS);
	put_data(data);
	set_pin(WR_N);
	reset_pin(WR_N);
}

void lcd_setup(void) {
	LCD_WR_REG(0x0011); //Exit Sleep
	LCD_WR_REG(0x00CF); // Power Control B
		LCD_WR_DATA(0x0000); // Always 0x00
		LCD_WR_DATA(0x0081); //
		LCD_WR_DATA(0X00c0);
	LCD_WR_REG(0x00ED); // Power on sequence control
		LCD_WR_DATA(0x0064); // Soft Start Keep 1 frame
		LCD_WR_DATA(0x0003); //
		LCD_WR_DATA(0X0012);
		LCD_WR_DATA(0X0081);
	LCD_WR_REG(0x00E8); // Driver timing control A
		LCD_WR_DATA(0x0085);
		LCD_WR_DATA(0x0001);
		LCD_WR_DATA(0x00798);
	LCD_WR_REG(0x00CB); // Power control A
		LCD_WR_DATA(0x0039);
		LCD_WR_DATA(0x002C);
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x0034);
		LCD_WR_DATA(0x0002);
	LCD_WR_REG(0x00F7); // Pump ratio control
		LCD_WR_DATA(0x0020);
	LCD_WR_REG(0x00EA); // Driver timing control B
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x0000);
	LCD_WR_REG(0x00B1); // Frame Control (In Normal Mode)
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x001b);
	LCD_WR_REG(0x00B6); // Display Function Control
		LCD_WR_DATA(0x000A);
		LCD_WR_DATA(0x00A2);
	LCD_WR_REG(0x00C0); //Power control 1
		LCD_WR_DATA(0x0005); //VRH[5:0]
	LCD_WR_REG(0x00C1); //Power control 2
		LCD_WR_DATA(0x0011); //SAP[2:0];BT[3:0]
	LCD_WR_REG(0x00C5); //VCM control 1
		LCD_WR_DATA(0x0045); //3F
		LCD_WR_DATA(0x0045); //3C
	LCD_WR_REG(0x00C7); //VCM control 2
		LCD_WR_DATA(0X00a2);
	LCD_WR_REG(0x0036); // Memory Access Control
		LCD_WR_DATA(0x0008);// BGR order
	LCD_WR_REG(0x00F2); // Enable 3G
		LCD_WR_DATA(0x0000); // 3Gamma Function Disable
	LCD_WR_REG(0x0026); // Gamma Set
		LCD_WR_DATA(0x0001); // Gamma curve selected
	LCD_WR_REG(0x00E0); // Positive Gamma Correction, Set Gamma
		LCD_WR_DATA(0x000F);
		LCD_WR_DATA(0x0026);
		LCD_WR_DATA(0x0024);
		LCD_WR_DATA(0x000b);
		LCD_WR_DATA(0x000E);
		LCD_WR_DATA(0x0008);
		LCD_WR_DATA(0x004b);
		LCD_WR_DATA(0X00a8);
		LCD_WR_DATA(0x003b);
		LCD_WR_DATA(0x000a);
		LCD_WR_DATA(0x0014);
		LCD_WR_DATA(0x0006);
		LCD_WR_DATA(0x0010);
		LCD_WR_DATA(0x0009);
		LCD_WR_DATA(0x0000);
	LCD_WR_REG(0X00E1); //Negative Gamma Correction, Set Gamma
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x001c);
		LCD_WR_DATA(0x0020);
		LCD_WR_DATA(0x0004);
		LCD_WR_DATA(0x0010);
		LCD_WR_DATA(0x0008);
		LCD_WR_DATA(0x0034);
		LCD_WR_DATA(0x0047);
		LCD_WR_DATA(0x0044);
		LCD_WR_DATA(0x0005);
		LCD_WR_DATA(0x000b);
		LCD_WR_DATA(0x0009);
		LCD_WR_DATA(0x002f);
		LCD_WR_DATA(0x0036);
		LCD_WR_DATA(0x000f);
		LCD_WR_REG(0x002A); // Column Address Set
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x00ef);
		LCD_WR_REG(0x002B); // Page Address Set
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x0000);
		LCD_WR_DATA(0x0001);
		LCD_WR_DATA(0x003f);
		LCD_WR_REG(0x003A); // COLMOD: Pixel Format Set
		LCD_WR_DATA(0x0055);
	LCD_WR_REG(0x00f6); // Interface Control
		LCD_WR_DATA(0x0001);
		LCD_WR_DATA(0x0030);
		LCD_WR_DATA(0x0000);
	LCD_WR_REG(0x0029); //display on
}

alt_up_adc_dev* adc;

// === MAIN
int main(void) {
	//set the direction of the PIO
	IOWR_ALTERA_AVALON_PIO_DIRECTION(PIO_0_BASE, 0xFFFFFFFF);

	//initialize the buffers for the ADC values of both channels
	uint16_t channel0[320];
	uint16_t channel1[320];
	for(int i=0;i<320;i++) {
		channel0[i] = 60;
		channel1[i] = 180;
	}
	uint32_t index = 0;

	//set the constant signals
	set_pin(RD_N);
	reset_pin(CS_N);
	set_pin(RES_N);
	set_pin(LCS_ON);

	//setting up the lcd
	lcd_setup();

	//setup the ADC
	adc = alt_up_adc_open_dev(ADC_0_NAME);
	alt_up_adc_auto_enable(adc);

 	while(1) {
		//read the ADC values and change them to pixel values
		unsigned int value_0 = alt_up_adc_read(adc, 0);
		unsigned int out_0 = (((value_0 - ADC_MIN_VALUE) * (LCD_MAX_VALUE - LCD_MIN_VALUE)) / (ADC_MAX_VALUE - ADC_MIN_VALUE)) + LCD_MIN_VALUE;
		unsigned int value_1 = alt_up_adc_read(adc, 1);
		unsigned int out_1 = (((value_1 - ADC_MIN_VALUE) * (LCD_MAX_VALUE - LCD_MIN_VALUE)) / (ADC_MAX_VALUE - ADC_MIN_VALUE)) + LCD_MIN_VALUE;

		//store the values in the buffers
		channel0[index%320] = out_0;
		channel1[index%320] = out_1 + 120;
		index++;

		//Hardware profiling
		/*
		PERF_RESET(PERFORMANCE_COUNTER_0_BASE);
		PERF_START_MEASURING(PERFORMANCE_COUNTER_0_BASE);
		PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, 1);*/

		//write pixels to screen
		LCD_WR_REG(0x002c); //new frame command
		for(int i=0;i<LCD_WIDTH;i++) {
			for(int j=0;j<LCD_HEIGHT;j++) {
				if((j>= channel0[(index+i-1)%LCD_WIDTH] && j<=channel0[(index+i)%LCD_WIDTH]) || (j<= channel0[(index+i-1)%LCD_WIDTH] && j >= channel0[(index+i)%LCD_WIDTH])) {
					LCD_WR_DATA(COLOR_0); //for channel 0
				}
				else if((j>= channel1[(index+i-1)%LCD_WIDTH] && j<=channel1[(index+i)%LCD_WIDTH]) || (j<= channel1[(index+i-1)%LCD_WIDTH] && j >= channel1[(index+i)%LCD_WIDTH])) {
					LCD_WR_DATA(COLOR_1); //for channel 1
				}
				else {
					LCD_WR_DATA(COLOR_BG);
				}
			}
		}

		//Hardware profiling
		/*
		PERF_END(PERFORMANCE_COUNTER_0_BASE, 1);
		PERF_STOP_MEASURING(PERFORMANCE_COUNTER_0_BASE);
		perf_print_formatted_report(PERFORMANCE_COUNTER_0_BASE, ALT_CPU_FREQ, 1, "test");*/

 	}
 return 0;
}
