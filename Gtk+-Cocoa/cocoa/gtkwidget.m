//
//  gtkwidget.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "GtkWindowPrivate.h"

#include <gtk/gtk.h>
#include "gtkprivate.h"

enum {
  SHOW,
  HIDE,
  MAP,
  UNMAP,
  REALIZE,
  UNREALIZE,
  DRAW,
  DRAW_FOCUS,
  DRAW_DEFAULT,
  SIZE_REQUEST,
  SIZE_ALLOCATE,
  STATE_CHANGED,
  PARENT_SET,
  STYLE_SET,
  ADD_ACCELERATOR,
  REMOVE_ACCELERATOR,
  GRAB_FOCUS,
  EVENT,
  BUTTON_PRESS_EVENT,
  BUTTON_RELEASE_EVENT,
  MOTION_NOTIFY_EVENT,
  DELETE_EVENT,
  DESTROY_EVENT,
  EXPOSE_EVENT,
  KEY_PRESS_EVENT,
  KEY_RELEASE_EVENT,
  ENTER_NOTIFY_EVENT,
  LEAVE_NOTIFY_EVENT,
  CONFIGURE_EVENT,
  FOCUS_IN_EVENT,
  FOCUS_OUT_EVENT,
  MAP_EVENT,
  UNMAP_EVENT,
  PROPERTY_NOTIFY_EVENT,
  SELECTION_CLEAR_EVENT,
  SELECTION_REQUEST_EVENT,
  SELECTION_NOTIFY_EVENT,
  SELECTION_GET,
  SELECTION_RECEIVED,
  PROXIMITY_IN_EVENT,
  PROXIMITY_OUT_EVENT,
  DRAG_BEGIN,
  DRAG_END,
  DRAG_DATA_DELETE,
  DRAG_LEAVE,
  DRAG_MOTION,
  DRAG_DROP,
  DRAG_DATA_GET,
  DRAG_DATA_RECEIVED,
  CLIENT_EVENT,
  NO_EXPOSE_EVENT,
  VISIBILITY_NOTIFY_EVENT,
  DEBUG_MSG,
  LAST_SIGNAL
};

typedef	struct	_GtkStateData	 GtkStateData;

struct _GtkStateData
{
  GtkStateType  state;
  guint		state_restoration : 1;
  guint         parent_sensitive : 1;
  guint		use_forall : 1;
};

extern GList *idle_funcs;
extern guint widget_signals[LAST_SIGNAL];
extern guint        aux_info_key_id;

void reset_focus_recurse (GtkWidget *widget, gpointer   data);
NSPoint convert_coords(GtkWidget *widget, int x, int y);
void
gtk_widget_show                 (GtkWidget *widget)
{
  NSView *obj; 
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));
  

  if (!GTK_WIDGET_VISIBLE (widget))
    {
      if (!GTK_WIDGET_TOPLEVEL (widget))
      {
/*
        if([obj isMemberOfClass:[GtkWindowPrivate class]])
        {
            GtkWindowPrivate *win = (GtkWindowPrivate *)obj;
			NSButton   *testButton;
            [win makeKeyAndOrderFront:win];
			testButton =  [[NSTextField alloc]
							initWithFrame:NSMakeRect(1, 1,100,50)];
		  [[win contentView] addSubview:testButton ];
		  [testButton  release]; 
        }
 */   
      	
      }
      if (GTK_IS_WINDOW (widget) && GTK_WIDGET_REALIZED (widget))
                [widget->window makeKeyAndOrderFront:widget->window ];
      gtk_signal_emit (GTK_OBJECT (widget), widget_signals[SHOW]);
    }
 //if(!GTK_IS_MENU_ITEM(widget))
 if([widget->proxy isKindOfClass:[NSView class]])
  {  
      obj = (NSView *)widget->proxy;
	  [obj setNeedsDisplay:TRUE];
      
 //     printf("widget %s\n", gtk_widget_get_name(widget));
	  if(widget->superview)
				[widget->superview addSubview:obj];
  }
}

