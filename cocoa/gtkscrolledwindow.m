//
//  gtkscrolledwindow.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>

#define SCROLLBAR_SPACING(w) (GTK_SCROLLED_WINDOW_CLASS (GTK_OBJECT (w)->klass)->scrollbar_spacing)

void gtk_scrolled_window_adjustment_changed (GtkAdjustment          *adjustment, gpointer                data);
void
gtk_scrolled_window_init (GtkScrolledWindow *scrolled_window)
{
//  NSScrollView *sw;
  
  GTK_WIDGET_SET_FLAGS (scrolled_window, GTK_NO_WINDOW);

  gtk_container_set_resize_mode (GTK_CONTAINER (scrolled_window), GTK_RESIZE_QUEUE);

  scrolled_window->hscrollbar = NULL;
  scrolled_window->vscrollbar = NULL;
  scrolled_window->hscrollbar_policy = GTK_POLICY_ALWAYS;
  scrolled_window->vscrollbar_policy = GTK_POLICY_ALWAYS;
  scrolled_window->hscrollbar_visible = FALSE;
  scrolled_window->vscrollbar_visible = FALSE;
  scrolled_window->window_placement = GTK_CORNER_TOP_LEFT;
/*
  sw = [[NSScrollView alloc] initWithFrame:NSMakeRect(10,10,300,300)];
  [sw setDocumentView:GTK_WIDGET(scrolled_window)->proxy];
  [sw setAutoresizesSubviews:FALSE];
  [sw setHasHorizontalScroller:YES];
  GTK_WIDGET(scrolled_window)->proxy = sw;
*/
}

void
gtk_scrolled_window_set_hadjustment (GtkScrolledWindow *scrolled_window,
				     GtkAdjustment     *hadjustment)
{
  GtkBin *bin;

  g_return_if_fail (scrolled_window != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (scrolled_window));
  if (hadjustment)
    g_return_if_fail (GTK_IS_ADJUSTMENT (hadjustment));
  else
    hadjustment = (GtkAdjustment*) gtk_object_new (GTK_TYPE_ADJUSTMENT, NULL);

  bin = GTK_BIN (scrolled_window);

  if (!scrolled_window->hscrollbar)
    {
      gtk_widget_push_composite_child ();
      scrolled_window->hscrollbar = gtk_hscrollbar_new (hadjustment);
      gtk_widget_set_composite_name (scrolled_window->hscrollbar, "hscrollbar");
      gtk_widget_pop_composite_child ();

      gtk_widget_set_parent (scrolled_window->hscrollbar, GTK_WIDGET (scrolled_window));
      gtk_widget_ref (scrolled_window->hscrollbar);
      gtk_widget_show (scrolled_window->hscrollbar);
    }
  else
    {
      GtkAdjustment *old_adjustment;
      
      old_adjustment = gtk_range_get_adjustment (GTK_RANGE (scrolled_window->hscrollbar));
      if (old_adjustment == hadjustment)
	return;

      gtk_signal_disconnect_by_func (GTK_OBJECT (old_adjustment),
				     GTK_SIGNAL_FUNC (gtk_scrolled_window_adjustment_changed),
				     scrolled_window);
      gtk_range_set_adjustment (GTK_RANGE (scrolled_window->hscrollbar),
				hadjustment);
    }
  hadjustment = gtk_range_get_adjustment (GTK_RANGE (scrolled_window->hscrollbar));
  gtk_signal_connect (GTK_OBJECT (hadjustment),
		      "changed",
		      GTK_SIGNAL_FUNC (gtk_scrolled_window_adjustment_changed),
		      scrolled_window);
  gtk_scrolled_window_adjustment_changed (hadjustment, scrolled_window);
  
  if (bin->child)
    gtk_widget_set_scroll_adjustments (bin->child,
				       gtk_range_get_adjustment (GTK_RANGE (scrolled_window->hscrollbar)),
				       gtk_range_get_adjustment (GTK_RANGE (scrolled_window->vscrollbar)));
}

