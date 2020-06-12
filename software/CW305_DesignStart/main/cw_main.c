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


// simpleserial and AES:
#include "simpleserial.h"
#include "hal.h"
#include "aes-independant.h"


// uartlite example:
#include "xstatus.h"
#include "xuartlite.h"


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
	while(1) {
          simpleserial_get();
	}
}


