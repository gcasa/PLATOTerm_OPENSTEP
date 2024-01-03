/**
 * PLATOTerm - A PLATO Terminal
 * Based on Steve Peltz's PAD
 * 
 * Author: Thomas Cherryhomes <thom.cherryhomes at gmail dot com>
 * Ported To OPENSTEP: Gregory Casamento <greg.casamento at gmail dot com>
 *
 * screen.c - Display output functions
 */
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "PLATOView.h"

#include <unistd.h>
#include "splash.h"
#include "screen.h"
#include "protocol.h"
#include "font.h"

unsigned char CharHigh=16;
unsigned char CharWide=8;
padPt TTYLoc;

extern int done;

unsigned char fontm23[2048];
padRGB backgroundColor={0,0,0};
padRGB foregroundColor={255,255,255};
padRGB black = {
    0,0,0
};
padRGB white = {
    255,255,255
};
unsigned long backgroundPixel, foregroundPixel;
NSString *win_title;
NSWindow *win;
PLATOView *content;
NSColor *fgColor = nil;
NSColor *bgColor = nil;

extern padBool FastText;
int screen;
int usedColors=0;
unsigned char control_pressed, shift_pressed;
padRGB backgroundColor,foregroundColor;
int ctr;

short max(a,b)
short a,b;
{
  return ( a > b ) ? a : b;
}

short min(a,b)
short a,b;
{
  return ( a < b ) ? a : b;
}

NSColor *padRGBToNSColor(padRGB p)
{
    float r = (float)p.red / 255.0;
    float g = (float)p.green / 255.0;
    float b = (float)p.blue / 255.0;
    float a = 1.0;
    return [NSColor colorWithCalibratedRed: r green: g blue: b alpha: a];
}

padRGB NSColorToPadRGB(NSColor *c)
{
    int r = [c redComponent] * 255;
    int g = [c greenComponent] * 255;
    int b = [c blueComponent] * 255;
    padRGB p;
    p.red = r;
    p.green = g;
    p.blue = b;

    return p;
}

/**
 * screen_init() - Set up the screen
 */
void screen_init(char *hostname, unsigned port) // hostname, port)
{
    NSRect frame = NSMakeRect(0,0,512,512);

    win_title = [NSString stringWithFormat: @"PLATOterm: %s:%u", hostname, port];    
    win = [[NSWindow alloc] initWithContentRect: frame   // XCreateSimpleWindow(display,DefaultRootWindow(display),0,0,512,512,5,white,black);
 	 			styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
				backing: NSBackingStoreBuffered
				defer: NO];

    content = [[PLATOView alloc] initWithFrame: frame platoScreen: screen];

    backgroundColor.red=backgroundColor.green=backgroundColor.blue=0;
    foregroundColor.red=foregroundColor.green=foregroundColor.blue=255;

    [content setBackgroundColor: padRGBToNSColor(backgroundColor)];
    [content setForegroundColor: padRGBToNSColor(foregroundColor)];

    [win setContentView: content];
    [content clear];

    [win setTitle: win_title];
    [win orderFrontRegardless];
    [win center];
}

/**
 * screen_main() - render/preserve screen
 */
void screen_main()
{
/*
	if (!XPending(display))
		return;

	XNextEvent(display,&event);
	if (event.type == KeyPress)
	{
		ks = XLookupKeysym(&event.xkey, event.xkey.state & ShiftMask ? 1 : 0);
        	control_pressed = (event.xkey.state & ControlMask ? TRUE : FALSE);
        	shift_pressed =   (event.xkey.state & ShiftMask   ? TRUE : FALSE);
		keyboard_main(ks,control_pressed,shift_pressed);	
        }
	else if (event.type == ButtonPress && event.xbutton.state)
	{
		touch_main(event.xbutton.x,event.xbutton.y);
	}
	else if (event.type == ClientMessage)
	{
		screen_handle_client_message(display, &event);
	}
	else if (event.type == Expose)
	{
		io_replay();
	} */
}

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
void screen_wait()
{
}

/**
 * screen_beep() - Beep the terminal
 */
void screen_beep()
{
  NSBeep();
}

/**
 * screen_clear - Clear the screen
 */
void screen_clear()
{
	io_replay_clear();
	screen_clear_colors();
	screen_background(&backgroundColor);
	screen_foreground(&foregroundColor);
    [content clear];
	//XSetWindowBackground(display,win,backgroundPixel);
	//XClearWindow(display,win);	
	//XSetForeground(display,gc,backgroundPixel);	
	//XFillRectangle(display,win,gc,0,0,512,512);
	//XSetForeground(display,gc,foregroundPixel);
	//XSetBackground(display,gc,backgroundPixel);
}

/**
 * screen_set_pen_mode() - Set pen mode
 */
void screen_set_pen_mode()
{
    if (CurMode == ModeErase || CurMode == ModeInverse)
    {
        NSColor *f = fgColor;
        NSColor *b = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0];
            [content setBackgroundColor: f];
            [content setForegroundColor: b];
            //XSetBackground(display,gc,foregroundPixel);
            //XSetForeground(display,gc,backgroundPixel);
    }
    else
    {
        NSColor *f = fgColor;
        NSColor *b = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 1.0];
        [content setBackgroundColor: b];
        [content setForegroundColor: f];
            //XSetBackground(display,gc,backgroundPixel);
            //XSetForeground(display,gc,foregroundPixel);
    }
}

