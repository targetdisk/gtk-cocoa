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

#include "gtkgc.h"


typedef struct _GtkGCKey       GtkGCKey;
typedef struct _GtkGCDrawable  GtkGCDrawable;

struct _GtkGCKey
{
  gint depth;
  GdkColormap *colormap;
  GdkGCValues values;
  GdkGCValuesMask mask;
};

struct _GtkGCDrawable
{
  gint depth;
  GdkPixmap *drawable;
};


static void      gtk_gc_init             (void);
static GtkGCKey* gtk_gc_key_dup          (GtkGCKey      *key);
static void      gtk_gc_key_destroy      (GtkGCKey      *key);
static gpointer  gtk_gc_new              (gpointer       key);
static void      gtk_gc_destroy          (gpointer       value);
static guint     gtk_gc_key_hash         (gpointer       key);
static guint     gtk_gc_value_hash       (gpointer       value);
static gint      gtk_gc_key_compare      (gpointer       a,
					  gpointer       b);
static guint     gtk_gc_drawable_hash    (GtkGCDrawable *d);
static gint      gtk_gc_drawable_compare (GtkGCDrawable *a,
					  GtkGCDrawable *b);


static gint initialize = TRUE;
static GCache *gc_cache = NULL;
static GHashTable *gc_drawable_ht = NULL;

static GMemChunk *key_mem_chunk = NULL;


GdkGC*
gtk_gc_get (gint             depth,
	    GdkColormap     *colormap,
	    GdkGCValues     *values,
	    GdkGCValuesMask  values_mask)
{
  GtkGCKey key;
  GdkGC *gc;

  if (initialize)
    gtk_gc_init ();

  key.depth = depth;
  key.colormap = colormap;
  key.values = *values;
  key.mask = values_mask;

  gc = g_cache_insert (gc_cache, &key);

  return gc;
}

void
gtk_gc_release (GdkGC *gc)
{
  if (initialize)
    gtk_gc_init ();

  g_cache_remove (gc_cache, gc);
}


static void
gtk_gc_init (void)
{
  initialize = FALSE;

  gc_cache = g_cache_new ((GCacheNewFunc) gtk_gc_new,
			  (GCacheDestroyFunc) gtk_gc_destroy,
			  (GCacheDupFunc) gtk_gc_key_dup,
			  (GCacheDestroyFunc) gtk_gc_key_destroy,
			  (GHashFunc) gtk_gc_key_hash,
			  (GHashFunc) gtk_gc_value_hash,
			  (GCompareFunc) gtk_gc_key_compare);

  gc_drawable_ht = g_hash_table_new ((GHashFunc) gtk_gc_drawable_hash,
				     (GCompareFunc) gtk_gc_drawable_compare);
}

static GtkGCKey*
gtk_gc_key_dup (GtkGCKey *key)
{
  GtkGCKey *new_key;

  if (!key_mem_chunk)
    key_mem_chunk = g_mem_chunk_new ("key mem chunk", sizeof (GtkGCKey),
				     1024, G_ALLOC_AND_FREE);

  new_key = g_chunk_new (GtkGCKey, key_mem_chunk);

  *new_key = *key;

  return new_key;
}

static void
gtk_gc_key_destroy (GtkGCKey *key)
{
  g_mem_chunk_free (key_mem_chunk, key);
}

static gpointer
gtk_gc_new (gpointer key)
{
  GtkGCKey *keyval;
  GtkGCDrawable *drawable;
  GdkGC *gc;

  keyval = key;

  drawable = g_hash_table_lookup (gc_drawable_ht, &keyval->depth);
  if (!drawable)
    {
      drawable = g_new (GtkGCDrawable, 1);
      drawable->depth = keyval->depth;
      drawable->drawable = gdk_pixmap_new (NULL, 1, 1, drawable->depth);

      g_hash_table_insert (gc_drawable_ht, &drawable->depth, drawable);
    }

  gc = gdk_gc_new_with_values (drawable->drawable, &keyval->values, keyval->mask);

  return (gpointer) gc;
}

static void
gtk_gc_destroy (gpointer value)
{
  //gdk_gc_destroy ((GdkGC*) value);
}

