//
//  gtklabel.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Sep 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"
#include "gdk/gdkkeysyms.h"

#include <gtk/gtk.h>

void
gtk_label_init (GtkLabel *label)
{
  NSGtkButton *text;

  GTK_WIDGET_SET_FLAGS (label, GTK_NO_WINDOW);
  
  label->label = NULL;
  label->label_wc = NULL;
  label->pattern = NULL;

  label->words = NULL;

  label->max_width = 0;
  label->jtype = GTK_JUSTIFY_CENTER;
  label->wrap = FALSE;

  text = [[NSGtkButton alloc] initWithFrame:NSMakeRect(0,0,100,10)];
  [GTK_WIDGET(label)->proxy release];
  GTK_WIDGET(label)->proxy = text;
  GTK_WIDGET(label)->window = text;
  text->proxy = label;
  [text  setBordered:NO];
  [[text cell] setHighlightsBy:NSNoCellMask];
  gtk_label_set_text (label, "");
}

void
gtk_label_set_text (GtkLabel    *label,
		    const gchar *str)
{
  GdkWChar *str_wc;
  NSGtkButton *text;
  GtkWidget *parent;
  gint len;
  gint wc_len; 
  NSString *label_text;
  
    g_return_if_fail (GTK_IS_LABEL (label));
  if (!str)
    str = "";

 if (!label->label || strcmp (label->label, str))
    {
      /* Convert text to wide characters */
      len = strlen (str);
      str_wc = g_new (GdkWChar, len + 1);
      wc_len = gdk_mbstowcs (str_wc, str, len + 1);
      if (wc_len >= 0)
    {
      str_wc[wc_len] = '\0';
      gtk_label_set_text_internal (label, g_strdup (str), str_wc);
    }
      else
    g_free (str_wc);
    }

  label_text = [NSString stringWithCString:str];
  text = GTK_WIDGET(label)->proxy;
  parent = GTK_WIDGET(label)->parent;
  
  if( parent && GTK_IS_BUTTON(parent))
        [parent->proxy setTitle:label_text];
  //printf("label req %f %f \n", [text frame].size.width, [text frame].size.height);
  [text setTitle:label_text];
  [text display];
  //[text sizeToFit];
  //printf("label req %f %f \n", [text frame].size.width, [text frame].size.height);
  gtk_widget_queue_resize (GTK_WIDGET (label));
 //  gdk_idle_hook();
}

guint      
gtk_label_parse_uline (GtkLabel    *label,
		       const gchar *string)
{
  guint accel_key = GDK_VoidSymbol;
   
  gtk_label_set_text(label, string);

  return accel_key;
}

void
gtk_label_size_request (GtkWidget      *widget,
			GtkRequisition *requisition)
{
  GtkLabel *label;
  NSButton *text;
  
  g_return_if_fail (GTK_IS_LABEL (widget));
  g_return_if_fail (requisition != NULL);
  
  label = GTK_LABEL (widget);

  text = widget->proxy;
  requisition->width = [[text font] widthOfString:[text title]] +10;
  requisition->height = 16; //[text frame].size.height;// [[text font] xHeight];
  //printf("label %s requisition %d %d \n", [[text title] cString],requisition->width, requisition->height);
}

void
gtk_label_set_justify (GtkLabel        *label,
		       GtkJustification jtype)
{
  g_return_if_fail (GTK_IS_LABEL (label));
  g_return_if_fail (jtype >= GTK_JUSTIFY_LEFT && jtype <= GTK_JUSTIFY_FILL);
  
  if ((GtkJustification) label->jtype != jtype)
    {
      gtk_label_free_words (label);
      
      label->jtype = jtype;

      gtk_widget_queue_resize (GTK_WIDGET (label));
    }

	switch(jtype)
	{
		case GTK_JUSTIFY_LEFT:
			[GTK_WIDGET(label)->proxy setAlignment:NSLeftTextAlignment];
			break;
		case GTK_JUSTIFY_RIGHT:
			[GTK_WIDGET(label)->proxy setAlignment:NSRightTextAlignment];
			break;
		case GTK_JUSTIFY_CENTER:
			[GTK_WIDGET(label)->proxy setAlignment:NSCenterTextAlignment];
			break;
		case GTK_JUSTIFY_FILL:
			[GTK_WIDGET(label)->proxy setAlignment:NSJustifiedTextAlignment];
			break;
	}
}


