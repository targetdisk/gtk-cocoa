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

#include "gtkscrolledwindow.h"
#include "gtksignal.h"


/* scrolled window policy and size requisition handling:
 *
 * gtk size requisition works as follows:
 *   a widget upon size-request reports the width and height that it finds
 *   to be best suited to display its contents, including children.
 *   the width and/or height reported from a widget upon size requisition
 *   may be overidden by the user by specifying a width and/or height
 *   other than 0 through gtk_widget_set_usize().
 *
 * a scrolled window needs (for imlementing all three policy types) to
 * request its width and height based on two different rationales.
 * 1)   the user wants the scrolled window to just fit into the space
 *      that it gets allocated for a specifc dimension.
 * 1.1) this does not apply if the user specified a concrete value
 *      value for that specific dimension by either specifying usize for the
 *      scrolled window or for its child.
 * 2)   the user wants the scrolled window to take as much space up as
 *      is desired by the child for a specifc dimension (i.e. POLICY_NEVER).
 *
 * also, kinda obvious:
 * 3)   a user would certainly not have choosen a scrolled window as a container
 *      for the child, if the resulting allocation takes up more space than the
 *      child would have allocated without the scrolled window.
 *
 * conclusions:
 * A) from 1) follows: the scrolled window shouldn't request more space for a
 *    specifc dimension than is required at minimum.
 * B) from 1.1) follows: the requisition may be overidden by usize of the scrolled
 *    window (done automatically) or by usize of the child (needs to be checked).
 * C) from 2) follows: for POLICY_NEVER, the scrolled window simply reports the
 *    child's dimension.
 * D) from 3) follows: the scrolled window child's minimum width and minimum height
 *    under A) at least correspond to the space taken up by its scrollbars.
 */

#define SCROLLBAR_SPACING(w) (GTK_SCROLLED_WINDOW_CLASS (GTK_OBJECT (w)->klass)->scrollbar_spacing)

#define DEFAULT_SCROLLBAR_SPACING  3

enum {
  ARG_0,
  ARG_HADJUSTMENT,
  ARG_VADJUSTMENT,
  ARG_HSCROLLBAR_POLICY,
  ARG_VSCROLLBAR_POLICY,
  ARG_WINDOW_PLACEMENT
};


static void gtk_scrolled_window_class_init         (GtkScrolledWindowClass *klass);
static void gtk_scrolled_window_init               (GtkScrolledWindow      *scrolled_window);
static void gtk_scrolled_window_set_arg		   (GtkObject              *object,
						    GtkArg                 *arg,
						    guint                   arg_id);
static void gtk_scrolled_window_get_arg		   (GtkObject              *object,
						    GtkArg                 *arg,
						    guint                   arg_id);
static void gtk_scrolled_window_destroy            (GtkObject              *object);
static void gtk_scrolled_window_finalize           (GtkObject              *object);
static void gtk_scrolled_window_map                (GtkWidget              *widget);
static void gtk_scrolled_window_unmap              (GtkWidget              *widget);
static void gtk_scrolled_window_draw               (GtkWidget              *widget,
						    GdkRectangle           *area);
static void gtk_scrolled_window_size_request       (GtkWidget              *widget,
						    GtkRequisition         *requisition);
static void gtk_scrolled_window_size_allocate      (GtkWidget              *widget,
						    GtkAllocation          *allocation);
static void gtk_scrolled_window_add                (GtkContainer           *container,
						    GtkWidget              *widget);
static void gtk_scrolled_window_remove             (GtkContainer           *container,
						    GtkWidget              *widget);
static void gtk_scrolled_window_forall             (GtkContainer           *container,
						    gboolean		    include_internals,
						    GtkCallback             callback,
						    gpointer                callback_data);
static void gtk_scrolled_window_relative_allocation(GtkWidget              *widget,
						    GtkAllocation          *allocation);
void gtk_scrolled_window_adjustment_changed (GtkAdjustment          *adjustment,
						    gpointer                data);


static GtkContainerClass *parent_class = NULL;


GtkType
gtk_scrolled_window_get_type (void)
{
  static GtkType scrolled_window_type = 0;

  if (!scrolled_window_type)
    {
      static const GtkTypeInfo scrolled_window_info =
      {
	"GtkScrolledWindow",
	sizeof (GtkScrolledWindow),
	sizeof (GtkScrolledWindowClass),
	(GtkClassInitFunc) gtk_scrolled_window_class_init,
	(GtkObjectInitFunc) gtk_scrolled_window_init,
	/* reserved_1 */ NULL,
        /* reserved_2 */ NULL,
        (GtkClassInitFunc) NULL,
      };

      scrolled_window_type = gtk_type_unique (GTK_TYPE_BIN, &scrolled_window_info);
    }

  return scrolled_window_type;
}