void
gtk_scrolled_window_set_vadjustment (GtkScrolledWindow *scrolled_window,
				     GtkAdjustment     *vadjustment)
{
  GtkBin *bin;

  g_return_if_fail (scrolled_window != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (scrolled_window));
  if (vadjustment)
    g_return_if_fail (GTK_IS_ADJUSTMENT (vadjustment));
  else
    vadjustment = (GtkAdjustment*) gtk_object_new (GTK_TYPE_ADJUSTMENT, NULL);

  bin = GTK_BIN (scrolled_window);

  if (!scrolled_window->vscrollbar)
    {
      gtk_widget_push_composite_child ();
      scrolled_window->vscrollbar = gtk_vscrollbar_new (vadjustment);
      gtk_widget_set_composite_name (scrolled_window->vscrollbar, "vscrollbar");
      gtk_widget_pop_composite_child ();

      gtk_widget_set_parent (scrolled_window->vscrollbar, GTK_WIDGET (scrolled_window));
      gtk_widget_ref (scrolled_window->vscrollbar);
      gtk_widget_show (scrolled_window->vscrollbar);
    }
  else
    {
      GtkAdjustment *old_adjustment;
      
      old_adjustment = gtk_range_get_adjustment (GTK_RANGE (scrolled_window->vscrollbar));
      if (old_adjustment == vadjustment)
	return;

      gtk_signal_disconnect_by_func (GTK_OBJECT (old_adjustment),
				     GTK_SIGNAL_FUNC (gtk_scrolled_window_adjustment_changed),
				     scrolled_window);
      gtk_range_set_adjustment (GTK_RANGE (scrolled_window->vscrollbar),
				vadjustment);
    }
  vadjustment = gtk_range_get_adjustment (GTK_RANGE (scrolled_window->vscrollbar));
  gtk_signal_connect (GTK_OBJECT (vadjustment),
		      "changed",
		      GTK_SIGNAL_FUNC (gtk_scrolled_window_adjustment_changed),
		      scrolled_window);
  gtk_scrolled_window_adjustment_changed (vadjustment, scrolled_window);

  if (bin->child)
    gtk_widget_set_scroll_adjustments (bin->child,
				       gtk_range_get_adjustment (GTK_RANGE (scrolled_window->hscrollbar)),
				       gtk_range_get_adjustment (GTK_RANGE (scrolled_window->vscrollbar)));
}

void
gtk_scrolled_window_add (GtkContainer *container,
			 GtkWidget    *child)
{
//  NSScrollView *sw = GTK_WIDGET(container)->proxy;
  GtkScrolledWindow *scrolled_window;
  GtkBin *bin;

  bin = GTK_BIN (container);
  g_return_if_fail (bin->child == NULL);

  scrolled_window = GTK_SCROLLED_WINDOW (container);

  bin->child = child;
  gtk_widget_set_parent (child, GTK_WIDGET (bin));

  /* this is a temporary message */
  if (!gtk_widget_set_scroll_adjustments (child,
					  gtk_range_get_adjustment (GTK_RANGE (scrolled_window->hscrollbar)),
					  gtk_range_get_adjustment (GTK_RANGE (scrolled_window->vscrollbar))))
    g_warning ("gtk_scrolled_window_add(): cannot add non scrollable widget "
	       "use gtk_scrolled_window_add_with_viewport() instead");

  if (GTK_WIDGET_REALIZED (child->parent))
    gtk_widget_realize (child);

  if (GTK_WIDGET_VISIBLE (child->parent) && GTK_WIDGET_VISIBLE (child))
    {
      if (GTK_WIDGET_MAPPED (child->parent))
	gtk_widget_map (child);

      gtk_widget_queue_resize (child);
    }
	//[sw setDocumentView:child->proxy];
}

void
gtk_scrolled_window_size_request (GtkWidget      *widget,
				  GtkRequisition *requisition)
{
  GtkScrolledWindow *scrolled_window;
  GtkBin *bin;
  gint extra_width;
  gint extra_height;
  GtkRequisition hscrollbar_requisition;
  GtkRequisition vscrollbar_requisition;
  GtkRequisition child_requisition;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (widget));
  g_return_if_fail (requisition != NULL);

  scrolled_window = GTK_SCROLLED_WINDOW (widget);
  bin = GTK_BIN (scrolled_window);

  extra_width = 0;
  extra_height = 0;
  requisition->width = 0;
  requisition->height = 0;
  
  gtk_widget_size_request (scrolled_window->hscrollbar,
			   &hscrollbar_requisition);
  gtk_widget_size_request (scrolled_window->vscrollbar,
			   &vscrollbar_requisition);
  
  if (bin->child && GTK_WIDGET_VISIBLE (bin->child))
    {
      static guint quark_aux_info = 0;

      if (!quark_aux_info)
	quark_aux_info = g_quark_from_static_string ("gtk-aux-info");

      gtk_widget_size_request (bin->child, &child_requisition);

      if (scrolled_window->hscrollbar_policy == GTK_POLICY_NEVER)
	requisition->width += child_requisition.width;
      else
	{
	  GtkWidgetAuxInfo *aux_info;

	  aux_info = gtk_object_get_data_by_id (GTK_OBJECT (bin->child), quark_aux_info);
	  if (aux_info && aux_info->width > 0)
	    {
	      requisition->width += aux_info->width;
	      extra_width = -1;
	    }
	  else
	    requisition->width += vscrollbar_requisition.width;
	}

      if (scrolled_window->vscrollbar_policy == GTK_POLICY_NEVER)
	requisition->height += child_requisition.height;
      else
	{
	  GtkWidgetAuxInfo *aux_info;

	  aux_info = gtk_object_get_data_by_id (GTK_OBJECT (bin->child), quark_aux_info);
	  if (aux_info && aux_info->height > 0)
	    {
	      requisition->height += aux_info->height;
	      extra_height = -1;
	    }
	  else
	    requisition->height += hscrollbar_requisition.height;
	}
    }

  if (scrolled_window->hscrollbar_policy == GTK_POLICY_AUTOMATIC ||
      scrolled_window->hscrollbar_policy == GTK_POLICY_ALWAYS)
    {
      requisition->width = MAX (requisition->width, hscrollbar_requisition.width);
      if (!extra_height || scrolled_window->hscrollbar_policy == GTK_POLICY_ALWAYS)
	extra_height = SCROLLBAR_SPACING (scrolled_window) + hscrollbar_requisition.height;
    }

  if (scrolled_window->vscrollbar_policy == GTK_POLICY_AUTOMATIC ||
      scrolled_window->vscrollbar_policy == GTK_POLICY_ALWAYS)
    {
      requisition->height = MAX (requisition->height, vscrollbar_requisition.height);
      if (!extra_height || scrolled_window->vscrollbar_policy == GTK_POLICY_ALWAYS)
	extra_width = SCROLLBAR_SPACING (scrolled_window) + vscrollbar_requisition.width;
    }

  requisition->width += GTK_CONTAINER (widget)->border_width * 2 + MAX (0, extra_width);
  requisition->height += GTK_CONTAINER (widget)->border_width * 2 + MAX (0, extra_height);
}

