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

#include <string.h>
#include "gtkbutton.h"
#include "gtklabel.h"
#include "gtkmain.h"
#include "gtksignal.h"


#define CHILD_SPACING     1
#define DEFAULT_SPACING   7


enum {
  PRESSED,
  RELEASED,
  CLICKED,
  ENTER,
  LEAVE,
  LAST_SIGNAL
};
enum {
  ARG_0,
  ARG_LABEL,
  ARG_RELIEF
};



static void gtk_button_class_init     (GtkButtonClass   *klass);
static void gtk_button_init           (GtkButton        *button);
static void gtk_button_set_arg        (GtkObject        *object,
				       GtkArg           *arg,
				       guint		 arg_id);
static void gtk_button_get_arg        (GtkObject        *object,
				       GtkArg           *arg,
				       guint		 arg_id);
static void gtk_button_realize        (GtkWidget        *widget);
static void gtk_button_size_request   (GtkWidget        *widget,
				       GtkRequisition   *requisition);
static void gtk_button_size_allocate  (GtkWidget        *widget,
				       GtkAllocation    *allocation);
static void gtk_button_paint          (GtkWidget        *widget,
				       GdkRectangle     *area);
static void gtk_button_draw           (GtkWidget        *widget,
				       GdkRectangle     *area);
static void gtk_button_draw_focus     (GtkWidget        *widget);
static void gtk_button_draw_default   (GtkWidget        *widget);
static gint gtk_button_expose         (GtkWidget        *widget,
				       GdkEventExpose   *event);
static gint gtk_button_button_press   (GtkWidget        *widget,
				       GdkEventButton   *event);
static gint gtk_button_button_release (GtkWidget        *widget,
				       GdkEventButton   *event);
static gint gtk_button_enter_notify   (GtkWidget        *widget,
				       GdkEventCrossing *event);
static gint gtk_button_leave_notify   (GtkWidget        *widget,
				       GdkEventCrossing *event);
static gint gtk_button_focus_in       (GtkWidget        *widget,
				       GdkEventFocus    *event);
static gint gtk_button_focus_out      (GtkWidget        *widget,
				       GdkEventFocus    *event);
static void gtk_button_add            (GtkContainer     *container,
				       GtkWidget        *widget);
static void gtk_button_remove         (GtkContainer     *container,
				       GtkWidget        *widget);
static void gtk_real_button_pressed   (GtkButton        *button);
static void gtk_real_button_released  (GtkButton        *button);
static void gtk_real_button_enter     (GtkButton        *button);
static void gtk_real_button_leave     (GtkButton        *button);
static GtkType gtk_button_child_type  (GtkContainer     *container);


static GtkBinClass *parent_class = NULL;
static guint button_signals[LAST_SIGNAL] = { 0 };


GtkType
gtk_button_get_type (void)
{
  static GtkType button_type = 0;

  if (!button_type)
    {
      static const GtkTypeInfo button_info =
      {
	"GtkButton",
	sizeof (GtkButton),
	sizeof (GtkButtonClass),
	(GtkClassInitFunc) gtk_button_class_init,
	(GtkObjectInitFunc) gtk_button_init,
        /* reserved_1 */ NULL,
	/* reserved_2 */ NULL,
	(GtkClassInitFunc) NULL,
      };

      button_type = gtk_type_unique (GTK_TYPE_BIN, &button_info);
      gtk_type_set_chunk_alloc (button_type, 16);
    }

  return button_type;
}

