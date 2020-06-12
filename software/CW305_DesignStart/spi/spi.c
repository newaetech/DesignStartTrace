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
 * File:     spi.c
 * Release Information : Cortex-M3 DesignStart-r0p1-00rel0
 * ----------------------------------------------------------------
 *
 */

/*
 * --------Included Headers--------
 */

#include <stdio.h>

#include "m3_for_arty.h"        // Project specific header


#include "xparameters.h"
#include "xspi.h"

/************************** Variable Definitions **************************/
/*
 * The following are declared static to this module so they are zeroed and so they are
 * easily accessible from a debugger
 *
 * Also they are initialised in main, but accessed by the IRQ routines
 */
 
static XSpi QSPI_base;      /* The driver instance for the QSPI on the base board */
//static XSpi QSPI_XIP_dap;   /* The driver instance for the QSPI XIP on the DAPLink board */
//static XSpi QSPI_dap;       /* The driver instance for the normal QSPI on the DAPLink board */
//static XSpi SPI_dap;        /* The driver instance for the SPI on the DAPLink board */

// Local buffers relating to each QSPI instance
// The buffers are set to be the size of the FIFO in hardware
static u8 QSPI_base_tx_buf[XPAR_AXI_QUAD_SPI_0_FIFO_DEPTH];
static u8 QSPI_base_rx_buf[XPAR_AXI_QUAD_SPI_0_FIFO_DEPTH];


/*****************************************************************************/

// Initialise the SPI peripherals
int InitialiseSPI( int DapLinkFittedn )
{
    // Define local variables
    int status;

    // Initialise the QSPI on the base board
    status = XSpi_Initialize(&QSPI_base, XPAR_AXI_QUAD_SPI_0_DEVICE_ID);
    if (status != XST_SUCCESS)  {
        return XST_FAILURE;
    }

    XSpi_Reset(&QSPI_base);
    
    // Start is needed to enable all the registers
    // However it turns on global interrupts, so as are running in polled mode
    // we need to turn these off afterwards
    XSpi_Start(&QSPI_base);
    XSpi_IntrGlobalDisable(&QSPI_base);
    
    // Device has a single slave in lane 0
    XSpi_SetSlaveSelect(&QSPI_base, 0x1);

    // If DAP link fitted, then initialise the other SPI peripherals here
    
    return XST_SUCCESS;
    
}

// Set SPI interrupts
void DisableSPIInterrupts( void )
{
    // Disable interrupts from the base QSPI
    XSpi_IntrGlobalDisable(&QSPI_base);

}

int InitQSPIBaseFlash( void )
{
    int status;
    u32 ControlReg;
//    u32 loop;
    
    // REVISIT - just for debug
    // char8 str[64];

    /*
    * Setup the control register to enable master mode
    */
    ControlReg = XSpi_GetControlReg(&QSPI_base);
    XSpi_SetControlReg(&QSPI_base, ControlReg | XSP_CR_MASTER_MODE_MASK);

    // Set SR
    /* Commands for Spansion device on DAPLink board
    QSPI_base_tx_buf[0] = 0x01;
    QSPI_base_tx_buf[1] = 0x00;
    QSPI_base_tx_buf[2] = 0x42;
    */

    /*
    // Need to set the QUAD bit on the QSPI base device
    // Set WEL
    QSPI_base_tx_buf[0] = 0x06;
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 1);

    // For Micron on base board, need to write to non-volatile config reg
    QSPI_base_tx_buf[0] = 0xB1;
    QSPI_base_tx_buf[1] = 0xF7;     // set QUAD bit active
    QSPI_base_tx_buf[2] = 0xFF;
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 3);

    // Wait for command to complete on flash
    // REVISIT - could do by polling status bit possibly
    for (loop = 0; loop < 50000; loop++)
    {}
    */
    
    /*
    // Set WEL
    QSPI_base_tx_buf[0] = 0x06;
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 1);

    // For Micron on base board, also write to enhanced non-volatile config reg
    // This puts device into quad mode; but peripheral is still writing in single mode
    QSPI_base_tx_buf[0] = 0x61;
    QSPI_base_tx_buf[1] = 0x7F;     // set QUAD bit active
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 2);
    */
    
    /*
    // Wait for command to complete on flash
    // REVISIT - could do by polling status bit possibly
    for (loop = 0; loop < 1000; loop++)
    {}
    */
    
    // Set WEL
    QSPI_base_tx_buf[0] = 0x06;
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 1);

    // Read status reg
    QSPI_base_tx_buf[0] = 0x05;
    QSPI_base_tx_buf[1] = 0xFF;
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, QSPI_base_rx_buf, 2);

    /* Revisit
    // Looks like buffer is not populated, so reading it causes M1 to hang, (unknown signals in sim)
    sprintf( str, "s1 = %i\r\n", status );
    //sprintf( str, "sr = %u %u\r\n", QSPI_base_rx_buf[0], QSPI_base_rx_buf[1] );
    print( str );
    */
    
    return status;
}

