//
//  NSGtkDrawingArea.m
//  Gtk+
//
//  Created by Paolo Costabel on Tue Jul 22 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkDrawingArea.h"

extern GList *idle_funcs;

@implementation NSGtkDrawingArea

- (BOOL)isFlipped
{
    return TRUE;
}

- (void)drawRect:(NSRect)aRect
{
    GdkEventExpose *event;

    event = (GdkEventExpose *)gdk_event_new ();
    event->type = GDK_EXPOSE;
    event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->area.x = aRect.origin.x;
    event->area.y = aRect.origin.y;
    event->area.width = aRect.size.width;
    event->area.height = aRect.size.height-22;

    gtk_widget_event (proxy, event);
	while(idle_funcs)
		gdk_idle_hook();
}

@end
