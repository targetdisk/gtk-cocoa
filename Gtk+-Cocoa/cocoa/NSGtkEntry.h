//
//  NSGtkEntry.h
//  Gtk+
//
//  Created by Paolo Costabel on Mon Dec 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>


@interface NSGtkEntry : NSTextField
{
@public
    GtkWidget *proxy;
	bool locked;
	GtkSpinButton *sb;
}

- (void)activate:(id)sender;
- (void)controlTextDidChange:(NSNotification *)aNotification;
- (void)takeIntValueFrom : (id)sender;

@end
