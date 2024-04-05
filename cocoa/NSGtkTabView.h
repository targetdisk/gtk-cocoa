//
//  NSGtkTabView.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 06 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

@interface NSGtkTabView : NSTabView 
{
@public
	GtkWidget *proxy;
	int current,max_tabs;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)computeMaxTabs:(bool)reverse;

@end
