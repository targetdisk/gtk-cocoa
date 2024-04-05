//
//  GtkView.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 18 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface NSView(GtkView)

- (void)resizeWithOldSuperviewSize:(NSSize)oldFrameSize;
- (void)reshapeWithNewSize: (NSSize)newFrameSize;

@end
