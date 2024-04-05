/* 
 * Copyright (C) 1998 Janne Löf <jlof@mail.student.oulu.fi>
 * Copyright (C) 2000 Marc Flerackers <mflerackers@androme.be>
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
#include <GL/gl.h>
#include <gdk/gdkwin32.h>

static void fill_pfd(PIXELFORMATDESCRIPTOR *pfd, int *attriblist)
{
  /*
   * Ripped from glut's win32_x11.c
   */
  
  int *p = attriblist;

  memset(pfd, 0, sizeof(PIXELFORMATDESCRIPTOR));
  pfd->nSize = (sizeof(PIXELFORMATDESCRIPTOR));
  pfd->nVersion = 1;
  
  /* Defaults. */
  pfd->dwFlags = PFD_SUPPORT_OPENGL | PFD_DRAW_TO_WINDOW;
  pfd->iPixelType = PFD_TYPE_COLORINDEX;
  pfd->cColorBits = 32;
  pfd->cDepthBits = 0;
  pfd->cAccumBits = 0;
  
  while (*p) {
    switch (*p) {
    case GDK_GL_USE_GL:
      pfd->dwFlags |= PFD_SUPPORT_OPENGL;
      break;
    case GDK_GL_BUFFER_SIZE:
      pfd->cColorBits = *(++p);
      break;
    case GDK_GL_LEVEL:
      /* the bReserved flag of the pfd contains the
         overlay/underlay info. */
      pfd->bReserved = *(++p);
      break;
    case GDK_GL_RGBA:
      pfd->iPixelType = PFD_TYPE_RGBA;
      break;
    case GDK_GL_DOUBLEBUFFER:
      pfd->dwFlags |= PFD_DOUBLEBUFFER;
      break;
    case GDK_GL_STEREO:
      pfd->dwFlags |= PFD_STEREO;
      break;
    case GDK_GL_AUX_BUFFERS:
      pfd->cAuxBuffers = *(++p);
      break;
    case GDK_GL_RED_SIZE:
      pfd->cRedBits = 8; /* Try to get the maximum. */
      ++p;
      break;
    case GDK_GL_GREEN_SIZE:
      pfd->cGreenBits = 8;
      ++p;
      break;
    case GDK_GL_BLUE_SIZE:
      pfd->cBlueBits = 8;
      ++p;
      break;
    case GDK_GL_ALPHA_SIZE:
      pfd->cAlphaBits = 8;
      ++p;
      break;
    case GDK_GL_DEPTH_SIZE:
      pfd->cDepthBits = 32;
      ++p;
      break;
    case GDK_GL_STENCIL_SIZE:
      pfd->cStencilBits = *(++p);
      break;
    case GDK_GL_ACCUM_RED_SIZE:
    case GDK_GL_ACCUM_GREEN_SIZE:
    case GDK_GL_ACCUM_BLUE_SIZE:
    case GDK_GL_ACCUM_ALPHA_SIZE:
      /* I believe that WGL only used the cAccumRedBits,
	 cAccumBlueBits, cAccumGreenBits, and cAccumAlphaBits fields
	 when returning info about the accumulation buffer precision.
	 Only cAccumBits is used for requesting an accumulation
	 buffer. */
      pfd->cAccumBits += *(++p);
		break;
    }
    ++p;
  }
}

gint gdk_gl_query(void)
{
  return TRUE;
}

gchar *gdk_gl_get_info()
{
  return g_strdup_printf("VENDOR     : %s\n"
			 "VERSION    : %s\n"
			 "EXTENSIONS : %s\n",
			 glGetString ( GL_VENDOR ),
			 glGetString ( GL_VERSION ),
			 glGetString ( GL_EXTENSIONS ));
}

GdkVisual *gdk_gl_choose_visual(int *attrlist)
{
  return gdk_visual_get_system ();
}

int gdk_gl_get_config(GdkVisual *visual, int attrib)
{
  g_warning ( "not implemented" );
  return 0;
}

