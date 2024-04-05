/* GDK - The GIMP Drawing Kit
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

#include "gdk.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>


/* Forward declarations */
static gboolean gdk_window_gravity_works (void);
static void     gdk_window_set_static_win_gravity (GdkWindow *window, 
						   gboolean   on);
static gboolean gdk_window_have_shape_ext (void);

void
gdk_window_init (void)
{
#if 0
  XWindowAttributes xattributes;
  unsigned int width;
  unsigned int height;
  unsigned int border_width;
  unsigned int depth;
  int x, y;
  
  XGetGeometry (gdk_display, gdk_root_window, &gdk_root_window,
		&x, &y, &width, &height, &border_width, &depth);
  XGetWindowAttributes (gdk_display, gdk_root_window, &xattributes);
  
  gdk_root_parent.xwindow = gdk_root_window;
  gdk_root_parent.xdisplay = gdk_display;
  gdk_root_parent.window_type = GDK_WINDOW_ROOT;
  gdk_root_parent.window.user_data = NULL;
  gdk_root_parent.width = width;
  gdk_root_parent.height = height;
  gdk_root_parent.children = NULL;
  gdk_root_parent.colormap = NULL;
  gdk_root_parent.ref_count = 1;
  
  gdk_xid_table_insert (&gdk_root_window, &gdk_root_parent);
#endif
}

GdkWindow*
gdk_window_new (GdkWindow     *parent,
		GdkWindowAttr *attributes,
		gint           attributes_mask)
{
#if 0
  GdkWindow *window;
  GdkWindowPrivate *private;
  GdkWindowPrivate *parent_private;
  GdkVisual *visual;
  Display *parent_display;
  Window xparent;
  Visual *xvisual;
  XSetWindowAttributes xattributes;
  long xattributes_mask;
  XSizeHints size_hints;
  XWMHints wm_hints;
  XClassHint *class_hint;
  int x, y, depth;
  unsigned int class;
  char *title;
  int i;
  
  g_return_val_if_fail (attributes != NULL, NULL);
  
  if (!parent)
    parent = (GdkWindow*) &gdk_root_parent;
  
  parent_private = (GdkWindowPrivate*) parent;
  if (parent_private->destroyed)
    return NULL;
  
  xparent = parent_private->xwindow;
  parent_display = parent_private->xdisplay;
  
  private = g_new (GdkWindowPrivate, 1);
  window = (GdkWindow*) private;
  
  private->parent = parent;
  
  private->xdisplay = parent_display;
  private->destroyed = FALSE;
  private->mapped = FALSE;
  private->guffaw_gravity = FALSE;
  private->resize_count = 0;
  private->ref_count = 1;
  xattributes_mask = 0;
  
  if (attributes_mask & GDK_WA_X)
    x = attributes->x;
  else
    x = 0;
  
  if (attributes_mask & GDK_WA_Y)
    y = attributes->y;
  else
    y = 0;
  
  private->x = x;
  private->y = y;
  private->width = (attributes->width > 1) ? (attributes->width) : (1);
  private->height = (attributes->height > 1) ? (attributes->height) : (1);
  private->window_type = attributes->window_type;
  private->extension_events = FALSE;
  
  private->filters = NULL;
  private->children = NULL;
  
  window->user_data = NULL;
  
  if (attributes_mask & GDK_WA_VISUAL)
    visual = attributes->visual;
  else
    visual = gdk_visual_get_system ();
  xvisual = ((GdkVisualPrivate*) visual)->xvisual;
  
  xattributes.event_mask = StructureNotifyMask;
  for (i = 0; i < gdk_nevent_masks; i++)
    {
      if (attributes->event_mask & (1 << (i + 1)))
	xattributes.event_mask |= gdk_event_mask_table[i];
    }
  
  if (xattributes.event_mask)
    xattributes_mask |= CWEventMask;
  
  if (attributes_mask & GDK_WA_NOREDIR)
    {
      xattributes.override_redirect =
	(attributes->override_redirect == FALSE)?False:True;
      xattributes_mask |= CWOverrideRedirect;
    } 
  else
    xattributes.override_redirect = False;
  
  if (parent_private && parent_private->guffaw_gravity)
    {
      xattributes.win_gravity = StaticGravity;
      xattributes_mask |= CWWinGravity;
    }
  
  if (attributes->wclass == GDK_INPUT_OUTPUT)
    {
      class = InputOutput;
      depth = visual->depth;
      
      if (attributes_mask & GDK_WA_COLORMAP)
	private->colormap = attributes->colormap;
      else
	{
	  if ((((GdkVisualPrivate*)gdk_visual_get_system ())->xvisual) == xvisual)
	    private->colormap = gdk_colormap_get_system ();
	  else
	    private->colormap = gdk_colormap_new (visual, False);
	}
      
      xattributes.background_pixel = BlackPixel (gdk_display, gdk_screen);
      xattributes.border_pixel = BlackPixel (gdk_display, gdk_screen);
      xattributes_mask |= CWBorderPixel | CWBackPixel;
      
      switch (private->window_type)
	{
	case GDK_WINDOW_TOPLEVEL:
	  xattributes.colormap = ((GdkColormapPrivate*) private->colormap)->xcolormap;
	  xattributes_mask |= CWColormap;
	  
	  xparent = gdk_root_window;
	  break;
	  
	case GDK_WINDOW_CHILD:
	  xattributes.colormap = ((GdkColormapPrivate*) private->colormap)->xcolormap;
	  xattributes_mask |= CWColormap;
	  break;
	  
	case GDK_WINDOW_DIALOG:
	  xattributes.colormap = ((GdkColormapPrivate*) private->colormap)->xcolormap;
	  xattributes_mask |= CWColormap;
	  
	  xparent = gdk_root_window;
	  break;
	  
	case GDK_WINDOW_TEMP:
	  xattributes.colormap = ((GdkColormapPrivate*) private->colormap)->xcolormap;
	  xattributes_mask |= CWColormap;
	  
	  xparent = gdk_root_window;
	  
	  xattributes.save_under = True;
	  xattributes.override_redirect = True;
	  xattributes.cursor = None;
	  xattributes_mask |= CWSaveUnder | CWOverrideRedirect;
	  break;
	case GDK_WINDOW_ROOT:
	  g_error ("cannot make windows of type GDK_WINDOW_ROOT");
	  break;
	case GDK_WINDOW_PIXMAP:
	  g_error ("cannot make windows of type GDK_WINDOW_PIXMAP (use gdk_pixmap_new)");
	  break;
	}
    }
  else
    {
      depth = 0;
      class = InputOnly;
      private->colormap = gdk_colormap_get_system ();
    }
  
  private->xwindow = XCreateWindow (private->xdisplay, xparent,
				    x, y, private->width, private->height,
				    0, depth, class, xvisual,
				    xattributes_mask, &xattributes);
  gdk_window_ref (window);
  gdk_xid_table_insert (&private->xwindow, window);
  
  if (private->colormap)
    gdk_colormap_ref (private->colormap);
  
  gdk_window_set_cursor (window, ((attributes_mask & GDK_WA_CURSOR) ?
				  (attributes->cursor) :
				  NULL));
  
  if (parent_private)
    parent_private->children = g_list_prepend (parent_private->children, window);
  
  switch (private->window_type)
    {
    case GDK_WINDOW_DIALOG:
      XSetTransientForHint (private->xdisplay, private->xwindow, xparent);
    case GDK_WINDOW_TOPLEVEL:
    case GDK_WINDOW_TEMP:
      XSetWMProtocols (private->xdisplay, private->xwindow, gdk_wm_window_protocols, 2);
      break;
    case GDK_WINDOW_CHILD:
      if ((attributes->wclass == GDK_INPUT_OUTPUT) &&
	  (private->colormap != gdk_colormap_get_system ()) &&
	  (private->colormap != gdk_window_get_colormap (gdk_window_get_toplevel (window))))
	{
	  GDK_NOTE (MISC, g_message ("adding colormap window\n"));
	  gdk_window_add_colormap_windows (window);
	}
      
      return window;
    default:
      
      return window;
    }
  
  size_hints.flags = PSize;
  size_hints.width = private->width;
  size_hints.height = private->height;
  
  wm_hints.flags = InputHint | StateHint | WindowGroupHint;
  wm_hints.window_group = gdk_leader_window;
  wm_hints.input = True;
  wm_hints.initial_state = NormalState;
  
  /* FIXME: Is there any point in doing this? Do any WM's pay
   * attention to PSize, and even if they do, is this the
   * correct value???
   */
  XSetWMNormalHints (private->xdisplay, private->xwindow, &size_hints);
  
  XSetWMHints (private->xdisplay, private->xwindow, &wm_hints);
  
  if (!wm_client_leader_atom)
    wm_client_leader_atom = gdk_atom_intern ("WM_CLIENT_LEADER", FALSE);
  
  XChangeProperty (private->xdisplay, private->xwindow,
	   	   wm_client_leader_atom,
		   XA_WINDOW, 32, PropModeReplace,
		   (guchar*) &gdk_leader_window, 1);
  
  if (attributes_mask & GDK_WA_TITLE)
    title = attributes->title;
  else
    title = g_get_prgname ();
  
  XmbSetWMProperties (private->xdisplay, private->xwindow,
                      title, title,
                      NULL, 0,
                      NULL, NULL, NULL);
  
  if (attributes_mask & GDK_WA_WMCLASS)
    {
      class_hint = XAllocClassHint ();
      class_hint->res_name = attributes->wmclass_name;
      class_hint->res_class = attributes->wmclass_class;
      XSetClassHint (private->xdisplay, private->xwindow, class_hint);
      XFree (class_hint);
    }
  
  
  return window;
#endif
}

