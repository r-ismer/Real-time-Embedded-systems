/*
 * lt_24_utils.h
 *
 *  Created on: 29 déc. 2022
 *      Author: Ismer Richard
 */


#ifndef LT_24_UTILS_H_
#define LT_24_UTILS_H_

#include <stdio.h>
#include "system.h"
#include <stdint.h>

#define FRAME_SIZE 76800

#define CMD_SET_SIZE 23
#define ADDRESS_0 0*4
#define ADDRESS_1 1*4
#define STATUS 2*4
#define CMD_CMD 3*4
#define CMD_NUM 4*4
#define CMD_DATA 5*4

struct command {
	int cmd;
	int length;
	int *table;
};

void lcd_setup(void);
void lcd_set_address_0(uint32_t address);
void lcd_set_address_1(uint32_t address);
void lcd_start();

#endif /* LT_24_UTILS_H_ */
