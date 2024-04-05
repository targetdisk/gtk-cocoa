//
//  NSGtkSpinButton.h
//  Gtk+
//
//  Created by Paolo Costabel on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "NSGtkEntry.h"
#import "NSGtkView.h"

#include <gtk/gtk.h>

@interface NSGtkStepper : NSStepper
{
	GtkWidget *proxy;
}
- (void)takeValueFrom : (id)sender;
@end


@interface NSGtkSpinButton : NSGtkView
{
	NSStepper *stepper;
	NSGtkEntry *entry;
	NSNumberFormatter *formatter;
}

- (id) initWithFrame: (NSRect) frame entry:(NSGtkEntry *) anEntry;
- (void)takeIntValueFrom : (id)sender;
@end
