/*
 *  gtkwindow.c
 *  Gtk+
 *
 *  Created by Paolo Costabel on Sat Aug 10 2002.
 *  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
 *
 */
#import <AppKit/AppKit.h>
#import "GtkWindowPrivate.h"

#include "gtk/gtk.h"

#define debug printf("%s:%d\n",__FILE__,__LINE__);

typedef struct {
  GdkGeometry    geometry; /* Last set of geometry hints we set */
  GdkWindowHints flags;
  gint           width;
  gint           height;
} GtkWindowLastGeometryInfo;

typedef struct {
  /* Properties that the app has set on the window
   */
  GdkGeometry    geometry;	/* Geometry hints */
  GdkWindowHints mask;
  GtkWidget     *widget;	/* subwidget to which hints apply */
  gint           width;		/* Default size */
  gint           height;

  GtkWindowLastGeometryInfo last;
} GtkWindowGeometryInfo;

void
gtk_window_init (GtkWindow *window)
{
  GtkWindowPrivate *win;
  NSRect	contentRect;
  unsigned int windowStyle;
  GTK_WIDGET_UNSET_FLAGS (window, GTK_NO_WINDOW);
  GTK_WIDGET_SET_FLAGS (window, GTK_TOPLEVEL);

  gtk_container_set_resize_mode (GTK_CONTAINER (window), GTK_RESIZE_QUEUE);

  window->title = NULL;
  window->type = GTK_WINDOW_TOPLEVEL;
  window->focus_widget = NULL;
  window->default_widget = NULL;
  window->resize_count = 0;
  window->allow_shrink = FALSE;
  window->allow_grow = TRUE;
  window->auto_shrink = FALSE;
  window->handling_resize = FALSE;
  window->position = GTK_WIN_POS_NONE;
  window->use_uposition = TRUE;
  window->modal = FALSE;
  
  gtk_container_register_toplevel (GTK_CONTAINER (window));

  windowStyle = (NSTitledWindowMask | NSMiniaturizableWindowMask | 
                            NSResizableWindowMask | NSClosableWindowMask);
  win = [GtkWindowPrivate alloc];
  contentRect = NSMakeRect(0,0,100,500);
  
  win->widget = window;
  [win initWithContentRect:contentRect
		styleMask: windowStyle backing:NSBackingStoreBuffered defer: NO];
  [win setReleasedWhenClosed:NO];
  GTK_WIDGET(window)->window = [win contentView];
  GTK_WIDGET(window)->proxy = win;
}


void
gtk_window_realize (GtkWidget *widget)
{
    GtkWindow *window;
    GtkWindowPrivate  *  win;
    NSString *t;
    NSRect	contentRect,frame;

      g_return_if_fail (GTK_IS_WINDOW (widget));

  window = GTK_WINDOW (widget);

  /* ensure widget tree is properly size allocated */
  if (widget->allocation.x == -1 &&
      widget->allocation.y == -1 &&
      widget->allocation.width == 1 &&
      widget->allocation.height == 1)
    {
      GtkRequisition requisition;
      GtkAllocation allocation = { 0, 0, 200, 200 };

      gtk_widget_size_request (widget, &requisition);
      if (requisition.width || requisition.height)
	{
	  /* non-empty window */
	  allocation.width = requisition.width;
	  allocation.height = requisition.height;
	}
      gtk_widget_size_allocate (widget, &allocation);
      
      gtk_container_queue_resize (GTK_CONTAINER (widget));

      g_return_if_fail (!GTK_WIDGET_REALIZED (widget));
    }
  
  GTK_WIDGET_SET_FLAGS (widget, GTK_REALIZED);
  
    contentRect = NSMakeRect(widget->allocation.x, widget->allocation.y, 
        widget->allocation.width, widget->allocation.height);
        
	win = widget->proxy;
	[win setContentSize:contentRect.size];

	if(window->title)
	{
    	t = [NSString stringWithCString: window->title];
    	[win setTitle:t];
	}

  switch (window->type)
    {
    case GTK_WINDOW_TOPLEVEL:
         break;
    case GTK_WINDOW_DIALOG:
        break;
    case GTK_WINDOW_POPUP:
      break;
    }
   
  [[win contentView] setAutoresizesSubviews:FALSE];
//  [win setAutodisplay:FALSE];
//  [win useOptimizedDrawing:YES];
  [win setDelegate:win];  
  //[widget->proxy release];
  //widget->proxy = win;
  widget->window = [win contentView];
  //gdk_window_set_user_data (widget->window, window);

/*
  if (window->transient_parent &&
      GTK_WIDGET_REALIZED (window->transient_parent))
    gdk_window_set_transient_for (widget->window,
				  GTK_WIDGET (window->transient_parent)->window);
*/
    switch(window->position)
    {
		case GTK_WIN_POS_CENTER:
		  [win center];
			break;       
        case GTK_WIN_POS_MOUSE:
        {
            NSPoint mouseLoc = [NSEvent mouseLocation];
            NSSize winSize = [widget->proxy frame].size;
            
            mouseLoc.x -= winSize.width/2;
            mouseLoc.y -= winSize.height/2;
            [widget->proxy setFrameOrigin:mouseLoc];
            break;
        }
    }
  //  [win makeKeyAndOrderFront:win];
  //  [win display];
	frame = [win frame];
	frame.size.height++;
	[win setFrame:frame display:YES];
}

