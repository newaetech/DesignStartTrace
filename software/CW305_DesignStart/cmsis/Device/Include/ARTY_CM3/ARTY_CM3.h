/**************************************************************************//**
 * @file     ARTY_CM1.h
 * @brief    CMSIS Core Peripheral Access Layer Header File for
 *           CM1 Device
 * @version  V3.02
 * @date     18. April 2018
 *
 * @note
 *
 ******************************************************************************/
/* Copyright (c) 2011 - 2018 ARM LIMITED

   All rights reserved.
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are met:
   - Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.
   - Neither the name of ARM nor the names of its contributors may be used
     to endorse or promote products derived from this software without
     specific prior written permission.
   *
   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
   ARE DISCLAIMED. IN NO EVENT SHALL COPYRIGHT HOLDERS AND CONTRIBUTORS BE
   LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
   INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
   CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
   ---------------------------------------------------------------------------*/


#ifndef ARTY_CM3_H
#define ARTY_CM3_H

#ifdef __cplusplus
 extern "C" {
#endif


/* -------------------------  Interrupt Number Definition  ------------------------ */

typedef enum IRQn
{
/* --------------------- Cortex-M3 Processor Exceptions Numbers ------------------- */
  NonMaskableInt_IRQn           = -14,    /*!<  2 Cortex-M3 Non Maskable Interrupt      */
  HardFault_IRQn                = -13,    /*!<  3 Cortex-M3 Hard Fault Interrupt        */
  MemoryManagement_IRQn         = -12,    /*!<  4 Cortex-M3 Memory Management Interrupt	*/
  BusFault_IRQn                 = -11,    /*!<  5 Cortex-M3 Bus Fault Interrupt         */
  UsageFault_IRQn               = -10,    /*!<  6 Cortex-M3 Usage Fault Interrupt       */
  SVCall_IRQn                   = -5,     /*!< 11 Cortex-M3 SV Call Interrupt           */
  DebugMonitor_IRQn             = -4,     /*!< 12 Cortex-M3 Debug Monitor Interrupt     */
  PendSV_IRQn                   = -2,     /*!< 14 Cortex-M3 Pend SV Interrupt           */
  SysTick_IRQn                  = -1,     /*!< 15 Cortex-M3 System Tick Interrupt       */


/* ----------------------  ARTY_CM1 Specific Interrupt Numbers  ------------------- */
  UART0_IRQn                    = 0,       /* UART 0 Interrupt                      */
  GPIO0_IRQn                    = 1,       /* GPIO 0 Interrupt                      */
  GPIO1_IRQn                    = 2,       /* GPIO 1 Interrupt                      */
  QSPI0_IRQn                    = 3,       /* Quad SPI 0, (Arty board) Interrupt    */
  DAP_QSPI0_IRQn                = 4,       /* DAPLink board Quad SPI 0 Interrupt    */
  DAP_SPI0_IRQn                 = 5,       /* DAPLink board SPI 0 Interrupt         */
  DAP_QSPI_XIP_IRQn             = 6,       /* DAPLink board Quad SPI XIP Interrupt  */
  DAPLinkFittedn_IRQn           = 7,       /* Static signal used to detect fitting of DAPLink board */
  Unused8_IRQn                  = 8,
  Unused9_IRQn                  = 9,
  Unused10_IRQn                 = 10,
  Unused11_IRQn                 = 11,
  Unused12_IRQn                 = 12,
  Unused13_IRQn                 = 13,
  Unused14_IRQn                 = 14,
  Unused15_IRQn                 = 15,
  Unused16_IRQn                 = 16,
  Unused17_IRQn                 = 17,
  Unused18_IRQn                 = 18,
  Unused19_IRQn                 = 19,
  Unused20_IRQn                 = 20,
  Unused21_IRQn                 = 21,
  Unused22_IRQn                 = 22,
  Unused23_IRQn                 = 23,
  Unused24_IRQn                 = 24,
  Unused25_IRQn                 = 25,
  Unused26_IRQn                 = 26,
  Unused27_IRQn                 = 27,
  Unused28_IRQn                 = 28,
  Unused29_IRQn                 = 29,
  Unused30_IRQn                 = 30,
  Unused31_IRQn                 = 31,
} IRQn_Type;


/* ================================================================================ */
/* ================      Processor and Core Peripheral Section     ================ */
/* ================================================================================ */

/* --------  Configuration of the Cortex-M0 Processor and Core Peripherals  ------- */
#define __CM3_REV                 0x0000      /* Core revision r0p0                              */
#define __MPU_PRESENT             0           /* MPU present or not                              */
#define __NVIC_PRIO_BITS          2           /* Number of Bits used for Priority Levels         */
#define __Vendor_SysTickConfig    0           /* Set to 1 if different SysTick Config is used    */

#include <core_CM3.h>                         /* Processor and core peripherals                  */
#include "system_ARTY_CM3.h"                  /* System Header                                   */


/* ================================================================================ */
/* ================       Device Specific Peripheral Section       ================ */
/* ================================================================================ */

/* -------------------  Start of section using anonymous unions  ------------------ */
#if defined ( __CC_ARM   )
  #pragma push
#pragma anon_unions
#elif defined(__ICCARM__)
  #pragma language=extended
#elif defined(__GNUC__)
  /* anonymous unions are enabled by default */
#elif defined(__TMS470__)
/* anonymous unions are enabled by default */
#elif defined(__TASKING__)
  #pragma warning 586
#else
  #warning Not supported compiler type
#endif
/* --------------------  End of section using anonymous unions  ------------------- */

#if defined ( __CC_ARM   )
  #pragma pop
#elif defined(__ICCARM__)
  /* leave anonymous unions enabled */
#elif defined(__GNUC__)
  /* anonymous unions are enabled by default */
#elif defined(__TMS470__)
  /* anonymous unions are enabled by default */
#elif defined(__TASKING__)
  #pragma warning restore
#else
  #warning Not supported compiler type
#endif



#ifdef __cplusplus
}
#endif

#endif  /* ARTY_CM3_H */
