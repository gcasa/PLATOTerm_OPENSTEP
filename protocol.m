/**
 * PLATOTerm - A PLATO Terminal
 * Based on Steve Peltz's PAD
 * 
 * Author: Thomas Cherryhomes <thom.cherryhomes at gmail dot com>
 * This file written by Steve Peltz. Copyright notice preserved.
 * and this code has been used with permission, and can be considered
 * public domain.
 *
 * Adapted for OPENSTEP4.2/Mach on the NeXT by 
 * <greg.casamento at gmail dot com>
 *
 * protocol.c - Protocol decoder functions 
 */

/* Copyright (c) 1990 by Steve Peltz */

#include "protocol.h"

#define	BSIZE	64
#define TRUE 1
#define FALSE 0

static padBool EscFlag;		/* Currently in an escape sequence */
static Mode PMode,		/* Mode */
  CMode;			/* Command */
static unsigned short SubMode;	/* Block/Line modes */
static DataType PType,		/* Mode type */
  CType;			/* Current type */
static unsigned short Phase;		/* Phase of current type */
static padWord theWord;		/* Data received for various data types */
static padByte theChar;
static padByte rawChar;
static padByte lastChar;
static padRGB theColor;
static unsigned short LowX,		/* Previous coordinates received */
  HiX, LowY, HiY;
static padPt CurCoord;		/* Current coordinate */
static padWord Margin;		/* Margin for CR */
static padWord MemAddr;		/* Load address for program data */
static unsigned short CharCnt;	/* Current count for loading chars */
static charData Char;		/* Character data */
static padByte charBuff[BSIZE];
static unsigned short charCount;	/* Count of characters currently buffered */
static padPt charCoord;

static padByte PTAT0[128] = {	/* PLATO to ASCII lookup table */
  0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,	/* original mapping */
  0x38, 0x39, 0x26, 0x60, 0x0a, 0x5e, 0x2b, 0x2d,
  0x13, 0x04, 0x07, 0x08, 0x7b, 0x0b, 0x0d, 0x1a,
  0x02, 0x12, 0x01, 0x03, 0x7d, 0x0c, 0x83, 0x85,
  0x3c, 0x3e, 0x5b, 0x5d, 0x24, 0x25, 0x5f, 0x7c,
  0x2a, 0x28, 0x40, 0x27, 0x1c, 0x5c, 0x23, 0x7e,
  0x17, 0x05, 0x14, 0x19, 0x7f, 0x09, 0x1e, 0x18,
  0x0e, 0x1d, 0x11, 0x16, 0x00, 0x0f, 0x87, 0x88,
  0x20, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
  0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
  0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
  0x78, 0x79, 0x7a, 0x3d, 0x3b, 0x2f, 0x2e, 0x2c,
  0x1f, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
  0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
  0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
  0x58, 0x59, 0x5a, 0x29, 0x3a, 0x3f, 0x21, 0x22
};

static padByte PTAT1[128] = {
  0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,	/* flow control mapping */
  0x38, 0x39, 0x26, 0x60, 0x09, 0x5e, 0x2b, 0x2d,
  0x17, 0x04, 0x07, 0x08, 0x7b, 0x0b, 0x0d, 0x1a,
  0x02, 0x12, 0x01, 0x03, 0x7d, 0x0c, 0x83, 0x85,
  0x3c, 0x3e, 0x5b, 0x5d, 0x24, 0x25, 0x5f, 0x27,
  0x2a, 0x28, 0x40, 0x7c, 0x1c, 0x5c, 0x23, 0x7e,
  0x97, 0x84, 0x14, 0x19, 0x7f, 0x0a, 0x1e, 0x18,
  0x0e, 0x1d, 0x05, 0x16, 0x9d, 0x0f, 0x87, 0x88,
  0x20, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
  0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
  0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
  0x78, 0x79, 0x7a, 0x3d, 0x3b, 0x2f, 0x2e, 0x2c,
  0x1f, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
  0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
  0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
  0x58, 0x59, 0x5a, 0x29, 0x3a, 0x3f, 0x21, 0x22
};

/*	externally referenced variables	*/

padPt PLATOSize={512,512};	/* Logical screen size */
CharMem CurMem;			/* Font to plot in */
padBool TTY,			/* TTY mode */
  FlowControl,			/* Flow control on */
  ModeBold,			/* Character plotting conditions */
  Rotate, Reverse;