GdkWindow *
gdk_window_foreign_new (guint32 anid)
{
#if 0
  GdkWindow *window;
  GdkWindowPrivate *private;
  GdkWindowPrivate *parent_private;
  XWindowAttributes attrs;
  Window root, parent;
  Window *children = NULL;
  guint nchildren;
  gboolean result;

  gdk_error_trap_push ();
  result = XGetWindowAttributes (gdk_display, anid, &attrs);
  if (gdk_error_trap_pop () || !result)
    return NULL;

  /* FIXME: This is pretty expensive. Maybe the caller should supply
   *        the parent */
  gdk_error_trap_push ();
  result = XQueryTree (gdk_display, anid, &root, &parent, &children, &nchildren);
  if (gdk_error_trap_pop () || !result)
    return NULL;
  
  private = g_new (GdkWindowPrivate, 1);
  window = (GdkWindow*) private;
  
  if (children)
    XFree (children);
  private->parent = gdk_xid_table_lookup (parent);
  
  parent_private = (GdkWindowPrivate *)private->parent;
  
  if (parent_private)
    parent_private->children = g_list_prepend (parent_private->children, window);
  
  private->xwindow = anid;
  private->xdisplay = gdk_display;
  private->x = attrs.x;
  private->y = attrs.y;
  private->width = attrs.width;
  private->height = attrs.height;
  private->resize_count = 0;
  private->ref_count = 1;
  private->window_type = GDK_WINDOW_FOREIGN;
  private->destroyed = FALSE;
  private->mapped = (attrs.map_state != IsUnmapped);
  private->guffaw_gravity = FALSE;
  private->extension_events = 0;
  
  private->colormap = NULL;
  
  private->filters = NULL;
  private->children = NULL;
  
  window->user_data = NULL;
  
  gdk_window_ref (window);
  gdk_xid_table_insert (&private->xwindow, window);
  
  return window;
#endif
}