int WriteQSPIBaseFlash( u8 *pbytes, int length, u32 addr )
{
    int status;
    u32 ControlReg;
    u32 loop;
    
    // REVISIT - just for debug
    // char8 str[64];

    /*
    * Setup the control register to enable master mode
    */
    ControlReg = XSpi_GetControlReg(&QSPI_base);
    XSpi_SetControlReg(&QSPI_base, ControlReg | XSP_CR_MASTER_MODE_MASK);

    // Can only read a block the size of the buffer, minus the command length (4)
    if ((length == 0) || (length > (XPAR_AXI_QUAD_SPI_0_FIFO_DEPTH-4)))
        return XST_FAILURE;
    
    // Set WEL
    QSPI_base_tx_buf[0] = 0x06;
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 1);
    
    /*
    // For Micron on base board, write to enhanced non-volatile config reg
    QSPI_base_tx_buf[0] = 0x61;
    QSPI_base_tx_buf[1] = 0x7F;     // set QUAD bit active
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 2);

    // Wait for command to complete
    for (loop = 0; loop < 1000; loop++)
    {}
    */
    
    // Populate TX buffer 
//    QSPI_base_tx_buf[0] = 0x32;     // Micron Quad fast Page programme
    QSPI_base_tx_buf[0] = 0x02;     // Micron single page programme
    // 24 bit address
    QSPI_base_tx_buf[1] = ((addr >> 16) & 0xFF);
    QSPI_base_tx_buf[2] = ((addr >>  8) & 0xFF);
    QSPI_base_tx_buf[3] = ((addr >>  0) & 0xFF);
    // Fill buffer with data
    for (loop = 0; loop < length; loop++)
        QSPI_base_tx_buf[4 + loop] = *pbytes++;
    // Write to flash
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, (length+4));

    // Debug
    /*
    sprintf( str, "s1 = %i\r\n", status );
    print( str );
    */
    
    // Wait for command to complete
    for (loop = 0; loop < 20000; loop++)
    {}

    return status;
}

int ReadQSPIBaseFlash( u8 *pbytes, int length, u32 addr )
{
    int status;
    u32 ControlReg;
    u32 loop;
    
    // REVISIT - just for debug
    // char8 str[64];

    /*
    * Setup the control register to enable master mode
    */
    ControlReg = XSpi_GetControlReg(&QSPI_base);
    XSpi_SetControlReg(&QSPI_base, ControlReg | XSP_CR_MASTER_MODE_MASK);

    // Can only read a block the size of the buffer, minus the command length (4)
    if ((length == 0) || (length > (XPAR_AXI_QUAD_SPI_0_FIFO_DEPTH-4)))
        return XST_FAILURE;
    
    // Set WEL
    /*
    QSPI_base_tx_buf[0] = 0x06;
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 1);
    */
    
    /*
    // For Micron on base board, write to enhanced non-volatile config reg
    QSPI_base_tx_buf[0] = 0x61;
    QSPI_base_tx_buf[1] = 0x7F;     // set QUAD bit active
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, NULL, 2);

    // Wait for command to complete
    for (loop = 0; loop < 1000; loop++)
    {}
    */
    
    // Populate TX buffer 
//    QSPI_base_tx_buf[0] = 0x6B;     // Micron Quad output fast read
    QSPI_base_tx_buf[0] = 0x03;     // Micron read
    // 24 bit address
    QSPI_base_tx_buf[1] = ((addr >> 16) & 0xFF);
    QSPI_base_tx_buf[2] = ((addr >>  8) & 0xFF);
    QSPI_base_tx_buf[3] = ((addr >>  0) & 0xFF);
    // Fill buffer with 0x0, needed to generate clock cycles
    for (loop = 0; loop < length; loop++)
        QSPI_base_tx_buf[4 + loop] = 0x0;
    // Write to flash
    status = XSpi_Transfer(&QSPI_base, QSPI_base_tx_buf, QSPI_base_rx_buf, (length+4));
    
    // Copy local buffer to calling buffer (inefficient, could replace)
    // Data is placed after the command
    for (loop = 0; loop < length; loop++)
        *pbytes++ = QSPI_base_rx_buf[loop+4];

    // Debug
    /*
    sprintf( str, "s1 = %i\r\n", status );
    print( str );
    */
    
    return status;
}

