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
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
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
#include "gdk.h"
#include "gdkprivate.h"


GdkGC*
gdk_gc_new (GdkWindow *window)
{
  return gdk_gc_new_with_values (window, NULL, 0);
}

GdkGC*
gdk_gc_new_with_values (GdkWindow	*window,
			GdkGCValues	*values,
			GdkGCValuesMask	 values_mask)
{
  GdkGC *gc;
  GdkGCPrivate *private;

//  g_return_val_if_fail (window != NULL, NULL);

  private = g_new (GdkGCPrivate, 1);
  if(values)
    private->values = *values;
  return private;
}

void
gdk_gc_destroy (GdkGC *gc)
{
  gdk_gc_unref (gc);
}

GdkGC *
gdk_gc_ref (GdkGC *gc)
{
  GdkGCPrivate *private = (GdkGCPrivate*) gc;

  g_return_val_if_fail (gc != NULL, NULL);
  private->ref_count += 1;

  return gc;
}

void
gdk_gc_unref (GdkGC *gc)
{
  GdkGCPrivate *private = (GdkGCPrivate*) gc;
  
  g_return_if_fail (gc != NULL);
  g_return_if_fail (private->ref_count > 0);
  
  if (private->ref_count > 1)
    private->ref_count -= 1;
  else
    {
      memset (gc, 0, sizeof (GdkGCPrivate));
      g_free (gc);
    }
}

void
gdk_gc_get_values (GdkGC       *gc,
		   GdkGCValues *values)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);
  g_return_if_fail (values != NULL);

  private = (GdkGCPrivate*) gc;

 *values = private->values;
}

void
gdk_gc_set_foreground (GdkGC	*gc,
		       GdkColor *color)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);
  g_return_if_fail (color != NULL);

  private = (GdkGCPrivate*) gc;
}

void
gdk_gc_set_background (GdkGC	*gc,
		       GdkColor *color)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);
  g_return_if_fail (color != NULL);

  private = (GdkGCPrivate*) gc;
}

void
gdk_gc_set_font (GdkGC	 *gc,
		 GdkFont *font)
{
  GdkGCPrivate *gc_private;

  g_return_if_fail (gc != NULL);
  g_return_if_fail (font != NULL);

}

void
gdk_gc_set_function (GdkGC	 *gc,
		     GdkFunction  function)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

}


void
gdk_gc_set_fill (GdkGC	 *gc,
		 GdkFill  fill)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

}

void
gdk_gc_set_tile (GdkGC	   *gc,
		 GdkPixmap *tile)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

}

void
gdk_gc_set_stipple (GdkGC     *gc,
		    GdkPixmap *stipple)
{
#if 0
  GdkGCPrivate *private;
  GdkPixmapPrivate *pixmap_private;
  Pixmap pixmap;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

  pixmap = None;
  if (stipple)
    {
      pixmap_private = (GdkPixmapPrivate*) stipple;
      pixmap = pixmap_private->xwindow;
    }
#endif
}

void
gdk_gc_set_ts_origin (GdkGC *gc,
		      gint   x,
		      gint   y)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

}

void
gdk_gc_set_clip_origin (GdkGC *gc,
			gint   x,
			gint   y)
{
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

}

void
gdk_gc_set_clip_mask (GdkGC	*gc,
		      GdkBitmap *mask)
{
#if 0
  GdkGCPrivate *private;
  Pixmap xmask;
  
  g_return_if_fail (gc != NULL);
  
  if (mask)
    {
      GdkWindowPrivate *mask_private;
      
      mask_private = (GdkWindowPrivate*) mask;
      if (mask_private->destroyed)
	return;
      xmask = mask_private->xwindow;
    }
  else
    xmask = None;
  
  private = (GdkGCPrivate*) gc;

  XSetClipMask (private->xdisplay, private->xgc, xmask);
#endif
}


