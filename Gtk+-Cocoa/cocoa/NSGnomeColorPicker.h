//
//  NSGnomeColorPicker.h
//  Gtk+
//
//  Created by Paolo Costabel on Mon Feb 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

#include "gnome-color-picker.h"
struct _GnomeColorPickerPrivate {

	GtkWidget *drawing_area;/* Drawing area for color sample */
	GtkWidget *cs_dialog;	/* Color selection dialog */

	gchar *title;		/* Title for the color selection window */

	gdouble r, g, b, a;	/* Red, green, blue, and alpha values */

	guint dither : 1;	/* Dither or just paint a solid color? */
	guint use_alpha : 1;	/* Use alpha or not */
};


@interface NSGnomeColorPicker : NSColorWell 
{
	GtkWidget *proxy;
}

@end
