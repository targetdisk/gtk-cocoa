//
//  NSGtkTabView.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 06 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSGtkTabView.h"


@implementation NSGtkTabView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)drawRect:(NSRect)aRect
{
	if([self tabViewType] == NSNoTabsNoBorder)
		NSDrawWindowBackground(aRect);
	else
	{
		if([self tabViewType] == NSNoTabsLineBorder)
			NSDrawWindowBackground(aRect);
		[super drawRect:aRect];
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	GtkNotebook *notebook;	
    NSGtkTabView *tab;
	int idx;

	tab = tabView;
	notebook = tab->proxy;
    if(!notebook) return;
	idx = [tab indexOfTabViewItem:tabViewItem];

	if(idx == current+tab->max_tabs)
	{
		tab->current+=tab->max_tabs;
	}
	if(idx == current-1)
	{
        [tab computeMaxTabs:TRUE];
		tab->current-=tab->max_tabs;    
    
		if(tab->current<0)
			tab->current=0;    
        
	}	

	gtk_notebook_set_page(notebook, idx);
	gdk_idle_hook();
}

-(void) setFrameOrigin:(NSPoint)origin
{
	[super setFrameOrigin:origin];
}

-(void) setFrameSize:(NSSize)size
{
    size.height = proxy->allocation.height;
    size.width = proxy->allocation.width;
	[super setFrameSize:size];
	[self computeMaxTabs:FALSE];
}


-(void) setFrame:(NSRect)frame
{
	[super setFrame:frame];
	[self computeMaxTabs:FALSE];
}

-(void) computeMaxTabs:(bool)reverse
{

	int i,tabs=0;
	float space;
	max_tabs = -1;
	space = ([self tabViewType] == NSLeftTabsBezelBorder ? [self frame].size.height : [self frame].size.width);
	space -=40;
    if(reverse)
        for(i= current; i> 0; i--)
        {
            space -= [[self tabViewItemAtIndex:i] sizeOfLabel:FALSE].width+25;
            if(space <=0) break;
            tabs++;
        }
    else
        for(i= current; i< [self numberOfTabViewItems]; i++)
        {
            space -= [[self tabViewItemAtIndex:i] sizeOfLabel:FALSE].width+25;
            if(space <=0) break;
            tabs++;
        }
	max_tabs = tabs;

//	max_tabs = ([self tabViewType] == NSLeftTabsBezelBorder ? 2 : 4);
}
@end
