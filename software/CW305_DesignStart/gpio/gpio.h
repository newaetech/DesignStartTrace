/*
 * Copyright:
 * ----------------------------------------------------------------
 * This confidential and proprietary software may be used only as
 * authorised by a licensing agreement from ARM Limited
 *   (C) COPYRIGHT 2014, 2018 ARM Limited
 *       ALL RIGHTS RESERVED
 * The entire notice above must be reproduced on all authorised
 * copies and copies may only be made to the extent permitted
 * by a licensing agreement from ARM Limited.
 * ----------------------------------------------------------------
 * File:     gpio.h
 * Release Information : Cortex-M3 DesignStart-r0p1-00rel0
 * ----------------------------------------------------------------
 *
 */
 
//#include "xgpio.h"      // Needed for u32 definition
#include "xil_types.h"


int InitialiseGPIO( void );
void EnableGPIOInterrupts( void );
void IncLeds( void );
void SetDAPLinkQSPIMode( u32 mode );

// void GPIO0_Handler ( void );
// void GPIO1_Handler ( void );

/* GPIO channel identifiers */
#define ARTY_A7_LED_CHANNEL 1
#define ARTY_A7_DIP_CHANNEL 2
#define ARTY_A7_RGB_CHANNEL 1
#define ARTY_A7_PB_CHANNEL  2
#define ARTY_A7_DAPLINK_GPIO_CHANNEL 1

// GPIO register control
#define QSPI_XIPMODE  0x00                                              // XIP controller mode
#define QSPI_QSPIMODE 0x01                                              // QSPI controller mode

