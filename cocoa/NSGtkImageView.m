//
//  NSGtkView.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Oct 05 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSGtkImageView.h"


@implementation NSGtkImageView

- (void)mouseDown:(NSEvent *)theEvent
{
	return [[self superview] mouseDown:theEvent];
}

@end
