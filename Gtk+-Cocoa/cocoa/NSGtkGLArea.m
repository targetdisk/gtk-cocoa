//
//  NSGtkGLArea.m
//  Gtk+
//
//  Created by Paolo Costabel on Thu Jan 09 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkGLArea.h"
//#import "NSgtkMatrix.h"
#import "GtkEvents.h"

#include <gdk/gdktypes.h>

extern GList *idle_funcs;

@implementation NSGtkGLArea

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
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

- (id) initWithFrame: (NSRect) frame
{

	int attribs[] = 
	{
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAWindow,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAColorSize, 24,
		NSOpenGLPFAAlphaSize, 0,
		NSOpenGLPFADepthSize, 24,
		NSOpenGLPFAStencilSize, 0,
		NSOpenGLPFAAccumSize, 0,
		0
	};

	NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attribs]; 
	
	if (!fmt)
		NSLog(@"No OpenGL pixel format");

	tag = 0;
	return self = [super initWithFrame:frame pixelFormat: [fmt autorelease]];
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

/*
    event2 = (GdkEventExpose *)gdk_event_new ();
    event2->type = GDK_EXPOSE;
    event2->window = (GdkWindow *)proxy;
    event2->send_event = FALSE;
    event2->area.x = frameRect.origin.x;
    event2->area.y = frameRect.origin.y;
    event2->area.width = frameRect.size.width;
    event2->area.height = frameRect.size.height-22;

    gtk_widget_event (proxy, event2);
*/
	//while(idle_funcs)
//	gdk_idle_hook();
	[super reshape];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags;
 
	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
printf("modifier fags %x\n",flags);
printf("left widget %x\n",proxy);
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_PRESS;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON1_MASK;
	_mouse_state |= GDK_BUTTON1_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	event->button = 1;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();

}

- (void)mouseDragged:(NSEvent *)theEvent
{
	GdkEventMotion *event;
	NSPoint mouseLoc;
	int flags;
    NSImage *image;
    NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *pboard;


	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventMotion *)gdk_event_new();
	event->type = GDK_MOTION_NOTIFY;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->is_hint = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = _mouse_state;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();

    // get image
    image = ns_gtk_dnd_get_drag_source_image(proxy);
             
    // if no image, this is not a drag site
    if(!image)
        return [super mouseDragged:theEvent];
    
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
  // Provide data for our custom type, and simple NSStrings.
    [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
    
    // Put string data on the pboard... notice you candrag into TextEdit!
    [pboard setString:@"Test"  forType: NSStringPboardType];

    [self dragImage:image at:[self convertPoint:[theEvent locationInWindow] fromView:nil] offset:dragOffset
        event:theEvent pasteboard:pboard source:self slideBack:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags;

	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_RELEASE;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON1_MASK;
	_mouse_state &= ~ GDK_BUTTON1_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	event->button = 1;
	
    gtk_widget_event (proxy, event);
	 gdk_idle_hook();
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags;
printf("proxy %x\n",proxy);
	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_PRESS;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON3_MASK;
	_mouse_state |= GDK_BUTTON3_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	event->button = 3;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
	GdkEventMotion *event;
	NSPoint mouseLoc;
	int flags;

	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventMotion *)gdk_event_new();
	event->type = GDK_MOTION_NOTIFY;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->is_hint = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON3_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags;

	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_RELEASE;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON3_MASK;
	_mouse_state &= ~ GDK_BUTTON3_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	event->button = 3;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags;

	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_PRESS;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON2_MASK;
	_mouse_state |= GDK_BUTTON2_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	event->button = 2;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
	GdkEventMotion *event;
	NSPoint mouseLoc;
	int flags;

	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventMotion *)gdk_event_new();
	event->type = GDK_MOTION_NOTIFY;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->is_hint = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = _mouse_state;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
	NSPoint mouseLoc;
	GdkEventButton *event;
	int flags;

	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_BUTTON_RELEASE;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
    event->x = mouseLoc.x;
    event->y = [self frame].size.height -mouseLoc.y;
	event->state = GDK_BUTTON2_MASK;
	_mouse_state &= ~ GDK_BUTTON2_MASK;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	event->button = 2;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationCopy;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	GtkWidget *w = [[sender draggingSource] proxy];

	ns_gtk_drag_and_drop(w, proxy, 0, 0);

    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}
/*
- (void)keyDown:(NSEvent *)theEvent
{
	GdkEventKey *event;
	int flags;

	flags = [theEvent modifierFlags];
	event = (GdkEventButton *)gdk_event_new();
	event->type = GDK_KEY_PRESS;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
	if(flags & NSShiftKeyMask)
		event->state |= GDK_SHIFT_MASK;
	if(flags & NSControlKeyMask)
		event->state |= GDK_CONTROL_MASK;
	if(flags & NSAlternateKeyMask)
		event->state |= GDK_MOD1_MASK;
	event->keyval = *[[theEvent characters] cString];
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
	

}
*/
- (void)mouseEntered:(NSEvent *)theEvent
{
	GdkEventCrossing *event;
	NSRect r = [self frame];

	if(![self canDraw]) return;
	event = (GdkEventCrossing *)gdk_event_new();
	event->type = GDK_ENTER_NOTIFY;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();
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

- (BOOL)becomeFirstResponder
{
    printf("first responder %x\n",self);
	return YES;
}

-(void) setFrame:(NSRect)frame
{
	if(proxy)
	{
		frame.size.height = proxy->allocation.height;
		frame.size.width = proxy->allocation.width;
	}
	[super setFrame:frame];
}

-(void) setFrameOrigin:(NSPoint)origin
{
	[super setFrameOrigin:origin];
}

-(void) setFrameSize:(NSSize)size
{
	if(proxy)
	{
		size.height = proxy->allocation.height;
		size.width = proxy->allocation.width;
	}
    
    [super setFrameSize:size];
	printf("size %f\n",[self frame].size.height);
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if(tag)
		[self removeTrackingRect:tag];
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
			gtk_widget_event (proxy, event);
			gdk_idle_hook();
		}
	}
}



- (GtkWidget *)proxy
{
	return proxy;
}
@end
