//
//  NSGnomeColorPicker.m
//  Gtk+
//
//  Created by Paolo Costabel on Mon Feb 17 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGnomeColorPicker.h"


@implementation NSGnomeColorPicker

- (void)color_set:(id)sender
{
	GnomeColorPicker *cp = GNOME_COLOR_PICKER(proxy);
	NSColor *selected_color;
	float red,green,blue,alpha;

	selected_color = [self color];
	[[selected_color colorUsingColorSpaceName:NSCalibratedRGBColorSpace]  getRed:&red green:&green blue:&blue alpha:&alpha];
	cp->_priv->r = red;
	cp->_priv->g = green;
	cp->_priv->b = blue;
	cp->_priv->a = alpha;
    gtk_signal_emit_by_name(proxy,"color-set", red*65535, green*65535, blue*65535, alpha*65535);
}

@end