/*****************************************
 * gtk_widget_hide:
 *
 *   arguments:
 *
 *   results:
 *****************************************/

void
gtk_widget_hide (GtkWidget *widget)
{
  NSView *obj = (NSView *)widget->proxy;
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));
  
  if (GTK_WIDGET_VISIBLE (widget))
  {
      	gtk_widget_ref (widget);
      	gtk_signal_emit (GTK_OBJECT (widget), widget_signals[HIDE]);
      	if (!GTK_WIDGET_TOPLEVEL (widget) && !GTK_OBJECT_DESTROYED (widget))
			gtk_widget_queue_resize (widget);
      	gtk_widget_unref (widget);
      	if (GTK_IS_WINDOW (widget))
			[widget->window orderOut:widget->window ];
		else
		{
			widget->superview = [obj superview];
			[obj removeFromSuperview];
		}
  }
}

void
gtk_widget_unparent (GtkWidget *widget)
{
  GtkWidget *toplevel;
  GtkWidget *old_parent;
//  NSView *obj = (NSView *)widget->proxy;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));
  if (widget->parent == NULL)
    return;
  
  /* keep this function in sync with gtk_menu_detach()
   */

  /* unset focused and default children properly, this code
   * should eventually move into some gtk_window_unparent_branch() or
   * similar function.
   */
  
  toplevel = gtk_widget_get_toplevel (widget);
  if (GTK_CONTAINER (widget->parent)->focus_child == widget)
    {
      gtk_container_set_focus_child (GTK_CONTAINER (widget->parent), NULL);

      if (GTK_IS_WINDOW (toplevel))
	{
	  GtkWidget *child;
      
	  child = GTK_WINDOW (toplevel)->focus_widget;
	  
	  while (child && child != widget)
	    child = child->parent;
	  
	  if (child == widget)
	    gtk_window_set_focus (GTK_WINDOW (toplevel), NULL);
	}
    }
  if (GTK_IS_WINDOW (toplevel))
    {
      GtkWidget *child;
      
      child = GTK_WINDOW (toplevel)->default_widget;
      
      while (child && child != widget)
	child = child->parent;
      
      if (child == widget)
	gtk_window_set_default (GTK_WINDOW (toplevel), NULL);
    }

  if (GTK_WIDGET_REDRAW_PENDING (widget))
    gtk_widget_redraw_queue_remove (widget);

  if (GTK_IS_RESIZE_CONTAINER (widget))
    gtk_container_clear_resize_widgets (GTK_CONTAINER (widget));
  
  /* Remove the widget and all its children from any ->resize_widgets list
   * of all the parents in our branch. This code should move into gtkcontainer.c
   * somwhen, since we mess around with ->resize_widgets, which is
   * actually not of our business.
   *
   * Two ways to make this prettier:
   *   Write a g_slist_conditional_remove (GSList, gboolean (*)(gpointer))
   *   Change resize_widgets to a GList
   */
  toplevel = widget->parent;
  while (toplevel)
    {
      GSList *slist;
      GSList *prev;

      if (!GTK_CONTAINER (toplevel)->resize_widgets)
	{
	  toplevel = toplevel->parent;
	  continue;
	}

      prev = NULL;
      slist = GTK_CONTAINER (toplevel)->resize_widgets;
      while (slist)
	{
	  GtkWidget *child;
	  GtkWidget *parent;
	  GSList *last;

	  last = slist;
	  slist = last->next;
	  child = last->data;
	  
	  parent = child;
	  while (parent && (parent != widget))
	    parent = parent->parent;
	  
	  if (parent == widget)
	    {
	      GTK_PRIVATE_UNSET_FLAG (child, GTK_RESIZE_NEEDED);
	      
	      if (prev)
		prev->next = slist;
	      else
		GTK_CONTAINER (toplevel)->resize_widgets = slist;
	      
	      g_slist_free_1 (last);
	    }
	  else
	    prev = last;
	}

      toplevel = toplevel->parent;
    }

  gtk_widget_queue_clear_child (widget);

  /* Reset the width and height here, to force reallocation if we
   * get added back to a new parent. This won't work if our new
   * allocation is smaller than 1x1 and we actually want a size of 1x1...
   * (would 0x0 be OK here?)
   */
  widget->allocation.width = 1;
  widget->allocation.height = 1;
  
  if (GTK_WIDGET_REALIZED (widget) && !GTK_WIDGET_IN_REPARENT (widget))
    gtk_widget_unrealize (widget);

  old_parent = widget->parent;
  widget->parent = NULL;
  gtk_widget_set_parent_window (widget, NULL);
  gtk_signal_emit (GTK_OBJECT (widget), widget_signals[PARENT_SET], old_parent);
  
  gtk_widget_unref (widget);
  if(widget->superview)
  	[widget->proxy removeFromSuperview];
}


