/* 
 * Copyright (C) 1998 Janne Löf <jlof@mail.student.oulu.fi>
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
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */


#include "gdkgl.h"

#include <gdk/gdkx.h>


#include <GL/gl.h>
#include <GL/glx.h>
#include <string.h>


static XVisualInfo *get_xvisualinfo(GdkVisual *visual)
{
  Display *dpy;
  XVisualInfo vinfo_template;
  XVisualInfo *vi;
  int nitems_return;

  dpy = GDK_DISPLAY();

  /* 'GLX uses VisualInfo records because they uniquely identify
   * a (VisualID,screen,depth) tuple.'
   */
  vinfo_template.visual   = GDK_VISUAL_XVISUAL(visual);
  vinfo_template.visualid = XVisualIDFromVisual(vinfo_template.visual);
  vinfo_template.depth    = visual->depth;
  vinfo_template.screen   = DefaultScreen(dpy);
  vi = XGetVisualInfo(dpy, VisualIDMask|VisualDepthMask|VisualScreenMask,
		      &vinfo_template, &nitems_return);

  g_assert( vi!=0  && nitems_return==1 ); /* visualinfo needs to be unique */

  /* remember to XFree returned XVisualInfo !!! */
  return vi;
}



gint gdk_gl_query(void)
{
  return (glXQueryExtension(GDK_DISPLAY(),NULL,NULL) == True) ? TRUE : FALSE;
}


gchar *gdk_gl_get_info()
{
  return g_strdup_printf("VENDOR     : %s\n"
			 "VERSION    : %s\n"
			 "EXTENSIONS : %s\n",
			 glXGetClientString(GDK_DISPLAY(), GLX_VENDOR),
			 glXGetClientString(GDK_DISPLAY(), GLX_VERSION),
			 glXGetClientString(GDK_DISPLAY(), GLX_EXTENSIONS));
}


GdkVisual *gdk_gl_choose_visual(int *attrlist)
{
  Display *dpy;
  XVisualInfo *vi;
  GdkVisual  *visual;

  g_return_val_if_fail(attrlist != NULL, NULL);

  dpy = GDK_DISPLAY();
  if ((vi = glXChooseVisual(dpy,DefaultScreen(dpy), attrlist)) == NULL)
    return NULL;
  
  visual = gdkx_visual_get(vi->visualid);
  XFree(vi);
  return visual;
}


int gdk_gl_get_config(GdkVisual *visual, int attrib)
{
  Display *dpy;
  XVisualInfo *vi;
  int value;
  
  g_return_val_if_fail(visual != NULL, -1);

  dpy = GDK_DISPLAY();
 
  vi = get_xvisualinfo(visual);

  if (glXGetConfig(dpy, vi, attrib, &value) == 0)
    {
      XFree(vi);
      return value;
    }
  XFree(vi);
  return -1;
}

struct _GdkGLContext {
  GObject     parent;
  Display    *xdisplay;
  GLXContext  glxcontext;
};
struct _GdkGLContextClass {
  GObjectClass parent_class;
};
typedef struct _GdkGLContextClass GdkGLContextClass;

static GObjectClass *glcontext_parent_class;

static void gdk_gl_context_class_init (GdkGLContextClass *class);

GType
gdk_gl_context_get_type (void)
{
  static GType object_type = 0;

  if (!object_type)
    {
      static const GTypeInfo object_info =
      {
        sizeof (GdkGLContextClass),
        (GBaseInitFunc) NULL,
        (GBaseFinalizeFunc) NULL,
        (GClassInitFunc) gdk_gl_context_class_init,
        NULL,           /* class_finalize */
        NULL,           /* class_data */
        sizeof (GdkGLContext),
        0,              /* n_preallocs */
        (GInstanceInitFunc) NULL,
      };
      
      object_type = g_type_register_static (G_TYPE_OBJECT,
                                            "GdkGLContext",
                                            &object_info, 0);
    }
  return object_type;
}

