/* AppDelegate.m created by heron on Tue 24-Aug-2021 */

#import "AppDelegate.h"

// Application specific headers...
#include "protocol.h"
#include "screen.h"
#include "io.h"
#include "terminal.h"
#include "keyboard.h"
#include "touch.h"

@implementation AppDelegate

- (void) doTimer: (NSTimer *)timer
{
  screen_main();
  io_main();
}

- (void) applicationDidFinishLaunching: (NSNotification *)n
{
}

- (IBAction) createConnection: (id)sender
{
    [_panel makeKeyAndOrderFront: self];
}

- (IBAction) startClient: (id)sender
{
    char *hostname = [[_hostnameField stringValue] cString];
    unsigned port = [[_portField stringValue] intValue];

    [_panel orderOut: self];

    screen_init(hostname, port);
    touch_init();
    terminal_initial_position();
    io_init(hostname,port);

    _timer = [NSTimer scheduledTimerWithTimeInterval: 0.1
                                              target: self
                                            selector: @selector(doTimer:)
                                            userInfo: nil
                                             repeats: YES];
}

- (void) applicationWillTerminate: (NSNotification *)n
{
  [_timer invalidate];
  touch_done();
  io_done();
  screen_done();
}

@end
