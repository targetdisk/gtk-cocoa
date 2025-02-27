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

#include "gtkcheckbutton.h"
#include "gtklabel.h"


#define INDICATOR_SIZE     10
#define INDICATOR_SPACING  2

#define CHECK_BUTTON_CLASS(w)  GTK_CHECK_BUTTON_CLASS (GTK_OBJECT (w)->klass)


static void gtk_check_button_class_init          (GtkCheckButtonClass *klass);
static void gtk_check_button_init                (GtkCheckButton      *check_button);
static void gtk_check_button_draw                (GtkWidget           *widget,
						  GdkRectangle        *area);
static void gtk_check_button_draw_focus          (GtkWidget           *widget);
static void gtk_check_button_size_request        (GtkWidget           *widget,
						  GtkRequisition      *requisition);
static void gtk_check_button_size_allocate       (GtkWidget           *widget,
						  GtkAllocation       *allocation);
static gint gtk_check_button_expose              (GtkWidget           *widget,
						  GdkEventExpose      *event);
static void gtk_check_button_paint               (GtkWidget           *widget,
						  GdkRectangle        *area);
static void gtk_check_button_draw_indicator      (GtkCheckButton      *check_button,
						  GdkRectangle        *area);
static void gtk_real_check_button_draw_indicator (GtkCheckButton      *check_button,
						  GdkRectangle        *area);

static GtkToggleButtonClass *parent_class = NULL;


GtkType
gtk_check_button_get_type (void)
{
  static GtkType check_button_type = 0;
  
  if (!check_button_type)
    {
      static const GtkTypeInfo check_button_info =
      {
	"GtkCheckButton",
	sizeof (GtkCheckButton),
	sizeof (GtkCheckButtonClass),
	(GtkClassInitFunc) gtk_check_button_class_init,
	(GtkObjectInitFunc) gtk_check_button_init,
	/* reserved_1 */ NULL,
        /* reserved_2 */ NULL,
        (GtkClassInitFunc) NULL,
      };
      
      check_button_type = gtk_type_unique (GTK_TYPE_TOGGLE_BUTTON, &check_button_info);
    }
  
  return check_button_type;
}

static void
gtk_check_button_class_init (GtkCheckButtonClass *class)
{
  GtkWidgetClass *widget_class;
  
  widget_class = (GtkWidgetClass*) class;
  parent_class = gtk_type_class (gtk_toggle_button_get_type ());
  
  widget_class->draw = gtk_check_button_draw;
  widget_class->draw_focus = gtk_check_button_draw_focus;
  widget_class->size_request = gtk_check_button_size_request;
  widget_class->size_allocate = gtk_check_button_size_allocate;
  widget_class->expose_event = gtk_check_button_expose;
  
  class->indicator_size = INDICATOR_SIZE;
  class->indicator_spacing = INDICATOR_SPACING;
  class->draw_indicator = gtk_real_check_button_draw_indicator;
}

GtkWidget*
gtk_check_button_new (void)
{
  return gtk_widget_new (GTK_TYPE_CHECK_BUTTON, NULL);
}


/* This should only be called when toggle_button->draw_indicator
 * is true.
 */
static void
gtk_check_button_paint (GtkWidget    *widget,
			GdkRectangle *area)
{
  GtkCheckButton *check_button;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_CHECK_BUTTON (widget));
  
  check_button = GTK_CHECK_BUTTON (widget);
  
  if (GTK_WIDGET_DRAWABLE (widget))
    {
      gint border_width;
	  
      gtk_check_button_draw_indicator (check_button, area);
      
      border_width = GTK_CONTAINER (widget)->border_width;
#if 0
      if (GTK_WIDGET_HAS_FOCUS (widget))
	gtk_paint_focus (widget->style, widget->window,
			 NULL, widget, "checkbutton",
			 border_width + widget->allocation.x,
			 border_width + widget->allocation.y,
			 widget->allocation.width - 2 * border_width - 1,
			 widget->allocation.height - 2 * border_width - 1);
#endif
    }
}

