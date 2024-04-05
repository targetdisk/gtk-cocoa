//
//  NSColorView.h
//  Gtk+
//
//  Created by Paolo Costabel on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface NSColorView : NSView 
{
	NSColor *bgColor;
}

- (void)drawRect:(NSRect)aRect;

@end
