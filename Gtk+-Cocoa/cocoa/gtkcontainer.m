//
//  gtkcontainer.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 17 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import	"NSGtkView.h"
#import "GtkWindowPrivate.h"

#include <gtk/gtk.h>

enum {
  ADD,
  REMOVE,
  CHECK_RESIZE,
  FOCUS,
  SET_FOCUS_CHILD,
  LAST_SIGNAL
};

extern guint container_signals[LAST_SIGNAL];

void
gtk_container_add (GtkContainer *container,
		   GtkWidget    *widget)
{    
  NSView *view,*subView;
  GtkWindowPrivate *win;
  
  g_return_if_fail (container != NULL);
  g_return_if_fail (GTK_IS_CONTAINER (container));
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_WIDGET (widget));
  g_return_if_fail (widget->parent == NULL);
/*
    view = (NSView *)GTK_WIDGET(container)->proxy;
    win = (GtkWindowPrivate *)GTK_WIDGET(container)->window;
    subView = (NSView *)widget->proxy;
     
    if(win)
    {
        view = [win contentView];
    }
   
	printf("subview %f %f\n",[subView frame].origin.x,[subView frame].origin.y); 
    [view addSubview:subView];
	//widget->superview = view;
    [subView display];
*/
     gtk_signal_emit (GTK_OBJECT (container), container_signals[ADD], widget);
}

void
gtk_container_init (GtkContainer *container)
{
  NSGtkView *view;

  container->focus_child = NULL;
  container->border_width = 0;
  container->need_resize = FALSE;
  container->resize_mode = GTK_RESIZE_PARENT;
  container->reallocate_redraws = FALSE;
  container->resize_widgets = NULL;
  view =[[NSGtkView alloc] initWithFrame:NSMakeRect(0,0,100,200)];
  [view setAutoresizesSubviews:FALSE];
  view->proxy = container;
  [GTK_WIDGET(container)->proxy release];
  GTK_WIDGET(container)->proxy = view;
}


