//
//  gdkwidow.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
/* Needed for SEEK_END in SunOS */
#include <unistd.h>

#include "gdk.h"
#include "gdkprivate.h"

void
gdk_window_raise (GdkWindow *window)
{
	[window makeKeyAndOrderFront:window];
}

void
gdk_window_get_position (GdkWindow *window,
			 gint      *x,
			 gint      *y)
{
	NSPoint p;

	p = [window frame].origin;
	*x = p.x;
	*y = p.y;
}

GdkWindow*
gdk_window_get_pointer (GdkWindow       *window,
			gint            *x,
			gint            *y,
			GdkModifierType *mask)
{
	NSPoint p;

	p = [window mouseLocationOutsideOfEventStream];
    if(x)
        *x = p.x;
    
    if(y)
        *y = p.y;

	return window;
}


void
gdk_window_get_size (GdkWindow *window,
		     gint       *width,
		     gint       *height)
{
#if 0
  GdkWindowPrivate *window_private;
  
  g_return_if_fail (window != NULL);
  
  window_private = (GdkWindowPrivate*) window;
  
  if (width)
    *width = window_private->width;
  if (height)
    *height = window_private->height;
#endif
if (width)
    *width = [window frame].size.width;
  if (height)
    *height = [window frame].size.height;
}

GdkWindow*
gdk_window_get_parent (GdkWindow *window)
{

  g_return_val_if_fail (window != NULL, NULL);
  
  if(![window superview])
        return [window window];
        
  return [window superview];

}

GList*
gdk_window_get_children (GdkWindow *window)
{
/*
  GdkWindowPrivate *private;
  GdkWindow *child;
  GList *children;
  unsigned int nchildren;
  unsigned int i;
  
  g_return_val_if_fail (window != NULL, NULL);
  
  private = (GdkWindowPrivate*) window;
  if (private->destroyed)
    return NULL;
  
  children = NULL;
  
  if (nchildren > 0)
    {
      for (i = 0; i < nchildren; i++)
	{
	  child = gdk_window_lookup (xchildren[i]);
          if (child)
            children = g_list_prepend (children, child);
	}
      
    }
  
  return children;
*/
return NULL;
}
