//
//  gdkfont.m
//  Gtk+-Cocoa
//
//  Created by Paolo Costabel on Sun Nov 07 2004.
//  Copyright (c) 2004 Zebra Development, Inc. All rights reserved.
//
#import <AppKit/AppKit.h>
#include <gdk/gdk.h>

typedef struct _GdkFontPrivate         GdkFontPrivate;

struct _GdkFontPrivate
{
  GdkFont font;
  guint ref_count;
  NSFont *nsfont;
};


GdkFont*
gdk_font_load (const gchar *font_name)
{

  GdkFont *font;
  GdkFontPrivate *private;
  NSFont *nsfont;
  
  g_return_val_if_fail (font_name != NULL, NULL);

  nsfont = [NSFont fontWithName:[NSString stringWithCString:font_name] size:0.0];
  if (nsfont == NULL)
    nsfont = [NSFont labelFontOfSize:0.0];

  private = g_new (GdkFontPrivate, 1);
  private->nsfont = nsfont;
  private->ref_count = 1;
 
  font = (GdkFont*) private;
  font->type = GDK_FONT_FONT;
  font->ascent =  [nsfont ascender];
  font->descent = [nsfont descender];

  return font;
}
