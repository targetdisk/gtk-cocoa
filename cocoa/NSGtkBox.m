//
//  NSGtkBox.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkBox.h"


@implementation NSGtkBox

- (void)drawRect:(NSRect)aRect
{
	NSRect frameRect;

	[super drawRect:aRect];
	if(highlight)
	{
        [[NSColor redColor]  set];
		frameRect = [self frame];
		frameRect.origin.x = 0;
		frameRect.origin.y = 0;

        NSFrameRect( frameRect );
	}
} 

@end

