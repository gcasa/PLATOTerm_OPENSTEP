/* PLATOView.m created by heron on Mon 06-Sep-2021 */

#import "PLATOView.h"

@implementation PLATOView
- (id) initWithFrame: (NSRect)f platoScreen: (unsigned)s
{
    self = [super initWithFrame: f];
    if (self != nil)
      {
      }
    return self;
}

- (void) drawRect: (NSRect)f
{
    [super drawRect: f];
}

- (void) setBackgroundColor: (NSColor *)c
{
    _backgroundColor = c;
    [_backgroundColor set];
    [_backgroundColor retain];
}

- (NSColor *) backgroundColor
{
    return _backgroundColor;
}

- (void) setForegroundColor: (NSColor *)c
{
    _foregroundColor = c;
    [_foregroundColor set];
    [_foregroundColor retain];
}

- (NSColor *) foregroundColor
{
    return _foregroundColor;
}


- (void) _clearSelector
{
  [_backgroundColor set];
  NSRectFill(NSMakeRect(0,0,512,512)); 
}

- (void) clear
{
  NSImageRep *r = nil;
  NSImage *i = nil;

  i = [[NSImage alloc] initWithSize: NSMakeSize(512,512)];
  r = [[NSCustomImageRep alloc] initWithDrawSelector: @selector(_clearSelector)
                                delegate: self];

  [i setFlipped: YES];
  [r setSize: NSMakeSize(512,512)];
  [i addRepresentation: r];
  [self setImage: i];

  [r release];
  [i release];
  NSLog(@"Clear");
}

- (void) drawLineX1: (short)x1 Y1: (short)y1 X2: (short)x2 Y2: (short)y2
{
  float r = [_foregroundColor redComponent];
  float g = [_foregroundColor greenComponent];
  float b = [_foregroundColor blueComponent];

  [[self image] lockFocus];
  
  PSsetrgbcolor(r,g,b);
  PSmoveto(x1,y1);
  PSlineto(x2,y2);
  PSstroke();

  [[self window] flushWindow];  
  [[self image] unlockFocus];
  [self setNeedsDisplay: YES];
}

- (void) drawDotX: (short)x Y: (short)y
{
  [[self image] lockFocus];

  [_foregroundColor set];
  NSRectFill(NSMakeRect(x,y,1,1));
  [[self window] flushWindow];  

  [[self image] unlockFocus];
  [self setNeedsDisplay: YES];
}

- (void) drawBlockX1: (short)x1 Y1: (short)y1 X2: (short)x2 Y2: (short)y2
{
    [[self image] lockFocus];

    [_foregroundColor set];
    NSRectFill(NSMakeRect(x1,y1,x2,y2));
    [[self window] flushWindow];  

    [[self image] unlockFocus];
    [self setNeedsDisplay: YES];  
}

- (void) inverse
{
    
}

- (NSColor *) colorAtX: (int)x y: (int)y
{
    // NSBitmapImageRep *rep = [NSBitmapImageRep imageWithData: [[self image] TIFFRepresentation]];
    return nil; // [rep colorAtX:x y:y];
}

@end
