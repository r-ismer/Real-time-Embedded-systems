/*
 * lt_24_utils.c
 *
 *  Created on: 29 déc. 2022
 *      Author: Ismer Richard
 */

#include <stdio.h>
#include "lt_24_utils.h"
#include "io.h"
#include "sys/alt_irq.h"
#include <unistd.h>

int pwr_ctrl_b_table[3]		= {0x0000,0x0081,0x00C0};
int pwr_on_seq_table[4]		= {0x0064,0x0003,0x0012,0x0081};
int drv_ctrl_a_table[3]	= {0x0085,0x0001,0x0798};
int pwr_ctrl_a_table[5]= {0x0039,0x002C,0x0000,0x0034,0x0002};
int pmp_rat_ctrl_table[1]= {0x0020};
int drv_ctrl_b_table[2]= {0x0000,0x0000};
int frame_ctrl_table[2]= {0x0000,0x001B};
int disp_fun_ctrl_table[2]= {0x000A,0x00A2};
int pwr_ctrl_1_table[1] = {0x0005};
int pwr_ctrl_2_table[1] = {0x0011};
int vcm_ctrl_1_table[2] = {0x0045, 0x0034};
int vcm_ctrl_2_table[1] = {0x00A2};
int mem_acc_ctrl_table[1] = {0x0008};
int enable_3g_table[1] = {0x0000};
int gamma_set_table[1] = {0x0001};
int p_gam_corr_table[15] = {0x000F,0x0026,0x0024,0x000B,0x0000,
							0x0008,0x004B,0x00A8,0x003B,0x000A,
							0x0014,0x0006,0x0010,0x0009,0x0000};
int n_gam_corr_table[15] = {0x0000,0x001C,0x0020,0x0004,0x0010,
							0x0008,0x0034,0x0047,0x0044,0x0005,
							0x000B,0x0009,0x002F,0x0036,0x000F};
int col_addr_set_table[4] = {0x0000,0x0000,0x0000,0x00EF};
int pag_addr_set_table[4] = {0x0000,0x0000,0x0001,0x003F};
int pix_format_set_table[1] = {0x0055};
int interface_ctrl_table[3] = {0x0001,0x0030,0x0000};

struct command exit_sleep = {0x0011, 0, NULL};
struct command pwr_ctrl_b = {0x00CF, 3, pwr_ctrl_b_table};
struct command pwr_on_seq = {0x00ED, 4, pwr_on_seq_table};
struct command drv_ctrl_a = {0x00E8, 3, drv_ctrl_a_table};
struct command pwr_ctrl_a = {0x00CB, 5, pwr_ctrl_a_table};
struct command pmp_rat_ctrl = {0x00F7, 1, pmp_rat_ctrl_table};
struct command drv_ctrl_b = {0x00EA, 2, drv_ctrl_b_table};
struct command frame_ctrl = {0x00B1, 2, frame_ctrl_table};
struct command disp_fun_ctrl = {0x00B6, 2, disp_fun_ctrl_table};
struct command pwr_ctrl_1 = {0x00C0, 1, pwr_ctrl_1_table};
struct command pwr_ctrl_2 = {0x00C1, 1, pwr_ctrl_2_table};
struct command vcm_ctrl_1 = {0x00C5, 2, vcm_ctrl_1_table};
struct command vcm_ctrl_2 = {0x00C7, 1, vcm_ctrl_2_table};
struct command mem_acc_ctrl = {0x0036, 1, mem_acc_ctrl_table};
struct command enable_3g = {0x00F2, 1, enable_3g_table};
struct command gamma_set = {0x0026, 1, gamma_set_table};
struct command p_gam_corr = {0x00E0, 15, p_gam_corr_table};
struct command n_gam_corr = {0x00E1, 15, n_gam_corr_table};
struct command col_addr_set = {0x002A, 4, col_addr_set_table};
struct command pag_addr_set = {0x002B, 4, pag_addr_set_table};
struct command pix_format_set = {0x003A, 1, pix_format_set_table};
struct command interface_ctrl = {0x00F5, 3, interface_ctrl_table};
struct command disp_on = {0x0029, 0, NULL};

struct command *command_set[CMD_SET_SIZE] = {
		&exit_sleep,
		&pwr_ctrl_b,
		&pwr_on_seq,
		&drv_ctrl_a,
		&pwr_ctrl_a,
		&pmp_rat_ctrl,
		&drv_ctrl_b,
		&frame_ctrl,
		&disp_fun_ctrl,
		&pwr_ctrl_1,
		&pwr_ctrl_2,
		&vcm_ctrl_1,
		&vcm_ctrl_2,
		&mem_acc_ctrl,
		&enable_3g,
		&gamma_set,
		&p_gam_corr,
		&n_gam_corr,
		&col_addr_set,
		&pag_addr_set,
		&pix_format_set,
		&interface_ctrl,
		&disp_on
};

void lcd_setup(void){
	for(int i = 0; i<CMD_SET_SIZE; i++){
		printf("------------------------------\n");
		struct command *cmd = command_set[i];
		IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, CMD_CMD, cmd->cmd);
		printf("command : %x \n", cmd->cmd);

		IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, CMD_NUM, cmd->length);

		if(cmd->length != 0) {
			for(int j = 0; j < (cmd->length); j++){
				IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, CMD_DATA, cmd->table[j]);
			}
		}

		IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, STATUS, 1<<1);

		usleep(100);
	}
	return;
}

void lcd_set_address_0(uint32_t address) {
	IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, ADDRESS_0, address);
}

void lcd_set_address_1(uint32_t address) {
	IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, ADDRESS_1, address);
}

void lcd_start() {
	IOWR_32DIRECT(LT_24_ANALYZER_0_BASE, STATUS, 1);
}