void
gdk_window_destroy (GdkWindow *window)
{
}

/* This function is called when the XWindow is really gone.  */

void
gdk_window_destroy_notify (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed)
    {
      if (private->window_type != GDK_WINDOW_FOREIGN)
	g_warning ("GdkWindow %#lx unexpectedly destroyed", private->xwindow);

      gdk_window_internal_destroy (window, FALSE, FALSE);
    }
  
  gdk_xid_table_remove (private->xwindow);
  gdk_window_unref (window);
#endif
}

GdkWindow*
gdk_window_ref (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private = (GdkWindowPrivate *)window;
  g_return_val_if_fail (window != NULL, NULL);
  
  private->ref_count += 1;
  return window;
#endif
}

void
gdk_window_unref (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private = (GdkWindowPrivate *)window;
  g_return_if_fail (window != NULL);
  g_return_if_fail (private->ref_count > 0);
  
  private->ref_count -= 1;
  if (private->ref_count == 0)
    {
      if (!private->destroyed)
	{
	  if (private->window_type == GDK_WINDOW_FOREIGN)
	    gdk_xid_table_remove (private->xwindow);
	  else
	    g_warning ("losing last reference to undestroyed window\n");
	}
      g_dataset_destroy (window);
      g_free (window);
    }
#endif
}

void
gdk_window_show (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (!private->destroyed)
    {
      private->mapped = TRUE;
      XRaiseWindow (private->xdisplay, private->xwindow);
      XMapWindow (private->xdisplay, private->xwindow);
    }
#endif
}

void
gdk_window_hide (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (!private->destroyed)
    {
      private->mapped = FALSE;
      XUnmapWindow (private->xdisplay, private->xwindow);
    }
#endif
}

void
gdk_window_withdraw (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (!private->destroyed)
    XWithdrawWindow (private->xdisplay, private->xwindow, 0);
#endif
}

void
gdk_window_move (GdkWindow *window,
		 gint       x,
		 gint       y)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (!private->destroyed)
    {
      XMoveWindow (private->xdisplay, private->xwindow, x, y);
      
      if (private->window_type == GDK_WINDOW_CHILD)
	{
	  private->x = x;
	  private->y = y;
	}
    }
#endif
}

void
gdk_window_resize (GdkWindow *window,
		   gint       width,
		   gint       height)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  if (width < 1)
    width = 1;
  if (height < 1)
    height = 1;
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed &&
      ((private->resize_count > 0) ||
       (private->width != (guint16) width) ||
       (private->height != (guint16) height)))
    {
      XResizeWindow (private->xdisplay, private->xwindow, width, height);
      private->resize_count += 1;
      
      if (private->window_type == GDK_WINDOW_CHILD)
	{
	  private->width = width;
	  private->height = height;
	}
    }
#endif
}

void
gdk_window_move_resize (GdkWindow *window,
			gint       x,
			gint       y,
			gint       width,
			gint       height)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  if (width < 1)
    width = 1;
  if (height < 1)
    height = 1;
  
  private = (GdkWindowPrivate*) window;
  if (!private->destroyed)
    {
      XMoveResizeWindow (private->xdisplay, private->xwindow, x, y, width, height);
      
      if (private->guffaw_gravity)
	{
	  GList *tmp_list = private->children;
	  while (tmp_list)
	    {
	      GdkWindowPrivate *child_private = tmp_list->data;
	      
	      child_private->x -= x - private->x;
	      child_private->y -= y - private->y;
	      
	      tmp_list = tmp_list->next;
	    }
	}
      
      if (private->window_type == GDK_WINDOW_CHILD)
	{
	  private->x = x;
	  private->y = y;
	  private->width = width;
	  private->height = height;
	}
    }
#endif
}

void
gdk_window_reparent (GdkWindow *window,
		     GdkWindow *new_parent,
		     gint       x,
		     gint       y)
{
#if 0
  GdkWindowPrivate *window_private;
  GdkWindowPrivate *parent_private;
  GdkWindowPrivate *old_parent_private;
  
  g_return_if_fail (window != NULL);
  
  if (!new_parent)
    new_parent = (GdkWindow*) &gdk_root_parent;
  
  window_private = (GdkWindowPrivate*) window;
  old_parent_private = (GdkWindowPrivate*)window_private->parent;
  parent_private = (GdkWindowPrivate*) new_parent;
  
  if (!window_private->destroyed && !parent_private->destroyed)
    XReparentWindow (window_private->xdisplay,
		     window_private->xwindow,
		     parent_private->xwindow,
		     x, y);
  
  window_private->parent = new_parent;
  
  if (old_parent_private)
    old_parent_private->children = g_list_remove (old_parent_private->children, window);
  
  if ((old_parent_private &&
       (!old_parent_private->guffaw_gravity != !parent_private->guffaw_gravity)) ||
      (!old_parent_private && parent_private->guffaw_gravity))
    gdk_window_set_static_win_gravity (window, parent_private->guffaw_gravity);
  
  parent_private->children = g_list_prepend (parent_private->children, window);
#endif
}

void
gdk_window_clear (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed)
    XClearWindow (private->xdisplay, private->xwindow);
#endif
}

