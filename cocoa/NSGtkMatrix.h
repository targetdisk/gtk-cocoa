//
//  NSGtkMatrix.h
//  Gtk+
//
//  Created by Paolo Costabel on Wed Jan 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>


#include <gtk/gtk.h>
#include "gnome-icon-list.h"
@interface NSGtkMatrix : NSMatrix 
{
	GtkWidget *proxy;
}

-(void)select_icon:(id)sender;
- (void)mouseDown:(NSEvent *)theEvent;
- (GtkWidget *)proxy;

@end