/**
 * screen_block_draw(Coord1, Coord2) - Perform a block fill from Coord1 to Coord2
 */
void screen_block_draw(Coord1, Coord2)
padPt *Coord1;
padPt *Coord2;
{
	short x1,y1,x2,y2;

	x1=min(Coord1->x,Coord2->x);
	x2=max(Coord1->x,Coord2->x);
	y1=min(Coord1->y^0x1FF,Coord2->y^0x1FF);
	y2=max(Coord1->y^0x1FF,Coord2->y^0x1FF);
	screen_set_pen_mode();
	// XFillRectangle(display, win, gc, x1, y1, x2-x1, y2-y1);
    [content drawBlockX1: x1 Y1:y1 X2:x2-x1 Y2:y2-y1];
}

void screen_dot_draw_xy(short x, short y)
{
    [content drawDotX: x Y: y];
}

/**
 * screen_dot_draw(Coord) - Plot a mode 0 pixel
 */
void screen_dot_draw(Coord)
padPt* Coord;
{
	screen_set_pen_mode();
	//XDrawPoint(display, win, gc, Coord->x, Coord->y^0x1FF);
    [content drawDotX: Coord->x Y: Coord->y^0x1FF];
}

/**
 * screen_line_draw(Coord1, Coord2) - Draw a mode 1 line
 */
void screen_line_draw(Coord1, Coord2)
padPt* Coord1;
padPt* Coord2;
{
	screen_set_pen_mode();
	//  XDrawLine(display, win, gc, Coord1->x, Coord1->y^0x1FF, Coord2->x, Coord2->y^0x1FF);
    [content drawLineX1: Coord1->x Y1: Coord1->y^0x1FF X2: Coord2->x Y2: Coord2->y^0x1FF];
}

/**
 * screen_char_draw(Coord, ch, count) - Output buffer from ch* of length count as PLATO characters
 */
void screen_char_draw(Coord, ch, count)
padPt* Coord;
unsigned char* ch;
unsigned char count;
{
  short offset = 0; 
  unsigned short x;    
  unsigned short y;
  unsigned short* px;  
  unsigned short* py;
  unsigned char i; 
  unsigned char a; 
  unsigned char j,k; 
  char b; 
  char width=8;
  char height=16;
  short deltaX=1;
  short deltaY=1;
  unsigned char *p;
  unsigned char* curfont = NULL;
  NSColor *mainColor, *altColor;

  if (CurMode==ModeRewrite)
    {
	altColor=bgColor; 
    }
  else if (CurMode==ModeInverse)
    {
   	altColor=fgColor; 
    }
 
  if (CurMode==ModeErase || CurMode==ModeInverse)
    {
      mainColor=bgColor;
    }
  else
    {
      mainColor=fgColor;
    }
 
  switch(CurMem)
    {
    case M0:
      curfont=font;
      offset=-32;
      break;
    case M1:
      curfont=font;
      offset=64;
      break;
    case M2:
      curfont=fontm23;
      offset=-32;
      break;
    case M3:
      curfont=fontm23;
      offset=32;
      break;
     }
  x=Coord->x;
  if (ModeBold)
    y=((Coord->y+30)^0x1FF)&0x1FF;
  else    
    y=((Coord->y+15)^0x1FF)&0x1FF;
     
  if (FastText==padF)
    {
      goto chardraw_with_fries;
    }
 
  /* the diet chardraw routine - fast text output. */
 
  for (i=0;i<count;++i)
    {
      a=*ch;
      ++ch;
      a+=offset;
      p=&curfont[FONTPTR(a)];
      
      for (j=0;j<16;++j)
        {
          b=*p;
          
          for (k=0;k<8;++k)
            {
              if (b<0) /* check sign bit. */
		{
		    [mainColor set];
                    screen_dot_draw_xy(x,y);
		}
              ++x;
              b<<=1;
            }
 
          ++y;
          x-=width;
          ++p;
        }
          
      x+=width;
      y-=height;
    }
 
  return;
 
 chardraw_with_fries:
  if (Rotate)
    {
      deltaX=-abs(deltaX);
      width=-abs(width);
      px=&y;
      py=&x;
    }
    else
    {
      px=&x;
      py=&y;
    }
 
  if (ModeBold)
    {
      deltaX = deltaY = 2;
      width<<=1;
      height<<=1;
    }
 
  for (i=0;i<count;++i)
    {
      a=*ch;
      ++ch;
      a+=offset;
      p=&curfont[FONTPTR(a)];
      for (j=0;j<16;++j)
        {
          b=*p;
 
          if (Rotate)
            {
              px=&y;
              py=&x;
            }
          else
            {
              px=&x;
              py=&y;
            }
 
          for (k=0;k<8;++k)
            {
              if (b<0) /* check sign bit. */
                {
		  [content setForegroundColor: mainColor];
		  [mainColor set];
		  //XSetForeground(display,gc,mainColor);
                  if (ModeBold)
                    {
                      screen_dot_draw_xy(*px+1,*py);
                      screen_dot_draw_xy(*px,*py+1);
                      screen_dot_draw_xy(*px+1,*py+1);
			//XDrawPoint(display,win,gc,*px,*py+1);
			//XDrawPoint(display,win,gc,*px+1,*py+1);
                    }
                  
                    screen_dot_draw_xy(*px,*py);
                }
              else
                {
                  if (CurMode==ModeInverse || CurMode==ModeRewrite)
                    {
		      [content setForegroundColor: altColor];
		      [altColor set];
                      if (ModeBold)
                        {
                 
                          screen_dot_draw_xy(*px+1,*py);
                          screen_dot_draw_xy(*px,*py+1);
                          screen_dot_draw_xy(*px+1,*py+1);
                        }
	                screen_dot_draw_xy(*px,*py);
                    }
                }
 
              x += deltaX;
              b<<=1;
            }
 
          y+=deltaY;
          x-=width;
          ++p;
        }
          
      Coord->x+=width;
      x+=width;
      y-=height;
    }
 
  return;
}