void
gdk_window_clear_area (GdkWindow *window,
		       gint       x,
		       gint       y,
		       gint       width,
		       gint       height)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed)
    XClearArea (private->xdisplay, private->xwindow,
		x, y, width, height, False);
#endif
}

void
gdk_window_clear_area_e (GdkWindow *window,
		         gint       x,
		         gint       y,
		         gint       width,
		         gint       height)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed)
    XClearArea (private->xdisplay, private->xwindow,
		x, y, width, height, True);
#endif
}

void
gdk_window_copy_area (GdkWindow    *window,
		      GdkGC        *gc,
		      gint          x,
		      gint          y,
		      GdkWindow    *source_window,
		      gint          source_x,
		      gint          source_y,
		      gint          width,
		      gint          height)
{
#if 0
  GdkWindowPrivate *src_private;
  GdkWindowPrivate *dest_private;
  GdkGCPrivate *gc_private;
  
  g_return_if_fail (window != NULL);
  g_return_if_fail (gc != NULL);
  
  if (source_window == NULL)
    source_window = window;
  
  src_private = (GdkWindowPrivate*) source_window;
  dest_private = (GdkWindowPrivate*) window;
  gc_private = (GdkGCPrivate*) gc;
  
  if (!src_private->destroyed && !dest_private->destroyed)
    {
      XCopyArea (dest_private->xdisplay, src_private->xwindow, dest_private->xwindow,
		 gc_private->xgc,
		 source_x, source_y,
		 width, height,
		 x, y);
    }
#endif
}

void
gdk_window_lower (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed)
    XLowerWindow (private->xdisplay, private->xwindow);
#endif
}

void
gdk_window_set_user_data (GdkWindow *window,
			  gpointer   user_data)
{
#if 0
  g_return_if_fail (window != NULL);
  
  window->user_data = user_data;
#endif
}

void
gdk_window_set_hints (GdkWindow *window,
		      gint       x,
		      gint       y,
		      gint       min_width,
		      gint       min_height,
		      gint       max_width,
		      gint       max_height,
		      gint       flags)
{
#if 0
  GdkWindowPrivate *private;
  XSizeHints size_hints;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (private->destroyed)
    return;
  
  size_hints.flags = 0;
  
  if (flags & GDK_HINT_POS)
    {
      size_hints.flags |= PPosition;
      size_hints.x = x;
      size_hints.y = y;
    }
  
  if (flags & GDK_HINT_MIN_SIZE)
    {
      size_hints.flags |= PMinSize;
      size_hints.min_width = min_width;
      size_hints.min_height = min_height;
    }
  
  if (flags & GDK_HINT_MAX_SIZE)
    {
      size_hints.flags |= PMaxSize;
      size_hints.max_width = max_width;
      size_hints.max_height = max_height;
    }
  
  /* FIXME: Would it be better to delete this property of
   *        flags == 0? It would save space on the server
   */
  XSetWMNormalHints (private->xdisplay, private->xwindow, &size_hints);
#endif
}

void 
gdk_window_set_geometry_hints (GdkWindow      *window,
			       GdkGeometry    *geometry,
			       GdkWindowHints  geom_mask)
{
#if 0
  GdkWindowPrivate *private;
  XSizeHints size_hints;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (private->destroyed)
    return;
  
  size_hints.flags = 0;
  
  if (geom_mask & GDK_HINT_POS)
    {
      size_hints.flags |= PPosition;
      /* We need to initialize the following obsolete fields because KWM 
       * apparently uses these fields if they are non-zero.
       * #@#!#!$!.
       */
      size_hints.x = 0;
      size_hints.y = 0;
    }
  
  if (geom_mask & GDK_HINT_MIN_SIZE)
    {
      size_hints.flags |= PMinSize;
      size_hints.min_width = geometry->min_width;
      size_hints.min_height = geometry->min_height;
    }
  
  if (geom_mask & GDK_HINT_MAX_SIZE)
    {
      size_hints.flags |= PMaxSize;
      size_hints.max_width = MAX (geometry->max_width, 1);
      size_hints.max_height = MAX (geometry->max_height, 1);
    }
  
  if (geom_mask & GDK_HINT_BASE_SIZE)
    {
      size_hints.flags |= PBaseSize;
      size_hints.base_width = geometry->base_width;
      size_hints.base_height = geometry->base_height;
    }
  
  if (geom_mask & GDK_HINT_RESIZE_INC)
    {
      size_hints.flags |= PResizeInc;
      size_hints.width_inc = geometry->width_inc;
      size_hints.height_inc = geometry->height_inc;
    }
  
  if (geom_mask & GDK_HINT_ASPECT)
    {
      size_hints.flags |= PAspect;
      if (geometry->min_aspect <= 1)
	{
	  size_hints.min_aspect.x = 65536 * geometry->min_aspect;
	  size_hints.min_aspect.y = 65536;
	}
      else
	{
	  size_hints.min_aspect.x = 65536;
	  size_hints.min_aspect.y = 65536 / geometry->min_aspect;;
	}
      if (geometry->max_aspect <= 1)
	{
	  size_hints.max_aspect.x = 65536 * geometry->max_aspect;
	  size_hints.max_aspect.y = 65536;
	}
      else
	{
	  size_hints.max_aspect.x = 65536;
	  size_hints.max_aspect.y = 65536 / geometry->max_aspect;;
	}
    }

  /* FIXME: Would it be better to delete this property of
   *        geom_mask == 0? It would save space on the server
   */
  XSetWMNormalHints (private->xdisplay, private->xwindow, &size_hints);
#endif
}

