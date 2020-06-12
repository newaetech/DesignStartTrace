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


#include "cw_gpio.h"
#include "xparameters.h"        // Project memory and device map
#include "xgpio.h"              // Xilinx GPIO routines

 
static XGpio Gpio_TrigOut;     /* The driver instance for GPIO Device 0 */

/*****************************************************************************/

// Initialise the GPIO, clear the trigger output:
int InitialiseGPIO( void )
{
    // Define local variables
    int status;

    status = XGpio_Initialize(&Gpio_TrigOut, XPAR_AXI_GPIO_0_DEVICE_ID);
    if (status != XST_SUCCESS)  {
        return XST_FAILURE;
    }

    XGpio_SetDataDirection(&Gpio_TrigOut, TRIG_CHANNEL, 0xFFFFFFFE);
    ClearTrig();
    return XST_SUCCESS;
}

void SetTrig ( void )
{
    XGpio_DiscreteWrite(&Gpio_TrigOut, TRIG_CHANNEL, 1);
    
}

void ClearTrig ( void )
{
    XGpio_DiscreteWrite(&Gpio_TrigOut, TRIG_CHANNEL, 0);
}

