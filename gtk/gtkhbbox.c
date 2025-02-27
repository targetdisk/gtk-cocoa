/* GTK - The GIMP Toolkit
 * Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/*
 * Modified by the GTK+ Team and others 1997-1999.  See the AUTHORS
 * file for a list of people on the GTK+ Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GTK+ at ftp://ftp.gtk.org/pub/gtk/. 
 */

#include "gtkhbbox.h"


static void gtk_hbutton_box_class_init    (GtkHButtonBoxClass   *klass);
static void gtk_hbutton_box_init          (GtkHButtonBox        *box);
static void gtk_hbutton_box_size_request  (GtkWidget      *widget,
					   GtkRequisition *requisition);
static void gtk_hbutton_box_size_allocate (GtkWidget      *widget,
					   GtkAllocation  *allocation);

static gint default_spacing = 30;
static gint default_layout_style = GTK_BUTTONBOX_EDGE;

guint
gtk_hbutton_box_get_type (void)
{
  static guint hbutton_box_type = 0;

  if (!hbutton_box_type)
    {
      static const GtkTypeInfo hbutton_box_info =
      {
	"GtkHButtonBox",
	sizeof (GtkHButtonBox),
	sizeof (GtkHButtonBoxClass),
	(GtkClassInitFunc) gtk_hbutton_box_class_init,
	(GtkObjectInitFunc) gtk_hbutton_box_init,
	/* reserved_1 */ NULL,
        /* reserved_2 */ NULL,
        (GtkClassInitFunc) NULL,
      };

      hbutton_box_type = gtk_type_unique (gtk_button_box_get_type (), &hbutton_box_info);
    }

  return hbutton_box_type;
}

static void
gtk_hbutton_box_class_init (GtkHButtonBoxClass *class)
{
  GtkWidgetClass *widget_class;

  widget_class = (GtkWidgetClass*) class;

  widget_class->size_request = gtk_hbutton_box_size_request;
  widget_class->size_allocate = gtk_hbutton_box_size_allocate;
}

static void
gtk_hbutton_box_init (GtkHButtonBox *hbutton_box)
{
	/* button_box_init has done everything allready */
}

GtkWidget*
gtk_hbutton_box_new (void)
{
  GtkHButtonBox *hbutton_box;

  hbutton_box = gtk_type_new (gtk_hbutton_box_get_type ());

  return GTK_WIDGET (hbutton_box);
}


/* set default value for spacing */

void gtk_hbutton_box_set_spacing_default (gint spacing)
{
  default_spacing = spacing;
}


/* set default value for layout style */

void gtk_hbutton_box_set_layout_default (GtkButtonBoxStyle layout)
{
  g_return_if_fail (layout >= GTK_BUTTONBOX_DEFAULT_STYLE &&
		    layout <= GTK_BUTTONBOX_END);

  default_layout_style = layout;
}

/* get default value for spacing */

gint gtk_hbutton_box_get_spacing_default (void)
{
  return default_spacing;
}


/* get default value for layout style */

GtkButtonBoxStyle gtk_hbutton_box_get_layout_default (void)
{
  return default_layout_style;
}


  
static void
gtk_hbutton_box_size_request (GtkWidget      *widget,
			      GtkRequisition *requisition)
{
  GtkBox *box;
  GtkButtonBox *bbox;
  gint nvis_children;
  gint child_width;
  gint child_height;
  gint spacing;
  GtkButtonBoxStyle layout;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_HBUTTON_BOX (widget));
  g_return_if_fail (requisition != NULL);

  box = GTK_BOX (widget);
  bbox = GTK_BUTTON_BOX (widget);

  spacing = bbox->spacing != GTK_BUTTONBOX_DEFAULT
	  ? bbox->spacing : default_spacing;
  layout = bbox->layout_style != GTK_BUTTONBOX_DEFAULT_STYLE
	  ? bbox->layout_style : default_layout_style;
  
  gtk_button_box_child_requisition (widget,
				    &nvis_children,
				    &child_width,
				    &child_height);

  if (nvis_children == 0)
  {
    requisition->width = 0; 
    requisition->height = 0;
  }
  else
  {
    switch (layout)
    {
    case GTK_BUTTONBOX_SPREAD:
      requisition->width =
	      nvis_children*child_width + ((nvis_children+1)*spacing);
      break;
    case GTK_BUTTONBOX_EDGE:
    case GTK_BUTTONBOX_START:
    case GTK_BUTTONBOX_END:
      requisition->width = nvis_children*child_width + ((nvis_children-1)*spacing);
      break;
    default:
      g_assert_not_reached();
      break;
    }
	  
    requisition->height = child_height;
  }
	  
  requisition->width += GTK_CONTAINER (box)->border_width * 2;
  requisition->height += GTK_CONTAINER (box)->border_width * 2;
}



static void
gtk_hbutton_box_size_allocate (GtkWidget     *widget,
			       GtkAllocation *allocation)
{
  GtkButtonBox *box;
  GtkHButtonBox *hbox;
  GtkBoxChild *child;
  GList *children;
  GtkAllocation child_allocation;
  gint nvis_children;
  gint child_width;
  gint child_height;
  gint x = 0;
  gint y = 0;
  gint width;
  gint childspace;
  gint childspacing = 0;
  GtkButtonBoxStyle layout;
  gint spacing;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_HBUTTON_BOX (widget));
  g_return_if_fail (allocation != NULL);

  box = GTK_BUTTON_BOX (widget);
  hbox = GTK_HBUTTON_BOX (widget);
  spacing = box->spacing != GTK_BUTTONBOX_DEFAULT
	  ? box->spacing : default_spacing;
  layout = box->layout_style != GTK_BUTTONBOX_DEFAULT_STYLE
	  ? box->layout_style : default_layout_style;
  gtk_button_box_child_requisition (widget,
				    &nvis_children,
				    &child_width,
				    &child_height);
  widget->allocation = *allocation;
  width = allocation->width - GTK_CONTAINER (box)->border_width*2;
  switch (layout)
  {
  case GTK_BUTTONBOX_SPREAD:
    childspacing = (width - (nvis_children*child_width)) / (nvis_children+1);
    x = allocation->x + GTK_CONTAINER (box)->border_width + childspacing;
    break;
  case GTK_BUTTONBOX_EDGE:
    if (nvis_children >= 2)
    {
      childspacing =
	      (width - (nvis_children*child_width)) / (nvis_children-1);
      x = allocation->x + GTK_CONTAINER (box)->border_width;
    }
    else
      {
		      /* one or zero children, just center */
        childspacing = width;
	x = allocation->x + (allocation->width - child_width) / 2;
      }
    break;
  case GTK_BUTTONBOX_START:
    childspacing = spacing;
    x = allocation->x + GTK_CONTAINER (box)->border_width;
    break;
  case GTK_BUTTONBOX_END:
    childspacing = spacing;
    x = allocation->x + allocation->width - child_width * nvis_children
	    - spacing *(nvis_children-1)
	    - GTK_CONTAINER (box)->border_width;
    break;
  default:
    g_assert_not_reached();
    break;
  }
		  
  
  y = /*allocation->y +*/ (allocation->height - child_height) / 2;
  childspace = child_width + childspacing;

  children = GTK_BOX (box)->children;
	  
  while (children)
    {
      child = children->data;
      children = children->next;

      if (GTK_WIDGET_VISIBLE (child->widget))
	{
	  child_allocation.width = child_width;
	  child_allocation.height = child_height;
	  child_allocation.x = x;
	  child_allocation.y = y;
	  gtk_widget_size_allocate (child->widget, &child_allocation);
	  x += childspace;
	}
    }
}
  