void
gdk_window_set_title (GdkWindow   *window,
		      const gchar *title)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (!private->destroyed)
    XmbSetWMProperties (private->xdisplay, private->xwindow,
			title, title, NULL, 0, NULL, NULL, NULL);
#endif
}

void          
gdk_window_set_role (GdkWindow   *window,
		     const gchar *role)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  
  if (role)
    XChangeProperty (private->xdisplay, private->xwindow,
		     gdk_atom_intern ("WM_WINDOW_ROLE", FALSE), XA_STRING,
		     8, PropModeReplace, role, strlen (role));
  else
    XDeleteProperty (private->xdisplay, private->xwindow,
		     gdk_atom_intern ("WM_WINDOW_ROLE", FALSE));
#endif
}

void          
gdk_window_set_transient_for (GdkWindow *window, 
			      GdkWindow *parent)
{
#if 0
  GdkWindowPrivate *private;
  GdkWindowPrivate *parent_private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  parent_private = (GdkWindowPrivate*) parent;
  
  if (!private->destroyed && !parent_private->destroyed)
    XSetTransientForHint (private->xdisplay, 
			  private->xwindow, parent_private->xwindow);
#endif
}

void
gdk_window_set_background (GdkWindow *window,
			   GdkColor  *color)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (!private->destroyed)
    XSetWindowBackground (private->xdisplay, private->xwindow, color->pixel);
#endif
}



void
gdk_window_set_cursor (GdkWindow *window,
		       GdkCursor *cursor)
{
#if 0
  GdkWindowPrivate *window_private;
  GdkCursorPrivate *cursor_private;
  Cursor xcursor;
  
  g_return_if_fail (window != NULL);
  
  window_private = (GdkWindowPrivate*) window;
  cursor_private = (GdkCursorPrivate*) cursor;
  
  if (!cursor)
    xcursor = None;
  else
    xcursor = cursor_private->xcursor;
  
  if (!window_private->destroyed)
    XDefineCursor (window_private->xdisplay, window_private->xwindow, xcursor);
#endif

}

void
gdk_window_set_colormap (GdkWindow   *window,
			 GdkColormap *colormap)
{
#if 0
  GdkWindowPrivate *window_private;
  GdkColormapPrivate *colormap_private;
  
  g_return_if_fail (window != NULL);
  g_return_if_fail (colormap != NULL);
  
  window_private = (GdkWindowPrivate*) window;
  colormap_private = (GdkColormapPrivate*) colormap;
  
  if (!window_private->destroyed)
    {
      XSetWindowColormap (window_private->xdisplay,
			  window_private->xwindow,
			  colormap_private->xcolormap);
      
      if (window_private->colormap)
	gdk_colormap_unref (window_private->colormap);
      window_private->colormap = colormap;
      gdk_colormap_ref (window_private->colormap);
      
      if (window_private->window_type != GDK_WINDOW_TOPLEVEL)
	gdk_window_add_colormap_windows (window);
    }
#endif
}

void
gdk_window_get_user_data (GdkWindow *window,
			  gpointer  *data)
{

  g_return_if_fail (window != NULL);
  
  *data = window->user_data;

}

void
gdk_window_get_geometry (GdkWindow *window,
			 gint      *x,
			 gint      *y,
			 gint      *width,
			 gint      *height,
			 gint      *depth)
{
#if 0
  GdkWindowPrivate *window_private;
  Window root;
  gint tx;
  gint ty;
  guint twidth;
  guint theight;
  guint tborder_width;
  guint tdepth;
  
  if (!window)
    window = (GdkWindow*) &gdk_root_parent;
  
  window_private = (GdkWindowPrivate*) window;
  
  if (!window_private->destroyed)
    {
      XGetGeometry (window_private->xdisplay, window_private->xwindow,
		    &root, &tx, &ty, &twidth, &theight, &tborder_width, &tdepth);
      
      if (x)
	*x = tx;
      if (y)
	*y = ty;
      if (width)
	*width = twidth;
      if (height)
	*height = theight;
      if (depth)
	*depth = tdepth;
    }
#endif
}



GdkVisual*
gdk_window_get_visual (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *window_private;
  XWindowAttributes window_attributes;
  
  g_return_val_if_fail (window != NULL, NULL);
  
  window_private = (GdkWindowPrivate*) window;
  /* Huh? ->parent is never set for a pixmap. We should just return
   * null immeditately
   */
  while (window_private && (window_private->window_type == GDK_WINDOW_PIXMAP))
    window_private = (GdkWindowPrivate*) window_private->parent;
  
  if (window_private && !window_private->destroyed)
    {
      if (window_private->colormap == NULL)
	{
	  XGetWindowAttributes (window_private->xdisplay,
				window_private->xwindow,
				&window_attributes);
	  return gdk_visual_lookup (window_attributes.visual);
	}
      else
	return ((GdkColormapPrivate *)window_private->colormap)->visual;
    }
#endif  
  return NULL;
}

GdkColormap*
gdk_window_get_colormap (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *window_private;
  XWindowAttributes window_attributes;
  
  g_return_val_if_fail (window != NULL, NULL);
  window_private = (GdkWindowPrivate*) window;
  
  g_return_val_if_fail (window_private->window_type != GDK_WINDOW_PIXMAP, NULL);
  if (!window_private->destroyed)
    {
      if (window_private->colormap == NULL)
	{
	  XGetWindowAttributes (window_private->xdisplay,
				window_private->xwindow,
				&window_attributes);
	  return gdk_colormap_lookup (window_attributes.colormap);
	}
      else
	return window_private->colormap;
    }
  
#endif
  return NULL;
}