DispMode CurMode;		/* Current PLATO plotting mode */
padBool FastText;               /* Indicate to main program if text optimizations can be done. */


/*----------------------------------------------*
 *	InitPAD, InitTTY, InitPLATO		*
 *						*
 *	Called to initialize PAD variables.	*
 *	Calls back to external routines to	*
 *	set up proper plotting conditions.	*
 *----------------------------------------------*/


InitPAD ()
{
  InitTTY ();
}


InitTTY ()
{
  charCount = 0;
  EscFlag = FALSE;
  TTY = TRUE;
  FastText = TRUE;
  FlowControl = FALSE;
  terminal_set_tty();
}


InitPLATO ()
{
  if (TTY)
    InitPLATOx ();
}


InitPLATOx ()
{
  charCount = 0;
  EscFlag = FALSE;
  TTY = FALSE;
  terminal_set_plato ();
  SetMode (mAlpha, tByte);
  LowX = 0;
  HiX = 0;
  LowY = 0;
  HiY = 0;
  CurCoord.x = 0;
  CurCoord.y = 0;
  MemAddr = 0;
  CharCnt = 0;
  Margin = 0;
  ModeBold = FALSE;
  Rotate = FALSE;
  Reverse = FALSE;
  FastText = TRUE;
  CurMem = M0;
  CurMode = ModeRewrite;
}


/*----------------------------------------------*
 *	Key					*
 *						*
 *	Send a 10-bit internal key. If a keyset	*
 *	key, translate, else send as escaped	*
 *	sequence.				*
 *----------------------------------------------*/


Key (theKey)
padWord theKey;	
{
  if (theKey >> 7)
    {
      io_send_byte (0x1b);
      io_send_byte (0x40 | (theKey & 0x3f));
      io_send_byte (0x60 | ((theKey >> 6) & 0x0f));
    }
  else
    {

      if (FlowControl == 0)
	theKey = PTAT0[theKey];
      else
	theKey = PTAT1[theKey];

      if (theKey & 0x80)
	{
	  io_send_byte (0x1b);
	  io_send_byte (theKey & 0x7f);
	}
      else
	io_send_byte (theKey);
    }
}

/*----------------------------------------------*
 *	Touch					*
 *						*
 *	Send a touch key (01yyyyxxxx).		*
 *----------------------------------------------*/

Touch(where)
padPt *where;
{
  io_send_byte(0x1b);
  io_send_byte(0x1f);
  io_send_byte(0x40 + (where->x & 0x1f));
  io_send_byte(0x40 + ((where->x >> 5) & 0x0f));
  io_send_byte(0x40 + (where->y & 0x1f));
  io_send_byte(0x40 + ((where->y >> 5) & 0x0f));
  
  Key(0x100 | ((where->x >> 1) & 0xF0) |
      ((where->y >> 5) & 0x0F));
}

/*----------------------------------------------*
 *	Ext					*
 *						*
 *	Send an external key (10xxxxxxxx).	*
 *----------------------------------------------*/


Ext (theKey)
padWord theKey;
{
  Key (0x200 | (theKey & 0xFF));
}


/*----------------------------------------------*
 *	Echo					*
 *						*
 *	Send an echo key (001xxxxxx).		*
 *----------------------------------------------*/


Echo (theKey)
padWord theKey;
{
  Key (0x080 | theKey);
}



/*----------------------------------------------*
 *	SetCommand, SetMode			*
 *						*
 *	Set state machine variables.		*
 *----------------------------------------------*/


SetCommand (theMode, theType)
Mode theMode;
DataType theType;
{
  CMode = theMode;
  CType = theType;
  Phase = 0;
}


SetMode (theMode, theType)
Mode theMode;
DataType theType;
{
  PMode = theMode;
  PType = theType;
  SubMode = 0;
  SetCommand (theMode, theType);
}


/*----------------------------------------------*
 *	FixXY					*
 *						*
 *	Move location by offset, then make sure	*
 *	it is still on the screen.		*
 *----------------------------------------------*/


