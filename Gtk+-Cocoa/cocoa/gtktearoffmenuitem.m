//
//
//  gtktearoffmenuitem.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//
#import <AppKit/AppKit.h>
#import "NSGtkMenuItem.h"

#include <gtk/gtk.h>

void
gtk_tearoff_menu_item_init (GtkTearoffMenuItem *tearoff_menu_item)
{
  NSGtkMenuItem *l;
  tearoff_menu_item->torn_off = FALSE;

  l = [[NSGtkMenuItem alloc] initWithTitle:@"" action:@selector(activated:)  keyEquivalent:@""];
  [l setTarget:l];
  [GTK_WIDGET(tearoff_menu_item)->proxy release];
  GTK_WIDGET(tearoff_menu_item)->proxy = l;
  l->proxy = tearoff_menu_item;
}

