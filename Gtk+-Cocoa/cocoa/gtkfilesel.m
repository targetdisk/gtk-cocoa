//
//  gtkfilesel.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>

#include <gtk/gtk.h>
#include <sys/param.h>

void
gtk_file_selection_init (GtkFileSelection *filesel)
{
	filesel->fileop_file = NULL;
	GTK_WIDGET(filesel)->proxy = [NSOpenPanel openPanel];
}

void
gtk_file_selection_set_filename (GtkFileSelection *filesel,
				 const gchar      *filename)
{
  char  buf[MAXPATHLEN];
  const char *name, *last_slash;

  g_return_if_fail (filesel != NULL);
  g_return_if_fail (GTK_IS_FILE_SELECTION (filesel));
  g_return_if_fail (filename != NULL);

  last_slash = strrchr (filename, '/');

  if (!last_slash)
    {
      buf[0] = 0;
      name = filename;
    }
  else
    {
      gint len = MIN (MAXPATHLEN - 1, last_slash - filename + 1);

      strncpy (buf, filename, len);
      buf[len] = 0;

      name = last_slash + 1;
    }
#if 0
  gtk_file_selection_populate (filesel, buf, FALSE);

  if (filesel->selection_entry)
    gtk_entry_set_text (GTK_ENTRY (filesel->selection_entry), name);
#endif
	if(filesel->fileop_file)
		g_free(filesel->fileop_file);
	filesel->fileop_file = strdup(buf);
}