struct _GdkGLContext {
  GObject   parent;
  gboolean  initialised;
  HGLRC     hglrc;
  HDC       hdc;
  HWND      hwnd;
  GdkGLContext *share;
  PIXELFORMATDESCRIPTOR pfd;
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

  if (context->hglrc == wglGetCurrentContext () )
    wglMakeCurrent ( NULL, NULL );

  wglDeleteContext ( context->hglrc );
	
  if ( context->hwnd )
    ReleaseDC ( context->hwnd, context->hdc );
  else
    DeleteDC ( context->hdc );

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
  return gdk_gl_context_share_new ( visual, NULL, FALSE );
}

GdkGLContext *
gdk_gl_context_share_new(GdkVisual *visual, GdkGLContext *sharelist, gint direct)
{
  GdkGLContext *context;
  
  g_return_val_if_fail ( visual != NULL, NULL );

  context = g_object_new(GDK_TYPE_GL_CONTEXT, NULL);
  if (!context) return NULL;

  context->initialised = FALSE;
  context->hglrc   = NULL;
  context->hdc     = NULL;
  context->hwnd    = NULL;
  context->share   = sharelist ? g_object_ref(sharelist) : NULL;

  memset ( &(context->pfd), 0, sizeof(PIXELFORMATDESCRIPTOR) );

  /* if direct is TRUE, we create a context which renders to the screen, otherwise
     we create one to render to an offscreen bitmap */
  if ( direct )
  {
    context->pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
    context->pfd.nVersion = 1;
    context->pfd.dwFlags = PFD_SUPPORT_OPENGL | PFD_DRAW_TO_WINDOW | PFD_DOUBLEBUFFER;
    context->pfd.iPixelType = PFD_TYPE_RGBA;
    context->pfd.cColorBits = 24;
    context->pfd.cDepthBits = 32;
    context->pfd.iLayerType = PFD_MAIN_PLANE;
  } 
  else
  {
    context->pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
    context->pfd.nVersion = 1;
    context->pfd.dwFlags = PFD_SUPPORT_OPENGL | PFD_DRAW_TO_BITMAP | PFD_SUPPORT_GDI;
    context->pfd.iPixelType = PFD_TYPE_RGBA;
    context->pfd.cColorBits = 24;
    context->pfd.cDepthBits = 32;
    context->pfd.iLayerType = PFD_MAIN_PLANE;
  }
  
  return context;
}

GdkGLContext *
gdk_gl_context_attrlist_share_new(int *attrlist, GdkGLContext *sharelist, gint direct)
{
  GdkGLContext *context;

  g_return_val_if_fail(attrlist != NULL, NULL);

  context = g_object_new(GDK_TYPE_GL_CONTEXT, NULL);
  if (!context) return NULL;

  context->initialised = FALSE;
  context->hglrc    = NULL;
  context->hdc      = NULL;
  context->hwnd     = NULL;
  context->share    = sharelist ? g_object_ref(sharelist) : NULL;
  fill_pfd(&context->pfd, attrlist);

  return context;
}

gint gdk_gl_make_current(GdkDrawable *drawable, GdkGLContext *context)
{

  g_return_val_if_fail (GDK_IS_DRAWABLE(drawable), FALSE );
  g_return_val_if_fail (GDK_IS_GL_CONTEXT(context), FALSE );

  if ( !context->initialised )
  {
    int pf;
    HWND hwnd = (HWND) gdk_win32_drawable_get_handle ( drawable );

    context->hdc = GetDC ( hwnd );

    pf = ChoosePixelFormat ( context->hdc, &context->pfd );

    if ( pf != 0 )
	{
	  SetPixelFormat ( context->hdc, pf, &context->pfd );
	  context->hglrc = wglCreateContext ( context->hdc );
	}

    if (context->share)
	{
	  if ( context->share->hglrc )
	    wglShareLists ( context->share->hglrc, context->hglrc );
	  g_object_unref ( context->share );
	}

    context->initialised = TRUE;
  }

  g_return_val_if_fail ( context->hdc    != NULL, FALSE );
  g_return_val_if_fail ( context->hglrc  != NULL, FALSE );

  wglMakeCurrent ( context->hdc, context->hglrc );
  
  return TRUE;
}