GdkWindowType
gdk_window_get_type (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *window_private;
  
  g_return_val_if_fail (window != NULL, (GdkWindowType) -1);
  
  window_private = (GdkWindowPrivate*) window;
  return window_private->window_type;
#endif
}

gint
gdk_window_get_origin (GdkWindow *window,
		       gint      *x,
		       gint      *y)
{
#if 0
  GdkWindowPrivate *private;
  gint return_val;
  Window child;
  gint tx = 0;
  gint ty = 0;
  
  g_return_val_if_fail (window != NULL, 0);
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed)
    {
      return_val = XTranslateCoordinates (private->xdisplay,
					  private->xwindow,
					  gdk_root_window,
					  0, 0, &tx, &ty,
					  &child);
      
    }
  else
    return_val = 0;
  
  if (x)
    *x = tx;
  if (y)
    *y = ty;
  
  return return_val;
#endif
}

gboolean
gdk_window_get_deskrelative_origin (GdkWindow *window,
				    gint      *x,
				    gint      *y)
{
#if 0
  GdkWindowPrivate *private;
  gboolean return_val = FALSE;
  gint num_children, format_return;
  Window win, *child, parent, root;
  gint tx = 0;
  gint ty = 0;
  Atom type_return;
  static Atom atom = 0;
  gulong number_return, bytes_after_return;
  guchar *data_return;
  
  g_return_val_if_fail (window != NULL, 0);
  
  private = (GdkWindowPrivate*) window;
  
  if (!private->destroyed)
    {
      if (!atom)
	atom = XInternAtom (private->xdisplay, "ENLIGHTENMENT_DESKTOP", False);
      win = private->xwindow;
      
      while (XQueryTree (private->xdisplay, win, &root, &parent,
			 &child, (unsigned int *)&num_children))
	{
	  if ((child) && (num_children > 0))
	    XFree (child);
	  
	  if (!parent)
	    break;
	  else
	    win = parent;
	  
	  if (win == root)
	    break;
	  
	  data_return = NULL;
	  XGetWindowProperty (private->xdisplay, win, atom, 0, 0,
			      False, XA_CARDINAL, &type_return, &format_return,
			      &number_return, &bytes_after_return, &data_return);
	  if (type_return == XA_CARDINAL)
	    {
	      XFree (data_return);
              break;
	    }
	}
      
      return_val = XTranslateCoordinates (private->xdisplay,
					  private->xwindow,
					  win,
					  0, 0, &tx, &ty,
					  &root);
      if (x)
	*x = tx;
      if (y)
	*y = ty;
    }
  
  
  return return_val;
#endif
}

void
gdk_window_get_root_origin (GdkWindow *window,
			    gint      *x,
			    gint      *y)
{
#if 0
  GdkWindowPrivate *private;
  Window xwindow;
  Window xparent;
  Window root;
  Window *children;
  unsigned int nchildren;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (x)
    *x = 0;
  if (y)
    *y = 0;
  if (private->destroyed)
    return;
  
  while (private->parent && ((GdkWindowPrivate*) private->parent)->parent)
    private = (GdkWindowPrivate*) private->parent;
  if (private->destroyed)
    return;
  
  xparent = private->xwindow;
  do
    {
      xwindow = xparent;
      if (!XQueryTree (private->xdisplay, xwindow,
		       &root, &xparent,
		       &children, &nchildren))
	return;
      
      if (children)
	XFree (children);
    }
  while (xparent != root);
  
  if (xparent == root)
    {
      unsigned int ww, wh, wb, wd;
      int wx, wy;
      
      if (XGetGeometry (private->xdisplay, xwindow, &root, &wx, &wy, &ww, &wh, &wb, &wd))
	{
	  if (x)
	    *x = wx;
	  if (y)
	    *y = wy;
	}
    }
#endif
}

GdkWindow*
gdk_window_at_pointer (gint *win_x,
		       gint *win_y)
{
#if 0
  GdkWindowPrivate *private;
  GdkWindow *window;
  Window root;
  Window xwindow;
  Window xwindow_last = 0;
  int rootx = -1, rooty = -1;
  int winx, winy;
  unsigned int xmask;
  
  private = &gdk_root_parent;
  
  xwindow = private->xwindow;
  
  XGrabServer (private->xdisplay);
  while (xwindow)
    {
      xwindow_last = xwindow;
      XQueryPointer (private->xdisplay,
		     xwindow,
		     &root, &xwindow,
		     &rootx, &rooty,
		     &winx, &winy,
		     &xmask);
    }
  XUngrabServer (private->xdisplay);
  
  window = gdk_window_lookup (xwindow_last);
  
  if (win_x)
    *win_x = window ? winx : -1;
  if (win_y)
    *win_y = window ? winy : -1;
  
  return window;
#endif
}



GdkWindow*
gdk_window_get_toplevel (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  
  g_return_val_if_fail (window != NULL, NULL);
  
  private = (GdkWindowPrivate*) window;
  
  while (private->window_type == GDK_WINDOW_CHILD)
    {
      window = ((GdkWindowPrivate*) window)->parent;
      private = (GdkWindowPrivate*) window;
    }
  
  return window;
#endif
}


GdkEventMask  
gdk_window_get_events (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private;
  XWindowAttributes attrs;
  GdkEventMask event_mask;
  int i;
  
  g_return_val_if_fail (window != NULL, 0);
  
  private = (GdkWindowPrivate*) window;
  if (private->destroyed)
    return 0;
  
  XGetWindowAttributes (gdk_display, private->xwindow, 
			&attrs);
  
  event_mask = 0;
  for (i = 0; i < gdk_nevent_masks; i++)
    {
      if (attrs.your_event_mask & gdk_event_mask_table[i])
	event_mask |= 1 << (i + 1);
    }
  
  return event_mask;
#endif
}