FixXY (DX, DY)
short DX,DY;
{
  if (ModeBold)
    {
      DX = DX * 2;
      DY = DY * 2;
    }
  if (Reverse)
    DX = -DX;
  if (Rotate)
    {
      CurCoord.x = CurCoord.x + DY;
      CurCoord.y = CurCoord.y + DX;
    }
  else
    {
      CurCoord.x = CurCoord.x + DX;
      CurCoord.y = CurCoord.y + DY;
    }

  if (CurCoord.x < 0)
    CurCoord.x += PLATOSize.x;
  else if (CurCoord.x >= PLATOSize.x)
    CurCoord.x -= PLATOSize.x;

  if (CurCoord.y < 0)
    CurCoord.y += PLATOSize.y;
  else if (CurCoord.y >= PLATOSize.y)
    CurCoord.y -= PLATOSize.y;
}


/*----------------------------------------------*
 *	Superx, Subx, etc.			*
 *						*
 *	Various character positioning commands.	*
 *----------------------------------------------*/


Superx ()
{
  FixXY (0, 5);
}


Subx ()
{
  FixXY (0, -5);
}


Marginx ()
{
  if (Rotate)
    Margin = CurCoord.y;
  else
    Margin = CurCoord.x;
}


BSx ()
{
  FixXY (-8, 0);
}


HTx ()
{
  FixXY (8, 0);
}


LFx ()
{
  FixXY (0, -16);
}


VTx ()
{
  FixXY (0, 16);
}


FFx ()
{
  CurCoord.y = 0;
  CurCoord.x = 0;
  LFx ();
}


CRx ()
{
  if (Rotate)
    CurCoord.y = Margin;
  else
    CurCoord.x = Margin;
  LFx ();
}


/*----------------------------------------------*
 *	LoadCoordx				*
 *						*
 *	Assemble completed coordinate.		*
 *----------------------------------------------*/


LoadCoordx (SetCoord)
padPt *SetCoord;
{
  SetCoord->x = (HiX << 5) + LowX;
  SetCoord->y = (HiY << 5) + LowY;
}


/*----------------------------------------------*
 *	Blockx, Pointx, Linex, Alphax		*
 *						*
 *	Plot the specified item at the		*
 *	current location.			*
 *----------------------------------------------*/


Blockx ()
{
  padPt NewCoord;

  if (SubMode == 0)
    {
      LoadCoordx (&CurCoord);
      SubMode = 1;
    }
  else
    {
      LoadCoordx (&NewCoord);
      screen_block_draw (&CurCoord, &NewCoord);
      SubMode = 0;
      CurCoord.y-=15;
      CurCoord.x+=16;
    }
}


Pointx ()
{
  LoadCoordx (&CurCoord);
  screen_dot_draw (&CurCoord);
}


Linex ()
{
  padPt OldCoord;

  if (SubMode == 0)
    {
      LoadCoordx (&CurCoord);
      SubMode = 1;
    }
  else
    {
      OldCoord.y = CurCoord.y;
      OldCoord.x = CurCoord.x;
      LoadCoordx (&CurCoord);
      screen_line_draw (&OldCoord, &CurCoord);
    }
}


Alphax ()
{
  if (charCount == 0)
    charCoord = CurCoord;
  charBuff[charCount++] = theChar;
  HTx ();
  if (charCount >= BSIZE)
    {
      screen_char_draw (&charCoord, charBuff, charCount);
      charCount = 0;
    }
}


/*----------------------------------------------*
 *	LoadEchox				*
 *						*
 *	Echo responses to system.		*
 *----------------------------------------------*/


LoadEchox ()
{
  theWord &= 0x7f;
  switch (theWord)
    {

    case 0x52:
      FlowControl=TRUE;
      if (FlowControl)
	Echo (0x53);		/* flow control on */
      else
	Echo (0x52);		/* flow control not on */
      break;
    case 0x60:                  /* Inquire about ascii specific features. */
      Echo (terminal_get_features());
      break;
    case 0x70:
      Echo (terminal_get_type ());	/* terminal type */
      break;

    case 0x71:
      Echo (terminal_get_subtype());	/* subtype */
      break;

    case 0x72:
      Echo (terminal_get_load_file ());	/* load file */
      break;

    case 0x73:
      Echo (terminal_get_configuration ());	/* configuration */
      break;

    case 0x7A:
      Key (0x3FF);		/* send backout */
      break;

    case 0x7B:
      screen_beep ();
      break;			/* beep */

    case 0x7D:
      Echo (terminal_mem_read (MemAddr) & 0x7F);
      break;

    default:
      Echo (theWord);		/* normal echo */
      break;
    }
}


LoadAddrx ()
{
  MemAddr = theWord;
  CharCnt = 0;
}


