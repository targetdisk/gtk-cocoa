//
//  NSGtkTableView.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkTableView.h"


@implementation NSGtkTableView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	GtkCList *clist = GTK_CLIST(proxy);

	return clist->rows;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex 
{
	char *text;	
	GdkPixmap *pixmap;
	GdkBitmap *mask;
	GtkCList *clist = GTK_CLIST(proxy);
	int column;
	static NSImage *dummyImage = NULL;

	column = [aTableView columnWithIdentifier:[aTableColumn identifier]];
	if(	gtk_clist_get_text(clist, rowIndex, column, &text))
		return [NSString stringWithCString:text];
	else
		if(	gtk_clist_get_pixmap(clist, rowIndex, column, &pixmap, &mask))
			return pixmap;
	else
		return @"";
		
}

/*
-(void) setFrameSize:(NSSize)size
{
	if(!lock_size)
		[super setFrameSize:size];
}
*/

- (void)tile
{
	lock_size = TRUE;
	[super tile];
	lock_size = FALSE;
}

- (GtkWidget *)proxy
{
	return proxy;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags, row;
    NSImage *image;
    NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSPasteboard *pboard;

    [[self window] makeKeyAndOrderFront:self];
	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	row = [self rowAtPoint:mouseLoc];
	if (row < 0)
	{
		[super mouseDown:theEvent];
		return;
	}
	[self selectRow:row byExtendingSelection:FALSE];
	gtk_clist_select_row (proxy, row,0);
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
}



@end