/* Write some data to the SPI.  Sequence taken from selftest example */
int WriteSPIData( u8 * pbyte, int length )
{
    u32 Data;
    u8  DataWidth;
    u32 Index;
    int incr;
    u32 StatusReg;
    u32 ControlReg;
    int NumSent = 0;
    char8 str[64];
    

    DataWidth = QSPI_base.DataWidth;
    incr = DataWidth/8;

    sprintf(str, "len %i, Wid %i, incr %i\r\n", length, DataWidth, incr );
    print( (const char8 *)str );
    /*
    * Setup the control register to enable master mode
    */
    ControlReg = XSpi_GetControlReg(&QSPI_base);
    XSpi_SetControlReg(&QSPI_base, ControlReg | XSP_CR_MASTER_MODE_MASK);
                
    /*
     * Loop across data, filling the send FIFO
     * Stop writing once FIFO is full
     */
    for (Index = 0; Index < length; Index += incr) {

        /*
         * Fill the transmit register.
         */
        StatusReg = XSpi_GetStatusReg(&QSPI_base);
        if ((StatusReg & XSP_SR_TX_FULL_MASK) == 0) {
            Data = *pbyte;

            // Increment pointer the correct amount
            pbyte += incr;
            
            XSpi_WriteReg(QSPI_base.BaseAddr, XSP_DTR_OFFSET, Data);
            NumSent += incr;
        }
    }

// Do we need to set slave to 0x0?
//    #define XSP_SSR_OFFSET		0x70	/**< 32-bit slave select */
    XSpi_SetSlaveSelectReg(&QSPI_base, 0x00000000);

    
    /*
     * Start the transfer by not inhibiting the transmitter and
     * enabling the device.
     */
    ControlReg = XSpi_GetControlReg(&QSPI_base) &
                     (~XSP_CR_TRANS_INHIBIT_MASK);
    XSpi_SetControlReg(&QSPI_base, ControlReg |
                XSP_CR_ENABLE_MASK);

    /*
     * Wait for the transfer to be done by polling the transmit
     * empty status bit.
     */
    do {
        StatusReg = XSpi_IntrGetStatus(&QSPI_base);
    } while ((StatusReg & XSP_INTR_TX_EMPTY_MASK) == 0);

    XSpi_IntrClear(&QSPI_base, XSP_INTR_TX_EMPTY_MASK);
    

    return NumSent;
}

// Define the SPI interrupt handlers
void QSPI0_Handler ( void )
{

    // Clear interrupt from SPI
//    XSpi_InterruptClear(&QSPI_base, XSPI_IR_MASK);
    // Clear interrupt in NVIC
    NVIC_ClearPendingIRQ(QSPI0_IRQn);
}

// Define the SPI interrupt handlers
void DAP_QSPI0_Handler ( void )
{

    // Clear interrupt from SPI
//    XSpi_InterruptClear(&QSPI_base, XSPI_IR_MASK);
    // Clear interrupt in NVIC
    NVIC_ClearPendingIRQ(DAP_QSPI0_IRQn);
}
// Define the SPI interrupt handlers
void DAP_SPI0_Handler ( void )
{

    // Clear interrupt from SPI
//    XSpi_InterruptClear(&QSPI_base, XSPI_IR_MASK);
    // Clear interrupt in NVIC
    NVIC_ClearPendingIRQ(DAP_SPI0_IRQn);
}
// Define the SPI interrupt handlers
void DAP_QSPI_XIP_Handler ( void )
{

    // Clear interrupt from SPI
//    XSpi_InterruptClear(&QSPI_base, XSPI_IR_MASK);
    // Clear interrupt in NVIC
    NVIC_ClearPendingIRQ(DAP_QSPI_XIP_IRQn);
}