static void
gtk_button_class_init (GtkButtonClass *klass)
{
  GtkObjectClass *object_class;
  GtkWidgetClass *widget_class;
  GtkContainerClass *container_class;

  object_class = (GtkObjectClass*) klass;
  widget_class = (GtkWidgetClass*) klass;
  container_class = (GtkContainerClass*) klass;

  parent_class = gtk_type_class (GTK_TYPE_BIN);

  gtk_object_add_arg_type ("GtkButton::label", GTK_TYPE_STRING, GTK_ARG_READWRITE, ARG_LABEL);
  gtk_object_add_arg_type ("GtkButton::relief", GTK_TYPE_RELIEF_STYLE, GTK_ARG_READWRITE, ARG_RELIEF);

  button_signals[PRESSED] =
    gtk_signal_new ("pressed",
                    GTK_RUN_FIRST,
                    object_class->type,
                    GTK_SIGNAL_OFFSET (GtkButtonClass, pressed),
                    gtk_marshal_NONE__NONE,
		    GTK_TYPE_NONE, 0);
  button_signals[RELEASED] =
    gtk_signal_new ("released",
                    GTK_RUN_FIRST,
                    object_class->type,
                    GTK_SIGNAL_OFFSET (GtkButtonClass, released),
                    gtk_marshal_NONE__NONE,
		    GTK_TYPE_NONE, 0);
  button_signals[CLICKED] =
    gtk_signal_new ("clicked",
                    GTK_RUN_FIRST | GTK_RUN_ACTION,
                    object_class->type,
                    GTK_SIGNAL_OFFSET (GtkButtonClass, clicked),
                    gtk_marshal_NONE__NONE,
		    GTK_TYPE_NONE, 0);
  button_signals[ENTER] =
    gtk_signal_new ("enter",
                    GTK_RUN_FIRST,
                    object_class->type,
                    GTK_SIGNAL_OFFSET (GtkButtonClass, enter),
                    gtk_marshal_NONE__NONE,
		    GTK_TYPE_NONE, 0);
  button_signals[LEAVE] =
    gtk_signal_new ("leave",
                    GTK_RUN_FIRST,
                    object_class->type,
                    GTK_SIGNAL_OFFSET (GtkButtonClass, leave),
                    gtk_marshal_NONE__NONE,
		    GTK_TYPE_NONE, 0);

  gtk_object_class_add_signals (object_class, button_signals, LAST_SIGNAL);

  object_class->set_arg = gtk_button_set_arg;
  object_class->get_arg = gtk_button_get_arg;

  widget_class->activate_signal = button_signals[CLICKED];
  widget_class->realize = gtk_button_realize;
  widget_class->draw = gtk_button_draw;
  widget_class->draw_focus = gtk_button_draw_focus;
  widget_class->draw_default = gtk_button_draw_default;
  widget_class->size_request = gtk_button_size_request;
  widget_class->size_allocate = gtk_button_size_allocate;
  widget_class->expose_event = gtk_button_expose;
  widget_class->button_press_event = gtk_button_button_press;
  widget_class->button_release_event = gtk_button_button_release;
  widget_class->enter_notify_event = gtk_button_enter_notify;
  widget_class->leave_notify_event = gtk_button_leave_notify;
  widget_class->focus_in_event = gtk_button_focus_in;
  widget_class->focus_out_event = gtk_button_focus_out;

  container_class->add = gtk_button_add;
  container_class->remove = gtk_button_remove;
  container_class->child_type = gtk_button_child_type;

  klass->pressed = gtk_real_button_pressed;
  klass->released = gtk_real_button_released;
  klass->clicked = NULL;
  klass->enter = gtk_real_button_enter;
  klass->leave = gtk_real_button_leave;
}



static GtkType
gtk_button_child_type  (GtkContainer     *container)
{
  if (!GTK_BIN (container)->child)
    return GTK_TYPE_WIDGET;
  else
    return GTK_TYPE_NONE;
}

static void
gtk_button_set_arg (GtkObject *object,
		    GtkArg    *arg,
		    guint      arg_id)
{
  GtkButton *button;

  button = GTK_BUTTON (object);

  switch (arg_id)
    {
      GtkWidget *child;

    case ARG_LABEL:
		gtk_button_set_label_text (button,
		       GTK_VALUE_STRING (*arg) ? GTK_VALUE_STRING (*arg) : "");
      break;
    case ARG_RELIEF:
      gtk_button_set_relief (button, GTK_VALUE_ENUM (*arg));
      break;
    default:
      break;
    }
}

static void
gtk_button_get_arg (GtkObject *object,
		    GtkArg    *arg,
		    guint      arg_id)
{
  GtkButton *button;

  button = GTK_BUTTON (object);

  switch (arg_id)
    {
    case ARG_LABEL:
		GTK_VALUE_STRING (*arg) = 
			gtk_button_get_label_text (button);
      break;
    case ARG_RELIEF:
      GTK_VALUE_ENUM (*arg) = gtk_button_get_relief (button);
      break;
    default:
      arg->type = GTK_TYPE_INVALID;
      break;
    }
}

GtkWidget*
gtk_button_new (void)
{
  return GTK_WIDGET (gtk_type_new (gtk_button_get_type ()));
}

void
gtk_button_pressed (GtkButton *button)
{
  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  gtk_signal_emit (GTK_OBJECT (button), button_signals[PRESSED]);
}

void
gtk_button_released (GtkButton *button)
{
  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  gtk_signal_emit (GTK_OBJECT (button), button_signals[RELEASED]);
}

void
gtk_button_clicked (GtkButton *button)
{
  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  gtk_signal_emit (GTK_OBJECT (button), button_signals[CLICKED]);
}

void
gtk_button_enter (GtkButton *button)
{
  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  gtk_signal_emit (GTK_OBJECT (button), button_signals[ENTER]);
}

void
gtk_button_leave (GtkButton *button)
{
  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  gtk_signal_emit (GTK_OBJECT (button), button_signals[LEAVE]);
}


GtkReliefStyle
gtk_button_get_relief (GtkButton *button)
{
  g_return_val_if_fail (button != NULL, GTK_RELIEF_NORMAL);
  g_return_val_if_fail (GTK_IS_BUTTON (button), GTK_RELIEF_NORMAL);

  return button->relief;
}

static void
gtk_button_realize (GtkWidget *widget)
{
  GtkButton *button;
  gint border_width;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_BUTTON (widget));

  button = GTK_BUTTON (widget);
  GTK_WIDGET_SET_FLAGS (widget, GTK_REALIZED);

  border_width = GTK_CONTAINER (widget)->border_width;
}

static void
gtk_button_get_props (GtkButton *button,
		      gint      *default_spacing)
{
}
	

