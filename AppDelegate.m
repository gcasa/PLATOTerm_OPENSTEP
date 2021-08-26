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

- (void) doTimer
{
  screen_main();
  io_main();
}

- (void) applicationDidFinishLaunching: (NSNotification *)n
{
  screen_init(); // hostname,port);
  touch_init();
  terminal_initial_position();
  io_init(); // hostname,port);

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
