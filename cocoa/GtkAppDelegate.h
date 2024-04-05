//
//  GtkAppdelegate.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface GtkAppDelegate : NSObject {
	NSApplicationTerminateReply(*cocoa_confirm_terminate)();
	BOOL (*cocoa_open_file)();
}

- (void) setTerminateHook: (void *)hook;
- (void) applicationWillFinishLaunching: (NSNotification *)not;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
@end