static void
gdk_gl_context_finalize(GObject *object)
{
  GdkGLContext *context;

  context = GDK_GL_CONTEXT(object);

  if (context->glxcontext) {
    if (context->glxcontext == glXGetCurrentContext())
      glXMakeCurrent(context->xdisplay, None, NULL);

    glXDestroyContext(context->xdisplay, context->glxcontext);
  }
  context->glxcontext = NULL;

  (* glcontext_parent_class->finalize)(object);
}

static void
gdk_gl_context_class_init(GdkGLContextClass *class)
{
  GObjectClass *gobject_class;

  gobject_class = G_OBJECT_CLASS(class);
  glcontext_parent_class = g_type_class_peek_parent(class);

  gobject_class->finalize = gdk_gl_context_finalize;
}

GdkGLContext *
gdk_gl_context_new(GdkVisual *visual)
{
  return gdk_gl_context_share_new(visual, NULL, FALSE);
}


GdkGLContext *
gdk_gl_context_share_new(GdkVisual *visual, GdkGLContext *sharelist, gint direct)
{
  Display *dpy;
  XVisualInfo *vi;
  GLXContext glxcontext;
  GdkGLContext *context;

  g_return_val_if_fail(visual != NULL, NULL);

  context = g_object_new(GDK_TYPE_GL_CONTEXT, NULL);
  if (!context) return NULL;

  dpy = GDK_DISPLAY();

  vi = get_xvisualinfo(visual);

  if (sharelist)
    glxcontext = glXCreateContext(dpy, vi, sharelist->glxcontext, direct ? True : False);
  else
    glxcontext = glXCreateContext(dpy, vi, 0, direct ? True : False);
  
  XFree(vi);
  if (glxcontext == NULL) {
    g_object_unref(context);
    return NULL;
  }
  
  context->xdisplay = dpy;
  context->glxcontext = glxcontext;
  
  return context;
}

GdkGLContext *gdk_gl_context_attrlist_share_new(int *attrlist, GdkGLContext *sharelist, gint direct)
{
  GdkVisual *visual = gdk_gl_choose_visual(attrlist);
  if (visual)
    return gdk_gl_context_share_new(visual, sharelist, direct);
  return NULL;
}


gint gdk_gl_make_current(GdkDrawable *drawable, GdkGLContext *context)
{

  g_return_val_if_fail(drawable != NULL, FALSE);
  g_return_val_if_fail(context  != NULL, FALSE);

  return (glXMakeCurrent(context->xdisplay, GDK_WINDOW_XWINDOW(drawable),
			 context->glxcontext) == True) ? TRUE : FALSE;

#if 0
  if (context->glxcontext != None && context->glxcontext == glXGetCurrentContext())
    {
      glFlush();
      return TRUE;
    }
  else
    {
      return (glXMakeCurrent(context->xdisplay, GDK_WINDOW_XWINDOW(drawable), context->glxcontext) == True) ? TRUE : FALSE;
    }
#endif
}

void gdk_gl_swap_buffers(GdkDrawable *drawable)
{
  g_return_if_fail(drawable != NULL);

  glXSwapBuffers(GDK_WINDOW_XDISPLAY(drawable), GDK_WINDOW_XWINDOW(drawable));
}

void gdk_gl_wait_gdk(void)
{
  glXWaitX();
}

void gdk_gl_wait_gl (void)
{
  glXWaitGL();
}


/* glpixmap stuff */

struct _GdkGLPixmap {
  GObject   parent;
  Display   *xdisplay;
  GLXPixmap glxpixmap;
  GdkPixmap *front_left;
};

struct _GdkGLPixmapClass {
  GObjectClass parent_class;
};
typedef struct _GdkGLPixmapClass GdkGLPixmapClass;

static GObjectClass *glpixmap_parent_class;

static void gdk_gl_pixmap_class_init (GdkGLPixmapClass *class);

