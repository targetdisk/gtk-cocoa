//
//  gdkpixmap.m
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

typedef struct
{
	unsigned char red,green,blue,alpha;
} Color;


gboolean
color_parse(gchar *color_name, Color *color)
{
	unsigned int red,green,blue;
	sscanf(color_name,"#%2x%2x%2x",&red,&green,&blue);
	color->red = (unsigned char)red;
	color->green = (unsigned char)green;
	color->blue = (unsigned char)blue;
	color->alpha = 255;
	return TRUE;
}

GdkPixmap*
gdk_pixmap_new (GdkWindow *window,
		gint       width,
		gint       height,
		gint       depth)
{
  GdkPixmap *pixmap;

  g_return_val_if_fail ((window != NULL) || (depth != -1), NULL);
  g_return_val_if_fail ((width != 0) && (height != 0), NULL);

  return pixmap;
}

GdkPixmap *
gdk_bitmap_create_from_data (GdkWindow   *window,
			     const gchar *data,
			     gint         width,
			     gint         height)
{
  GdkPixmap *pixmap;

  g_return_val_if_fail (data != NULL, NULL);
  g_return_val_if_fail ((width != 0) && (height != 0), NULL);

  return pixmap;
}

GdkPixmap*
gdk_pixmap_create_from_data (GdkWindow   *window,
			     const gchar *data,
			     gint         width,
			     gint         height,
			     gint         depth,
			     GdkColor    *fg,
			     GdkColor    *bg)
{
  GdkPixmap *pixmap;

  g_return_val_if_fail (data != NULL, NULL);
  g_return_val_if_fail (fg != NULL, NULL);
  g_return_val_if_fail (bg != NULL, NULL);
  g_return_val_if_fail ((window != NULL) || (depth != -1), NULL);
  g_return_val_if_fail ((width != 0) && (height != 0), NULL);

  return pixmap;
}

static gint
gdk_pixmap_seek_string (FILE  *infile,
                        const gchar *str,
                        gint   skip_comments)
{
  char instr[1024];

  while (1)
    {
      if (fscanf (infile, "%1023s", instr) != 1)
	return FALSE;
	  
      if (skip_comments == TRUE && strcmp (instr, "/*") == 0)
        {
	  do
	    {
	      if (fscanf (infile, "%1023s", instr) != 1)
		return FALSE;
	    }
	  while (strcmp (instr, "*/") != 0);
        }
      else if (strcmp (instr, str) == 0)
        return TRUE;
    }
}

static gint
gdk_pixmap_seek_char (FILE  *infile,
                      gchar  c)
{
  gint b, oldb;

  while ((b = getc(infile)) != EOF)
    {
      if (c != b && b == '/')
	{
	  b = getc (infile);
	  if (b == EOF)
	    return FALSE;
	  else if (b == '*')	/* we have a comment */
 	    {
	      b = -1;
	      do
 		{
 		  oldb = b;
		  b = getc (infile);
 		  if (b == EOF)
 		    return FALSE;
 		}
 	      while (!(oldb == '*' && b == '/'));
 	    }
        }
      else if (c == b)
 	return TRUE;
    }
  return FALSE;
}

static gint
gdk_pixmap_read_string (FILE  *infile,
                        gchar **buffer,
			guint *buffer_size)
{
  gint c;
  guint cnt = 0, bufsiz, ret = FALSE;
  gchar *buf;

  buf = *buffer;
  bufsiz = *buffer_size;
  if (buf == NULL)
    {
      bufsiz = 10 * sizeof (gchar);
      buf = g_new(gchar, bufsiz);
    }

  do
    c = getc (infile);
  while (c != EOF && c != '"');

  if (c != '"')
    goto out;

  while ((c = getc(infile)) != EOF)
    {
      if (cnt == bufsiz)
	{
	  guint new_size = bufsiz * 2;
	  if (new_size > bufsiz)
	    bufsiz = new_size;
	  else
	    goto out;
	  
 	  buf = (gchar *) g_realloc (buf, bufsiz);
	  buf[bufsiz-1] = '\0';
	}

      if (c != '"')
        buf[cnt++] = c;
      else
        {
          buf[cnt] = 0;
	  ret = TRUE;
	  break;
        }
    }

 out:
  buf[bufsiz-1] = '\0';		/* ensure null termination for errors */
  *buffer = buf;
  *buffer_size = bufsiz;
  return ret;
}

