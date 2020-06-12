;/**************************************************************************//**
; * @file     startup_CM3DS_MPS2.s
; * @brief    CMSIS Cortex-M3 Core Device Startup File for
; *           Device CM3DS_MPS2
; * @version  V3.01
; * @date     06. March 2012
; *
; * @note
; * Copyright (C) 2012,2017 ARM Limited. All rights reserved.
; *
; * @par
; * ARM Limited (ARM) is supplying this software for use with Cortex-M
; * processor based microcontrollers.  This file can be freely distributed
; * within development tools that are supporting such ARM based processors.
; *
; * @par
; * THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
; * OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
; * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
; * ARM SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL, OR
; * CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
; *
; ******************************************************************************/
;/*
;//-------- <<< Use Configuration Wizard in Context Menu >>> ------------------
;*/


; <h> Stack Configuration
;   <o> Stack Size (in Bytes) <0x0-0xFFFFFFFF:8>
; </h>

Stack_Size      EQU     0x00000400

                AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem       SPACE   Stack_Size
__initial_sp


; <h> Heap Configuration
;   <o>  Heap Size (in Bytes) <0x0-0xFFFFFFFF:8>
; </h>

Heap_Size       EQU     0x00000C00

                AREA    HEAP, NOINIT, READWRITE, ALIGN=3
__heap_base
Heap_Mem        SPACE   Heap_Size
__heap_limit


                PRESERVE8
                THUMB


; Vector Table Mapped to Address 0 at Reset

                AREA    RESET, DATA, READONLY
                EXPORT  __Vectors
                EXPORT  __Vectors_End
                EXPORT  __Vectors_Size

__Vectors       DCD     __initial_sp              ; Top of Stack
                DCD     Reset_Handler             ; Reset Handler
                DCD     NMI_Handler               ; NMI Handler
                DCD     HardFault_Handler         ; Hard Fault Handler
                DCD     MemManage_Handler         ; MPU Fault Handler
                DCD     BusFault_Handler          ; Bus Fault Handler
                DCD     UsageFault_Handler        ; Usage Fault Handler
                DCD     0x55                      ; Reserved (used for alias testing)
                DCD     0                         ; Reserved
                DCD     0                         ; Reserved
                DCD     0                         ; Reserved
                DCD     SVC_Handler               ; SVCall Handler
                DCD     DebugMon_Handler          ; Debug Monitor Handler
                DCD     0                         ; Reserved
                DCD     PendSV_Handler            ; PendSV Handler
                DCD     SysTick_Handler           ; SysTick Handler

                ; External Interrupts
                DCD     UART0_Handler             ; UART 0 Handler
                DCD     GPIO0_Handler             ; GPIO 0 Handler
                DCD     GPIO1_Handler             ; GPIO 1 Handler
                DCD     QSPI0_Handler             ; QUAD SPI 0 (Arty board) Handler
                DCD     DAP_QSPI0_Handler         ; DAPLink board QUAD SPI 0 Handler
                DCD     DAP_SPI0_Handler          ; DAPLink board SPI 0 Handler
                DCD     DAP_QSPI_XIP_Handler      ; DAPLink board QUAD SPI XIP Handler
                DCD     DAPLinkFittedn            ; Used as steady state GPIO input, not IRQ
                DCD     Unused_IRQ8               ; Unused
                DCD     Unused_IRQ9               ; Unused
                DCD     Unused_IRQ10              ; Unused
                DCD     Unused_IRQ11              ; Unused
                DCD     Unused_IRQ12              ; Unused
                DCD     Unused_IRQ13              ; Unused
                DCD     Unused_IRQ14              ; Unused
                DCD     Unused_IRQ15              ; Unused
                DCD     Unused_IRQ16              ; Unused
                DCD     Unused_IRQ17              ; Unused
                DCD     Unused_IRQ18              ; Unused
                DCD     Unused_IRQ19              ; Unused
                DCD     Unused_IRQ20              ; Unused
                DCD     Unused_IRQ21              ; Unused
                DCD     Unused_IRQ22              ; Unused
                DCD     Unused_IRQ23              ; Unused
                DCD     Unused_IRQ24              ; Unused
                DCD     Unused_IRQ25              ; Unused
                DCD     Unused_IRQ26              ; Unused
                DCD     Unused_IRQ27              ; Unused
                DCD     Unused_IRQ28              ; Unused
                DCD     Unused_IRQ29              ; Unused
                DCD     Unused_IRQ30              ; Unused
                DCD     Unused_IRQ31              ; Unused
__Vectors_End

__Vectors_Size  EQU     __Vectors_End - __Vectors

                AREA    |.text|, CODE, READONLY


; Reset Handler

