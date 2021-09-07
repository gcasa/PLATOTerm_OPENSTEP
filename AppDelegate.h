/* AppDelegate.h created by heron on Tue 24-Aug-2021 */

#import <AppKit/AppKit.h>

@interface AppDelegate : NSObject
{
    IBOutlet NSPanel *_panel;
    IBOutlet NSTextField *_hostnameField;
    IBOutlet NSTextField *_portField;

    NSTimer *_timer;
}

- (IBAction) startClient: (id)sender;
- (IBAction) createConnection: (id)sender;

@end
