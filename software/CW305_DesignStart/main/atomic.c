/*
 * Copyright:
 * ----------------------------------------------------------------
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 *   (C) COPYRIGHT 2014, 2016 ARM Limited
 *       ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 * ----------------------------------------------------------------
 * File:     atomic.h
 * Release Information : Cortex-M3 DesignStart-r0p1-00rel0
 * ----------------------------------------------------------------
 *
 */

// Atomic test function in assembly
#include <stdint.h>
#include <stdio.h>
#include "atomic.h"
#include <stdlib.h>
#include <xil_printf.h>

// Test atomic access
uint32_t atomic_access(uint32_t *mem, uint32_t val){
	volatile uint32_t original_val;
	volatile uint32_t new_val;
	uint32_t status;
//  char    debugStr[256];
	
	original_val = *mem;
	status = atomic_test(mem, val);
	new_val = *mem;
//	if (status == 0) {
//		print("STREX OK   ");
//	} else {
//		print("STREX Fail ");
//	}
//	sprintf(debugStr, "At %8x, was %8x, now %8x\r\n",(uint32_t)mem, original_val, new_val);
//	print (debugStr);
	return status;
}
