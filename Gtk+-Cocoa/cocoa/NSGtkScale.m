//
//  NSGtkScale.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Feb 01 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkScale.h"


@implementation NSGtkScale

- (void)value_changed:(id)sender
{
	GtkAdjustment *adj;
	GtkRange *range = proxy;

	adj = range->adjustment;
	if([self isVertical])
		adj->value = (1-[sender floatValue])*(adj->upper-adj->lower-adj->page_size)+adj->lower;
	else
		adj->value = [sender floatValue]*(adj->upper-adj->lower-adj->page_size)+adj->lower;
	gtk_signal_emit_by_name (GTK_OBJECT (adj), "value_changed");
	printf("adj %f\n",adj->value);
}

- (void)mouseDown:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags;
	GtkRange *range = proxy;


	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_PRESS;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON1_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	event->button = 1;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();

	[super mouseDown:theEvent];
	[self mouseUp:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags;
	GtkRange *range = proxy;

	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_RELEASE;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON1_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	event->button = 1;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}
@end
