//
//  gnomecolorpicker.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSGnomeColorPicker.h"

#include <gtk/gtk.h>
#include "gnome-color-picker.h"

void
gnome_color_picker_instance_init (GnomeColorPicker *cp)
{
	NSGnomeColorPicker *ncp;
	GtkWidget *alignment;
	GtkWidget *frame;

	/* Create the widgets */
	cp->_priv = g_new0(GnomeColorPickerPrivate, 1);
	/* Start with opaque black, dither on, alpha disabled */

	cp->_priv->r = 0.0;
	cp->_priv->g = 0.0;
	cp->_priv->b = 0.0;
	cp->_priv->a = 1.0;
	cp->_priv->dither = TRUE;
	cp->_priv->use_alpha = FALSE;

	ncp = [[NSGnomeColorPicker alloc] initWithFrame:NSMakeRect(0,0,10,10)];
//	[ncp setBordered:FALSE];
    [ncp setAction: @selector (color_set:)];
    [ncp setTarget: ncp];
	ncp->proxy = cp;
    [GTK_WIDGET(cp)->proxy release];
    GTK_WIDGET(cp)->proxy = ncp;
#if 0
	/*
	 * The application may very well override these.
	 */
	_add_atk_name_desc (GTK_WIDGET (cp),
			    _("Color Selector"),
			    _("Open a dialog to specify the color"));

	alignment = gtk_alignment_new (0.5, 0.5, 0.0, 0.0);
	gtk_container_set_border_width (GTK_CONTAINER (alignment), COLOR_PICKER_PAD);
	gtk_container_add (GTK_CONTAINER (cp), alignment);
	gtk_widget_show (alignment);

	frame = gtk_frame_new (NULL);
	gtk_frame_set_shadow_type (GTK_FRAME (frame), GTK_SHADOW_ETCHED_OUT);
	gtk_container_add (GTK_CONTAINER (alignment), frame);
	gtk_widget_show (frame);

	gtk_widget_push_colormap (gdk_rgb_get_colormap ());

	cp->_priv->drawing_area = gtk_drawing_area_new ();

	gtk_widget_set_size_request (cp->_priv->drawing_area, COLOR_PICKER_WIDTH, COLOR_PICKER_HEIGHT);
	g_signal_connect (cp->_priv->drawing_area, "expose_event",
			  G_CALLBACK (expose_event), cp);
	gtk_container_add (GTK_CONTAINER (frame), cp->_priv->drawing_area);
	gtk_widget_show (cp->_priv->drawing_area);

	cp->_priv->title = g_strdup (_("Pick a color")); /* default title */

	/* Create the buffer for the image so that we can create an image.  Also create the
	 * picker's pixmap.
	 */

	cp->_priv->pixbuf = gdk_pixbuf_new (GDK_COLORSPACE_RGB, FALSE, 8, COLOR_PICKER_WIDTH, COLOR_PICKER_HEIGHT);

	cp->_priv->gc = NULL;
	gtk_widget_pop_colormap ();



	gtk_drag_dest_set (GTK_WIDGET (cp),
			   GTK_DEST_DEFAULT_MOTION |
			   GTK_DEST_DEFAULT_HIGHLIGHT |
			   GTK_DEST_DEFAULT_DROP,
			   drop_types, 1, GDK_ACTION_COPY);
	gtk_drag_source_set (GTK_WIDGET(cp),
			     GDK_BUTTON1_MASK|GDK_BUTTON3_MASK,
			     drop_types, 1,
			     GDK_ACTION_COPY);
	g_signal_connect (cp, "drag_data_received",
			  G_CALLBACK (drag_data_received), cp);
	g_signal_connect (cp, "drag_data_get",
			  G_CALLBACK (drag_data_get), cp);
#endif
}

/**
 * gnome_color_picker_set_d
 * @cp: Pointer to GNOME color picker widget.
 * @r: Red color component, values are in [0.0, 1.0]
 * @g: Green color component, values are in [0.0, 1.0]
 * @b: Blue color component, values are in [0.0, 1.0]
 * @a: Alpha component, values are in [0.0, 1.0]
 *
 * Description:
 * Set color shown in the color picker widget using floating point values.
 */

void
gnome_color_picker_set_d (GnomeColorPicker *cp, gdouble r, gdouble g, gdouble b, gdouble a)
{
	NSGnomeColorPicker *ncp;

	g_return_if_fail (cp != NULL);
	g_return_if_fail (GNOME_IS_COLOR_PICKER (cp));
	g_return_if_fail ((r >=	0.0) &&	(r <= 1.0));
	g_return_if_fail ((g >=	0.0) &&	(g <= 1.0));
	g_return_if_fail ((b >=	0.0) && (b <= 1.0));
	g_return_if_fail ((a >=	0.0) && (a <= 1.0));

	cp->_priv->r = r;
	cp->_priv->g = g;
	cp->_priv->b = b;
	cp->_priv->a = a;
	ncp = (NSGnomeColorPicker *)GTK_WIDGET(cp)->proxy;
	[ncp setColor:[NSColor colorWithCalibratedRed:r green:g blue:b alpha:a]];
}