void
gdk_gc_set_clip_rectangle (GdkGC	*gc,
			   GdkRectangle *rectangle)
{
#if 0
  GdkGCPrivate *private;
  XRectangle xrectangle;
   
  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

  if (rectangle)
    {
      xrectangle.x = rectangle->x; 
      xrectangle.y = rectangle->y;
      xrectangle.width = rectangle->width;
      xrectangle.height = rectangle->height;
      
      XSetClipRectangles (private->xdisplay, private->xgc, 0, 0,
			  &xrectangle, 1, Unsorted);
    }
  else
    XSetClipMask (private->xdisplay, private->xgc, None);
#endif
} 

void
gdk_gc_set_clip_region (GdkGC		 *gc,
			GdkRegion	 *region)
{
#if 0
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

  if (region)
    {
      GdkRegionPrivate *region_private;

      region_private = (GdkRegionPrivate*) region;
      XSetRegion (private->xdisplay, private->xgc, region_private->xregion);
    }
  else
    XSetClipMask (private->xdisplay, private->xgc, None);
#endif
}

void
gdk_gc_set_subwindow (GdkGC	       *gc,
		      GdkSubwindowMode	mode)
{
#if 0
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

  XSetSubwindowMode (private->xdisplay, private->xgc, mode);
#endif
}

void
gdk_gc_set_exposures (GdkGC     *gc,
		      gboolean   exposures)
{
#if 0
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

  XSetGraphicsExposures (private->xdisplay, private->xgc, exposures);
#endif
}

void
gdk_gc_set_line_attributes (GdkGC	*gc,
			    gint	 line_width,
			    GdkLineStyle line_style,
			    GdkCapStyle	 cap_style,
			    GdkJoinStyle join_style)
{
#if 0
  GdkGCPrivate *private;
  int xline_style;
  int xcap_style;
  int xjoin_style;

  g_return_if_fail (gc != NULL);

  private = (GdkGCPrivate*) gc;

  switch (line_style)
    {
    case GDK_LINE_SOLID:
      xline_style = LineSolid;
      break;
    case GDK_LINE_ON_OFF_DASH:
      xline_style = LineOnOffDash;
      break;
    case GDK_LINE_DOUBLE_DASH:
      xline_style = LineDoubleDash;
      break;
    default:
      xline_style = None;
    }

  switch (cap_style)
    {
    case GDK_CAP_NOT_LAST:
      xcap_style = CapNotLast;
      break;
    case GDK_CAP_BUTT:
      xcap_style = CapButt;
      break;
    case GDK_CAP_ROUND:
      xcap_style = CapRound;
      break;
    case GDK_CAP_PROJECTING:
      xcap_style = CapProjecting;
      break;
    default:
      xcap_style = None;
    }

  switch (join_style)
    {
    case GDK_JOIN_MITER:
      xjoin_style = JoinMiter;
      break;
    case GDK_JOIN_ROUND:
      xjoin_style = JoinRound;
      break;
    case GDK_JOIN_BEVEL:
      xjoin_style = JoinBevel;
      break;
    default:
      xjoin_style = None;
    }

  XSetLineAttributes (private->xdisplay, private->xgc, line_width,
		      xline_style, xcap_style, xjoin_style);
#endif
}

void
gdk_gc_set_dashes (GdkGC      *gc,
		   gint	       dash_offset,
		   gint8       dash_list[],
		   gint        n)
{ 
#if 0
  GdkGCPrivate *private;

  g_return_if_fail (gc != NULL);
  g_return_if_fail (dash_list != NULL);

  private = (GdkGCPrivate*) gc;

  XSetDashes (private->xdisplay, private->xgc, dash_offset, dash_list, n);
#endif
}

void
gdk_gc_copy (GdkGC *dst_gc, GdkGC *src_gc)
{
#if 0
  GdkGCPrivate *dst_private, *src_private;

  src_private = (GdkGCPrivate *) src_gc;
  dst_private = (GdkGCPrivate *) dst_gc;

  XCopyGC (src_private->xdisplay, src_private->xgc, ~((~1) << GCLastBit),
	   dst_private->xgc);
#endif
}