LoadCharx ()
{
  Char[CharCnt] = theWord;
  if (CharCnt < 7)
    CharCnt++;
  else
    {
      terminal_char_load ((((MemAddr - terminal_get_char_address ()) >> 4) & 0x7f), Char);
      CharCnt = 0;
      MemAddr += 16;
    }
}


LoadMemx ()
{
  terminal_mem_load (MemAddr, theWord);
  MemAddr += 2;
}


SSFx ()
{
  padByte device;

  device = (theWord >> 10) & 0xFF;
  if (device == 1)
    {
      terminal_ext_allow ((theWord >> 3) & 1);
      touch_allow ((theWord >> 5) & 1);
    }
  else if ((theWord >> 9) & 1)
    {
      terminal_set_ext_in (device);
      if (!((theWord >> 8) & 1))
	Ext (terminal_ext_in ());
    }
  else
    {
      terminal_set_ext_out (device);
      if (!((theWord >> 8) & 1))
	terminal_ext_out (theWord & 0xFF);
    }
}


Externalx ()
{
  terminal_ext_out ((theWord >> 8) & 0xFF);
  terminal_ext_out (theWord & 0xFF);
}


GoMode ()
{
  switch (CMode)
    {
    case mBlock:
      Blockx ();
      break;
    case mPoint:
      Pointx ();
      break;
    case mLine:
      Linex ();
      break;
    case mAlpha:
      Alphax ();
      break;
    case mLoadCoord:
      LoadCoordx (&CurCoord);
      break;
    case mLoadAddr:
      LoadAddrx ();
      break;
    case mSSF:
      SSFx ();
      break;
    case mExternal:
      Externalx ();
      break;
    case mLoadEcho:
      LoadEchox ();
      break;
    case mLoadChar:
      LoadCharx ();
      break;
    case mLoadMem:
      LoadMemx ();
      break;
    case mMode5:
      terminal_mode_5 (theWord);
      break;
    case mMode6:
      terminal_mode_6 (theWord);
      break;
    case mMode7:
      terminal_mode_7 (theWord);
      break;
    case mFore:
      screen_foreground(&theColor);
      break;
    case mBack:
      screen_background(&theColor);
      break;
    case mPaint:
      screen_paint(&CurCoord);
      break;
    }
  CMode = PMode;
  CType = PType;
  Phase = 0;
}


GoWord ()
{
  switch (Phase)
    {
    case 0:
      theWord = theChar & 0x3F;
      Phase = 1;
      break;
    case 1:
      theWord |= ((theChar & 0x3F) << 6);
      Phase = 2;
      break;
    case 2:
      theWord |= ((theChar & 0x3F) << 12);
      GoMode ();
      break;
    }
}


GoCoord ()
{
  unsigned short CoordType, CoordValue;

  CoordValue = theChar & 0x1F;
  CoordType = ((theChar >> 5) & 3);
  switch (CoordType)
    {
    case 1:
      switch (Phase)
	{
	case 0:
	  HiY = CoordValue;
	  break;
	case 1:
	  HiX = CoordValue;
	  break;
	}
      Phase = 1;
      break;
    case 2:
      LowX = CoordValue;
      GoMode ();
      break;
    case 3:
      LowY = CoordValue;
      Phase = 1;
      break;
    }
}


GoColor ()
{
  switch (Phase)
    {
    case 0:
      theColor.blue = (theChar & 0x3f);
      break;
    case 1:
      theColor.blue |= (theChar & 0x03) << 6;
      theColor.green = (theChar & 0x3c) >> 2;
      break;
    case 2:
      theColor.green |= (theChar & 0x0f) << 4;
      theColor.red = (theChar & 0x30) >> 4;
      break;
    case 3:
      theColor.red |= (theChar & 0x3f) << 2;
      break;
    }
  if (Phase < 3)
    Phase++;
  else
    GoMode ();
}


GoPaint ()
{
  if (Phase == 0)
    Phase = 1;
  else
    GoMode ();

}


DataChar ()
{
  switch (CType)
    {
    case tByte:
      Alphax ();
      break;
    case tWord:
      GoWord ();
      break;
    case tCoord:
      GoCoord ();
      break;
    case tColor:
      GoColor ();
      break;
    case tPaint:
      GoPaint ();
      break;
    }
}


