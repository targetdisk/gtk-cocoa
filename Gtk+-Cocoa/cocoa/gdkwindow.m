//
//  gdkwidow.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
/* Needed for SEEK_END in SunOS */
#include <unistd.h>

#include "gdk.h"
#include "gdkprivate.h"

void
gdk_window_raise (GdkWindow *window)
{
	[window makeKeyAndOrderFront:window];
}

void
gdk_window_get_position (GdkWindow *window,
			 gint      *x,
			 gint      *y)
{
	NSPoint p;

	p = [window frame].origin;
	*x = p.x;
	*y = p.y;
}

GdkWindow*
gdk_window_get_pointer (GdkWindow       *window,
			gint            *x,
			gint            *y,
			GdkModifierType *mask)
{
	NSPoint p;

	p = [window mouseLocationOutsideOfEventStream];
	*x = p.x;
	*y = p.y;

	return window;
}


