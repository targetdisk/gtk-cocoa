//
//  gdkimlib.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#include "gtk.h"
#include "gdkprivate.h"
 
void
gdk_draw_line (GdkDrawable *drawable,
	       GdkGC       *gc,
	       gint         x1, 
	       gint         y1,
	       gint         x2,
	       gint         y2)
{
	NSView *view;
	float r,g,b;
        GdkGCValues values;
        GdkColor color;

        view  = (NSView *)drawable;
        gdk_gc_get_values(gc, &values);
        
        color = values.foreground;
        
	r = (float)color.red/65535;
	g = (float)color.green/65535;
	b = (float)color.blue/65535;
	[view lockFocus];
	[[NSGraphicsContext currentContext] setShouldAntialias: NO];
	[NSBezierPath setDefaultLineWidth:0.01];
	[[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1+.5,y1+.5) toPoint:NSMakePoint(x2+.5,y2+.5)];
	[view unlockFocus];
	
}

void
gdk_draw_rectangle (GdkDrawable *drawable,
		    GdkGC        *gc,
		    gint         filled,
		    gint         x,
		    gint         y,
		    gint         width,
		    gint         height)
{
	NSView *view;
	float r,g,b;
        GdkGCValues values;
        GdkColor color;

        view  = (NSView *)drawable;
        gdk_gc_get_values(gc, &values);
        
        color = values.foreground;
        
	r = (float)color.red/65535;
	g = (float)color.green/65535;
	b = (float)color.blue/65535;
	[view lockFocus];
	[NSBezierPath setDefaultLineWidth:0];
	[[NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0] set];
	if(filled)
		NSRectFill(NSMakeRect(x,y,width,height));
	else
		NSFrameRect(NSMakeRect(x,y,width,height)); 
	[view unlockFocus];
}


