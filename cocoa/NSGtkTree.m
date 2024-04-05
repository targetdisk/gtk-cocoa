//
//  NSGtkTree.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Jan 05 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkTree.h"
#import "ImageAndTextCell.h"


@implementation NSGtkTree

static NSGtkTreeNode *dummy;

extern void ns_gtk_ctree_expand(GtkCTree *ctree, GtkCTreeNode *node, gpointer data);

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

// Required methods.
- (id)outlineView:(NSOutlineView *)olv child:(int)index ofItem:(id)item 
{
	int i;
	NSGtkTreeNode *node_item = (NSGtkTreeNode *)item;
	GtkCTree *tree = proxy;
	GtkCTreeNode *node;
	GtkCTreeRow *row;
		
	if(!item)
	{
/*
		if(!index)
		{
			if(!dummy)
				dummy = [NSGtkTreeNode alloc];       
			return dummy;
		}
		index--;
*/
		node = GTK_CLIST (tree)->row_list;
		while(index)
		{
			node = GTK_CTREE_ROW(node)->sibling;
			index--;
		}
		return node->proxy;
	}
	else
		row  = GTK_CTREE_ROW(node_item->node);

	for(i = 0,node = row->children; i<index; i++, node = GTK_CTREE_NODE_NEXT(node));

    return node->proxy;
}

- (BOOL)outlineView:(NSOutlineView *)olv isItemExpandable:(id)item 
{
	NSGtkTreeNode *node_item = (NSGtkTreeNode *)item;
	GtkCTreeRow *row;

	if(!node_item->node) return FALSE;
	row  = GTK_CTREE_ROW(node_item->node);

    return !row->is_leaf;
}

- (int)outlineView:(NSOutlineView *)olv numberOfChildrenOfItem:(id)item 
{
	GtkCTreeNode *node;
	GtkCTree *tree = proxy;
	NSGtkTreeNode *node_item = (NSGtkTreeNode *)item;
	int n = 0;

	if(!item)
	{
		if(GTK_CLIST(tree)->row_list)
		{
			node = GTK_CLIST(tree)->row_list; 
//			n++;
		}
		else
			return 0;
	}
	else if(!node_item->node) 
		return 0;
	else
		node = GTK_CTREE_ROW(node_item->node)->children;

	while(node)
	{
		node = GTK_CTREE_ROW(node)->sibling;
		n++;
	}

    return n;
}