void          
gdk_window_set_events (GdkWindow       *window,
		       GdkEventMask     event_mask)
{
#if 0
  GdkWindowPrivate *private;
  long xevent_mask;
  int i;
  
  g_return_if_fail (window != NULL);
  
  private = (GdkWindowPrivate*) window;
  if (private->destroyed)
    return;
  
  xevent_mask = StructureNotifyMask;
  for (i = 0; i < gdk_nevent_masks; i++)
    {
      if (event_mask & (1 << (i + 1)))
	xevent_mask |= gdk_event_mask_table[i];
    }
  
  XSelectInput (gdk_display, private->xwindow, 
		xevent_mask);
#endif
}

void
gdk_window_add_colormap_windows (GdkWindow *window)
{
#if 0
  GdkWindow *toplevel;
  GdkWindowPrivate *toplevel_private;
  GdkWindowPrivate *window_private;
  Window *old_windows;
  Window *new_windows;
  int i, count;
  
  g_return_if_fail (window != NULL);
  
  toplevel = gdk_window_get_toplevel (window);
  toplevel_private = (GdkWindowPrivate*) toplevel;
  window_private = (GdkWindowPrivate*) window;
  if (window_private->destroyed)
    return;
  
  old_windows = NULL;
  if (!XGetWMColormapWindows (toplevel_private->xdisplay,
			      toplevel_private->xwindow,
			      &old_windows, &count))
    {
      count = 0;
    }
  
  for (i = 0; i < count; i++)
    if (old_windows[i] == window_private->xwindow)
      {
	XFree (old_windows);
	return;
      }
  
  new_windows = g_new (Window, count + 1);
  
  for (i = 0; i < count; i++)
    new_windows[i] = old_windows[i];
  new_windows[count] = window_private->xwindow;
  
  XSetWMColormapWindows (toplevel_private->xdisplay,
			 toplevel_private->xwindow,
			 new_windows, count + 1);
  
  g_free (new_windows);
  if (old_windows)
    XFree (old_windows);
#endif
}

static gboolean
gdk_window_have_shape_ext (void)
{
#if 0
  enum { UNKNOWN, NO, YES };
  static gint have_shape = UNKNOWN;
  
  if (have_shape == UNKNOWN)
    {
      int ignore;
      if (XQueryExtension (gdk_display, "SHAPE", &ignore, &ignore, &ignore))
	have_shape = YES;
      else
	have_shape = NO;
    }
  
  return (have_shape == YES);
#endif
}

/*
 * This needs the X11 shape extension.
 * If not available, shaped windows will look
 * ugly, but programs still work.    Stefan Wille
 */
void
gdk_window_shape_combine_mask (GdkWindow *window,
			       GdkBitmap *mask,
			       gint x, gint y)
{
#if 0
  GdkWindowPrivate *window_private;
  Pixmap pixmap;
  
  g_return_if_fail (window != NULL);
  
#ifdef HAVE_SHAPE_EXT
  window_private = (GdkWindowPrivate*) window;
  if (window_private->destroyed)
    return;
  
  if (gdk_window_have_shape_ext ())
    {
      if (mask)
	{
	  GdkWindowPrivate *pixmap_private;
	  
	  pixmap_private = (GdkWindowPrivate*) mask;
	  pixmap = (Pixmap) pixmap_private->xwindow;
	}
      else
	{
	  x = 0;
	  y = 0;
	  pixmap = None;
	}
      
      XShapeCombineMask (window_private->xdisplay,
			 window_private->xwindow,
			 ShapeBounding,
			 x, y,
			 pixmap,
			 ShapeSet);
    }
#endif /* HAVE_SHAPE_EXT */
#endif
}

void          
gdk_window_add_filter (GdkWindow     *window,
		       GdkFilterFunc  function,
		       gpointer       data)
{
#if 0
  GdkWindowPrivate *private;
  GList *tmp_list;
  GdkEventFilter *filter;
  
  private = (GdkWindowPrivate*) window;
  if (private && private->destroyed)
    return;
  
  if (private)
    tmp_list = private->filters;
  else
    tmp_list = gdk_default_filters;
  
  while (tmp_list)
    {
      filter = (GdkEventFilter *)tmp_list->data;
      if ((filter->function == function) && (filter->data == data))
	return;
      tmp_list = tmp_list->next;
    }
  
  filter = g_new (GdkEventFilter, 1);
  filter->function = function;
  filter->data = data;
  
  if (private)
    private->filters = g_list_append (private->filters, filter);
  else
    gdk_default_filters = g_list_append (gdk_default_filters, filter);
#endif
}

void
gdk_window_remove_filter (GdkWindow     *window,
			  GdkFilterFunc  function,
			  gpointer       data)
{
#if 0
  GdkWindowPrivate *private;
  GList *tmp_list, *node;
  GdkEventFilter *filter;
  
  private = (GdkWindowPrivate*) window;
  
  if (private)
    tmp_list = private->filters;
  else
    tmp_list = gdk_default_filters;
  
  while (tmp_list)
    {
      filter = (GdkEventFilter *)tmp_list->data;
      node = tmp_list;
      tmp_list = tmp_list->next;
      
      if ((filter->function == function) && (filter->data == data))
	{
	  if (private)
	    private->filters = g_list_remove_link (private->filters, node);
	  else
	    gdk_default_filters = g_list_remove_link (gdk_default_filters, node);
	  g_list_free_1 (node);
	  g_free (filter);
	  
	  return;
	}
    }
#endif
}

