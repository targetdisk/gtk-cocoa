//
//  gtkglarea.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkGLArea.h"

#include <gtk/gtk.h>
#include "gtkgl/gtkglarea.h"

void
gtk_gl_area_init (GtkGLArea *gl_area)
{
  NSGtkGLArea *glv;

  gl_area->glcontext = NULL;
  glv = [[NSGtkGLArea alloc] initWithFrame:NSMakeRect(0,0,100,100)];
  GTK_WIDGET(gl_area)->proxy = glv;
  GTK_WIDGET(gl_area)->window = glv;
  glv->proxy = gl_area;
}

gint gtk_gl_area_make_current(GtkGLArea *gl_area)
{
 NSGtkGLArea *glv;

  g_return_val_if_fail(gl_area != NULL, FALSE);
  g_return_val_if_fail(GTK_IS_GL_AREA (gl_area), FALSE);
//  g_return_val_if_fail(GTK_WIDGET_REALIZED(gl_area), FALSE);

  glv = GTK_WIDGET(gl_area)->proxy;

   [[glv openGLContext] makeCurrentContext];
  return TRUE;

}

GtkWidget*
gtk_gl_area_share_new (int *attrlist, GtkGLArea *share)
{
 NSGtkGLArea *glv;
  GtkGLArea *gl_area;
int attribs[] =
    {
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAWindow,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAStencilSize, 8,
        NSOpenGLPFAAccumSize, 0,
        0
    };

    
  gl_area = gtk_type_new(GTK_TYPE_GL_AREA);
  if(share)
  {
		NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attribs]; 
		glv = GTK_WIDGET(gl_area)->proxy;
		NSOpenGLContext *ctx = [[NSOpenGLContext alloc] initWithFormat:[fmt autorelease] shareContext:[GTK_WIDGET(share)->proxy openGLContext]];

		[ctx setView:glv];
		[glv setOpenGLContext:ctx];
		[ctx release];
  }
#if 0
#if !defined(WIN32)

  GdkVisual *visual;
  void *glcontext;

  g_return_val_if_fail(share == NULL || GTK_IS_GL_AREA(share), NULL);

  visual = gdk_gl_choose_visual(attrlist);
  if (visual == NULL)
    return NULL;

  glcontext = gdk_gl_context_share_new(visual, share ? share->glcontext : NULL, TRUE);
  if (glcontext == NULL)
    return NULL;

  /* use colormap and visual suitable for OpenGL rendering */
  gtk_widget_push_colormap(gdk_colormap_new(visual,TRUE));
  gtk_widget_push_visual(visual);
  
  gl_area = g_object_new(GTK_TYPE_GL_AREA, NULL);
  gl_area->glcontext = glcontext;

  /* pop back defaults */
  gtk_widget_pop_visual();
  gtk_widget_pop_colormap();

#else

  GdkGLContext *glcontext;

  g_return_val_if_fail(share == NULL || GTK_IS_GL_AREA(share), NULL);

  glcontext = gdk_gl_context_attrlist_share_new(attrlist, share ? share->glcontext : NULL, TRUE);
  if (glcontext == NULL)
    return NULL;

  gl_area = g_object_new(GTK_TYPE_GL_AREA, NULL);
  gl_area->glcontext = glcontext;

#endif
#endif
  return GTK_WIDGET(gl_area);
}


void gtk_gl_area_swap_buffers(GtkGLArea *gl_area)
{
 NSGtkGLArea *glv;

  g_return_if_fail(gl_area != NULL);
  g_return_if_fail(GTK_IS_GL_AREA(gl_area));
//  g_return_if_fail(GTK_WIDGET_REALIZED(gl_area));

  glv = GTK_WIDGET(gl_area)->proxy;

  [[glv openGLContext] flushBuffer];

}