static gchar*
gdk_pixmap_skip_whitespaces (gchar *buffer)
{
  gint32 index = 0;

  while (buffer[index] != 0 && (buffer[index] == 0x20 || buffer[index] == 0x09))
    index++;

  return &buffer[index];
}

static gchar*
gdk_pixmap_skip_string (gchar *buffer)
{
  gint32 index = 0;

  while (buffer[index] != 0 && buffer[index] != 0x20 && buffer[index] != 0x09)
    index++;

  return &buffer[index];
}

/* Xlib crashed ince at a color name lengths around 125 */
#define MAX_COLOR_LEN 120

static gchar*
gdk_pixmap_extract_color (gchar *buffer)
{
  gint counter, numnames;
  gchar *ptr = NULL, ch, temp[128];
  gchar color[MAX_COLOR_LEN], *retcol;
  gint space;

  counter = 0;
  while (ptr == NULL)
    {
      if (buffer[counter] == 'c')
        {
          ch = buffer[counter + 1];
          if (ch == 0x20 || ch == 0x09)
            ptr = &buffer[counter + 1];
        }
      else if (buffer[counter] == 0)
        return NULL;

      counter++;
    }

  ptr = gdk_pixmap_skip_whitespaces (ptr);

  if (ptr[0] == 0)
    return NULL;
  else if (ptr[0] == '#')
    {
      counter = 1;
      while (ptr[counter] != 0 && 
             ((ptr[counter] >= '0' && ptr[counter] <= '9') ||
              (ptr[counter] >= 'a' && ptr[counter] <= 'f') ||
              (ptr[counter] >= 'A' && ptr[counter] <= 'F')))
        counter++;

      retcol = g_new (gchar, counter+1);
      strncpy (retcol, ptr, counter);

      retcol[counter] = 0;
      
      return retcol;
    }

  color[0] = 0;
  numnames = 0;

  space = MAX_COLOR_LEN - 1;
  while (space > 0)
    {
      sscanf (ptr, "%127s", temp);

      if (((gint)ptr[0] == 0) ||
	  (strcmp ("s", temp) == 0) || (strcmp ("m", temp) == 0) ||
          (strcmp ("g", temp) == 0) || (strcmp ("g4", temp) == 0))
	{
	  break;
	}
      else
        {
          if (numnames > 0)
	    {
	      space -= 1;
	      strcat (color, " ");
	    }
	  strncat (color, temp, space);
	  space -= MIN (space, strlen (temp));
          ptr = gdk_pixmap_skip_string (ptr);
          ptr = gdk_pixmap_skip_whitespaces (ptr);
          numnames++;
        }
    }

  retcol = g_strdup (color);
  return retcol;
}


enum buffer_op
{
  op_header,
  op_cmap,
  op_body
};
  

static void 
gdk_xpm_destroy_notify (gpointer data)
{
}
  
GdkPixmap *
gdk_pixmap_create_from_file ( gchar *  filename)
{
  FILE *fp;
  NSImage *img;
  
	NSString *path = [NSString stringWithCString:filename];
 	img = [NSImage alloc];
	img = [img initWithContentsOfFile:path]; 
	return img;
}

GdkPixmap *
gdk_pixmap_create_from_ppm ( gchar *  filename)
{
  FILE *fp;
  NSBitmapImageRep *image;
  NSImage *img;
  gint width, height, num_cols;
  gchar *buffer, pixel_str[32];
  unsigned char *bitplanes[5];
  char type[8],buf[256];
  
  fp = fopen(filename, "rb");
  if(!fp) return NULL;
  
  fread(type,3,1, fp);
   type[2] ='\0';
  if(strcmp(type,"P6")) 
  {
	fclose(fp);
	NSString *path = [NSString stringWithCString:filename];
//	img = [NSImage alloc];
//	img = [img initWithContentsOfFile:path]; 
	return NULL;
  } 
/*  {
		NSString *thePath = [NSString stringWithCString:filename];
		NSData *myData = [NSData dataWithContentsOfFile:thePath];
		fclose(fp);
		image = [NSBitmapImageRep imageRepWithData:myData];
		if(image)
		{
  			img = [NSImage alloc];
  			[img addRepresentation:image];
	    	return img;
		}
		else return NULL;
  }
*/
  fgets(buf,256, fp);
  while(buf[0]=='#')
    fgets(buf,256, fp);
  sscanf (buf,"%d %d", &width, &height);
  fscanf (fp,"%d\n", &num_cols);
  image = [NSBitmapImageRep alloc];
  [image initWithBitmapDataPlanes:NULL
		pixelsWide:width
		pixelsHigh:height
		bitsPerSample:8
		samplesPerPixel:3
		hasAlpha:NO
		isPlanar:NO
		colorSpaceName:NSDeviceRGBColorSpace
		bytesPerRow:0
		bitsPerPixel:0];
		
   [image getBitmapDataPlanes:bitplanes];
   fread(bitplanes[0],width*3,height,fp);
   fclose(fp);
      
  img = [NSImage alloc];
  [img addRepresentation:image];
  return img;
}

