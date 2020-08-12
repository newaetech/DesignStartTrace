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

#include "uECC.c"       // yes this is weird but a bunch of needed defines are there
#include "uECC_vli.h"

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

// Use globals for pmul input (P) and output (Q) points because
// they're too big to transmit all in one simpleserial transfer:
uECC_word_t P[uECC_MAX_WORDS * 2];
uECC_word_t Q[uECC_MAX_WORDS * 2];


uint8_t setreg(uint8_t* x)
{
        uint32_t val;
        val = x[4] + (x[3] << 8) + (x[2] << 16) + (x[1] << 24);
//0:  DWT->CTRL
//1:  DWT->COMP0
//2:  DWT->COMP1
//3:  ETM->CR
//4:  ETM->TESSEICR
//5:  ETM->TEEVR
//6:  ETM->TECR1
//7:  TPI->ACPR
//8:  TPI->SPPR
//9:  TPI->FFCR
//10: TPI->CSPSR
//11: ITM->TCR
        if       (x[0] == 0)    {DWT->CTRL = val;}
        else if  (x[0] == 1)    {DWT->COMP0 = val;}
        else if  (x[0] == 2)    {DWT->COMP1 = val;}
        else if  (x[0] == 3)    {ETM_SetupMode(); ETM->CR = val; ETM_TraceMode();}
        else if  (x[0] == 4)    {ETM_SetupMode(); ETM->TESSEICR = val; ETM_TraceMode();}
        else if  (x[0] == 5)    {ETM_SetupMode(); ETM->TEEVR   = val; ETM_TraceMode();}
        else if  (x[0] == 6)    {ETM_SetupMode(); ETM->TECR1   = val; ETM_TraceMode();}
        else if  (x[0] == 7)    {TPI->ACPR    = val;}
        else if  (x[0] == 8)    {TPI->SPPR    = val;}
        else if  (x[0] == 9)    {TPI->FFCR    = val;}
        else if  (x[0] == 10)   {TPI->CSPSR   = val;}
        else if  (x[0] == 11)   {ITM->TCR     = val;}

	return 0x00;
}


uint8_t getreg(uint8_t* x)
{
        uint32_t val;
        if       (x[0] == 0)    {val = DWT->CTRL;}
        else if  (x[0] == 1)    {val = DWT->COMP0;}
        else if  (x[0] == 2)    {val = DWT->COMP1 ;}
        else if  (x[0] == 3)    {val = ETM->CR;}
        else if  (x[0] == 4)    {val = ETM->TESSEICR;}
        else if  (x[0] == 5)    {val = ETM->TEEVR;}
        else if  (x[0] == 6)    {val = ETM->TECR1;}
        else if  (x[0] == 7)    {val = TPI->ACPR;}
        else if  (x[0] == 8)    {val = TPI->SPPR;}
        else if  (x[0] == 9)    {val = TPI->FFCR;}
        else if  (x[0] == 10)   {val = TPI->CSPSR;}
        else if  (x[0] == 11)   {val = ITM->TCR;}

        x[3] = val & 0xff;
        x[2] = (val >> 8) & 0xff;
        x[1] = (val >> 16) & 0xff;
        x[0] = (val >> 24) & 0xff;
	simpleserial_put('r', 4, x);
	return 0x00;
}

void enable_trace()
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

void uECC_point_mult(uECC_word_t *result,
                     const uECC_word_t *point,
                     const uECC_word_t *scalar,
                     uECC_Curve curve) {
    uECC_word_t tmp1[uECC_MAX_WORDS];
    uECC_word_t tmp2[uECC_MAX_WORDS];
    uECC_word_t *p2[2] = {tmp1, tmp2};
    uECC_word_t carry = regularize_k(scalar, tmp1, tmp2, curve);

    EccPoint_mult(result, point, p2[!carry], 0, curve->num_n_bits + 1, curve);
}


uint8_t run_pmul_fixed(uint8_t* k)
{
    const struct uECC_Curve_t * curve;
    //uECC_word_t kwords[uECC_MAX_WORDS] = {k[0],0,0,0,0,0,0,0}; // TODO
    uECC_word_t kwords[uECC_MAX_WORDS];
    curve = uECC_secp256r1();

    int i, j;
    for (i = 0; i < 8; i++) {
       kwords[7-i] = 0;
       for (j = 0; j < 4; j++) {
          kwords[7-i] |= k[i*4+j] << ((3-j)*8);
       }
    }

    trigger_high();
    uECC_point_mult(Q, curve->G, kwords, curve);
    trigger_low();
    // we don't return the result because it's too long, but let's return
    // something to indicate that the command ran:
    simpleserial_put('r', 1, k);
    return 0x00;
}



// return x coordinate of pmul result:
uint8_t get_qx(uint8_t* x)
{
    int i, j;
    for (i = 0; i < 8; i++) {
       for (j = 0; j < 4; j++) {
          x[i*4+j] = (int)((Q[i] >> (3-j)*8) & 255);
       }
    }
    simpleserial_put('r', 32, x);
    return 0x00;
}


// return y coordinate of pmul result:
uint8_t get_qy(uint8_t* y)
{
    int i, j;
    for (i = 0; i < 8; i++) {
       for (j = 0; j < 4; j++) {
          y[i*4+j] = (int)((Q[i+8] >> (3-j)*8) & 255);
       }
    }
    simpleserial_put('r', 32, y);
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
	simpleserial_addcmd('s', 5, setreg);
	simpleserial_addcmd('g', 5, getreg);
        simpleserial_addcmd('f', 32, run_pmul_fixed);
        simpleserial_addcmd('q', 32, get_qx);
        simpleserial_addcmd('r', 32, get_qy);

        enable_trace();

	while(1) {
          simpleserial_get();
	}
}