static void
gtk_button_paint (GtkWidget    *widget,
		  GdkRectangle *area)
{
}

static void
gtk_button_draw (GtkWidget    *widget,
		 GdkRectangle *area)
{
}

static void
gtk_button_draw_focus (GtkWidget *widget)
{
}

static void
gtk_button_draw_default (GtkWidget *widget)
{
}

static gint
gtk_button_expose (GtkWidget      *widget,
		   GdkEventExpose *event)
{
  return FALSE;
}

static gint
gtk_button_button_press (GtkWidget      *widget,
			 GdkEventButton *event)
{
  GtkButton *button;

  g_return_val_if_fail (widget != NULL, FALSE);
  g_return_val_if_fail (GTK_IS_BUTTON (widget), FALSE);
  g_return_val_if_fail (event != NULL, FALSE);

  if (event->type == GDK_BUTTON_PRESS)
    {
      button = GTK_BUTTON (widget);

      if (!GTK_WIDGET_HAS_FOCUS (widget))
	gtk_widget_grab_focus (widget);

      if (event->button == 1)
	{
	  gtk_button_pressed (button);
	}
    }

  return TRUE;
}

static gint
gtk_button_button_release (GtkWidget      *widget,
			   GdkEventButton *event)
{
  GtkButton *button;

  g_return_val_if_fail (widget != NULL, FALSE);
  g_return_val_if_fail (GTK_IS_BUTTON (widget), FALSE);
  g_return_val_if_fail (event != NULL, FALSE);

  if (event->button == 1)
    {
      button = GTK_BUTTON (widget);
      gtk_button_released (button);
    }

  return TRUE;
}

static gint
gtk_button_enter_notify (GtkWidget        *widget,
			 GdkEventCrossing *event)
{
  return FALSE;
}

static gint
gtk_button_leave_notify (GtkWidget        *widget,
			 GdkEventCrossing *event)
{
  return FALSE;
}

static gint
gtk_button_focus_in (GtkWidget     *widget,
		     GdkEventFocus *event)
{
  return FALSE;
}

static gint
gtk_button_focus_out (GtkWidget     *widget,
		      GdkEventFocus *event)
{
  return FALSE;
}

static void
gtk_button_add (GtkContainer *container,
		GtkWidget    *widget)
{
  g_return_if_fail (container != NULL);
  g_return_if_fail (widget != NULL);

//  if (GTK_CONTAINER_CLASS (parent_class)->add)
//    GTK_CONTAINER_CLASS (parent_class)->add (container, widget);

  GTK_BUTTON (container)->child = GTK_BIN (container)->child;
  ns_gtk_button_add(container, widget);
}

static void
gtk_button_remove (GtkContainer *container,
		   GtkWidget    *widget)
{
  g_return_if_fail (container != NULL);
  g_return_if_fail (widget != NULL);

  if (GTK_CONTAINER_CLASS (parent_class)->remove)
    GTK_CONTAINER_CLASS (parent_class)->remove (container, widget);

  GTK_BUTTON (container)->child = GTK_BIN (container)->child;
}

static void
gtk_real_button_pressed (GtkButton *button)
{
  GtkStateType new_state;

  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  button->button_down = TRUE;

  new_state = (button->in_button ? GTK_STATE_ACTIVE : GTK_STATE_NORMAL);

  if (GTK_WIDGET_STATE (button) != new_state)
    {
      gtk_widget_set_state (GTK_WIDGET (button), new_state);
      gtk_widget_queue_draw (GTK_WIDGET (button));
    }
}

static void
gtk_real_button_released (GtkButton *button)
{
  GtkStateType new_state;

  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  if (button->button_down)
    {
      button->button_down = FALSE;

      if (button->in_button)
	gtk_button_clicked (button);

      new_state = (button->in_button ? GTK_STATE_PRELIGHT : GTK_STATE_NORMAL);

      if (GTK_WIDGET_STATE (button) != new_state)
	{
	  gtk_widget_set_state (GTK_WIDGET (button), new_state);
	  /* We _draw () instead of queue_draw so that if the operation
	   * blocks, the label doesn't vanish.
	   */
	  gtk_widget_draw (GTK_WIDGET (button), NULL);
	}
    }
}

static void
gtk_real_button_enter (GtkButton *button)
{
  GtkStateType new_state;

  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  new_state = (button->button_down ? GTK_STATE_ACTIVE : GTK_STATE_PRELIGHT);

  if (GTK_WIDGET_STATE (button) != new_state)
    {
      gtk_widget_set_state (GTK_WIDGET (button), new_state);
      gtk_widget_queue_draw (GTK_WIDGET (button));
    }
}

static void
gtk_real_button_leave (GtkButton *button)
{
  g_return_if_fail (button != NULL);
  g_return_if_fail (GTK_IS_BUTTON (button));

  if (GTK_WIDGET_STATE (button) != GTK_STATE_NORMAL)
    {
      gtk_widget_set_state (GTK_WIDGET (button), GTK_STATE_NORMAL);
      gtk_widget_queue_draw (GTK_WIDGET (button));
    }
}