static void
gtk_scrolled_window_class_init (GtkScrolledWindowClass *class)
{
  GtkObjectClass *object_class;
  GtkWidgetClass *widget_class;
  GtkContainerClass *container_class;

  object_class = (GtkObjectClass*) class;
  widget_class = (GtkWidgetClass*) class;
  container_class = (GtkContainerClass*) class;
  parent_class = gtk_type_class (GTK_TYPE_BIN);

  gtk_object_add_arg_type ("GtkScrolledWindow::hadjustment",
			   GTK_TYPE_ADJUSTMENT,
			   GTK_ARG_READWRITE | GTK_ARG_CONSTRUCT,
			   ARG_HADJUSTMENT);
  gtk_object_add_arg_type ("GtkScrolledWindow::vadjustment",
			   GTK_TYPE_ADJUSTMENT,
			   GTK_ARG_READWRITE | GTK_ARG_CONSTRUCT,
			   ARG_VADJUSTMENT);
  gtk_object_add_arg_type ("GtkScrolledWindow::hscrollbar_policy",
			   GTK_TYPE_POLICY_TYPE,
			   GTK_ARG_READWRITE,
			   ARG_HSCROLLBAR_POLICY);
  gtk_object_add_arg_type ("GtkScrolledWindow::vscrollbar_policy",
			   GTK_TYPE_POLICY_TYPE,
			   GTK_ARG_READWRITE,
			   ARG_VSCROLLBAR_POLICY);
  gtk_object_add_arg_type ("GtkScrolledWindow::window_placement",
			   GTK_TYPE_CORNER_TYPE,
			   GTK_ARG_READWRITE,
			   ARG_WINDOW_PLACEMENT);

  object_class->set_arg = gtk_scrolled_window_set_arg;
  object_class->get_arg = gtk_scrolled_window_get_arg;
  object_class->destroy = gtk_scrolled_window_destroy;
  object_class->finalize = gtk_scrolled_window_finalize;

  widget_class->map = gtk_scrolled_window_map;
  widget_class->unmap = gtk_scrolled_window_unmap;
  widget_class->draw = gtk_scrolled_window_draw;
  widget_class->size_request = gtk_scrolled_window_size_request;
  widget_class->size_allocate = gtk_scrolled_window_size_allocate;

  container_class->add = gtk_scrolled_window_add;
  container_class->remove = gtk_scrolled_window_remove;
  container_class->forall = gtk_scrolled_window_forall;

  class->scrollbar_spacing = DEFAULT_SCROLLBAR_SPACING;
}

static void
gtk_scrolled_window_set_arg (GtkObject        *object,
			     GtkArg           *arg,
			     guint             arg_id)
{
  GtkScrolledWindow *scrolled_window;

  scrolled_window = GTK_SCROLLED_WINDOW (object);

  switch (arg_id)
    {
    case ARG_HADJUSTMENT:
      gtk_scrolled_window_set_hadjustment (scrolled_window, GTK_VALUE_POINTER (*arg));
      break;
    case ARG_VADJUSTMENT:
      gtk_scrolled_window_set_vadjustment (scrolled_window, GTK_VALUE_POINTER (*arg));
      break;
    case ARG_HSCROLLBAR_POLICY:
      gtk_scrolled_window_set_policy (scrolled_window,
				      GTK_VALUE_ENUM (*arg),
				      scrolled_window->vscrollbar_policy);
      break;
    case ARG_VSCROLLBAR_POLICY:
      gtk_scrolled_window_set_policy (scrolled_window,
				      scrolled_window->hscrollbar_policy,
				      GTK_VALUE_ENUM (*arg));
      break;
    case ARG_WINDOW_PLACEMENT:
      gtk_scrolled_window_set_placement (scrolled_window,
					 GTK_VALUE_ENUM (*arg));
      break;
    default:
      break;
    }
}

static void
gtk_scrolled_window_get_arg (GtkObject        *object,
			     GtkArg           *arg,
			     guint             arg_id)
{
  GtkScrolledWindow *scrolled_window;

  scrolled_window = GTK_SCROLLED_WINDOW (object);

  switch (arg_id)
    {
    case ARG_HADJUSTMENT:
      GTK_VALUE_POINTER (*arg) = gtk_scrolled_window_get_hadjustment (scrolled_window);
      break;
    case ARG_VADJUSTMENT:
      GTK_VALUE_POINTER (*arg) = gtk_scrolled_window_get_vadjustment (scrolled_window);
      break;
    case ARG_HSCROLLBAR_POLICY:
      GTK_VALUE_ENUM (*arg) = scrolled_window->hscrollbar_policy;
      break;
    case ARG_VSCROLLBAR_POLICY:
      GTK_VALUE_ENUM (*arg) = scrolled_window->vscrollbar_policy;
      break;
    case ARG_WINDOW_PLACEMENT:
      GTK_VALUE_ENUM (*arg) = scrolled_window->window_placement;
      break;
    default:
      arg->type = GTK_TYPE_INVALID;
      break;
    }
}

