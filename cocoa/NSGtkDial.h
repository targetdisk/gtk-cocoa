//
//  NSGtkDial.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Mar 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSCircularSlider.h"

#include <gtk/gtk.h>

@interface NSGtkDial : SSCircularSlider 
{
	GtkWidget *proxy;
}

@end