void
gtk_scrolled_window_relative_allocation (GtkWidget     *widget,
					 GtkAllocation *allocation)
{
  GtkScrolledWindow *scrolled_window;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (allocation != NULL);

  scrolled_window = GTK_SCROLLED_WINDOW (widget);

  allocation->x = GTK_CONTAINER (widget)->border_width;
  allocation->y = GTK_CONTAINER (widget)->border_width;
  allocation->width = MAX (1, (gint)widget->allocation.width - allocation->x * 2);
  allocation->height = MAX (1, (gint)widget->allocation.height - allocation->y * 2);

  if (scrolled_window->vscrollbar_visible)
    {
      GtkRequisition vscrollbar_requisition;
      gtk_widget_get_child_requisition (scrolled_window->vscrollbar,
					&vscrollbar_requisition);
  
      if (scrolled_window->window_placement == GTK_CORNER_TOP_RIGHT ||
	  scrolled_window->window_placement == GTK_CORNER_BOTTOM_RIGHT)
	allocation->x += (vscrollbar_requisition.width +
			  SCROLLBAR_SPACING (scrolled_window));

      allocation->width = MAX (1, (gint)allocation->width -
			       ((gint)vscrollbar_requisition.width +
				(gint)SCROLLBAR_SPACING (scrolled_window)));
    }
  if (scrolled_window->hscrollbar_visible)
    {
      GtkRequisition hscrollbar_requisition;
      gtk_widget_get_child_requisition (scrolled_window->hscrollbar,
					&hscrollbar_requisition);
  
      if (scrolled_window->window_placement == GTK_CORNER_BOTTOM_LEFT ||
	  scrolled_window->window_placement == GTK_CORNER_BOTTOM_RIGHT)
	allocation->y += (hscrollbar_requisition.height +
			  SCROLLBAR_SPACING (scrolled_window));

      allocation->height = MAX (1, (gint)allocation->height -
				((gint)hscrollbar_requisition.height +
				 (gint)SCROLLBAR_SPACING (scrolled_window)));
    }
}