GtkWidget*
gtk_scrolled_window_new (GtkAdjustment *hadjustment,
			 GtkAdjustment *vadjustment)
{
  GtkWidget *scrolled_window;

  if (hadjustment)
    g_return_val_if_fail (GTK_IS_ADJUSTMENT (hadjustment), NULL);

  if (vadjustment)
    g_return_val_if_fail (GTK_IS_ADJUSTMENT (vadjustment), NULL);

  scrolled_window = gtk_widget_new (GTK_TYPE_SCROLLED_WINDOW,
				    "hadjustment", hadjustment,
				    "vadjustment", vadjustment,
				    NULL);

  return scrolled_window;
}

GtkAdjustment*
gtk_scrolled_window_get_hadjustment (GtkScrolledWindow *scrolled_window)
{
  g_return_val_if_fail (scrolled_window != NULL, NULL);
  g_return_val_if_fail (GTK_IS_SCROLLED_WINDOW (scrolled_window), NULL);

  return (scrolled_window->hscrollbar ?
	  gtk_range_get_adjustment (GTK_RANGE (scrolled_window->hscrollbar)) :
	  NULL);
}

GtkAdjustment*
gtk_scrolled_window_get_vadjustment (GtkScrolledWindow *scrolled_window)
{
  g_return_val_if_fail (scrolled_window != NULL, NULL);
  g_return_val_if_fail (GTK_IS_SCROLLED_WINDOW (scrolled_window), NULL);

  return (scrolled_window->vscrollbar ?
	  gtk_range_get_adjustment (GTK_RANGE (scrolled_window->vscrollbar)) :
	  NULL);
}

void
gtk_scrolled_window_set_placement (GtkScrolledWindow *scrolled_window,
				   GtkCornerType      window_placement)
{
  g_return_if_fail (scrolled_window != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (scrolled_window));

  if (scrolled_window->window_placement != window_placement)
    {
      scrolled_window->window_placement = window_placement;

      gtk_widget_queue_resize (GTK_WIDGET (scrolled_window));
    }
}

static void
gtk_scrolled_window_destroy (GtkObject *object)
{
  GtkScrolledWindow *scrolled_window;

  g_return_if_fail (object != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (object));

  scrolled_window = GTK_SCROLLED_WINDOW (object);

  gtk_widget_unparent (scrolled_window->hscrollbar);
  gtk_widget_unparent (scrolled_window->vscrollbar);
  gtk_widget_destroy (scrolled_window->hscrollbar);
  gtk_widget_destroy (scrolled_window->vscrollbar);

  GTK_OBJECT_CLASS (parent_class)->destroy (object);
}

static void
gtk_scrolled_window_finalize (GtkObject *object)
{
  GtkScrolledWindow *scrolled_window;

  scrolled_window = GTK_SCROLLED_WINDOW (object);

  gtk_widget_unref (scrolled_window->hscrollbar);
  gtk_widget_unref (scrolled_window->vscrollbar);

  GTK_OBJECT_CLASS (parent_class)->finalize (object);
}

static void
gtk_scrolled_window_map (GtkWidget *widget)
{
  GtkScrolledWindow *scrolled_window;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (widget));

  scrolled_window = GTK_SCROLLED_WINDOW (widget);

  /* chain parent class handler to map self and child */
  GTK_WIDGET_CLASS (parent_class)->map (widget);
  
  if (GTK_WIDGET_VISIBLE (scrolled_window->hscrollbar) &&
      !GTK_WIDGET_MAPPED (scrolled_window->hscrollbar))
    gtk_widget_map (scrolled_window->hscrollbar);
  
  if (GTK_WIDGET_VISIBLE (scrolled_window->vscrollbar) &&
      !GTK_WIDGET_MAPPED (scrolled_window->vscrollbar))
    gtk_widget_map (scrolled_window->vscrollbar);
}

static void
gtk_scrolled_window_unmap (GtkWidget *widget)
{
  GtkScrolledWindow *scrolled_window;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (widget));

  scrolled_window = GTK_SCROLLED_WINDOW (widget);

  /* chain parent class handler to unmap self and child */
  GTK_WIDGET_CLASS (parent_class)->unmap (widget);
  
  if (GTK_WIDGET_MAPPED (scrolled_window->hscrollbar))
    gtk_widget_unmap (scrolled_window->hscrollbar);
  
  if (GTK_WIDGET_MAPPED (scrolled_window->vscrollbar))
    gtk_widget_unmap (scrolled_window->vscrollbar);
}

