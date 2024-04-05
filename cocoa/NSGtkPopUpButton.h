//
//  NSGtkPopUpButton.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Jan 26 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>



@interface NSGtkPopUpButton : NSPopUpButton 
{
@public
    GtkWidget *proxy;
	int width, height;
}

@end
