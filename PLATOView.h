/* PLATOView.h created by heron on Mon 06-Sep-2021 */

#import <AppKit/AppKit.h>

@interface PLATOView : NSImageView
{
    NSColor *_backgroundColor;
    NSColor *_foregroundColor;
}

- (id) initWithFrame: (NSRect)f platoScreen: (unsigned)s;
 
- (void) setBackgroundColor: (NSColor *)c;
- (NSColor *) backgroundColor;

- (void) setForegroundColor: (NSColor *)c;
- (NSColor *) foregroundColor;

- (void) clear;
- (void) drawLineX1: (short)x1 Y1: (short)y1 X2: (short)x2 Y2: (short)y2;
- (void) drawDotX: (short)x Y: (short)y;
- (void) drawBlockX1: (short)x1 Y1: (short)y1 X2: (short)x2 Y2: (short)y2;
- (void) inverse;

@end