static void
gtk_scrolled_window_draw (GtkWidget    *widget,
			  GdkRectangle *area)
{
  GtkScrolledWindow *scrolled_window;
  GtkBin *bin;
  GdkRectangle child_area;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (widget));
  g_return_if_fail (area != NULL);
  
  scrolled_window = GTK_SCROLLED_WINDOW (widget);
  bin = GTK_BIN (widget);

  if (bin->child && GTK_WIDGET_VISIBLE (bin->child) &&
      gtk_widget_intersect (bin->child, area, &child_area))
    gtk_widget_draw (bin->child, &child_area);
  
  if (GTK_WIDGET_VISIBLE (scrolled_window->hscrollbar) &&
      gtk_widget_intersect (scrolled_window->hscrollbar, area, &child_area))
    gtk_widget_draw (scrolled_window->hscrollbar, &child_area);
  
  if (GTK_WIDGET_VISIBLE (scrolled_window->vscrollbar) &&
      gtk_widget_intersect (scrolled_window->vscrollbar, area, &child_area))
    gtk_widget_draw (scrolled_window->vscrollbar, &child_area);
}

static void
gtk_scrolled_window_forall (GtkContainer *container,
			    gboolean	  include_internals,
			    GtkCallback   callback,
			    gpointer      callback_data)
{
  g_return_if_fail (container != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (container));
  g_return_if_fail (callback != NULL);

  GTK_CONTAINER_CLASS (parent_class)->forall (container,
					      include_internals,
					      callback,
					      callback_data);
  if (include_internals)
    {
      GtkScrolledWindow *scrolled_window;

      scrolled_window = GTK_SCROLLED_WINDOW (container);
      
      if (scrolled_window->vscrollbar)
	callback (scrolled_window->vscrollbar, callback_data);
      if (scrolled_window->hscrollbar)
	callback (scrolled_window->hscrollbar, callback_data);
    }
}


void
gtk_scrolled_window_adjustment_changed (GtkAdjustment *adjustment,
					gpointer       data)
{
  GtkScrolledWindow *scrolled_win;

  g_return_if_fail (adjustment != NULL);
  g_return_if_fail (data != NULL);

  scrolled_win = GTK_SCROLLED_WINDOW (data);

  if (adjustment == gtk_range_get_adjustment (GTK_RANGE (scrolled_win->hscrollbar)))
    {
      if (scrolled_win->hscrollbar_policy == GTK_POLICY_AUTOMATIC)
	{
	  gboolean visible;
	  
	  visible = scrolled_win->hscrollbar_visible;
	  scrolled_win->hscrollbar_visible = (adjustment->upper - adjustment->lower >
					      adjustment->page_size);
	  if (scrolled_win->hscrollbar_visible != visible)
	    gtk_widget_queue_resize (GTK_WIDGET (scrolled_win));
	}
    }
  else if (adjustment == gtk_range_get_adjustment (GTK_RANGE (scrolled_win->vscrollbar)))
    {
      if (scrolled_win->vscrollbar_policy == GTK_POLICY_AUTOMATIC)
	{
	  gboolean visible;

	  visible = scrolled_win->vscrollbar_visible;
	  scrolled_win->vscrollbar_visible = (adjustment->upper - adjustment->lower >
					      adjustment->page_size);
	  if (scrolled_win->vscrollbar_visible != visible)
	    gtk_widget_queue_resize (GTK_WIDGET (scrolled_win));
	}
    }
}

static void
gtk_scrolled_window_remove (GtkContainer *container,
			    GtkWidget    *child)
{
  g_return_if_fail (container != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (container));
  g_return_if_fail (child != NULL);
  g_return_if_fail (GTK_BIN (container)->child == child);
  
  gtk_widget_set_scroll_adjustments (child, NULL, NULL);

  /* chain parent class handler to remove child */
  GTK_CONTAINER_CLASS (parent_class)->remove (container, child);
}

void
gtk_scrolled_window_add_with_viewport (GtkScrolledWindow *scrolled_window,
				       GtkWidget         *child)
{
  GtkBin *bin;
  GtkWidget *viewport;

  g_return_if_fail (scrolled_window != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (scrolled_window));
  g_return_if_fail (child != NULL);
  g_return_if_fail (GTK_IS_WIDGET (child));
  g_return_if_fail (child->parent == NULL);

  bin = GTK_BIN (scrolled_window);

  if (bin->child != NULL)
    {
      g_return_if_fail (GTK_IS_VIEWPORT (bin->child));
      g_return_if_fail (GTK_BIN (bin->child)->child == NULL);

      viewport = bin->child;
    }
  else
    {
      viewport =
        gtk_viewport_new (gtk_scrolled_window_get_hadjustment (scrolled_window),
			  gtk_scrolled_window_get_vadjustment (scrolled_window));
      gtk_container_add (GTK_CONTAINER (scrolled_window), viewport);
    }

  gtk_widget_show (viewport);
  gtk_container_add (GTK_CONTAINER (viewport), child);
}