Reset_Handler   PROC
                EXPORT  Reset_Handler             [WEAK]
                IMPORT  SystemInit
                IMPORT  __main
                LDR     R0, =SystemInit
                BLX     R0
                LDR     R0, =__main
                BX      R0
                ENDP


; Dummy Exception Handlers (infinite loops which can be modified)

NMI_Handler     PROC
                EXPORT  NMI_Handler               [WEAK]
                B       .
                ENDP
HardFault_Handler\
                PROC
                EXPORT  HardFault_Handler         [WEAK]
                B       .
                ENDP
MemManage_Handler\
                PROC
                EXPORT  MemManage_Handler         [WEAK]
                B       .
                ENDP
BusFault_Handler\
                PROC
                EXPORT  BusFault_Handler          [WEAK]
                B       .
                ENDP
UsageFault_Handler\
                PROC
                EXPORT  UsageFault_Handler        [WEAK]
                B       .
                ENDP
SVC_Handler     PROC
                EXPORT  SVC_Handler               [WEAK]
                B       .
                ENDP
DebugMon_Handler\
                PROC
                EXPORT  DebugMon_Handler          [WEAK]
                B       .
                ENDP
PendSV_Handler\
                PROC
                EXPORT  PendSV_Handler            [WEAK]
                B       .
                ENDP
SysTick_Handler\
                PROC
                EXPORT  SysTick_Handler           [WEAK]
                B       .
                ENDP

Default_Handler PROC
                EXPORT UART0_Handler              [WEAK]
                EXPORT GPIO0_Handler              [WEAK]
                EXPORT GPIO1_Handler              [WEAK]
                EXPORT QSPI0_Handler              [WEAK]
                EXPORT DAP_QSPI0_Handler          [WEAK]
                EXPORT DAP_SPI0_Handler           [WEAK]
                EXPORT DAP_QSPI_XIP_Handler       [WEAK]
                EXPORT DAPLinkFittedn             [WEAK]
                EXPORT Unused_IRQ8                [WEAK]
                EXPORT Unused_IRQ9                [WEAK]
                EXPORT Unused_IRQ10               [WEAK]
                EXPORT Unused_IRQ11               [WEAK]
                EXPORT Unused_IRQ12               [WEAK]
                EXPORT Unused_IRQ13               [WEAK]
                EXPORT Unused_IRQ14               [WEAK]
                EXPORT Unused_IRQ15               [WEAK]
                EXPORT Unused_IRQ16               [WEAK]
                EXPORT Unused_IRQ17               [WEAK]
                EXPORT Unused_IRQ18               [WEAK]
                EXPORT Unused_IRQ19               [WEAK]
                EXPORT Unused_IRQ20               [WEAK]
                EXPORT Unused_IRQ21               [WEAK]
                EXPORT Unused_IRQ22               [WEAK]
                EXPORT Unused_IRQ23               [WEAK]
                EXPORT Unused_IRQ24               [WEAK]
                EXPORT Unused_IRQ25               [WEAK]
                EXPORT Unused_IRQ26               [WEAK]
                EXPORT Unused_IRQ27               [WEAK]
                EXPORT Unused_IRQ28               [WEAK]
                EXPORT Unused_IRQ29               [WEAK]
                EXPORT Unused_IRQ30               [WEAK]
                EXPORT Unused_IRQ31               [WEAK]

UART0_Handler
GPIO0_Handler
GPIO1_Handler
QSPI0_Handler 
DAP_QSPI0_Handler 
DAP_SPI0_Handler  
DAP_QSPI_XIP_Handler 
DAPLinkFittedn   
Unused_IRQ8   
Unused_IRQ9   
Unused_IRQ10  
Unused_IRQ11  
Unused_IRQ12  
Unused_IRQ13  
Unused_IRQ14  
Unused_IRQ15  
Unused_IRQ16  
Unused_IRQ17  
Unused_IRQ18  
Unused_IRQ19  
Unused_IRQ20  
Unused_IRQ21  
Unused_IRQ22  
Unused_IRQ23  
Unused_IRQ24  
Unused_IRQ25  
Unused_IRQ26  
Unused_IRQ27  
Unused_IRQ28  
Unused_IRQ29  
Unused_IRQ30  
Unused_IRQ31  
                B       .

                ENDP


                ALIGN


; User Initial Stack & Heap

                IF      :DEF:__MICROLIB

                EXPORT  __initial_sp
                EXPORT  __heap_base
                EXPORT  __heap_limit

                ELSE

                IMPORT  __use_two_region_memory
                EXPORT  __user_initial_stackheap

__user_initial_stackheap PROC
                LDR     R0, =  Heap_Mem
                LDR     R1, =(Stack_Mem + Stack_Size)
                LDR     R2, = (Heap_Mem +  Heap_Size)
                LDR     R3, = Stack_Mem
                BX      LR
                ENDP

                ALIGN

                ENDIF


                END