void
gtk_window_set_title (GtkWindow   *window,
		      const gchar *title)
{
  GtkWindowPrivate *win;
  NSString *t;
  g_return_if_fail (window != NULL);
  g_return_if_fail (GTK_IS_WINDOW (window));

  if (window->title)
    g_free (window->title);
  window->title = g_strdup (title);

  win  = (GtkWindowPrivate *)GTK_WIDGET (window)->proxy;
  if (GTK_WIDGET_REALIZED (window)) 
  { 
        t = [NSString stringWithCString: title];
       	[win setTitle:t];
  }
}


void        
gtk_window_set_default          (GtkWindow *window,
                                 GtkWidget *default_widget)
{
    GtkWindowPrivate *win;
    NSButtonCell *button = NULL; 
        
    g_return_if_fail (window != NULL);
    g_return_if_fail (GTK_IS_WINDOW (window));

    if (default_widget)
        g_return_if_fail (GTK_WIDGET_CAN_DEFAULT (default_widget));
    win = (GtkWindowPrivate *)GTK_WIDGET(window)->proxy;
	if(default_widget)
	    button = (NSButtonCell *)[((NSControl *)default_widget->proxy) cell];

  if (window->default_widget != default_widget)
    {
      if (window->default_widget)
	{
	  if (window->focus_widget != window->default_widget ||
	      !GTK_WIDGET_RECEIVES_DEFAULT (window->default_widget))
	    GTK_WIDGET_UNSET_FLAGS (window->default_widget, GTK_HAS_DEFAULT);
            [win setDefaultButtonCell:button];
	}

      window->default_widget = default_widget;
debug;
      if (window->default_widget)
	{
	  if (window->focus_widget == NULL ||
	      !GTK_WIDGET_RECEIVES_DEFAULT (window->focus_widget))
	    GTK_WIDGET_SET_FLAGS (window->default_widget, GTK_HAS_DEFAULT);
debug;      
            [win setDefaultButtonCell:button];
	}
    }
}

void       
gtk_window_set_default_size (GtkWindow   *window,
			     gint         width,
			     gint         height)
{
  GtkWindowPrivate *win; 
  GtkWindowGeometryInfo *info;

  g_return_if_fail (GTK_IS_WINDOW (window));

  win = (GtkWindowPrivate *)GTK_WIDGET(window)->proxy;
  info = gtk_window_get_geometry_info (window, TRUE);

  if (width >= 0)
    info->width = width;
  if (height >= 0)
    info->height = height;

  gtk_widget_queue_resize (GTK_WIDGET (window));
  [win setContentSize:NSMakeSize(width, height)];
}
 
void        
gtk_window_set_policy           (GtkWindow *window,
                                             gint allow_shrink,
                                             gint allow_grow,
                                             gint auto_shrink)
{
    GtkWindowPrivate *win; 
    g_return_if_fail (window != NULL);
    g_return_if_fail (GTK_IS_WINDOW (window));

    window->allow_shrink = (allow_shrink != FALSE);
    window->allow_grow = (allow_grow != FALSE);
    window->auto_shrink = (auto_shrink != FALSE);

    win = (GtkWindowPrivate *)GTK_WIDGET(window)->proxy;
    
    [win setShowsResizeIndicator:allow_grow];
}

void        
gtk_window_set_resizable           (GtkWindow *window, gint is_resizable)
{
    GtkWindowPrivate *win; 
    win = (GtkWindowPrivate *)GTK_WIDGET(window)->window;
    [win setShowsResizeIndicator:is_resizable];
}

void        gtk_window_set_geometry_hints   (GtkWindow *window,
                                             GtkWidget *geometry_widget,
                                             GdkGeometry *geometry,
                                             GdkWindowHints geom_mask)
{
    GtkWindowPrivate *win;
    GtkWindowGeometryInfo *info;

    g_return_if_fail (window != NULL);

    info = gtk_window_get_geometry_info (window, TRUE);
  
    if (info->widget)
        gtk_signal_disconnect_by_func (GTK_OBJECT (info->widget),
				   GTK_SIGNAL_FUNC (gtk_widget_destroyed),
				   &info->widget);
  
    info->widget = geometry_widget;
    if (info->widget)
        gtk_signal_connect (GTK_OBJECT (geometry_widget), "destroy",
			GTK_SIGNAL_FUNC (gtk_widget_destroyed),
			&info->widget);

    if (geometry)
        info->geometry = *geometry;
    
    info->mask = geom_mask;

    win = (GtkWindowPrivate *)GTK_WIDGET(window)->proxy;

    if(geom_mask & GDK_HINT_MIN_SIZE)
	[win setMinSize:NSMakeSize(geometry->min_width, geometry->min_height)]; 
    if(geom_mask & GDK_HINT_MAX_SIZE)
	[win setMaxSize:NSMakeSize(geometry->max_width, geometry->max_height)]; 
    if(geom_mask & GDK_HINT_ASPECT)
	[win setAspectRatio: NSMakeSize(geometry->min_aspect, 1.0)];
    if(geom_mask & GDK_HINT_RESIZE_INC)
	[win setResizeIncrements: NSMakeSize(geometry->width_inc, geometry->height_inc)];
}

