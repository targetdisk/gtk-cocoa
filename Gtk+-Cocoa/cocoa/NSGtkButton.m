//
//  NSGtkButton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Sep 22 2002.
//  Copyright (c) 2002 Zebra Development, Inc. All rights reserved.
//

#import "NSGtkButton.h"

extern GList *idle_funcs;

@implementation NSGtkButton


- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)clicked:(id)sender
{
    //gtk_object_ref(proxy);
    gtk_signal_emit_by_name(proxy,"clicked",proxy);
    gtk_signal_emit_by_name(proxy,"released",proxy);
    while(idle_funcs)
        gdk_idle_hook();
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationCopy;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSImage *image;
	NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *pboard;
	NSGtkButton *but = (NSGtkButton *)self;

	// get image
    image = ns_gtk_dnd_get_drag_source_image(but->proxy);
	
	// if no image, this is not a drag site
	if(!image)
		return [super mouseDown:theEvent];

    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
  // Provide data for our custom type, and simple NSStrings.
    [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
    
    // Put string data on the pboard... notice you candrag into TextEdit!
    [pboard setString:@"Test"  forType: NSStringPboardType];

    [self dragImage:image at:[self convertPoint:[theEvent locationInWindow] fromView:nil] offset:dragOffset 
        event:theEvent pasteboard:pboard source:self slideBack:YES];

printf("mouse dragged\n");
    return;
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

- (GtkWidget *)proxy
{
    return proxy;
}
@end
