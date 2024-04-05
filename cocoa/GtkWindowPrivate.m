//
//  GtkWindowPrivate.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 18 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//

#import "GtkWindowPrivate.h"

#include <gdk/gdktypes.h>
#include <gdk/gdkkeysyms.h>

extern GList *idle_funcs;

@implementation GtkWindowPrivate : NSWindow

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)sendEvent:(NSEvent *)anEvent
{  
//    if([anEvent type] == NSLeftMouseDown)
//    {
//        [[self firstResponder] mouseDown:anEvent];
 //   }
//    printf("window firstresponder %x\n",[self firstResponder]);
    [super sendEvent:anEvent];

//	gdk_idle_hook();
}

- (void)setFrame:(NSRect)frameRect display:(BOOL)flag
{
    [super setFrame:frameRect display:flag];
}

- (void)windowDidResize:(NSNotification *)aNotification
{
    GdkEventConfigure *event;
    NSRect frameRect = [[aNotification object] frame];
    
    event = (GdkEventConfigure *)gdk_event_new ();
    event->type = GDK_CONFIGURE;
    event->window = (GdkWindow *)widget;
    event->send_event = FALSE;
    event->x = frameRect.origin.x;
    event->y = frameRect.origin.y;
    event->width = frameRect.size.width;
    event->height = frameRect.size.height-22;

    printf("Window size %f %f\n",frameRect.size.width, frameRect.size.height);
    gtk_widget_event (widget, event);
//	while(idle_funcs)
		gdk_idle_hook();
}

- (void)keyUp:(NSEvent *)theEvent
{
	GdkEventKey *event;
	int flags;
	NSString *key;
	unichar character;

	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_KEY_RELEASE;
 	event->window = (GdkWindow *)widget;
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
		case NSDeleteFunctionKey:
		case NSDeleteCharacter:
			event->keyval = GDK_Delete;
			break;
		case NSF1FunctionKey:
			event->keyval = GDK_F1;
			break;
		case NSF2FunctionKey:
			event->keyval = GDK_F2;
			break;
		case NSF3FunctionKey:
			event->keyval = GDK_F3;
			break;
		case NSF4FunctionKey:
			event->keyval = GDK_F4;
			break;
		case NSF5FunctionKey:
			event->keyval = GDK_F5;
			break;
		case NSF6FunctionKey:
			event->keyval = GDK_F6;
			break;
		case NSF7FunctionKey:
			event->keyval = GDK_F7;
			break;
		case NSF8FunctionKey:
			event->keyval = GDK_F8;
			break;
		case NSF9FunctionKey:
			event->keyval = GDK_F9;
			break;
		case NSF10FunctionKey:
			event->keyval = GDK_F10;
			break;
		case NSF11FunctionKey:
			event->keyval = GDK_F11;
			break;
		case NSF12FunctionKey:
			event->keyval = GDK_F12;
			break;
		case NSF13FunctionKey:
			event->keyval = GDK_F13;
			break;
		case NSF14FunctionKey:
			event->keyval = GDK_F14;
			break;
		case NSF15FunctionKey:
			event->keyval = GDK_F15;
			break;
		default:
			event->keyval = *[key cString];
			break;
	}
	
    gtk_widget_event (widget, event);
	gdk_idle_hook();
}

- (void)keyDown:(NSEvent *)theEvent
{
	GdkEventKey *event;
	int flags;
	NSString *key;
	unichar character;

	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_KEY_PRESS;
 	event->window = (GdkWindow *)widget;
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
		case NSDeleteFunctionKey:
		case NSDeleteCharacter:
			event->keyval = GDK_Delete;
			break;
		case NSF1FunctionKey:
			event->keyval = GDK_F1;
			break;
		case NSF2FunctionKey:
			event->keyval = GDK_F2;
			break;
		case NSF3FunctionKey:
			event->keyval = GDK_F3;
			break;
		case NSF4FunctionKey:
			event->keyval = GDK_F4;
			break;
		case NSF5FunctionKey:
			event->keyval = GDK_F5;
			break;
		case NSF6FunctionKey:
			event->keyval = GDK_F6;
			break;
		case NSF7FunctionKey:
			event->keyval = GDK_F7;
			break;
		case NSF8FunctionKey:
			event->keyval = GDK_F8;
			break;
		case NSF9FunctionKey:
			event->keyval = GDK_F9;
			break;
		case NSF10FunctionKey:
			event->keyval = GDK_F10;
			break;
		case NSF11FunctionKey:
			event->keyval = GDK_F11;
			break;
		case NSF12FunctionKey:
			event->keyval = GDK_F12;
			break;
		case NSF13FunctionKey:
			event->keyval = GDK_F13;
			break;
		case NSF14FunctionKey:
			event->keyval = GDK_F14;
			break;
		case NSF15FunctionKey:
			event->keyval = GDK_F15;
			break;
		default:
			event->keyval = *[key cString];
			break;
	}
	
    gtk_widget_event (widget, event);
	gdk_idle_hook();
}

- (BOOL)windowShouldClose:(id)sender
{
    GdkEventAny *event;
    
    event = (GdkEventAny *)gdk_event_new ();
    event->type = GDK_DELETE;
    event->window = (GdkWindow *)widget;
    event->send_event = FALSE;

    gtk_widget_event (widget, event);
	while(idle_funcs)
		gdk_idle_hook();
	return NO;
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder
{
    BOOL res;
    
    res = [super makeFirstResponder:aResponder];
    if(res)
        printf("%x becomes first responder\n", aResponder);
    else
        printf("%x refuses first responder\n", aResponder);
        
    return res;
}

@end