void
ns_window_close(GtkWidget *window)
{
    [window->proxy close];
}

void
gtk_window_set_position (GtkWindow         *window,
			 GtkWindowPosition  position)
{
  g_return_if_fail (window != NULL);
  g_return_if_fail (GTK_IS_WINDOW (window));

  window->position = position;
}

void       
gtk_window_unset_transient_for  (GtkWindow *window)
{
  GtkWindowPrivate *win;
/*
  if (window->transient_parent)
    {
      gtk_signal_disconnect_by_func (GTK_OBJECT (window->transient_parent),
				     GTK_SIGNAL_FUNC (gtk_window_transient_parent_realized),
				     window);
      gtk_signal_disconnect_by_func (GTK_OBJECT (window->transient_parent),
				     GTK_SIGNAL_FUNC (gtk_window_transient_parent_unrealized),
				     window);
      gtk_signal_disconnect_by_func (GTK_OBJECT (window->transient_parent),
				     GTK_SIGNAL_FUNC (gtk_widget_destroyed),
				     &window->transient_parent);

      window->transient_parent = NULL;
    }
*/
    win = (GtkWindowPrivate *)GTK_WIDGET(window)->proxy;
	[win setLevel:NSNormalWindowLevel];
}

void       
gtk_window_set_transient_for  (GtkWindow *window, 
			       GtkWindow *parent)
{
  GtkWindowPrivate *win;
  g_return_if_fail (window != 0);

/*
  if (window->transient_parent)
    {
      if (GTK_WIDGET_REALIZED (window) && 
	  GTK_WIDGET_REALIZED (window->transient_parent) && 
	  (!parent || !GTK_WIDGET_REALIZED (parent)))
	gtk_window_transient_parent_unrealized (GTK_WIDGET (window->transient_parent),
						GTK_WIDGET (window));

      gtk_window_unset_transient_for (window);
    }

  window->transient_parent = parent;

  if (parent)
    {
      gtk_signal_connect (GTK_OBJECT (parent), "destroy",
			  GTK_SIGNAL_FUNC (gtk_widget_destroyed),
			  &window->transient_parent);
      gtk_signal_connect (GTK_OBJECT (parent), "realize",
			  GTK_SIGNAL_FUNC (gtk_window_transient_parent_realized),
			  window);
      gtk_signal_connect (GTK_OBJECT (parent), "unrealize",
			  GTK_SIGNAL_FUNC (gtk_window_transient_parent_unrealized),
			  window);

      if (GTK_WIDGET_REALIZED (window) &&
	  GTK_WIDGET_REALIZED (parent))
	gtk_window_transient_parent_realized (GTK_WIDGET (parent),
					      GTK_WIDGET (window));
    }
*/
    win = (GtkWindowPrivate *)GTK_WIDGET(window)->proxy;
	[win setLevel:NSFloatingWindowLevel];
}

void
gtk_window_show (GtkWidget *widget)
{
  GtkWindow *window = GTK_WINDOW (widget);
  GtkContainer *container = GTK_CONTAINER (window);
  gboolean need_resize;

  GTK_WIDGET_SET_FLAGS (widget, GTK_VISIBLE);

  need_resize = container->need_resize || !GTK_WIDGET_REALIZED (widget);
  container->need_resize = FALSE;

  if (need_resize)
    {
      GtkWindowGeometryInfo *info = gtk_window_get_geometry_info (window, TRUE);
      GtkAllocation allocation = { 0, 0 };
      GdkGeometry new_geometry;
      guint width, height, new_flags;

      /* determine default size to initially show the window with */
      gtk_widget_size_request (widget, NULL);
      gtk_window_compute_default_size (window, &width, &height);

      /* save away the last default size for later comparisions */
      info->last.width = width;
      info->last.height = height;

      /* constrain size to geometry */
      gtk_window_compute_hints (window, &new_geometry, &new_flags);
      gtk_window_constrain_size (window,
				 &new_geometry, new_flags,
				 width, height,
				 &width, &height);

      /* and allocate the window */
      allocation.width  = width;
      allocation.height = height;
      gtk_widget_size_allocate (widget, &allocation);
      
      if (GTK_WIDGET_REALIZED (widget))
		;//gdk_window_resize (widget->window, width, height);
      else
	gtk_widget_realize (widget);
    }
  
  gtk_container_check_resize (container);

  gtk_widget_map (widget);

 [widget->proxy makeKeyAndOrderFront:widget->proxy ];

/*
  if (window->modal)
    gtk_grab_add (widget);
*/
}