/**
 * screen_tty_char - Called to plot chars when in tty mode
 */
void screen_tty_char(theChar)
padByte theChar;
{
  if ((theChar >= 0x20) && (theChar < 0x7F)) {
    screen_char_draw(&TTYLoc, &theChar, 1);
    TTYLoc.x += CharWide;
  }  
  else if (theChar == 0x0b) /* Vertical Tab */
    {
      TTYLoc.y += CharHigh;
    }
  else if ((theChar == 0x08) && (TTYLoc.x > 7))/* backspace */
    {
      TTYLoc.x -= CharWide;
    }
  else if (theChar == 0x0A)/* line feed */
    TTYLoc.y -= CharHigh;
  else if (theChar == 0x0D)/* carriage return */
    TTYLoc.x = 0;
     
  if (TTYLoc.x + CharWide > 511) {/* wrap at right side */
    TTYLoc.x = 0;
    TTYLoc.y -= CharHigh;
  }  
     
  if (TTYLoc.y < 0) {
    screen_clear();
    TTYLoc.y=495;
  }  
}

/**
 * Clear colors in colormap we've allocated
 */
void screen_clear_colors()
{
}

/**
 * Return if color matches
 */
unsigned long screen_color_match(platocolor)
padRGB* platocolor;
{
  return 0;
}

/**
 * screen_foreground - Called to set foreground color.
 */
void screen_foreground(theColor)
padRGB* theColor;
{
    NSColor *aColor = nil;
    float r = (float)(theColor->red/255.0);
    float g = (float)(theColor->green/255.0);
    float b = (float)(theColor->blue/255.0);    

    NSLog(@"Set foreground color...  theColor r=%f g=%f b=%f", r, g, b);

    foregroundColor.red=theColor->red;
    foregroundColor.green=theColor->green;
    foregroundColor.blue=theColor->blue;
    foregroundPixel=screen_color_match(theColor);

    aColor = padRGBToNSColor(*theColor); 
    fgColor = aColor;
}

/**
 * screen_background - Called to set foreground color.
 */
void screen_background(theColor)
padRGB* theColor;
{
    NSColor *aColor = nil;
    float r = (float)(theColor->red/255.0);
    float g = (float)(theColor->green/255.0);
    float b = (float)(theColor->blue/255.0);

    NSLog(@"Set background color...  theColor r=%f g=%f b=%f", r, g, b);

    foregroundColor.red=theColor->red;
    foregroundColor.green=theColor->green;
    foregroundColor.blue=theColor->blue;
    foregroundPixel=screen_color_match(theColor);

    aColor = padRGBToNSColor(*theColor);
    bgColor = aColor;
}

/**
 * Recursive flood fill
 */
_screen_paint(x,y,oldpixel,newpixel)
unsigned long oldpixel,newpixel;
{
	unsigned long p = 0.0;  //XGetPixel(image,x,y);

	if (p != oldpixel)
		return;
	if (p == newpixel)
		return;
	if (p == oldpixel)
		//XPutPixel(image,x,y,newpixel);

	_screen_paint(x-1,y,oldpixel,newpixel);
	_screen_paint(x+1,y,oldpixel,newpixel);
	_screen_paint(x,y-1,oldpixel,newpixel);
	_screen_paint(x,y+1,oldpixel,newpixel);
}

void screen_paint(Coord)
padPt* Coord;
{
	int x = Coord->x;
	int y = Coord->y^0x1FF;
 	unsigned long oldpixel;	

	//image = XGetImage(display,win,0,0,511,511,AllPlanes,XYPixmap);
	//oldpixel = XGetPixel(image,x,y);
	//_screen_paint(x,y,oldpixel,foregroundPixel);
	//XPutImage(display,win,gc,image,0,0,0,0,511,511);
	//XDestroyImage(image);
	NSLog(@"paint...");
}

/**
 * screen_done()
 */
void screen_done()
{
    screen_clear_colors();
    [win close];
    [win release];
}
