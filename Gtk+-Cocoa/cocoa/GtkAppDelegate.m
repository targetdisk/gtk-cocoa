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
/*
 NSMenu *menu;
  NSMenuItem *item;
  NSMenu *menuBar = [NSApp mainMenu];
  
 item = [[NSMenuItem alloc] initWithTitle:@"Prova" action:nil keyEquivalent:@"P"];
 menu = [[NSMenu alloc] initWithTitle:@"Belin"];
 [menuBar addItem: item];
 [menuBar setSubmenu:menu forItem:item];
 */
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