void
gtk_widget_real_size_allocate (GtkWidget     *widget,
			       GtkAllocation *allocation)
{
  NSView *view = (NSView *)widget->proxy;
  NSRect frame;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));

  widget->allocation = *allocation;
  
//printf("widget allocation %d %d %d %d \n", allocation->x, allocation->y, allocation->width, allocation->height);
//printf("widget frame %f %f %f %f\n", [view frame].origin.x, [view frame].origin.y, [view frame].size.width, [view frame].size.height);
  frame = [view frame];
  frame.origin.x = allocation->x;
  frame.origin.y = allocation->y;
  frame.size.width = allocation->width;
  frame.size.height = allocation->height;

  [view setFrame:frame];

//printf("widget frame %f %f %f %f\n", [view frame].origin.x, [view frame].origin.y, [view frame].size.width, [view frame].size.height);
  [widget->proxy setNeedsDisplay:YES];
}

/*****************************************
 * gtk_widget_set_parent:
 *
 *   arguments:
 *
 *   results:
 *****************************************/


void
gtk_widget_set_parent (GtkWidget *widget,
		       GtkWidget *parent)
{
  NSView *view,*subView;
  GtkWindowPrivate *win;
  GtkStateData data;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));
  g_return_if_fail (widget->parent == NULL);
  g_return_if_fail (!GTK_WIDGET_TOPLEVEL (widget));
  g_return_if_fail (parent != NULL);
  g_return_if_fail (GTK_IS_WIDGET (parent));
  g_return_if_fail (widget != parent);

  /* keep this function in sync with gtk_menu_attach_to_widget()
   */

  gtk_widget_ref (widget);
  gtk_object_sink (GTK_OBJECT (widget));
  widget->parent = parent;

  if (GTK_WIDGET_STATE (parent) != GTK_STATE_NORMAL)
    data.state = GTK_WIDGET_STATE (parent);
  else
    data.state = GTK_WIDGET_STATE (widget);
  data.state_restoration = FALSE;
  data.parent_sensitive = (GTK_WIDGET_IS_SENSITIVE (parent) != FALSE);
  data.use_forall = GTK_WIDGET_IS_SENSITIVE (parent) != GTK_WIDGET_IS_SENSITIVE (widget);

    view = (NSView *)GTK_WIDGET(parent)->proxy;
    win = (GtkWindowPrivate *)GTK_WIDGET(parent)->window;
    subView = (NSView *)widget->proxy;

    if(win)
    {
        view = [win contentView];
    }
	if(GTK_WIDGET_VISIBLE(widget))
		[view addSubview:subView];
	widget->superview = view;
    [subView display];

  gtk_widget_propagate_state (widget, &data);
  
  gtk_widget_set_style_recurse (widget, NULL);

  gtk_signal_emit (GTK_OBJECT (widget), widget_signals[PARENT_SET], NULL);
}

/*****************************************
 * gtk_widget_size_allocate:
 *
 *   arguments:
 *
 *   results:
 *****************************************/

