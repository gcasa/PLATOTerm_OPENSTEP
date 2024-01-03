/**
 * PLATOTerm64 - A PLATO Terminal for the Commodore 64
 * Based on Steve Peltz's PAD
 * 
 * Author: Thomas Cherryhomes <thom.cherryhomes at gmail dot com>
 *
 * io.h - Input/output functions (serial/ethernet)
 */

#ifndef io_H
#define io_H

#include "protocol.h"

#define XON  0x11
#define XOFF 0x13

void io_inject(padByte *b, int l);

/**
 * void io_init() - Set-up the I/O
 */
void io_init(char *hostname, unsigned short port);

/**
 * void io_send_byte(b) - Send specified byte out
 */
void io_send_byte(unsigned char b);

/**
 * void io_main() - The IO main loop
 */
void io_main();

/**
 * Replay
 */
void io_replay();

/**
 * Clear replay buffer
 */
void io_replay_clear();

/**
 * void io_done() - Called to close I/O
 */
void io_done();

#endif /* void io_H */
