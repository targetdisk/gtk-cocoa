//
//  NSGtkBox.h
//  Gtk+
//
//  Created by Paolo Costabel on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


@interface NSGtkBox : NSBox 
{
	bool highlight;	
}

- (void)drawRect:(NSRect)aRect;

@end
