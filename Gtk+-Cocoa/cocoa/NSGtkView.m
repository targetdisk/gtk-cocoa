//
//  NSGtkView.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 05 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSGtkView.h"


@implementation NSGtkView

-(void)setEnabled:(BOOL)enabled
{
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
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

    printf("left view %x\n",proxy);

	// get image
    image = ns_gtk_dnd_get_drag_source_image(proxy);
	
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
