//
//  gnomedialog.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

#include "gnome-dialog.h"
#include <gtk/gtk.h>

struct GnomeDialogRunInfo {
  gint button_number;
  gint close_id, clicked_id, destroy_id;
  gboolean destroyed;
  GMainLoop *mainloop;
};


enum {
  CLICKED,
  CLOSE,
  LAST_SIGNAL
};

extern gint dialog_signals[LAST_SIGNAL];
 
extern void gnome_dialog_setbutton_callback(GnomeDialog *dialog, gint button_number, struct GnomeDialogRunInfo *runinfo);
extern gboolean gnome_dialog_quit_run(GnomeDialog *dialog, struct GnomeDialogRunInfo *runinfo);
extern void gnome_dialog_mark_destroy(GnomeDialog* dialog, struct GnomeDialogRunInfo* runinfo);
int
gnome_dialog_run_real(GnomeDialog *dialog, gboolean close_after)
{
  gboolean was_modal;
  struct GnomeDialogRunInfo ri = {-1,-1,-1,-1,FALSE,NULL};

  g_return_val_if_fail(dialog != NULL, -1);
  g_return_val_if_fail(GNOME_IS_DIALOG(dialog), -1);

  was_modal = GTK_WINDOW(dialog)->modal;
  if (!was_modal)
    gtk_window_set_modal(GTK_WINDOW(dialog),TRUE);

  /* There are several things that could happen to the dialog, and we
     need to handle them all: click, delete_event, close, destroy */

  ri.clicked_id =
    gtk_signal_connect(dialog, "clicked",
		     GTK_SIGNAL_FUNC (gnome_dialog_setbutton_callback), &ri);

  ri.close_id =
    gtk_signal_connect(dialog, "close",
		     GTK_SIGNAL_FUNC (gnome_dialog_quit_run), &ri);

  ri.destroy_id =
    gtk_signal_connect(dialog, "destroy",
		     GTK_SIGNAL_FUNC(gnome_dialog_mark_destroy), &ri);

  if ( ! GTK_WIDGET_VISIBLE(GTK_WIDGET(dialog)) )
    gtk_widget_show(GTK_WIDGET(dialog));  
    [NSApp runModalForWindow:GTK_WIDGET(dialog)->window];
/*
  ri.mainloop = g_main_loop_new (NULL, FALSE);
  g_main_loop_run (ri.mainloop);

  g_assert(ri.mainloop == NULL);
*/
  	if(!ri.destroyed) 
	{

  //  gtk_signal_handler_disconnect(dialog, ri.destroy_id);

    if(!was_modal)
      {
	gtk_window_set_modal(GTK_WINDOW(dialog),FALSE);
      }

    if(ri.close_id >= 0) /* We didn't shut down the run? */
      {
	//	gtk_signal_handler_disconnect(dialog, ri.close_id);
	//	gtk_signal_handler_disconnect(dialog, ri.clicked_id);
      }

    if (close_after)
      {
        gnome_dialog_close(dialog);
      }
  }


  return ri.button_number;
}

void gnome_dialog_close_real(GnomeDialog * dialog)
{
  g_return_if_fail(dialog != NULL);
  g_return_if_fail(GNOME_IS_DIALOG(dialog));

  [NSApp stopModal];
  gtk_widget_hide(GTK_WIDGET(dialog));

  if ( ! dialog->just_hide ) {
    gtk_widget_destroy (GTK_WIDGET (dialog));
  }
}

void
gnome_dialog_button_clicked (GtkWidget   *button,
			     GtkWidget   *dialog)
{
  GList *list;
  int which = 0;

  g_return_if_fail(dialog != NULL);
  g_return_if_fail(GNOME_IS_DIALOG(dialog));

  list = GNOME_DIALOG (dialog)->buttons;

  while (list){
    if (list->data == button) {
	      gboolean click_closes;

	      click_closes = GNOME_DIALOG(dialog)->click_closes;

	      gtk_signal_emit (dialog, dialog_signals[CLICKED], //0,
			     which);

	      /* The dialog may have been destroyed by the clicked signal, which
		 is why we had to save the click_closes flag.  Users should be
		 careful not to set click_closes and then destroy the dialog
		 themselves too. */

	      if (click_closes) {
		      gnome_dialog_close(GNOME_DIALOG(dialog));
	      }

	      /* Dialog may now be destroyed... */
	      break;
    }
    list = list->next;
    ++which;
  }
  [NSApp stopModal];
}

void
gnome_dialog_shutdown_run(GnomeDialog* dialog,
                          struct GnomeDialogRunInfo* runinfo)
{
  [NSApp stopModal];
/*
  if (!runinfo->destroyed)
    {
      gtk_signal_handler_disconnect(dialog, runinfo->close_id);
      gtk_signal_handler_disconnect(dialog, runinfo->clicked_id);

      runinfo->close_id = runinfo->clicked_id = -1;
    }

  if (runinfo->mainloop)
    {
      g_main_loop_quit (runinfo->mainloop);
      g_main_loop_unref (runinfo->mainloop);
      runinfo->mainloop = NULL;
    }
*/
}
