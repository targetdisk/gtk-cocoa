/*
 * Copyright (C) 1997-1998 Janne Löf <jlof@mail.student.oulu.fi>
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

#include "gtkglarea.h"
#include <gl.h>
#include <stdarg.h>

static void gtk_gl_area_class_init    (GtkGLAreaClass *klass);
static void gtk_gl_area_init          (GtkGLArea      *glarea);
static void gtk_gl_area_destroy       (GtkObject      *object); /* change to finalize? */

static GtkDrawingAreaClass *parent_class = NULL;


GtkType
gtk_gl_area_get_type (void)
{
  static GtkType object_type = 0;

  if (!object_type)
    {
      static const GtkTypeInfo object_info =
      {
		"GtkGLArea",
        sizeof (GtkGLArea),
        sizeof (GtkGLAreaClass),
        (GtkClassInitFunc) gtk_gl_area_class_init,
        (GtkObjectInitFunc) gtk_gl_area_init,
        NULL,           /* class_finalize */
        NULL,           /* class_data */
        (GtkClassInitFunc) NULL,
      };
      
      object_type = gtk_type_unique (GTK_TYPE_DRAWING_AREA, &object_info);
    }
  return object_type;
}

static void
gtk_gl_area_class_init (GtkGLAreaClass *klass)
{
  GtkObjectClass *object_class;

  parent_class = gtk_type_class(GTK_TYPE_DRAWING_AREA);
  object_class = (GtkObjectClass*) klass;
  
  object_class->destroy = gtk_gl_area_destroy;
}




GtkWidget*
gtk_gl_area_new_vargs(GtkGLArea *share, ...)
{
  GtkWidget *glarea;
  va_list ap;
  int i;
  gint *attrlist;

  va_start(ap, share);
  i=1;
  while (va_arg(ap, int) != GL_NONE) /* get number of arguments */
    i++;
  va_end(ap);

  attrlist = g_new(int,i);

  va_start(ap,share);
  i=0;
  while ( (attrlist[i] = va_arg(ap, int)) != GL_NONE) /* copy args to list */
    i++;
  va_end(ap);
  
  glarea = gtk_gl_area_share_new(attrlist, share);

  g_free(attrlist);

  return glarea;
}

GtkWidget*
gtk_gl_area_new (int *attrlist)
{
  return gtk_gl_area_share_new(attrlist, NULL);
}


static void
gtk_gl_area_destroy(GtkObject *object)
{
  GtkGLArea *gl_area;

  g_return_if_fail (object != NULL);
  g_return_if_fail (GTK_IS_GL_AREA(object));
  
  gl_area = GTK_GL_AREA(object);

  //if (gl_area->glcontext)
  //  g_object_unref(gl_area->glcontext);
  //gl_area->glcontext = NULL;

  if (GTK_OBJECT_CLASS (parent_class)->destroy)
    (* GTK_OBJECT_CLASS (parent_class)->destroy) (object);
}



