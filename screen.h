/**
 * PLATOTerm64 - A PLATO Terminal for the Commodore 64
 * Based on Steve Peltz's PAD
 * 
 * Author: Thomas Cherryhomes <thom.cherryhomes at gmail dot com>
 *
 * screen.h - Display output functions
 */

#ifndef SCREEN_H
#define SCREEN_H

#include "protocol.h"

short max(short a, short b);

short min(short a, short b);

/**
 * screen_init() - Set up the screen
 */
void screen_init(char *hostname, unsigned port);

/**
 * screen_main() - render/preserve screen
 */
void screen_main();

/*
void screen_handle_client_message(display, e)
Display display;
XEvent *e;
{
	if ((Atom)e->xclient.data.l[0]==wmdeleteMessage)
	{
		done = TRUE;
	}
}*/

/**
 * screen_wait() - Sleep for approx 16.67ms
 */
void screen_wait();

/**
 * screen_beep() - Beep the terminal
 */
void screen_beep();

/**
 * screen_clear - Clear the screen
 */
void screen_clear();

/**
 * screen_set_pen_mode() - Set pen mode
 */
void screen_set_pen_mode();

/**
 * screen_block_draw(Coord1, Coord2) - Perform a block fill from Coord1 to Coord2
 */
void screen_block_draw(padPt *Coord1, padPt *Coord2);

/**
 * screen_dot_draw(Coord) - Plot a mode 0 pixel
 */
void screen_dot_draw(padPt *Coord);

/**
 * screen_line_draw(Coord1, Coord2) - Draw a mode 1 line
 */
void screen_line_draw(padPt *Coord1, padPt *Coord2);

/**
 * screen_char_draw(Coord, ch, count) - Output buffer from ch* of length count as PLATO characters
 */
void screen_char_draw(padPt *Coord, unsigned char *ch, unsigned char count);

/**
 * screen_tty_char - Called to plot chars when in tty mode
 */
void screen_tty_char(padByte theChar);

/**
 * Clear colors in colormap we've allocated
 */
void screen_clear_colors();

/**
 * Return if color matches
 */
unsigned long screen_color_match(padRGB *platocolor);

/**
 * screen_foreground - Called to set foreground color.
 */
void screen_foreground(padRGB *theColor);

/**
 * screen_background - Called to set foreground color.
 */
void screen_background(padRGB *theColor);

void screen_paint(padPt *Coord);

/**
 * screen_done()
 */
void screen_done();


#endif /* SCREEN_H */
