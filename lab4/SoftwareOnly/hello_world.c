#include <inttypes.h>
#include "system.h"
#include "io.h"
#include <stdio.h>
#include <unistd.h>

// This file makes the LCD controller component read an image from memory and displays it on the LCD screen


void LCD_WR_REG(uint32_t data) {
	IOWR_32DIRECT(LCD_DMA_0_BASE, 0, data);
	for(uint8_t i = 0; i<= 2; i++);
}

void LCD_WR_DATA(uint32_t data) {
	IOWR_32DIRECT(LCD_DMA_0_BASE, 0, data + (1 <<16));
	for(uint8_t i = 0; i<= 2; i++);
}

void Wait(uint64_t time ){
	for(uint64_t i = 0; i < time; ++i);
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


// === MAIN
int main(void) {
	printf("Hello World");

	//setting up the lcd
	lcd_setup();
	LCD_WR_REG(0x002c);
 	while(1) {
 		LCD_WR_DATA(0x00001F);
 		usleep(100);
 	}
 return 0;
}
