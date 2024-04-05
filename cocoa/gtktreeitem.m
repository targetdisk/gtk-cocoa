//
//  gtktreeitem.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 17 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

GtkWidget*
gtk_tree_item_new_with_label (const gchar *label)
{
  GtkWidget *tree_item;
  GtkWidget *label_widget;

  tree_item = gtk_tree_item_new ();
  label_widget = gtk_label_new (label);
  gtk_misc_set_alignment (GTK_MISC (label_widget), 0.0, 0.5);

  [[label_widget->proxy cell] setHighlightsBy:NSNoCellMask];
  [[label_widget->proxy cell] setAlignment:NSLeftTextAlignment];
  gtk_container_add (GTK_CONTAINER (tree_item), label_widget);
  gtk_widget_show (label_widget);


  return tree_item;
}


