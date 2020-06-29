/*
    This file is part of the ChipWhisperer Example Targets
    Copyright (C) 2020 NewAE Technology Inc.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

// Xilinx specific headers
#include "xparameters.h"
#include "xgpio.h"
#include "xuartlite_l.h"

#include "m3_for_arty.h"        // Project specific header
#include "cw_gpio.h"
#include "uart.h"
#include "spi.h"
#include "main.h"
#include "arm_etm.h"


// simpleserial and AES:
#include "simpleserial.h"
#include "hal.h"
#include "aes-independant.h"

// uartlite example:
#include "xstatus.h"
#include "xuartlite.h"


void enable_itm()
{
    // Configure TPI
    CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk; // Enable access to registers
    TPI->ACPR = 1; // Trace clock = HCLK/(x+1) = 8MHz = UART 's baudrate
                   // The HCLK of F105 is 8MHz so x is 0, and the F103 is 72MHz so x is 8
                   // (not needed for parallel mode)
    TPI->SPPR = 0; // parallel trace mode
    //TPI->SPPR = 1; // SWO with Manchester encoding
    //TPI->SPPR = 2; // SWO with NRZ encoding
    TPI->FFCR = 0x102; // packet framing enabled
    //TPI->FFCR = 0x100; // for DWT/ITM only, no ETM
    //if (trace_lanes == 1) {TPI->CSPSR =0x00000001;}
    //else if (trace_lanes == 2) {TPI->CSPSR =0x00000002;}
    //else if (trace_lanes == 4) {TPI->CSPSR =0x00000008;}
    TPI->CSPSR =0x00000008;

    // Configure ITM:
    ITM->LAR = 0xC5ACCE55;
    ITM->TCR = (1 << ITM_TCR_TraceBusID_Pos) // Trace bus ID for TPIU
             | (1 << ITM_TCR_DWTENA_Pos) // Enable events from DWT
             | (0 << ITM_TCR_SYNCENA_Pos) // Disable sync packets!
             | (1 << ITM_TCR_ITMENA_Pos); // Main enable for ITM
    ITM->TER = 0xFFFFFFFF; // Enable all stimulus ports
    ITM->TPR = 0x00000000; // allow unpriviledged access

    // Configure DWT:
    DWT->CTRL = (0xf << DWT_CTRL_POSTINIT_Pos);// countdown counter for PC sampling, must be written
                                               // before enabling PC sampling
    DWT->CTRL = (1 << DWT_CTRL_CYCTAP_Pos)     // Prescaler for PC sampling: 0 = x32, 1 = x512
              | (8 << DWT_CTRL_POSTPRESET_Pos) // PC sampling postscaler
              | (0 << DWT_CTRL_PCSAMPLENA_Pos) // disable PC sampling
              | (1 << DWT_CTRL_SYNCTAP_Pos)    // sync packets every 16M cycles
              | (0 << DWT_CTRL_EXCTRCENA_Pos)  // disable exception trace
              | (1 << DWT_CTRL_CYCCNTENA_Pos); // enable cycle counter

    // Configure DWT PC comparator 0:
    DWT->COMP0 = 0x000003E6;
    DWT->MASK0 = 0;
    DWT->FUNCTION0 = (0 << DWT_FUNCTION_DATAVMATCH_Pos) // address match
                   | (0 << DWT_FUNCTION_CYCMATCH_Pos)
                   | (0 << DWT_FUNCTION_EMITRANGE_Pos) 
                   | (8 << DWT_FUNCTION_FUNCTION_Pos); // Iaddr CMPMATCH event

    // Configure DWT PC comparator 1:
    DWT->COMP1 = 0x000003F4;
    DWT->MASK1 = 0;
    DWT->FUNCTION1 = (0 << DWT_FUNCTION_DATAVMATCH_Pos) // address match
                   | (0 << DWT_FUNCTION_CYCMATCH_Pos)
                   | (0 << DWT_FUNCTION_EMITRANGE_Pos) 
                   | (8 << DWT_FUNCTION_FUNCTION_Pos); // Iaddr CMPMATCH event


    // Configure ETM:
    ETM->LAR = 0xC5ACCE55;
    ETM_SetupMode();
    ETM->CR = ETM_CR_ETMEN; // Enable ETM output port
            // portmode appears to have no effect?
            //| ETM_CR_PORTMODE_1_1; //(0x00002000, 1:1)
            //| ETM_CR_PORTMODE_2_1; // 2:1
    ETM->TRACEIDR = 2; // Trace bus ID for TPIU
    ETM->FFLR = 0; // Stall processor when FIFO is full
    //ETM->TEEVR = 0x00000020;    // EmbeddedICE comparator 0
    //ETM->TEEVR = 0x00000021;    // EmbeddedICE comparator 1
    ETM->TEEVR = 0x000150a0;    // EmbeddedICE comparator 0 or 1
    ETM->TESSEICR = 0xf; // set EmbeddedICE watchpoint 0 as a TraceEnable start resource. 
    ETM->TECR1 = 0; // tracing is unaffected by the trace start/stop logic
    ETM_TraceMode();
}


// Print a given string to ITM with 8-bit writes.
void ITM_Print(int port, const char *p)
{
    if ((ITM->TCR & ITM_TCR_ITMENA_Msk) && (ITM->TER & (1UL << port)))
    {
        while (*p)
        {
            while (ITM->PORT[port].u32 == 0);
            ITM->PORT[port].u8 = *p++;
        }
        print("ITM alive!\n");
    }
    else {print("Couldn't print!\n");}
}


uint8_t test_itm(uint8_t* x)
{
        ITM_Print(0, "ITM alive!");
	return 0x00;
}


uint8_t get_mask (uint8_t* m)
{
   aes_indep_mask(m);
   return 0x00;
}

uint8_t get_key(uint8_t* k)
{
	aes_indep_key(k);
	return 0x00;
}

uint8_t get_pt(uint8_t* pt)
{
	trigger_high();
        aes_indep_enc(pt);
	trigger_low();
	simpleserial_put('r', 16, pt);
	return 0x00;
}

uint8_t reset(uint8_t* x)
{
	// Reset key here if needed
	return 0x00;
}

uint8_t info(uint8_t* x)
{
        print("DesignStart Cortex M3, compiled ");
        print(__DATE__);
        print(", ");
        print(__TIME__);
        print("\n");
	return 0x00;
}

uint8_t settessicr(uint8_t* x)
{
        uint32_t val;
        val = x[3] + (x[2] << 8) + (x[1] << 16) + (x[0] << 24);
        ETM->TESSEICR = val;
	return 0x00;
}

uint8_t setcomp0(uint8_t* x)
{
        uint32_t val;
        val = x[3] + (x[2] << 8) + (x[1] << 16) + (x[0] << 24);
        DWT->COMP0 = val;
	return 0x00;
}

uint8_t getcomp0(uint8_t* x)
{
        uint32_t val;
        val = DWT->COMP0;
        x[3] = val & 0xff;
        x[2] = (val >> 8) & 0xff;
        x[1] = (val >> 16) & 0xff;
        x[0] = (val >> 24) & 0xff;
	simpleserial_put('r', 4, x);
	return 0x00;
}

uint8_t getccer(uint8_t* x)
{
        uint32_t val;
        //val = ETM->CCER;
        val = ETM->IDR;
        x[3] = val & 0xff;
        x[2] = (val >> 8) & 0xff;
        x[1] = (val >> 16) & 0xff;
        x[0] = (val >> 24) & 0xff;
	simpleserial_put('r', 4, x);
	return 0x00;
}



uint8_t setteevr(uint8_t* x)
{
        uint32_t val;
        val = x[3] + (x[2] << 8) + (x[1] << 16) + (x[0] << 24);
        ETM->TEEVR = val;
	return 0x00;
}


int main(void)
{
        uint8_t tmp[KEY_LENGTH] = {DEFAULT_KEY};
	
	trigger_setup(); //defined to InitialiseGPIO
        init_uart();	 //defined to InitialiseUART
				
        aes_indep_init();
        aes_indep_key(tmp);

        /* Uncomment this to get a HELLO message for debug:
        info(tmp)
        */

	simpleserial_init();		
	simpleserial_addcmd('k', 16, get_key);
	simpleserial_addcmd('p', 16, get_pt);
	simpleserial_addcmd('x', 0, reset);
	simpleserial_addcmd('i', 0, info);
	simpleserial_addcmd('m', 18, get_mask);
	simpleserial_addcmd('t', 0, test_itm);
	simpleserial_addcmd('s', 4, setcomp0);
	simpleserial_addcmd('g', 4, getcomp0);
	simpleserial_addcmd('e', 4, setteevr);
	simpleserial_addcmd('G', 4, getccer);
	simpleserial_addcmd('T', 4, settessicr);

        enable_itm();

	while(1) {
          simpleserial_get();
	}
}