void
gtk_scrolled_window_size_allocate (GtkWidget     *widget,
				   GtkAllocation *allocation)
{
  GtkScrolledWindow *scrolled_window;
  GtkBin *bin;
  GtkAllocation relative_allocation;
  GtkAllocation child_allocation;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (widget));
  g_return_if_fail (allocation != NULL);

  scrolled_window = GTK_SCROLLED_WINDOW (widget);
  bin = GTK_BIN (scrolled_window);

  widget->allocation = *allocation;

  if (scrolled_window->hscrollbar_policy == GTK_POLICY_ALWAYS)
    scrolled_window->hscrollbar_visible = TRUE;
  else if (scrolled_window->hscrollbar_policy == GTK_POLICY_NEVER)
    scrolled_window->hscrollbar_visible = FALSE;
  if (scrolled_window->vscrollbar_policy == GTK_POLICY_ALWAYS)
    scrolled_window->vscrollbar_visible = TRUE;
  else if (scrolled_window->vscrollbar_policy == GTK_POLICY_NEVER)
    scrolled_window->vscrollbar_visible = FALSE;

  if (bin->child && GTK_WIDGET_VISIBLE (bin->child))
    {
      gboolean previous_hvis;
      gboolean previous_vvis;
      guint count = 0;
      
      do
	{
	  gtk_scrolled_window_relative_allocation (widget, &relative_allocation);
	  
	  child_allocation.x = relative_allocation.x;// + allocation->x;
	  child_allocation.y = relative_allocation.y;// + allocation->y;
	  child_allocation.width = relative_allocation.width;
	  child_allocation.height = relative_allocation.height;
	  
	  previous_hvis = scrolled_window->hscrollbar_visible;
	  previous_vvis = scrolled_window->vscrollbar_visible;
	  
	  gtk_widget_size_allocate (bin->child, &child_allocation);

	  /* If, after the first iteration, the hscrollbar and the
	   * vscrollbar flip visiblity, then we need both.
	   */
	  if (count &&
	      previous_hvis != scrolled_window->hscrollbar_visible &&
	      previous_vvis != scrolled_window->vscrollbar_visible)
	    {
	      scrolled_window->hscrollbar_visible = TRUE;
	      scrolled_window->vscrollbar_visible = TRUE;

	      /* a new resize is already queued at this point,
	       * so we will immediatedly get reinvoked
	       */
	      return;
	    }
	  
	  count++;
	}
      while (previous_hvis != scrolled_window->hscrollbar_visible ||
	     previous_vvis != scrolled_window->vscrollbar_visible);
    }
  else
    gtk_scrolled_window_relative_allocation (widget, &relative_allocation);
  
  if (scrolled_window->hscrollbar_visible)
    {
      GtkRequisition hscrollbar_requisition;
      gtk_widget_get_child_requisition (scrolled_window->hscrollbar,
					&hscrollbar_requisition);
  
      if (!GTK_WIDGET_VISIBLE (scrolled_window->hscrollbar))
	gtk_widget_show (scrolled_window->hscrollbar);

      child_allocation.x = relative_allocation.x;
      if (scrolled_window->window_placement == GTK_CORNER_TOP_LEFT ||
	  scrolled_window->window_placement == GTK_CORNER_TOP_RIGHT)
	child_allocation.y = (relative_allocation.y +
			      relative_allocation.height +
			      SCROLLBAR_SPACING (scrolled_window));
      else
	child_allocation.y = GTK_CONTAINER (scrolled_window)->border_width;

      child_allocation.width = relative_allocation.width;
      child_allocation.height = hscrollbar_requisition.height;
//      child_allocation.x += allocation->x;
//      child_allocation.y += allocation->y;

      gtk_widget_size_allocate (scrolled_window->hscrollbar, &child_allocation);
    }
  else if (GTK_WIDGET_VISIBLE (scrolled_window->hscrollbar))
    gtk_widget_hide (scrolled_window->hscrollbar);

  if (scrolled_window->vscrollbar_visible)
    {
      GtkRequisition vscrollbar_requisition;
      if (!GTK_WIDGET_VISIBLE (scrolled_window->vscrollbar))
	gtk_widget_show (scrolled_window->vscrollbar);

      gtk_widget_get_child_requisition (scrolled_window->vscrollbar,
					&vscrollbar_requisition);

      if (scrolled_window->window_placement == GTK_CORNER_TOP_LEFT ||
	  scrolled_window->window_placement == GTK_CORNER_BOTTOM_LEFT)
	child_allocation.x = (relative_allocation.x +
			      relative_allocation.width +
			      SCROLLBAR_SPACING (scrolled_window));
      else
	child_allocation.x = GTK_CONTAINER (scrolled_window)->border_width;

      child_allocation.y = relative_allocation.y;
      child_allocation.width = vscrollbar_requisition.width;
      child_allocation.height = relative_allocation.height;
//      child_allocation.x += allocation->x;
//      child_allocation.y += allocation->y;

      gtk_widget_size_allocate (scrolled_window->vscrollbar, &child_allocation);
    }
  else if (GTK_WIDGET_VISIBLE (scrolled_window->vscrollbar))
    gtk_widget_hide (scrolled_window->vscrollbar);
}


void
gtk_scrolled_window_set_policy (GtkScrolledWindow *scrolled_window,
				GtkPolicyType      hscrollbar_policy,
				GtkPolicyType      vscrollbar_policy)
{
  g_return_if_fail (scrolled_window != NULL);
  g_return_if_fail (GTK_IS_SCROLLED_WINDOW (scrolled_window));

  if ((scrolled_window->hscrollbar_policy != hscrollbar_policy) ||
      (scrolled_window->vscrollbar_policy != vscrollbar_policy))
    {
      scrolled_window->hscrollbar_policy = hscrollbar_policy;
      scrolled_window->vscrollbar_policy = vscrollbar_policy;

      gtk_widget_queue_resize (GTK_WIDGET (scrolled_window));
    }
}


