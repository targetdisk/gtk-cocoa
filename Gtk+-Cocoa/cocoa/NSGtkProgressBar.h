//
//  NSGtkProgressBar.h
//  Gtk+
//
//  Created by Paolo Costabel on Sun Sep 22 2002.
//  Copyright (c) 2002 Zebra Development All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

@interface NSGtkProgressBar : NSProgressIndicator
{
@public
    GtkWidget *proxy;
}

@end