void
gtk_widget_size_allocate (GtkWidget	*widget,
			  GtkAllocation *allocation)
{
  NSPoint origin;
  GtkWidgetAuxInfo *aux_info;
  GtkAllocation real_allocation;
  gboolean needs_draw = FALSE;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));
  
  real_allocation = *allocation;
  aux_info = gtk_object_get_data_by_id (GTK_OBJECT (widget), aux_info_key_id);
  
  if (aux_info)
    {
      if (aux_info->x != -1)
	real_allocation.x = aux_info->x;
      if (aux_info->y != -1)
	real_allocation.y = aux_info->y;
    }

  real_allocation.width = MAX (real_allocation.width, 1);
  real_allocation.height = MAX (real_allocation.height, 1);

  if (real_allocation.width > 32767 ||
      real_allocation.height > 32767)
    {
      g_warning ("gtk_widget_size_allocate(): attempt to allocate widget with width %d and height %d",
		 real_allocation.width,
		 real_allocation.height);
      real_allocation.width = MIN (real_allocation.width, 32767);
      real_allocation.height = MIN (real_allocation.height, 32767);
    }
  
  if (GTK_WIDGET_NO_WINDOW (widget))
    {
      if (widget->allocation.x != real_allocation.x ||
	  widget->allocation.y != real_allocation.y ||
	  widget->allocation.width != real_allocation.width ||
	  widget->allocation.height != real_allocation.height)
	{
	  gtk_widget_queue_clear_child (widget);
	  needs_draw = TRUE;
	}
    }
  else if (widget->allocation.width != real_allocation.width ||
	   widget->allocation.height != real_allocation.height)
    {
      needs_draw = TRUE;
    }

  if (GTK_IS_RESIZE_CONTAINER (widget))
    gtk_container_clear_resize_widgets (GTK_CONTAINER (widget));

  //printf("widget %s %d %d %d %d\n",gtk_widget_get_name(widget),real_allocation.x,real_allocation.y,real_allocation.width, real_allocation.height);
  gtk_signal_emit (GTK_OBJECT (widget), widget_signals[SIZE_ALLOCATE], &real_allocation);

  if (needs_draw)
    {
      gtk_widget_queue_draw (widget);
      if (widget->parent && GTK_CONTAINER (widget->parent)->reallocate_redraws)
	gtk_widget_queue_draw (widget->parent);
    }
	  origin = NSMakePoint(real_allocation.x,real_allocation.y); //convert_coords(widget, real_allocation.x,real_allocation.y);
  // flip y
  //
  if(!GTK_IS_WINDOW(widget))
  {
	  origin.y = widget->parent->allocation.height - origin.y - real_allocation.height;
	  [widget->proxy setFrameOrigin:origin];
	  [widget->proxy setFrameSize:NSMakeSize(real_allocation.width, real_allocation.height)];
	  //printf("coonverted y= %f %d %f\n",origin.y, real_allocation.height, [widget->proxy frame].size.height );
  }
  //printf("end widget %s\n",gtk_widget_get_name(widget));
  [widget->proxy setNeedsDisplay:TRUE];
}

NSPoint
convert_coords(GtkWidget *widget, int x, int y)
{
     NSPoint parent_relative = NSMakePoint(x,y);

     if(widget->parent)
     {
     	parent_relative.x -= widget->parent->allocation.x; 		
     	parent_relative.y -= widget->parent->allocation.y; 		
     }

     return parent_relative;
}

