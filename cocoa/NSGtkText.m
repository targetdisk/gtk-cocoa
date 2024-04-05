//
//  NSGtkText.m
//  Gtk+
//
//  Created by Paolo Costabel on Mon Dec 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSGtkText.h"
#include <gdk/gdkkeysyms.h>

@implementation NSGtkText

- (void)activate:(id)sender
{
	gtk_signal_emit_by_name(proxy,"activate",proxy);
}

- (void)textDidChange:(NSNotification *)aNotification
{
  	GtkEditable *editable;
	NSString *s =  [[aNotification object] string];
	gchar *text = [s cString];
  	gint tmp_pos;

	if(locked) return;
	locked = TRUE;
    editable = GTK_EDITABLE (proxy);
  
    gtk_editable_delete_text (editable, 0, -1);

	tmp_pos = 0;
	gtk_editable_insert_text (editable, text, strlen (text), &tmp_pos);
	editable->current_pos = tmp_pos;

	editable->selection_start_pos = 0;
	editable->selection_end_pos = 0;

	locked = FALSE;
	printf("text changed: %s\n", text);
}

- (void)takeIntValueFrom : (id)sender
{
	
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSControlTextDidChangeNotification" object: self];
   [super takeIntValueFrom: sender];

	// this entry is connected to a spin button
	//
    gtk_adjustment_set_value (GTK_SPIN_BUTTON(proxy)->adjustment, [sender intValue]);
} 

-(void) setFrame:(NSRect)frame
{
	[super setFrame:frame];
}

-(void) setFrameOrigin:(NSPoint)origin
{
	[super setFrameOrigin:origin];
}

-(void) setFrameSize:(NSSize)size
{
//    size.height = proxy->allocation.height-10;
    
    [super setFrameSize:size];
    [self reshape];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	GdkEventCrossing *event;
	NSRect r = [self frame];

	if(![self canDraw]) return;
	if([self isEditable]) return;
	event = (GdkEventCrossing *)gdk_event_new();
	event->type = GDK_ENTER_NOTIFY;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
	
	[[self window] makeFirstResponder:self];
printf("entered %f %f %f %f\n",r.origin.x, r.origin.y, r.size.width, r.size.height);
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (void)reshape
{
	GtkWidget *w = proxy;
    GdkEventConfigure *event;
    GdkEventExpose *event2;
	NSRect frameRect = [self frame];
    
	if(tag)
		[self removeTrackingRect:tag];
    event = (GdkEventConfigure *)gdk_event_new ();
    event->type = GDK_CONFIGURE;
    event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = frameRect.origin.x;
    event->y = frameRect.origin.y;
    event->width = frameRect.size.width;
    event->height = frameRect.size.height;
	frameRect.origin.x =0;
	frameRect.origin.y =0;
	tag = [self addTrackingRect:frameRect owner:self userData:NULL assumeInside:NO];
    gtk_widget_event (proxy, event);
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if(tag)
        {
		[self removeTrackingRect:tag];
                tag = 0;
        }
}

- (void)mouseExited:(NSEvent *)theEvent
{
	GdkEventCrossing *event;

	event = (GdkEventCrossing *)gdk_event_new();
	event->type = GDK_LEAVE_NOTIFY;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}


- (void)keyDown:(NSEvent *)theEvent
{
	GdkEventKey *event;
	int flags;
	NSString *key;
	unichar character;

	if([self isEditable])
	{
		[super keyDown:theEvent];
		return;
	}
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_KEY_PRESS;
    event->send_event = FALSE;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	key = [theEvent characters] ;
	character = [key characterAtIndex:0];
	switch(character)
	{
		case NSUpArrowFunctionKey:
			event->keyval = GDK_Up;
			break;
		case NSDownArrowFunctionKey:
			event->keyval = GDK_Down;
			break;
		case NSLeftArrowFunctionKey:
			event->keyval = GDK_Left;
			break;
		case NSRightArrowFunctionKey:
			event->keyval = GDK_Right;
			break;
		default:
			event->keyval = *[key cString];
			break;
	}
	
printf("window key down event\n");
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (void)viewDidMoveToWindow
{
	NSPoint mouseLoc;
	mouseLoc = [self convertPoint:[[self window] convertScreenToBase:[NSEvent mouseLocation]] fromView:nil];
	if([self mouse:mouseLoc inRect:[self frame]])
	{
		GdkEventCrossing *event;
		NSRect r = [self frame];

		if([self canDraw])
		{
			event = (GdkEventCrossing *)gdk_event_new();
			event->type = GDK_ENTER_NOTIFY;
			event->window = (GdkWindow *)proxy;
			event->send_event = FALSE;
			printf("entered %f %f %f %f\n",r.origin.x, r.origin.y, r.size.width, r.size.height);
			gtk_widget_event (proxy, event);
			gdk_idle_hook();
		}
	}
	if(!tag)
	{
		NSRect frameRect = [self frame];
		frameRect.origin.x =0;
		frameRect.origin.y =0;
		tag = [self addTrackingRect:frameRect owner:self userData:NULL assumeInside:NO];
	}
}

@end
