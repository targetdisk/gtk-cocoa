//
//  NSGtkDnD.m
//  Gtk+
//
//  Created by Paolo Costabel on Tue Jan 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkDnD.h"


@implementation NSGtkDnD

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)isLocal
{
	return NSDragOperationCopy;
}

@end
