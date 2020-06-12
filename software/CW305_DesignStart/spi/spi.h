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
 * File:     spi.h
 * Release Information : Cortex-M3 DesignStart-r0p1-00rel0
 * ----------------------------------------------------------------
 *
 */

#include "xil_types.h"

int InitialiseSPI( int DapLinkFittedn );
void DisableSPIInterrupts( void );
int WriteSPIData( u8 * pbyte, int length );
int InitQSPIBaseFlash( void );
int WriteQSPIBaseFlash( u8 *pbytes, int length, u32 addr );
int ReadQSPIBaseFlash( u8 *pbytes, int length, u32 addr );

