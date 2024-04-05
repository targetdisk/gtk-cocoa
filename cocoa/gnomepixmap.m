//
//  gnomepixmap.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkImageView.h"

#include <gtk/gtk.h>

#include "gdk_imlib.h"
#include "gnome-pixmap.h"

void
gnome_pixmap_load_imlib (GnomePixmap *gpixmap, GdkImlibImage *image )
{
	GtkWidget *w = GTK_WIDGET(gpixmap);
	g_return_if_fail (gpixmap != NULL);
        g_return_if_fail (image != NULL);
	g_return_if_fail (GNOME_IS_PIXMAP (gpixmap));

	w->requisition.width = image->rgb_width;
	w->requisition.height = image->rgb_height;
	[w->proxy setImage:image->pixmap];
    gtk_widget_queue_resize(w);
    gdk_idle_hook();
}

void
gnome_pixmap_init (GnomePixmap *gpixmap)
{
	NSGtkImageView *imv;

	imv = [[NSGtkImageView alloc] initWithFrame:NSMakeRect(0,0,64,64)];
/*
	[imv setButtonType:NSOnOffButton];
	[[imv cell]  setEnabled:FALSE];
	[[imv cell]  setShowsStateBy:NSNoCellMask];
	[imv setBordered:FALSE];
	[[imv cell] setImageDimsWhenDisabled:FALSE];
*/
	[GTK_WIDGET(gpixmap)->proxy release];
	GTK_WIDGET(gpixmap)->proxy = imv;
}

void
gnome_pixmap_load_xpm_d (GnomePixmap *gpixmap,
			 const char **xpm_data)
{
	GdkPixmap *pixmap;
	GtkWidget *w = GTK_WIDGET(gpixmap);


	g_return_if_fail (gpixmap != NULL);
	g_return_if_fail (GNOME_IS_PIXMAP (gpixmap));

	pixmap = gdk_pixmap_create_from_xpm_d ( NULL, NULL, NULL, xpm_data);
	[w->proxy setImage:pixmap];
}

GnomePixmap *
gnome_pixmap_new_from_imlib_at_size (GdkImlibImage *image,
				int width, int height)
{
	GdkPixmap *pixmap;
	GnomePixmap *retval;
	GdkImlibImage *scaled;

	retval  = gtk_object_new (GNOME_TYPE_PIXMAP, NULL);
	scaled = gdk_imlib_clone_scaled_image(image, width, height);
	[GTK_WIDGET(retval)->proxy setImage:scaled->pixmap];
	return retval;
}

/**
 * gnome_pixmap_new_from_file:
 * @filename: The filename of the file to be loaded.
 *
 * Note that the new_from_file functions give you no way to detect errors;
 * if the file isn't found/loaded, you get an empty widget.
 * to detect errors just do:
 *
 * <programlisting>
 * pixbuf = gdk_pixbuf_new_from_file (filename);
 * if (pixbuf != NULL) {
 *         gpixmap = gtk_image_new_from_pixbuf (pixbuf);
 * } else {
 *         // handle your error...
 * }
 * </programlisting>
 * 
 * Return value: A newly allocated @GnomePixmap with the file at @filename loaded.
 **/
GtkWidget*
gnome_pixmap_new_from_file (const char *filename)
{
 	NSGtkImageView *imv;
	GtkPixmap *retval = gtk_object_new (GNOME_TYPE_PIXMAP, NULL);
    imv = [[NSGtkImageView alloc] initWithFrame:NSMakeRect(0,0,64,64)];
//	gtk_image_set_from_file (GTK_IMAGE (retval), filename);
	[GTK_WIDGET(retval)->proxy release];
	GTK_WIDGET(retval)->proxy = imv;
	retval->pixmap = gdk_pixmap_create_from_xpm(NULL, NULL,NULL,filename);
    if(!retval->pixmap)
	{
        GTK_WIDGET(retval)->proxy = retval->pixmap = gdk_pixmap_create_from_ppm(filename);
	}
	[imv setImage:retval->pixmap];
	return retval;
}

/**
 * gnome_pixmap_new_from_file_at_size:
 * @filename: The filename of the file to be loaded.
 * @width: The width to scale the image to.
 * @height: The height to scale the image to.
 *
 * Loads a new @GnomePixmap from a file, and scales it (if necessary) to the
 * size indicated by @height and @width.  If either are set to -1, then the
 * "natural" dimension of the image is used in place.  See
 * @gnome_pixmap_new_from_file for information on error handling.
 *
 * Return value: value: A newly allocated @GnomePixmap with the file at @filename loaded.
 **/
GtkWidget*
gnome_pixmap_new_from_file_at_size (const gchar *filename, gint width, gint height)
{
 	NSGtkImageView *imv;
	GtkPixmap *retval = gtk_object_new (GNOME_TYPE_PIXMAP, NULL);
    imv = [[NSGtkImageView alloc] initWithFrame:NSMakeRect(0,0,width,height)];
//	gtk_image_set_from_file (GTK_IMAGE (retval), filename);
	[GTK_WIDGET(retval)->proxy release];
	GTK_WIDGET(retval)->proxy = imv;
	retval->pixmap = gdk_pixmap_create_from_xpm(NULL, NULL,NULL,filename);
    if(!retval->pixmap)
        retval->pixmap = gdk_pixmap_create_from_ppm(filename);
	[retval->pixmap setSize:NSMakeSize(width,height)];
	[retval->pixmap setScalesWhenResized:YES];
	[imv setImage:retval->pixmap];
	return retval;
}


/**
 * gnome_pixmap_new_from_xpm_d_at_size:
 * @xpm_data: The xpm data to be loaded.
 * @width: The width to scale the image to.
 * @height: The height to scale the image to.
 *
 * Loads a new @GnomePixmap from the @xpm_data, and scales it (if necessary) to
 * the size indicated by @height and @width.  If either are set to -1, then the
 * "natural" dimension of the image is used in place.
 *
 * Return value: value: A newly allocated @GnomePixmap with the image from @xpm_data loaded.
 **/
GtkWidget*
gnome_pixmap_new_from_xpm_d_at_size (const char **xpm_data, int width, int height)
{
 	NSGtkImageView *imv;
	GtkPixmap *retval = gtk_object_new (GNOME_TYPE_PIXMAP, NULL);
    imv = [[NSGtkImageView alloc] initWithFrame:NSMakeRect(0,0,width,height)];
//	gtk_image_set_from_file (GTK_IMAGE (retval), filename);
	[GTK_WIDGET(retval)->proxy release];
	GTK_WIDGET(retval)->proxy = imv;
	retval->pixmap = gdk_pixmap_create_from_xpm_d(NULL, NULL,NULL, xpm_data);
	[retval->pixmap setSize:NSMakeSize(width,height)];
	[retval->pixmap setScalesWhenResized:YES];
	[imv setImage:retval->pixmap];
	return retval;
}