void
gtk_widget_real_grab_focus (GtkWidget *focus_widget)
{
  GtkWindowPrivate *win;
  g_return_if_fail (focus_widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (focus_widget));
  
  if (GTK_WIDGET_CAN_FOCUS (focus_widget))
    {
      GtkWidget *toplevel;
      GtkWidget *widget;
      
      /* clear the current focus setting, break if the current widget
       * is the focus widget's parent, since containers above that will
       * be set by the next loop.
       */
      toplevel = gtk_widget_get_toplevel (focus_widget);
      if (GTK_IS_WINDOW (toplevel))
	{
	  widget = GTK_WINDOW (toplevel)->focus_widget;
	  
	  if (widget == focus_widget)
	    {
	      /* We call gtk_window_set_focus() here so that the
	       * toplevel window can request the focus if necessary.
	       * This is needed when the toplevel is a GtkPlug
	       */
	      if (!GTK_WIDGET_HAS_FOCUS (widget))
		gtk_window_set_focus (GTK_WINDOW (toplevel), focus_widget);

	      return;
	    }
	  
	  if (widget)
	    {
	      while (widget->parent && widget->parent != focus_widget->parent)
		{
		  widget = widget->parent;
		  gtk_container_set_focus_child (GTK_CONTAINER (widget), NULL);
		}
	    }
	}
      else if (toplevel != focus_widget)
	{
	  /* gtk_widget_grab_focus() operates on a tree without window...
	   * actually, this is very questionable behaviour.
	   */
	  
	  gtk_container_foreach (GTK_CONTAINER (toplevel),
				 reset_focus_recurse,
				 NULL);
	}

      /* now propagate the new focus up the widget tree and finally
       * set it on the window
       */
      widget = focus_widget;
      while (widget->parent)
	{
	  gtk_container_set_focus_child (GTK_CONTAINER (widget->parent), widget);
	  widget = widget->parent;
	}
      	if (GTK_IS_WINDOW (widget))
		{
			gtk_window_set_focus (GTK_WINDOW (widget), focus_widget);
			win = widget->window;
            printf("focus widget %x\n",focus_widget);
			[win makeFirstResponder:focus_widget->proxy];
		}
    }
	
}

void
gtk_widget_real_destroy (GtkObject *object)
{
  GtkWidget *widget;
  GtkStyle *saved_style;

  /* gtk_object_destroy() will already hold a refcount on object
   */
  widget = GTK_WIDGET (object);

/*
  gtk_grab_remove (widget);
  
  saved_style = gtk_object_get_data_by_id (object, saved_default_style_key_id);
  if (saved_style)
    {
      gtk_style_unref (saved_style);
      gtk_object_remove_data_by_id (object, saved_default_style_key_id);
    }

  gtk_style_unref (widget->style);
  widget->style = NULL;
*/

  if(widget->superview)
  {
  	[widget->proxy removeFromSuperview];
  }
  else
  	[widget->proxy release];
  gtk_widget_super_destroy(object);
}

/*****************************************
 * gtk_widget_set_sensitive:
 *
 *   arguments:
 *     widget
 *     boolean value for sensitivity
 *
 *   results:
 *****************************************/

void
gtk_widget_set_sensitive (GtkWidget *widget,
			  gboolean   sensitive)
{
  GtkStateData data;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));

  sensitive = (sensitive != FALSE);

  if (sensitive == (GTK_WIDGET_SENSITIVE (widget) != FALSE))
    return;

  if (sensitive)
    {
      GTK_WIDGET_SET_FLAGS (widget, GTK_SENSITIVE);
      data.state = GTK_WIDGET_SAVED_STATE (widget);
    }
  else
    {
      GTK_WIDGET_UNSET_FLAGS (widget, GTK_SENSITIVE);
      data.state = GTK_WIDGET_STATE (widget);
    }
  data.state_restoration = TRUE;
  data.use_forall = TRUE;

  if (widget->parent)
    data.parent_sensitive = (GTK_WIDGET_IS_SENSITIVE (widget->parent) != FALSE);
  else
    data.parent_sensitive = TRUE;

  gtk_widget_propagate_state (widget, &data);
  if (GTK_WIDGET_DRAWABLE (widget))
    gtk_widget_queue_clear (widget);
    if([widget->proxy respondsToSelector:@selector(setEnabled)])
        [widget->proxy setEnabled:sensitive];
}


void
ns_gtk_widget_finalize (GtkWidget *widget)
{
 if(widget->proxy && widget->superview)
    [widget->proxy release];
}