GType
gdk_gl_pixmap_get_type (void)
{
  static GType object_type = 0;

  if (!object_type)
    {
      static const GTypeInfo object_info =
      {
        sizeof (GdkGLPixmapClass),
        (GBaseInitFunc) NULL,
        (GBaseFinalizeFunc) NULL,
        (GClassInitFunc) gdk_gl_pixmap_class_init,
        NULL,           /* class_finalize */
        NULL,           /* class_data */
        sizeof (GdkGLPixmap),
        0,              /* n_preallocs */
        (GInstanceInitFunc) NULL,
      };
      
      object_type = g_type_register_static (G_TYPE_OBJECT,
                                            "GdkGLPixmap",
                                            &object_info, 0);
    }
  return object_type;
}

static void
gdk_gl_pixmap_finalize(GObject *object)
{
  GdkGLPixmap *pixmap;

  pixmap = GDK_GL_PIXMAP(object);

  if (pixmap->glxpixmap != None) {
    glXDestroyGLXPixmap(pixmap->xdisplay, pixmap->glxpixmap);
    glXWaitGL();
  }
  pixmap->glxpixmap = None;
  if (pixmap->front_left) {
    gdk_pixmap_unref(pixmap->front_left);
    glXWaitX();
  }
  pixmap->front_left = NULL;

  (* glcontext_parent_class->finalize)(object);
}

static void
gdk_gl_pixmap_class_init(GdkGLPixmapClass *class)
{
  GObjectClass *gobject_class;

  gobject_class = G_OBJECT_CLASS(class);
  glpixmap_parent_class = g_type_class_peek_parent(class);

  gobject_class->finalize = gdk_gl_pixmap_finalize;
}

GdkGLPixmap *
gdk_gl_pixmap_new(GdkVisual *visual, GdkPixmap *pixmap)
{
  Display *dpy;
  XVisualInfo *vi;
  Pixmap xpixmap;
  GdkGLPixmap *glpixmap;
  GLXPixmap glxpixmap;
  Window root_return;
  unsigned int x_ret, y_ret, w_ret, h_ret, bw_ret, depth_ret;

  g_return_val_if_fail(GDK_IS_VISUAL(visual), NULL);
  g_return_val_if_fail(GDK_IS_PIXMAP(pixmap), NULL);

  glpixmap = g_object_new(GDK_TYPE_GL_PIXMAP, NULL);
  if (!glpixmap) return NULL;

  dpy = GDK_DISPLAY();
  xpixmap = (Pixmap)GDK_DRAWABLE_XID(pixmap);
  
  g_return_val_if_fail(XGetGeometry(dpy, xpixmap, &root_return,
				    &x_ret, &y_ret, &w_ret, &h_ret, &bw_ret, &depth_ret), NULL);

  g_return_val_if_fail((gdk_gl_get_config(visual, GDK_GL_RED_SIZE) +
			gdk_gl_get_config(visual, GDK_GL_GREEN_SIZE) +
			gdk_gl_get_config(visual, GDK_GL_BLUE_SIZE)) == depth_ret, NULL);

  vi = get_xvisualinfo(visual);
  glxpixmap = glXCreateGLXPixmap(dpy, vi, xpixmap);
  XFree(vi);

  g_return_val_if_fail(glxpixmap != None, NULL);

  glpixmap->xdisplay   = dpy;
  glpixmap->glxpixmap  = glxpixmap;
  glpixmap->front_left = gdk_pixmap_ref(pixmap);

  return glpixmap;
}


gint gdk_gl_pixmap_make_current(GdkGLPixmap *glpixmap, GdkGLContext *context)
{
  Display  *dpy;
  GLXPixmap glxpixmap;
  GLXContext glxcontext;

  g_return_val_if_fail(GDK_IS_GL_PIXMAP(glpixmap), FALSE);
  g_return_val_if_fail(GDK_IS_GL_PIXMAP(context), FALSE);

  dpy        = context->xdisplay;
  glxpixmap  = glpixmap->glxpixmap;
  glxcontext = context->glxcontext;

  return (glXMakeCurrent(dpy, glxpixmap, glxcontext) == True) ? TRUE : FALSE;
}

/* fonts */
void gdk_gl_use_gdk_font(GdkFont *font, int first, int count, int list_base)
{
  g_return_if_fail(font != NULL);
  glXUseXFont(gdk_font_id(font), first, count, list_base);
}

