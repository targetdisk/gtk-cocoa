//
//  NSColorView.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Jan 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSColorView.h"


@implementation NSColorView

- (void)drawRect:(NSRect)aRect
{
        [bgColor set];
        NSRectFill( aRect );
} 

@end