static GdkPixmap *
_gdk_pixmap_create_from_xpm (GdkWindow  *window,
			     GdkColormap *colormap,
			     GdkBitmap **mask,
			     GdkColor   *transparent_color,
			     gchar *   (*get_buf) (enum buffer_op op,
						   gpointer       handle),
			     gpointer    handle)
{
  NSBitmapImageRep *image;
  NSImage *img;
  gint width, height, num_cols, cpp, n, ns, cnt, xcnt, ycnt, wbytes;
  gchar *buffer, pixel_str[32],*color_string;
  gchar *name_buf;
  gulong index;
  unsigned char *bitplanes[5];
  GHashTable *color_hash = NULL;
  Color *color,*fallbackcolor, *colors, transparent={0,0,0,0};
  int bpr=0;
  
//  if ((window == NULL) && (colormap == NULL))
//    g_warning ("Creating pixmap from xpm with NULL window and colormap");
  
  
  buffer = (*get_buf) (op_header, handle);
  if (buffer == NULL)
    return NULL;
  
  sscanf (buffer,"%d %d %d %d", &width, &height, &num_cols, &cpp);
  if (cpp >= 32)
    {
      g_warning ("Pixmap has more than 31 characters per color\n");
      return NULL;
    }
  
  color_hash = g_hash_table_new (g_str_hash, g_str_equal);
  
  name_buf = g_new (gchar, num_cols * (cpp+1));
  colors = g_new (Color, num_cols);

  for (cnt = 0; cnt < num_cols; cnt++)
    {
      gchar *color_name;
      
      buffer = (*get_buf) (op_cmap, handle);
      if (buffer == NULL)
	goto error;
      
      color = &colors[cnt];
      color_string = &name_buf [cnt * (cpp + 1)];
      strncpy (color_string, buffer, cpp);
      color_string[cpp] = 0;
      buffer += strlen (color_string);
      
      color_name = gdk_pixmap_extract_color (buffer);
      
      if (color_name == NULL || g_strcasecmp (color_name, "None") == 0 ||
	  color_parse (color_name, color) == FALSE)
	{
	  color = &transparent;
	}
      
      g_free (color_name);
      
      g_hash_table_insert (color_hash, color_string, color);
      if (cnt == 0)
	fallbackcolor = color;
    }
  
  index = 0;
  image = [NSBitmapImageRep alloc];
  [image initWithBitmapDataPlanes:NULL
		pixelsWide:width
		pixelsHigh:height
		bitsPerSample:8
		samplesPerPixel:4
		hasAlpha:YES
		isPlanar:NO
		colorSpaceName:NSDeviceRGBColorSpace
		bytesPerRow:0
		bitsPerPixel:0];
		
   [image getBitmapDataPlanes:bitplanes];
	bpr = [image bytesPerRow];
#if 0
  if (mask)
    {
      /* The pixmap mask is just a bits pattern.
       * Color 0 is used for background and 1 for foreground.
       * We don't care about the colormap, we just need 0 and 1.
       */
      GdkColor mask_pattern;
      
      *mask = gdk_pixmap_new (window, width, height, 1);
      gc = gdk_gc_new (*mask);
      
      mask_pattern.pixel = 0;
      gdk_gc_set_foreground (gc, &mask_pattern);
      gdk_draw_rectangle (*mask, gc, TRUE, 0, 0, -1, -1);
      
      mask_pattern.pixel = 1;
      gdk_gc_set_foreground (gc, &mask_pattern);
    }
#endif
  
  wbytes = width * cpp;
  for (ycnt = 0; ycnt < height; ycnt++)
    {
      buffer = (*get_buf) (op_body, handle);
      
      /* FIXME: this slows things down a little - it could be
       * integrated into the strncpy below, perhaps. OTOH, strlen
       * is fast.
       */
      if ((buffer == NULL) || strlen (buffer) < wbytes)
	continue;
      
      for (n = 0, cnt = 0, xcnt = 0; n < wbytes; n += cpp, xcnt+=4)
	{
	  strncpy (pixel_str, &buffer[n], cpp);
	  pixel_str[cpp] = 0;
	  ns = 0;
	  
	  color = g_hash_table_lookup (color_hash, pixel_str);
	  
	  if (!color) /* screwed up XPM file */
	    color = fallbackcolor;
	  
	  bitplanes[0][ycnt*bpr+xcnt] = color->red;
	  bitplanes[0][ycnt*bpr+xcnt+1] = color->green;
	  bitplanes[0][ycnt*bpr+xcnt+2] = color->blue;
	  bitplanes[0][ycnt*bpr+xcnt+3] = color->alpha;
	}
      
    }
  
 error:
  
  if (color_hash != NULL)
    g_hash_table_destroy (color_hash);

  if (colors != NULL)
    g_free (colors);

  if (name_buf != NULL)
    g_free (name_buf);

  img = [NSImage alloc];
  [img addRepresentation:image];
  return img;
}


