//
//  NSGtkTabViewItem.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 06 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSGtkTabViewItem.h"
#import "NSGtkTabView.h"


@implementation NSGtkTabViewItem

- (void)drawRect:(NSRect)aRect
{

	//	[super drawRect:aRect];

}

- (void)drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)tabRect
{
	NSGtkTabView *tv;
	NSRect tabFrame;
	int index;
	
	
	tv = [self tabView];
	index = [tv indexOfTabViewItem:self];
	if(index < tv->current + tv->max_tabs && index >= tv->current) 
		[super drawLabel:shouldTruncateLabel inRect:tabRect];
	else if((index == tv->current+tv->max_tabs && !([tv tabViewType] == NSLeftTabsBezelBorder)) ||
			(index == tv->current-1 && [tv tabViewType] == NSLeftTabsBezelBorder) )
	{
		NSBezierPath *arrow = [NSBezierPath bezierPath];
		float x = tabRect.origin.x;
		float y = tabRect.origin.y;

		[arrow moveToPoint:NSMakePoint(x,y+4)];
		[arrow lineToPoint:NSMakePoint(x,y+12)];
		[arrow lineToPoint:NSMakePoint(x+8,y+8)];
		[arrow closePath];
		[arrow fill];
	}
	else if((index == tv->current-1 && !([tv tabViewType] == NSLeftTabsBezelBorder)) ||
			(index == tv->current+tv->max_tabs && [tv tabViewType] == NSLeftTabsBezelBorder) )
	{
		NSBezierPath *arrow = [NSBezierPath bezierPath];
		float x = tabRect.origin.x;
		float y = tabRect.origin.y;

		[arrow moveToPoint:NSMakePoint(x+8,y+4)];
		[arrow lineToPoint:NSMakePoint(x+8,y+12)];
		[arrow lineToPoint:NSMakePoint(x,y+8)];
		[arrow closePath];
		[arrow fill];
	}
		
}

- (NSString *)description
{
	return [self label];
}

- (NSSize)sizeOfLabel:(BOOL)shouldTruncateLabel
{
    NSGtkTabView *tabView;
	int index;

	tabView = [self tabView];
	if(tabView->max_tabs == -1)
		return [super sizeOfLabel:shouldTruncateLabel];

	index = [tabView indexOfTabViewItem:self];
	
	if(index < tabView->current -1 || index > tabView->current+tabView->max_tabs)
		return NSMakeSize(-20,0);
	else if (index == tabView->current -1 || index == tabView->current+tabView->max_tabs)
		return NSMakeSize(8,16);
	else
		return [super sizeOfLabel:shouldTruncateLabel];
}

@end