- (id)outlineView:(NSOutlineView *)olv objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item 
{
	GtkCTreeRow *row;
	GtkCTree *tree = proxy;
	NSGtkTreeNode *node_item = (NSGtkTreeNode *)item;
	char *text;
	GdkPixmap *pixmap;
	int column, cell_type;

	if(!node_item->node) return NULL;

	row  = GTK_CTREE_ROW(node_item->node);
	column = [olv columnWithIdentifier:[tableColumn identifier]];
/*
	if(!column && !row->is_leaf && ![olv isItemExpanded:item])
	{
		[olv expandItem:item];
		[olv reloadData];
	}
*/
	cell_type = gtk_ctree_node_get_cell_type (tree, node_item->node, column);
	switch(cell_type)
	{
		case  GTK_CELL_TEXT:
			if(gtk_ctree_node_get_text (tree, node_item->node, column, &text))
                        {
                            if(text)
                        	return [NSString stringWithCString:text];
                            else
                                return @"";
                        }
			else
				return @""; 
		case  GTK_CELL_PIXTEXT:
			if(gtk_ctree_node_get_pixtext (tree, node_item->node, column, &text, NULL, &pixmap, NULL))
            {
            	if(text)
					return [NSString stringWithCString:text];
                            else
					return pixmap; 
            }
			else
				return @""; 
		case  GTK_CELL_PIXMAP:
			if(gtk_ctree_node_get_pixtext (tree, node_item->node, column, &text, NULL, &pixmap, NULL))
				return pixmap;
	}
    return @"";
}
/*
-(void) setFrame:(NSRect)frame
{
    frame.size.height = proxy->allocation.height;

	[super setFrame:frame];
}

-(void) setFrameOrigin:(NSPoint)origin
{
	[super setFrameOrigin:origin];
}

-(void) setFrameSize:(NSSize)size
{
    size.height = proxy->allocation.height;
    
    [super setFrameSize:size];
}

*/
- (void)tree_select_row:(id)sender
{
	GtkCTree *tree = proxy;
	GtkCList *clist = tree;
	NSGtkTreeNode *node_item;
	NSEnumerator *sel;
	GtkCTreeNode *node;
	NSNumber *object;
	int row = [self selectedRow];
	
//	g_list_free(clist->selection);
//	clist->selection = NULL;
	gtk_clist_unselect_all(tree);

	sel = [self selectedRowEnumerator];

	while (object = [sel nextObject]) 
	{
		node_item = [self itemAtRow:[object intValue]];
		node = node_item->node;
		if(!g_list_find(clist->selection, node))
			clist->selection = g_list_append (clist->selection, node);
	}
	
    if(row!=-1)
	{
		node_item = [self itemAtRow:row];
		node = node_item->node;
    	gtk_signal_emit_by_name(tree,"tree_select_row", node, 0);
	}
    gtk_signal_emit_by_name(tree,"selection_changed");
	gdk_idle_hook();
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard 
{ 
    NSImage *image;
    NSSize dragOffset = NSMakeSize(0.0, 0.0);
    NSGtkTree *tree = (NSGtkTree *)self;
	NSPoint mouseLoc;
	int row,col;

    // get image
    image = ns_gtk_dnd_get_drag_source_image(tree->proxy);
             
    // if no image, this is not a drag site
    if(!image)
        return NO;
    
  // Provide data for our custom type, and simple NSStrings.
    [pboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:self];
    
    // Put string data on the pboard... notice you candrag into TextEdit!
    [pboard setString:@"Test"  forType: NSStringPboardType];

printf("mouse dragged\n");
    return YES;   
}  

- (unsigned int)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)childIndex 
{
    return NSDragOperationGeneric;
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(int)childIndex 
{
	GtkWidget *w =  proxy;
	NSRect rect; 
	int x,y;
    
    if(childIndex == -1)
        rect = [olv rectOfRow:[olv rowForItem:targetItem]];
    else
        rect = [olv rectOfRow:childIndex];
	x = rect.origin.x+rect.size.width/2;
	y = rect.origin.y+rect.size.height/2;
        
    ns_gtk_drag_and_drop(w, proxy, x, y);

    return YES;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	NSGtkTreeNode *node_item = [[notification userInfo] objectForKey:@"NSObject"];

    tree_expand (proxy, node_item->node, NULL);
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification
{
	NSGtkTreeNode *node_item = [[notification userInfo] objectForKey:@"NSObject"];

    tree_collapse (proxy, node_item->node, NULL);
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	GtkCTree *tree = proxy;
	NSGtkTreeNode *node_item = (NSGtkTreeNode *)item;
	GdkColor color;
	int column,cell_type;
	float r,g,b,a;
	
	if(!node_item->node) return;
	column = [outlineView columnWithIdentifier:[tableColumn identifier]];
	cell_type = gtk_ctree_node_get_cell_type (tree, node_item->node, column);
	if(cell_type == GTK_CELL_TEXT)
	{
		if(GTK_CTREE_ROW (node_item->node)->row.fg_set)
		{
			color = GTK_CTREE_ROW (node_item->node)->row.foreground;
			r = (float)color.red/65535;
			g = (float)color.green/65535;
			b = (float)color.blue/65535;
		}
		else
			r = g = b = 0.0;
		a = 1.0;
		[cell setTextColor:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:a]];
	}
}


- (void)mouseDown:(NSEvent *)theEvent
{
    GtkCTree *tree = proxy;
	GtkCList *clist = tree;
	NSGtkTreeNode *node_item;
	GtkCTreeNode *node;
	GdkEventButton *event;
	NSPoint mouseLoc;
	int flags, row_clicked;
    
    mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    flags = [theEvent modifierFlags];
    // if the row was not selected, select it so dragging works properly
    row_clicked = [self rowAtPoint:mouseLoc];
    if(![self isRowSelected:row_clicked] && flags == 256 )
    {
    /*
    	gtk_clist_unselect_all(tree);
        node_item = [self itemAtRow:row_clicked];
        if(node_item)
        {
            node = node_item->node;
            clist->selection = g_list_append (clist->selection, node);

            [self selectRow:row_clicked byExtendingSelection:NO];
        }
    */
    [self tree_select_row:self];
    }
    [[self window] makeKeyAndOrderFront:self];
    [super mouseDown:theEvent];
	
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
        gtk_widget_grab_focus(proxy);
	
    gtk_widget_event (proxy, event);
	gdk_idle_hook();

}

- (void)mouseEntered:(NSEvent *)theEvent
{
	GdkEventCrossing *event;
	NSRect r = [self frame];

	if(![self canDraw]) return;
	event = (GdkEventCrossing *)gdk_event_new();
	event->type = GDK_ENTER_NOTIFY;
 	event->window = (GdkWindow *)proxy;
    event->send_event = FALSE;
	
printf("entered %f %f %f %f\n",r.origin.x, r.origin.y, r.size.width, r.size.height);
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

- (void)viewWillMoveToWindow:(NSWindow *)newWindow
{
	if(tag)
		[self removeTrackingRect:tag];
}

- (void)viewDidMoveToWindow
{
	NSPoint mouseLoc;
        NSRect frameRect = [self frame];
    
    if([self canDraw])
    {
        if(tag)
			[self removeTrackingRect:tag];
        tag = [self addTrackingRect:frameRect owner:self userData:NULL assumeInside:NO];
	}
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
}

-(void)thaw
{
	GtkCTree *tree = proxy;
	[self reloadData];
	gtk_ctree_pre_recursive(tree, NULL, ns_gtk_ctree_expand, NULL);
}
@end

@implementation NSGtkTreeNode

@end
