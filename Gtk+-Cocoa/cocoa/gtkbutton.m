//
//  gtkbutton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

#include <gtk/gtk.h>
 
#define CHILD_SPACING     1
 
void
gtk_button_init (GtkButton *button)
{
  NSGtkButton *but;
  GTK_WIDGET_SET_FLAGS (button, GTK_CAN_FOCUS | GTK_RECEIVES_DEFAULT);
  GTK_WIDGET_UNSET_FLAGS (button, GTK_NO_WINDOW);

  button->child = NULL;
  button->in_button = FALSE;
  button->button_down = FALSE;
  button->relief = GTK_RELIEF_NORMAL;
  but = [[NSGtkButton alloc] initWithFrame:NSMakeRect(0,0,100,20)];
  [but setButtonType:NSMomentaryPushButton];
  [but setBezelStyle:NSRoundedBezelStyle];
  [but setAction: @selector (clicked:)];
  [but setTarget: but];
  but->proxy = button;
  but->width = but->height = 48;
  but->customImage = FALSE;
  [GTK_WIDGET(button)->proxy release];
  GTK_WIDGET(button)->proxy = but;
  GTK_WIDGET(button)->window = but;
}


GtkWidget*
gtk_button_new_with_label (const gchar *label)
{
  NSGtkButton *but;
  GtkWidget *button;
  GtkWidget *label_widget;
  
  button = gtk_button_new ();
  label_widget = gtk_label_new (label);
  gtk_misc_set_alignment (GTK_MISC (label_widget), 0.5, 0.5);

  gtk_container_add (GTK_CONTAINER (button), label_widget);

  but = button->proxy; 
  
  but->width = [but frame].size.width;
  //but->height = [but frame].size.height;
  but->height = 24;
  return button;
}

void
gtk_button_set_label_text (GtkButton *button, const gchar *label)
{
  NSButton *but;
  NSString *l;
   
  but = GTK_WIDGET(button)->proxy; 
  if(label)
  {
  	l = [NSString stringWithCString: label];
  	[but setTitle:l];
  }
  
  return button;
}

gchar *
gtk_button_get_label_text (GtkButton *button)
{
  NSButton *but;
  GtkWidget *button;
  NSString *l;
  
  but = GTK_WIDGET(button)->proxy;
  l = [but title];
  
  return strdup([l cString]);
}

void
gtk_button_set_relief(GtkButton *button,
                      GtkReliefStyle newstyle)
{
    NSButton *but;
        
    g_return_if_fail (button != NULL);
    g_return_if_fail (GTK_IS_BUTTON (button));
    but = (NSButton *)GTK_WIDGET(button)->proxy;
    
    button->relief = newstyle;
    
    switch(newstyle)
    {
	case GTK_RELIEF_NORMAL:
		//[but setBezelStyle:NSRoundedBezelStyle];
		[but setBezelStyle:NSRegularSquareBezelStyle];
		[but setBordered:YES];
		break;
	case GTK_RELIEF_HALF:
		[but setBezelStyle:NSRegularSquareBezelStyle];
		[but setBordered:YES];
		break;
	case GTK_RELIEF_NONE:
		[but setBordered:NO];
		break;
    }

}

void
gtk_button_size_request (GtkWidget      *widget,
			 GtkRequisition *requisition)
{
  NSGtkButton *but;
  GtkButton *button = GTK_BUTTON (widget);
  gint default_spacing;

  but = widget->proxy;
  requisition->width =  but->width; 
  requisition->height = but->height;
}

void
gtk_button_size_allocate (GtkWidget     *widget,
			  GtkAllocation *allocation)
{
  GtkButton *button = GTK_BUTTON (widget);
  GtkAllocation child_allocation;
  widget->allocation = *allocation;
 
//  [widget->proxy setFrame:NSMakeRect(allocation->x,allocation->y,allocation->width, allocation->height)];
 // [widget->proxy display];
}

void
ns_gtk_button_add (GtkContainer *container,
		GtkWidget    *widget)
{    
   NSGtkButton *but = GTK_WIDGET(container)->proxy;
   // Cocoa does not support arbitrary controls
  // inside a button. We only support images and labels
  if(GTK_IS_PIXMAP(widget))
  {
    NSImageView *iv = widget->proxy;
    NSButton *oldBut = GTK_WIDGET(container)->proxy;
    NSRect frame;
    
    but = [[NSGtkButton alloc] initWithFrame:NSMakeRect(0,0,100,100)];
    [[but cell] setType:NSImageCellType];
    [but setImage:[iv image]];
    [[but cell] setImagePosition:NSImageOnly];
    [but sizeToFit];
    frame = [but frame];
    frame.size.width += CHILD_SPACING+6;
    frame.size.height += CHILD_SPACING+6;
    [but setFrame:frame];
    [but setAction: @selector (clicked:)];
    [but setTarget: but];
    [but setBezelStyle:[oldBut bezelStyle]];
    [but setBordered:[oldBut isBordered]];
    but->width = [but frame].size.width;
    but->height = [but frame].size.height;
    but->proxy = container;
    but->customImage = TRUE;
    if(![but isBordered])
    {
        [but setBordered:YES];
        [but setShowsBorderOnlyWhileMouseInside:TRUE];
    }
    if(GTK_IS_TOGGLE_BUTTON (but->proxy))
    {
        [but setButtonType:NSPushOnPushOffButton];
    }
    [oldBut release]; 
    GTK_WIDGET(container)->proxy = but;
    GTK_WIDGET(container)->window = but;
    widget->superview = NULL;
  }
  if(GTK_IS_LABEL(widget))
  {
    NSButton *label = widget->proxy; 
    [but setTitle:[label title]];
    [but sizeToFit];
    but->width = [but frame].size.width+CHILD_SPACING+6;
    but->height = [but frame].size.height+CHILD_SPACING+6;
    widget->superview = NULL;
  }
  if(GTK_IS_ARROW(widget))
  {
    switch(GTK_ARROW(widget)->arrow_type)
    {
      case GTK_ARROW_RIGHT:
           [but setTitle:[NSString stringWithFormat:@"%C",0x25B6]];
           break;
       case GTK_ARROW_LEFT:
           [but setTitle:[NSString stringWithFormat:@"%C",0x25C0]];
          break;
       case GTK_ARROW_UP:
          [but setTitle:[NSString stringWithFormat:@"%C",0x25B2]];
           break;
       case GTK_ARROW_DOWN:
          [but setTitle:[NSString stringWithFormat:@"%C",0x25BC]];
           break;
    }
  }
}