struct file_handle
{
  FILE *infile;
  gchar *buffer;
  guint buffer_size;
};


static gchar *
file_buffer (enum buffer_op op, gpointer handle)
{
  struct file_handle *h = handle;

  switch (op)
    {
    case op_header:
      if (gdk_pixmap_seek_string (h->infile, "XPM", FALSE) != TRUE)
	break;

      if (gdk_pixmap_seek_char (h->infile,'{') != TRUE)
	break;
      /* Fall through to the next gdk_pixmap_seek_char. */

    case op_cmap:
      gdk_pixmap_seek_char (h->infile, '"');
      fseek (h->infile, -1, SEEK_CUR);
      /* Fall through to the gdk_pixmap_read_string. */

    case op_body:
      gdk_pixmap_read_string (h->infile, &h->buffer, &h->buffer_size);
      return h->buffer;
    }
  return 0;
}

GdkPixmap*
gdk_pixmap_colormap_create_from_xpm (GdkWindow   *window,
				     GdkColormap *colormap,
				     GdkBitmap  **mask,
				     GdkColor    *transparent_color,
				     const gchar *filename)
{
  struct file_handle h;
  GdkPixmap *pixmap = NULL;
  char *buffer[256];
  
printf("%s\n",getcwd(buffer, 256));
  memset (&h, 0, sizeof (h));
  h.infile = fopen (filename, "rb");
  if (h.infile != NULL)
    {
      pixmap = _gdk_pixmap_create_from_xpm (window, colormap, mask,
					    transparent_color,
					    file_buffer, &h);
      fclose (h.infile);
      g_free (h.buffer);
    }

  return pixmap;
}

GdkPixmap*
gdk_pixmap_create_from_xpm (GdkWindow  *window,
			    GdkBitmap **mask,
			    GdkColor   *transparent_color,
			    const gchar *filename)
{
  return gdk_pixmap_colormap_create_from_xpm (window, NULL, mask,
				       transparent_color, filename);
}


struct mem_handle
{
  gchar **data;
  int offset;
};


static gchar *
mem_buffer (enum buffer_op op, gpointer handle)
{
  struct mem_handle *h = handle;
  switch (op)
    {
    case op_header:
    case op_cmap:
    case op_body:
      if (h->data[h->offset])
	return h->data[h->offset ++];
    }
  return 0;
}


GdkPixmap*
gdk_pixmap_colormap_create_from_xpm_d (GdkWindow  *window,
				       GdkColormap *colormap,
				       GdkBitmap **mask,
				       GdkColor   *transparent_color,
				       gchar     **data)
{
  struct mem_handle h;
  GdkPixmap *pixmap = NULL;

  memset (&h, 0, sizeof (h));
  h.data = data;
  pixmap = _gdk_pixmap_create_from_xpm (window, colormap, mask,
					transparent_color,
					mem_buffer, &h);
  return pixmap;
}


GdkPixmap*
gdk_pixmap_create_from_xpm_d (GdkWindow  *window,
			      GdkBitmap **mask,
			      GdkColor   *transparent_color,
			      gchar     **data)
{
  return gdk_pixmap_colormap_create_from_xpm_d (window, NULL, mask,
						transparent_color, data);
}

GdkPixmap*
gdk_pixmap_foreign_new (guint32 anid)
{
  return NULL;
}

GdkPixmap*
gdk_pixmap_ref (GdkPixmap *pixmap)
{
  return pixmap;
}

void
gdk_pixmap_unref (GdkPixmap *pixmap)
{
}

GdkBitmap *
gdk_bitmap_ref (GdkBitmap *bitmap)
{
}

void
gdk_bitmap_unref (GdkBitmap *bitmap)
{
}

