//
//  gnome-file-entry.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#include <gtk/gtk.h>
#include "gnome-file-entry.h"

struct _GnomeFileEntryPrivate {
	GtkWidget *gentry;

	char *browse_dialog_title;

	gboolean is_modal : 1;

	gboolean directory_entry : 1; /*optional flag to only do directories*/

	gboolean save_panel : 1; /*optional flag to open a save panel */

	/* FIXME: Non local files!! */
	/* FIXME: executable_entry as used in gnome_run */
	/* FIXME: multiple_entry for entering multiple filenames */
};


void
browse_clicked(GnomeFileEntry *fentry)
{
#if 0
	GtkWidget *fsw;
	GtkFileSelection *fs;
	char *p;

	/*if it already exists make sure it's shown and raised*/
	if(fentry->fsw) {
		gtk_widget_show(fentry->fsw);
		if(fentry->fsw->window)
			gdk_window_raise(fentry->fsw->window);
		fs = GTK_FILE_SELECTION(fentry->fsw);
		gtk_widget_set_sensitive(fs->file_list,
					 ! fentry->_priv->directory_entry);

		p = build_filename (fentry);
		if (p != NULL) {
			gtk_file_selection_set_filename (fs, p);
			g_free (p);
		}
		return;
	}


	fsw = gtk_file_selection_new (fentry->_priv->browse_dialog_title
				      ? fentry->_priv->browse_dialog_title
				      : _("Select file"));

	g_object_set_data (GTK_OBJECT (fsw), "gnome_file_entry", fentry);

	fs = GTK_FILE_SELECTION (fsw);
	gtk_widget_set_sensitive(fs->file_list,
				 ! fentry->_priv->directory_entry);

	p = build_filename (fentry);
	if (p != NULL) {
		gtk_file_selection_set_filename (fs, p);
		g_free (p);
	}

	gtk_signal_connect (fs->ok_button, "clicked",
			  G_CALLBACK (browse_dialog_ok),
			  fs);
	gtk_signal_connect_swapped (fs->cancel_button, "clicked",
				  G_CALLBACK (gtk_widget_destroy),
				  fsw);
	gtk_signal_connect (fsw, "destroy",
			  G_CALLBACK (browse_dialog_kill),
			  fentry);

	if (gtk_grab_get_current ())
		gtk_grab_add (fsw);

	gtk_widget_show (fsw);

	if(fentry->_priv->is_modal)
		gtk_window_set_modal (GTK_WINDOW (fsw), TRUE);
	fentry->fsw = fsw;
#endif
	GtkWidget *entry;
	NSOpenPanel *op;
	char * FileName;
	int res,i;
	NSArray *filter = [NSArray array];

	entry = gnome_file_entry_gtk_entry (fentry);
	if(fentry->_priv->save_panel)
	{
		op = [NSSavePanel savePanel];
		res = [op runModalForDirectory:nil file:nil];
	}
	else
	{
		op = [NSOpenPanel openPanel];
		if(fentry->filter)
			for(i=0;fentry->filter[i];i++)
				filter = [filter arrayByAddingObject:[NSString stringWithCString:fentry->filter[i]]];
		res = [op runModalForDirectory:nil file:nil types:filter];
	}
	if(res==NSOKButton)
	{
		if(fentry->_priv->save_panel)
			FileName = [[op filename] cString];
		else
			FileName = [[[op filenames] objectAtIndex:0] cString];
		browse_dialog_ok(NULL,FileName);
		gtk_entry_set_text (GTK_ENTRY (entry),
			    FileName);
		gtk_signal_emit_by_name (entry, "activate");
	}
}

void
gnome_file_entry_save_panel(GnomeFileEntry *fentry, gboolean save)
{
	fentry->_priv->save_panel = save;
}

void
gnome_file_entry_set_filter(GnomeFileEntry *fentry, gchar **filter)
{
	fentry->filter = filter;
}