void gdk_gl_swap_buffers(GdkDrawable *drawable)
{
  HDC   hdc;
  HWND  hwnd;

  g_return_if_fail ( GDK_IS_DRAWABLE(drawable) );

  hwnd = (HWND) gdk_win32_drawable_get_handle ( drawable );
  hdc  = GetDC ( hwnd );
  if ( hdc  == NULL )
  {
     g_warning ( "gdk_gl_swap_buffers: GetDC failed" );
     return;
  }
  SwapBuffers ( hdc );
  ReleaseDC ( hwnd, hdc );
}


void gdk_gl_wait_gdk(void)
{
	GdiFlush ();
}

void gdk_gl_wait_gl (void)
{
	glFinish ();
}

/* glpixmap stuff */

struct _GdkGLPixmap {
  GObject   object;
  gboolean  initialised;
  HDC       hdc;
  HBITMAP   hbitmap;
  GdkPixmap *pixmap;
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

  glFinish ();
  SelectObject ( pixmap->hdc, pixmap->hbitmap );
  gdk_pixmap_unref ( pixmap->pixmap );

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

GdkGLPixmap *gdk_gl_pixmap_new(GdkVisual *visual, GdkPixmap *pixmap)
{
  GdkGLPixmap *glpixmap;

  g_return_val_if_fail(GDK_IS_VISUAL(visual), NULL);
  g_return_val_if_fail(GDK_IS_PIXMAP(pixmap), NULL);

  glpixmap = g_object_new(GDK_TYPE_GL_PIXMAP, NULL);
  if (!glpixmap) return NULL;

  glpixmap->initialised = FALSE;
  glpixmap->hdc = NULL;
  glpixmap->hbitmap = NULL;
  glpixmap->pixmap = gdk_pixmap_ref ( pixmap );

  return glpixmap;
}

gint gdk_gl_pixmap_make_current(GdkGLPixmap *glpixmap, GdkGLContext *context)
{
  g_return_val_if_fail (GDK_IS_GL_PIXMAP(glpixmap), FALSE );
  g_return_val_if_fail (GDK_IS_GL_CONTEXT(context), FALSE );

  if ( !context->initialised )
  {
    int pf;

    context->hdc = CreateCompatibleDC ( NULL );
    glpixmap->hdc = context->hdc;
    glpixmap->hbitmap = SelectObject ( context->hdc, (HBITMAP) gdk_win32_drawable_get_handle ( glpixmap->pixmap ) );

    pf = ChoosePixelFormat ( context->hdc, &context->pfd );

    if ( pf != 0 )
	{
	  SetPixelFormat ( context->hdc, pf, &context->pfd );
	  context->hglrc = wglCreateContext ( context->hdc );
	}

    if (context->share)
	{
	  if ( context->share->hglrc )
	    wglShareLists ( context->share->hglrc, context->hglrc );
	  gdk_gl_context_unref ( (GdkGLContext*)context->share );
	}

    context->initialised = TRUE;
  }

  g_return_val_if_fail ( context->hdc    != NULL, FALSE );
  g_return_val_if_fail ( context->hglrc  != NULL, FALSE );

  wglMakeCurrent ( context->hdc, context->hglrc );
  
  return TRUE;
}

/* fonts */
void gdk_gl_use_gdk_font(GdkFont *font, int first, int count, int list_base)
{
  HDC dc = CreateCompatibleDC ( NULL );
  HFONT old_font = SelectObject ( dc, gdk_font_id ( font ) );

  wglUseFontBitmaps ( dc, first, count, list_base );

  SelectObject ( dc, old_font );
  DeleteDC ( dc );
}