static guint
gtk_gc_key_hash (gpointer key)
{
  GtkGCKey *keyval;
  guint hash_val;

  keyval = key;
  hash_val = 0;

  if (keyval->mask & GDK_GC_FOREGROUND)
    {
      hash_val += keyval->values.foreground.pixel;
    }
  if (keyval->mask & GDK_GC_BACKGROUND)
    {
      hash_val += keyval->values.background.pixel;
    }
#if 0
  if (keyval->mask & GDK_GC_FONT)
    {
      hash_val += gdk_font_id (keyval->values.font);
    }
#endif
  if (keyval->mask & GDK_GC_FUNCTION)
    {
      hash_val += (gint) keyval->values.function;
    }
  if (keyval->mask & GDK_GC_FILL)
    {
      hash_val += (gint) keyval->values.fill;
    }
  if (keyval->mask & GDK_GC_TILE)
    {
      hash_val += (glong) keyval->values.tile;
    }
  if (keyval->mask & GDK_GC_STIPPLE)
    {
      hash_val += (glong) keyval->values.stipple;
    }
  if (keyval->mask & GDK_GC_CLIP_MASK)
    {
      hash_val += (glong) keyval->values.clip_mask;
    }
  if (keyval->mask & GDK_GC_SUBWINDOW)
    {
      hash_val += (gint) keyval->values.subwindow_mode;
    }
  if (keyval->mask & GDK_GC_TS_X_ORIGIN)
    {
      hash_val += (gint) keyval->values.ts_x_origin;
    }
  if (keyval->mask & GDK_GC_TS_Y_ORIGIN)
    {
      hash_val += (gint) keyval->values.ts_y_origin;
    }
  if (keyval->mask & GDK_GC_CLIP_X_ORIGIN)
    {
      hash_val += (gint) keyval->values.clip_x_origin;
    }
  if (keyval->mask & GDK_GC_CLIP_Y_ORIGIN)
    {
      hash_val += (gint) keyval->values.clip_y_origin;
    }
  if (keyval->mask & GDK_GC_EXPOSURES)
    {
      hash_val += (gint) keyval->values.graphics_exposures;
    }
  if (keyval->mask & GDK_GC_LINE_WIDTH)
    {
      hash_val += (gint) keyval->values.line_width;
    }
  if (keyval->mask & GDK_GC_LINE_STYLE)
    {
      hash_val += (gint) keyval->values.line_style;
    }
  if (keyval->mask & GDK_GC_CAP_STYLE)
    {
      hash_val += (gint) keyval->values.cap_style;
    }
  if (keyval->mask & GDK_GC_JOIN_STYLE)
    {
      hash_val += (gint) keyval->values.join_style;
    }

  return hash_val;
}

static guint
gtk_gc_value_hash (gpointer value)
{
  return (gulong) value;
}

static gint
gtk_gc_key_compare (gpointer a,
		    gpointer b)
{
  GtkGCKey *akey;
  GtkGCKey *bkey;
  GdkGCValues *avalues;
  GdkGCValues *bvalues;

  akey = a;
  bkey = b;

  avalues = &akey->values;
  bvalues = &bkey->values;

  if (akey->mask != bkey->mask)
    return FALSE;

  if (akey->depth != bkey->depth)
    return FALSE;

  if (akey->colormap != bkey->colormap)
    return FALSE;

  if (akey->mask & GDK_GC_FOREGROUND)
    {
      if (avalues->foreground.pixel != bvalues->foreground.pixel)
	return FALSE;
    }
  if (akey->mask & GDK_GC_BACKGROUND)
    {
      if (avalues->background.pixel != bvalues->background.pixel)
	return FALSE;
    }
#if 0
  if (akey->mask & GDK_GC_FONT)
    {
      if (!gdk_font_equal (avalues->font, bvalues->font))
	return FALSE;
    }
#endif
  if (akey->mask & GDK_GC_FUNCTION)
    {
      if (avalues->function != bvalues->function)
	return FALSE;
    }
  if (akey->mask & GDK_GC_FILL)
    {
      if (avalues->fill != bvalues->fill)
	return FALSE;
    }
  if (akey->mask & GDK_GC_TILE)
    {
      if (avalues->tile != bvalues->tile)
	return FALSE;
    }
  if (akey->mask & GDK_GC_STIPPLE)
    {
      if (avalues->stipple != bvalues->stipple)
	return FALSE;
    }
  if (akey->mask & GDK_GC_CLIP_MASK)
    {
      if (avalues->clip_mask != bvalues->clip_mask)
	return FALSE;
    }
  if (akey->mask & GDK_GC_SUBWINDOW)
    {
      if (avalues->subwindow_mode != bvalues->subwindow_mode)
	return FALSE;
    }
  if (akey->mask & GDK_GC_TS_X_ORIGIN)
    {
      if (avalues->ts_x_origin != bvalues->ts_x_origin)
	return FALSE;
    }
  if (akey->mask & GDK_GC_TS_Y_ORIGIN)
    {
      if (avalues->ts_y_origin != bvalues->ts_y_origin)
	return FALSE;
    }
  if (akey->mask & GDK_GC_CLIP_X_ORIGIN)
    {
      if (avalues->clip_x_origin != bvalues->clip_x_origin)
	return FALSE;
    }
  if (akey->mask & GDK_GC_CLIP_Y_ORIGIN)
    {
      if (avalues->clip_y_origin != bvalues->clip_y_origin)
	return FALSE;
    }
  if (akey->mask & GDK_GC_EXPOSURES)
    {
      if (avalues->graphics_exposures != bvalues->graphics_exposures)
	return FALSE;
    }
  if (akey->mask & GDK_GC_LINE_WIDTH)
    {
      if (avalues->line_width != bvalues->line_width)
	return FALSE;
    }
  if (akey->mask & GDK_GC_LINE_STYLE)
    {
      if (avalues->line_style != bvalues->line_style)
	return FALSE;
    }
  if (akey->mask & GDK_GC_CAP_STYLE)
    {
      if (avalues->cap_style != bvalues->cap_style)
	return FALSE;
    }
  if (akey->mask & GDK_GC_JOIN_STYLE)
    {
      if (avalues->join_style != bvalues->join_style)
	return FALSE;
    }
  return TRUE;
}


static guint
gtk_gc_drawable_hash (GtkGCDrawable *d)
{
  return d->depth;
}

static gint
gtk_gc_drawable_compare (GtkGCDrawable *a,
			 GtkGCDrawable *b)
{
  return (a->depth == b->depth);
}
