//
//  GtkAppdelegate.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "GtkAppdelegate.h"


@implementation GtkAppDelegate
- (void) applicationDidFinishLaunching: (NSNotification *)not
{
    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(gdkIdle:)
    name:@"gdk_idle" object:nil];
}

- (void)gdkIdle:(NSNotification *)notification
{
		gdk_idle_hook();
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	if(cocoa_confirm_terminate)
		return (*cocoa_confirm_terminate)();
}

- (void) setTerminateHook:(void *)hook
{
	cocoa_confirm_terminate = hook;
}

- (void) setOpenFileHook:(void *)hook
{
	cocoa_open_file = hook;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	if(cocoa_open_file)
		return(*cocoa_open_file)(filename);

}
@end
