/*-----------------------------------------------------------------------------
 * Name:    Device.h
 * Purpose: Include the correct device header file
 *-----------------------------------------------------------------------------
 * This file is part of the uVision/ARM development tools.
 * This software may only be used under the terms of a valid, current,
 * end user licence from KEIL for a compatible version of KEIL software
 * development tools. Nothing else gives you the right to use this software.
 *
 * This software is supplied "AS IS" without warranties of any kind.
 *
 * Copyright (c) 2013 KEIL - An ARM Company. All rights reserved.
 *----------------------------------------------------------------------------*/

#ifndef __DEVICE_H
#define __DEVICE_H

#if defined ARTY_CM3
  #include "ARTY_CM3.h"                         /* device specific header file */
#else
  #warning "no appropriate header file found!"
#endif

#endif /* __DEVICE_H */
