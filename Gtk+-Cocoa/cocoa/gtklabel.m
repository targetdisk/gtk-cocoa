//
//  gtklabel.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Sep 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

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
  text->proxy = label;
  [text  setBordered:NO];
  [[text cell] setHighlightsBy:NSNoCellMask];
  gtk_label_set_text (label, "");
}

void
gtk_label_set_text (GtkLabel    *label,
		    const gchar *str)
{
  NSButton *text;
  g_return_if_fail (GTK_IS_LABEL (label));
  if (!str)
    str = "";

  g_free (label->label);
  label->label = g_strdup(str);

  text = GTK_WIDGET(label)->proxy;

  //printf("label req %f %f \n", [text frame].size.width, [text frame].size.height);
  [text setTitle:[NSString stringWithCString:str]];
  [text display];
  //[text sizeToFit];
  //printf("label req %f %f \n", [text frame].size.width, [text frame].size.height);
  gtk_widget_queue_resize (GTK_WIDGET (label));
  gdk_idle_hook();
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