void
gdk_window_set_override_redirect (GdkWindow *window,
				  gboolean override_redirect)
{
#if 0
  GdkWindowPrivate *private;
  XSetWindowAttributes attr;
  
  g_return_if_fail (window != NULL);
  private = (GdkWindowPrivate*) window;
  if (private->destroyed)
    return;
  
  attr.override_redirect = (override_redirect == FALSE)?False:True;
  XChangeWindowAttributes (gdk_display,
			   ((GdkWindowPrivate *)window)->xwindow,
			   CWOverrideRedirect,
			   &attr);
#endif
}

void          
gdk_window_set_icon (GdkWindow *window, 
		     GdkWindow *icon_window,
		     GdkPixmap *pixmap,
		     GdkBitmap *mask)
{
#if 0
  XWMHints *wm_hints;
  GdkWindowPrivate *window_private;
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  window_private = (GdkWindowPrivate*) window;
  if (window_private->destroyed)
    return;

  wm_hints = XGetWMHints (window_private->xdisplay, window_private->xwindow);
  if (!wm_hints)
    wm_hints = XAllocWMHints ();

  if (icon_window != NULL)
    {
      private = (GdkWindowPrivate *)icon_window;
      wm_hints->flags |= IconWindowHint;
      wm_hints->icon_window = private->xwindow;
    }
  
  if (pixmap != NULL)
    {
      private = (GdkWindowPrivate *)pixmap;
      wm_hints->flags |= IconPixmapHint;
      wm_hints->icon_pixmap = private->xwindow;
    }
  
  if (mask != NULL)
    {
      private = (GdkWindowPrivate *)mask;
      wm_hints->flags |= IconMaskHint;
      wm_hints->icon_mask = private->xwindow;
    }

  XSetWMHints (window_private->xdisplay, window_private->xwindow, wm_hints);
  XFree (wm_hints);
#endif
}

void          
gdk_window_set_icon_name (GdkWindow   *window, 
			  const gchar *name)
{
#if 0
  GdkWindowPrivate *window_private;
  XTextProperty property;
  gint res;
  
  g_return_if_fail (window != NULL);
  window_private = (GdkWindowPrivate*) window;
  if (window_private->destroyed)
    return;
  res = XmbTextListToTextProperty (window_private->xdisplay,
				   &name, 1, XStdICCTextStyle,
                               	   &property);
  if (res < 0)
    {
      g_warning ("Error converting icon name to text property: %d\n", res);
      return;
    }
  
  XSetWMIconName (window_private->xdisplay, window_private->xwindow,
		  &property);
  
  if (property.value)
    XFree (property.value);
#endif
}

void          
gdk_window_set_group (GdkWindow *window, 
		      GdkWindow *leader)
{
#if 0
  XWMHints *wm_hints;
  GdkWindowPrivate *window_private;
  GdkWindowPrivate *private;
  
  g_return_if_fail (window != NULL);
  g_return_if_fail (leader != NULL);
  window_private = (GdkWindowPrivate*) window;
  if (window_private->destroyed)
    return;
  
  private = (GdkWindowPrivate *)leader;

  wm_hints = XGetWMHints (window_private->xdisplay, window_private->xwindow);
  if (!wm_hints)
    wm_hints = XAllocWMHints ();

  wm_hints->flags |= WindowGroupHint;
  wm_hints->window_group = private->xwindow;

  XSetWMHints (window_private->xdisplay, window_private->xwindow, wm_hints);
  XFree (wm_hints);
#endif
}

void
gdk_window_set_functions (GdkWindow    *window,
			  GdkWMFunction functions)
{
#if 0
  MotifWmHints hints;
  
  hints.flags = MWM_HINTS_FUNCTIONS;
  hints.functions = functions;
  
  gdk_window_set_mwm_hints (window, &hints);
#endif
}

GList *
gdk_window_get_toplevels (void)
{
#if 0
  GList *new_list = NULL;
  GList *tmp_list;
  
  tmp_list = gdk_root_parent.children;
  while (tmp_list)
    {
      new_list = g_list_prepend (new_list, tmp_list->data);
      tmp_list = tmp_list->next;
    }
  
  return new_list;
#endif
}

/*************************************************************
 * gdk_window_is_visible:
 *     Check if the given window is mapped.
 *   arguments:
 *     window: 
 *   results:
 *     is the window mapped
 *************************************************************/

gboolean 
gdk_window_is_visible (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private = (GdkWindowPrivate *)window;
  
  g_return_val_if_fail (window != NULL, FALSE);
  
  return private->mapped;
#endif
}

/*************************************************************
 * gdk_window_is_viewable:
 *     Check if the window and all ancestors of the window
 *     are mapped. (This is not necessarily "viewable" in
 *     the X sense, since we only check as far as we have
 *     GDK window parents, not to the root window)
 *   arguments:
 *     window:
 *   results:
 *     is the window viewable
 *************************************************************/

gboolean 
gdk_window_is_viewable (GdkWindow *window)
{
#if 0
  GdkWindowPrivate *private = (GdkWindowPrivate *)window;
  
  g_return_val_if_fail (window != NULL, FALSE);
  
  while (private && 
	 (private != &gdk_root_parent) &&
	 (private->window_type != GDK_WINDOW_FOREIGN))
    {
      if (!private->mapped)
	return FALSE;
      
      private = (GdkWindowPrivate *)private->parent;
    }
  
  return TRUE;
#endif
}

void          
gdk_drawable_set_data (GdkDrawable   *drawable,
		       const gchar   *key,
		       gpointer	      data,
		       GDestroyNotify destroy_func)
{
//  g_dataset_set_data_full (drawable, key, data, destroy_func);
}