static void
gtk_check_button_draw (GtkWidget    *widget,
		       GdkRectangle *area)
{
  GtkCheckButton *check_button;
  GtkToggleButton *toggle_button;
  GtkBin *bin;
  GdkRectangle child_area;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_CHECK_BUTTON (widget));
  g_return_if_fail (area != NULL);
  
  check_button = GTK_CHECK_BUTTON (widget);
  toggle_button = GTK_TOGGLE_BUTTON (widget);
  bin = GTK_BIN (widget);
  
  if (GTK_WIDGET_DRAWABLE (widget))
    {
      if (toggle_button->draw_indicator)
	{
	  gtk_check_button_paint (widget, area);

	  if (bin->child && gtk_widget_intersect (bin->child, area, &child_area))
	    gtk_widget_draw (bin->child, &child_area);
	}
      else
	{
	  if (GTK_WIDGET_CLASS (parent_class)->draw)
	    (* GTK_WIDGET_CLASS (parent_class)->draw) (widget, area);
	}
    }
}

static void
gtk_check_button_draw_focus (GtkWidget *widget)
{
#if 0
  gint border_width;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_CHECK_BUTTON (widget));
  
  border_width = GTK_CONTAINER (widget)->border_width;
  gtk_widget_queue_clear_area (widget->parent, 
			       border_width + widget->allocation.x,
			       border_width + widget->allocation.y,
			       widget->allocation.width - 2 * border_width,
			       widget->allocation.height - 2 * border_width);
#endif
}

void
_gtk_check_button_get_props (GtkCheckButton *check_button,
			     gint           *indicator_size,
			     gint           *indicator_spacing)
{
#if 0
  GtkWidget *widget =  GTK_WIDGET (check_button);
  
  if (indicator_size)
    *indicator_size = gtk_style_get_prop_experimental (widget->style,
						       "GtkCheckButton::indicator_size",
						       CHECK_BUTTON_CLASS (widget)->indicator_size);
  if (indicator_spacing)
    *indicator_spacing = gtk_style_get_prop_experimental (widget->style,
							  "GtkCheckButton::indicator_spacing",
							  CHECK_BUTTON_CLASS (widget)->indicator_spacing);
#endif
}

static gint
gtk_check_button_expose (GtkWidget      *widget,
			 GdkEventExpose *event)
{
#if 0
  GtkCheckButton *check_button;
  GtkToggleButton *toggle_button;
  GtkBin *bin;
  GdkEventExpose child_event;
  
  g_return_val_if_fail (widget != NULL, FALSE);
  g_return_val_if_fail (GTK_IS_CHECK_BUTTON (widget), FALSE);
  g_return_val_if_fail (event != NULL, FALSE);
  
  check_button = GTK_CHECK_BUTTON (widget);
  toggle_button = GTK_TOGGLE_BUTTON (widget);
  bin = GTK_BIN (widget);
  
  if (GTK_WIDGET_DRAWABLE (widget))
    {
      if (toggle_button->draw_indicator)
	{
	  gtk_check_button_paint (widget, &event->area);
	  
	  child_event = *event;
	  if (bin->child && GTK_WIDGET_NO_WINDOW (bin->child) &&
	      gtk_widget_intersect (bin->child, &event->area, &child_event.area))
	    gtk_widget_event (bin->child, (GdkEvent*) &child_event);
	}
      else
	{
	  if (GTK_WIDGET_CLASS (parent_class)->expose_event)
	    (* GTK_WIDGET_CLASS (parent_class)->expose_event) (widget, event);
	}
    }
#endif  
  return FALSE;
}


static void
gtk_check_button_draw_indicator (GtkCheckButton *check_button,
				 GdkRectangle   *area)
{
  GtkCheckButtonClass *class;
  
  g_return_if_fail (check_button != NULL);
  g_return_if_fail (GTK_IS_CHECK_BUTTON (check_button));
  
  class = CHECK_BUTTON_CLASS (check_button);
  
  if (class->draw_indicator)
    (* class->draw_indicator) (check_button, area);
}


