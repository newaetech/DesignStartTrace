; Copyright:
; ----------------------------------------------------------------
; This confidential and proprietary software may be used only as
; authorised by a licensing agreement from ARM Limited
;   (C) COPYRIGHT 2019 ARM Limited
;       ALL RIGHTS RESERVED
; The entire notice above must be reproduced on all authorised
; copies and copies may only be made to the extent permitted
; by a licensing agreement from ARM Limited.
; ----------------------------------------------------------------
; File:     atomic.c
; Release Information : Cortex-M3 DesignStart-r0p0-00rel0
; ----------------------------------------------------------------

 EXPORT atomic_test
 AREA    |.text|, CODE, READONLY

; uint32_t atomic_test(uint32_t *mem, uint32_t val) 
; Atomic load/store, discarding the read value
atomic_test
  mov r2, r0;
  ldrex r3,[r2];
  strex r0,r1,[r2];
  bx lr;
  END
	