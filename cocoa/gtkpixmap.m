//
//  gtkbutton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

GtkWidget*
gtk_pixmap_new (GdkPixmap *val,
		GdkBitmap *mask)
{
  GtkPixmap *pixmap;
  NSImageView *img;
   
  g_return_val_if_fail (val != NULL, NULL);
  
  pixmap = gtk_type_new (gtk_pixmap_get_type ());
  
  pixmap->build_insensitive = TRUE;
  img = [[NSImageView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
  GTK_WIDGET(pixmap)->proxy = img;
  GTK_WIDGET(pixmap)->window = img;
  gtk_pixmap_set (pixmap, val, mask);
  
  return GTK_WIDGET (pixmap);
}

void
gtk_pixmap_set (GtkPixmap *pixmap,
		GdkPixmap *val,
		GdkBitmap *mask)
{
    GtkWidget *w = GTK_WIDGET(pixmap);
    NSImageView *iv = w->proxy;
    NSImage *img = val;
	[iv setImage:val];
    w->requisition.width = [img size].width;
    w->requisition.height = [img size].height;
}