ShowPLATO (buff, count)
padByte *buff;
unsigned short count;
{
  while (count--)
    {
      theChar = *buff++;
      if (lastChar==0xFF && theChar==0xFF)
	{
	  lastChar=0;
	}
      else
	{
	  rawChar=theChar;
	  theChar &=0x7F;
	  if (TTY)
	    {
	      if (!EscFlag)
		screen_tty_char (theChar);
	      else if (theChar == 0x02)
		InitPLATOx ();
	    }
	  else if (EscFlag)
	    {
	      switch (theChar)
		{
		case 0x03:
		  InitTTY ();
		  break;
		  
		case 0x0C:
		  screen_clear ();
		  break;
		  
		case 0x11:
		  CurMode = ModeInverse;
		  SetFast();
		  break;
		case 0x12:
		  CurMode = ModeWrite;
		  SetFast();
		  break;
		case 0x13:
		  CurMode = ModeErase;
		  SetFast();
		  break;
		case 0x14:
		  CurMode = ModeRewrite;
		  SetFast();
		  break;
		  
		case 0x32:
		  SetCommand (mLoadCoord, tCoord);
		  break;
		  
		case 0x40:
		  Superx ();
		  break;
		case 0x41:
		  Subx ();
		  break;
		  
		case 0x42:
		  CurMem = M0;
		  break;
		case 0x43:
		  CurMem = M1;
		  break;
		case 0x44:
		  CurMem = M2;
		  break;
		case 0x45:
		  CurMem = M3;
		  break;
		  
		case 0x4A:
		  Rotate = FALSE;
		  SetFast();
		  break;
		case 0x4B:
		  Rotate = TRUE;
		  SetFast();
		  break;
		case 0x4C:
		  Reverse = FALSE;
		  SetFast();
		  break;
		case 0x4D:
		  Reverse = TRUE;
		  SetFast();
		  break;
		case 0x4E:
		  ModeBold = FALSE;
		  SetFast();
		  break;
		case 0x4F:
		  ModeBold = TRUE;
		  SetFast();
		  break;
		  
		case 0x50:
		  SetMode (mLoadChar, tWord);
		  break;
		case 0x51:
		  SetCommand (mSSF, tWord);
		  break;
		case 0x52:
		  SetCommand (mExternal, tWord);
		  break;
		case 0x53:
		  SetMode (mLoadMem, tWord);
		  break;
		case 0x54:
		  SetMode (mMode5, tWord);
		  break;
		case 0x55:
		  SetMode (mMode6, tWord);
		  break;
		case 0x56:
		  SetMode (mMode7, tWord);
		  break;
		case 0x57:
		  SetCommand (mLoadAddr, tWord);
		  break;
		case 0x59:
		  SetCommand (mLoadEcho, tWord);
		  break;
		  
		case 0x5A:
		  Marginx ();
		  break;
		  
		case 0x61:
		  SetCommand (mFore, tColor);
		  break;
		case 0x62:
		  SetCommand (mBack, tColor);
		  break;
		case 0x63:
		  SetCommand (mPaint, tPaint);
		  break;
		}
	    }
	  else if (theChar < 0x20)
	    {
	      if (charCount > 0)
		{
		  screen_char_draw (&charCoord, charBuff, charCount);
		  charCount = 0;
		}
	      switch (theChar)
		{
		case 0x00:
		  screen_wait();
		case 0x08:
		  BSx ();
		  break;
		case 0x09:
		  HTx ();
		  break;
		case 0x0A:
		  LFx ();
		  break;
		case 0x0B:
		  VTx ();
		  break;
		case 0x0C:
		  FFx ();
		  break;
		case 0x0D:
		  CRx ();
		  break;
		  
		case 0x19:
		  SetMode (mBlock, tCoord);
		  break;
		case 0x1C:
		  SetMode (mPoint, tCoord);
		  break;
		case 0x1D:
		  SetMode (mLine, tCoord);
		  break;
		case 0x1F:
		  SetMode (mAlpha, tByte);
		  break;
		}
	    }
	  else
	    DataChar ();
	  
	  EscFlag = (theChar == 0x1B);
	  lastChar=rawChar;
	}
    }
  if (charCount > 0)
    {
      screen_char_draw (&charCoord, charBuff, charCount);
      charCount = 0;
    }
}

/**
 * SetFast()
 * Toggle fast text output if mode = write or erase, and no rotate or bold
 */
 SetFast()
{
  FastText = (((CurMode == ModeWrite) || (CurMode == ModeErase)) && ((Rotate == padF) && (ModeBold == padF))); 
}
