//
//  gtktoolbar.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 17 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

#include <gtk/gtk.h>

typedef struct _GtkToolbarChildSpace GtkToolbarChildSpace;
struct _GtkToolbarChildSpace
{
  GtkToolbarChild child;

  gint alloc_x, alloc_y;
};

GtkWidget *
gtk_toolbar_insert_element (GtkToolbar          *toolbar,
			    GtkToolbarChildType  type,
			    GtkWidget           *widget,
			    const char          *text,
			    const char          *tooltip_text,
			    const char          *tooltip_private_text,
			    GtkWidget           *icon,
			    GtkSignalFunc        callback,
			    gpointer             user_data,
			    gint                 position)
{
  GtkToolbarChild *child;
  GtkWidget *vbox;

  g_return_val_if_fail (toolbar != NULL, NULL);
  g_return_val_if_fail (GTK_IS_TOOLBAR (toolbar), NULL);
  if (type == GTK_TOOLBAR_CHILD_WIDGET)
    {
      g_return_val_if_fail (widget != NULL, NULL);
      g_return_val_if_fail (GTK_IS_WIDGET (widget), NULL);
    }
  else if (type != GTK_TOOLBAR_CHILD_RADIOBUTTON)
    g_return_val_if_fail (widget == NULL, NULL);

  if (type == GTK_TOOLBAR_CHILD_SPACE)
    child = (GtkToolbarChild *) g_new (GtkToolbarChildSpace, 1);
  else
    child = g_new (GtkToolbarChild, 1);

  child->type = type;
  child->icon = NULL;
  child->label = NULL;

  switch (type)
    {
    case GTK_TOOLBAR_CHILD_SPACE:
      child->widget = NULL;
      ((GtkToolbarChildSpace *) child)->alloc_x =
	((GtkToolbarChildSpace *) child)->alloc_y = 0;
      break;

    case GTK_TOOLBAR_CHILD_WIDGET:
      child->widget = widget;
      break;

    case GTK_TOOLBAR_CHILD_BUTTON:
    case GTK_TOOLBAR_CHILD_TOGGLEBUTTON:
    case GTK_TOOLBAR_CHILD_RADIOBUTTON:
      if (type == GTK_TOOLBAR_CHILD_BUTTON)
	{
	  child->widget = gtk_button_new ();
	  gtk_button_set_relief (GTK_BUTTON (child->widget), toolbar->relief);
      [[child->widget->proxy cell] setImagePosition:NSImageAbove];
	}
      else if (type == GTK_TOOLBAR_CHILD_TOGGLEBUTTON)
	{
	  child->widget = gtk_toggle_button_new ();
	  gtk_button_set_relief (GTK_BUTTON (child->widget), toolbar->relief);
	  gtk_toggle_button_set_mode (GTK_TOGGLE_BUTTON (child->widget),
				      FALSE);
	}
      else
	{
	  child->widget = gtk_radio_button_new (widget
						? gtk_radio_button_group (GTK_RADIO_BUTTON (widget))
						: NULL);
	  gtk_button_set_relief (GTK_BUTTON (child->widget), toolbar->relief);
	  gtk_toggle_button_set_mode (GTK_TOGGLE_BUTTON (child->widget), FALSE);
	}

      GTK_WIDGET_UNSET_FLAGS (child->widget, GTK_CAN_FOCUS);

      if (callback)
	gtk_signal_connect (GTK_OBJECT (child->widget), "clicked",
			    callback, user_data);

      vbox = gtk_vbox_new (FALSE, 0);
      gtk_container_add (GTK_CONTAINER (child->widget), vbox);
      gtk_widget_show (vbox);

      if (text)
	{
        NSGtkButton *but = child->widget->proxy;
        [but setTitle:[NSString stringWithCString:text]];
//	  child->label = gtk_label_new (text);
//	  gtk_box_pack_end (GTK_BOX (vbox), child->label, FALSE, FALSE, 0);
//	  if (toolbar->style != GTK_TOOLBAR_ICONS)
//	    gtk_widget_show (child->label);
        
    }

      if (icon)
	{
		NSGtkButton *but = child->widget->proxy;
		NSImage *image = [icon->proxy image];
		NSImageRep *rep;

	  child->icon = GTK_WIDGET (icon);

//	  gtk_box_pack_end (GTK_BOX (vbox), child->icon, FALSE, FALSE, 0);
//	  if (toolbar->style != GTK_TOOLBAR_TEXT)
//	    gtk_widget_show (child->icon);

        if(GTK_IS_PIXMAP(icon))
			rep = [image bestRepresentationForDevice:nil];
         else
            rep = [[image image] bestRepresentationForDevice:nil];
        [but setImage:child->icon->proxy];
        [but setImage:[child->icon->proxy image]];
		[but sizeToFit];
        [but setBezelStyle:NSRegularSquareBezelStyle];
        but->width = [but frame].size.width;
        but->height = [but frame].size.height;
        if(tooltip_text)
			[but setToolTip:[NSString stringWithCString:tooltip_text]];
            
	}

      gtk_widget_show (child->widget);
      break;

    default:
      g_assert_not_reached ();
    }

  if ((type != GTK_TOOLBAR_CHILD_SPACE) && tooltip_text)
    gtk_tooltips_set_tip (toolbar->tooltips, child->widget,
			  tooltip_text, tooltip_private_text);

  toolbar->children = g_list_insert (toolbar->children, child, position);
  toolbar->num_children++;

  if (type != GTK_TOOLBAR_CHILD_SPACE)
    {
      gtk_widget_set_parent (child->widget, GTK_WIDGET (toolbar));

      if (GTK_WIDGET_REALIZED (child->widget->parent))
	gtk_widget_realize (child->widget);

      if (GTK_WIDGET_VISIBLE (child->widget->parent) && GTK_WIDGET_VISIBLE (child->widget))
	{
	  if (GTK_WIDGET_MAPPED (child->widget->parent))
	    gtk_widget_map (child->widget);

	  gtk_widget_queue_resize (child->widget);
	}
    }
  else
    gtk_widget_queue_resize (GTK_WIDGET (toolbar));

  return child->widget;
}



