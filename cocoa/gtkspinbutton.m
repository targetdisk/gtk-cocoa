//
//  gtkspinbutton.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkSpinButton.h"

#include <gtk/gtk.h>

#define MAX_TEXT_LENGTH                    256

void
gtk_spin_button_init (GtkSpinButton *spin_button)
{
  NSGtkSpinButton *sb;

  spin_button->adjustment = NULL;
  spin_button->panel = NULL;
  spin_button->shadow_type = GTK_SHADOW_NONE;
  spin_button->timer = 0;
  spin_button->ev_time = 0;
  spin_button->climb_rate = 0.0;
  spin_button->timer_step = 0.0;
  spin_button->update_policy = GTK_UPDATE_ALWAYS;
  spin_button->in_child = 2;
  spin_button->click_child = 2;
  spin_button->button = 0;
  spin_button->need_timer = FALSE;
  spin_button->timer_calls = 0;
  spin_button->digits = 0;
  spin_button->numeric = FALSE;
  spin_button->wrap = FALSE;
  spin_button->snap_to_ticks = FALSE;

  sb = [[NSGtkSpinButton alloc] initWithFrame:NSMakeRect(0,0,100,25) entry:(NSGtkEntry *)GTK_WIDGET(spin_button)->proxy];
  [GTK_WIDGET(spin_button)->proxy release];
  GTK_WIDGET(spin_button)->proxy = sb;
  GTK_WIDGET(spin_button)->window = sb;
  sb->proxy = spin_button;	
//  sb->stepper->proxy = spin_button;	
  gtk_spin_button_set_adjustment (spin_button,
				  (GtkAdjustment*) gtk_adjustment_new (0, 0, 0, 0, 0, 0));
	sb->entry->sb = spin_button;
}

void
gtk_spin_button_size_allocate (GtkWidget     *widget,
			       GtkAllocation *allocation)
{
  GtkAllocation child_allocation;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_SPIN_BUTTON (widget));
  g_return_if_fail (allocation != NULL);

  widget->allocation = *allocation;
#if 0
  child_allocation = *allocation;
  if (child_allocation.width > ARROW_SIZE + 2 * widget->style->klass->xthickness)
    child_allocation.width -= ARROW_SIZE + 2 * widget->style->klass->xthickness;

  GTK_WIDGET_CLASS (parent_class)->size_allocate (widget, &child_allocation);


  if (GTK_WIDGET_REALIZED (widget))
    {
      child_allocation.width = ARROW_SIZE + 2 * widget->style->klass->xthickness;
      child_allocation.height = widget->requisition.height;  
      child_allocation.x = (allocation->x + allocation->width - ARROW_SIZE - 
			    2 * widget->style->klass->xthickness);
      child_allocation.y = allocation->y + (allocation->height - widget->requisition.height) / 2;

      gdk_window_move_resize (GTK_SPIN_BUTTON (widget)->panel, 
			      child_allocation.x,
			      child_allocation.y,
			      child_allocation.width,
			      child_allocation.height); 
    }
#endif
}

void
gtk_spin_button_size_request (GtkWidget      *widget,
			      GtkRequisition *requisition)
{
  g_return_if_fail (widget != NULL);
  g_return_if_fail (requisition != NULL);
  g_return_if_fail (GTK_IS_SPIN_BUTTON (widget));

//  GTK_WIDGET_CLASS (parent_class)->size_request (widget, requisition);
  
  requisition->width = 100 ;
  requisition->height = 25 ;
    //+ 2 * widget->style->klass->xthickness;
}

void
gtk_spin_button_value_changed (GtkAdjustment *adjustment,
			       GtkSpinButton *spin_button)
{
  NSGtkSpinButton *sb;
  char buf[MAX_TEXT_LENGTH];
  int i;

  g_return_if_fail (adjustment != NULL);
  g_return_if_fail (GTK_IS_ADJUSTMENT (adjustment));

  sprintf (buf, "%0.*f", spin_button->digits, adjustment->value);
//  gtk_entry_set_text (GTK_ENTRY (spin_button), buf);
  sb = GTK_WIDGET(spin_button)->proxy;
  for(i=0;i<spin_button->digits;i++)
	buf[i]='0';
  buf[i]='\0';

  //[sb->formatter setFormat:[NSString stringWithCString:@"#####"]]; 
  [sb->entry setIntValue:adjustment->value];
  [sb->stepper setIntValue:adjustment->value];
}

/* Callback used when the spin button's adjustment changes.  We need to redraw
 * the arrows when the adjustment's range changes.
 */
void
spinbutton_adjustment_changed_cb (GtkAdjustment *adjustment, gpointer data)
{
  GtkSpinButton *spin_button;
  NSGtkSpinButton *sb;

  spin_button = GTK_SPIN_BUTTON (data);

  sb = GTK_WIDGET(spin_button)->proxy;
  [sb->stepper setMinValue:adjustment->lower];
  [sb->stepper setMaxValue:adjustment->upper];
  //gtk_spin_button_draw_arrow (spin_button, GTK_ARROW_UP);
 // gtk_spin_button_draw_arrow (spin_button, GTK_ARROW_DOWN);
}

void
gtk_spin_button_set_adjustment (GtkSpinButton *spin_button,
				GtkAdjustment *adjustment)
{
  NSGtkSpinButton *sb;

  g_return_if_fail (spin_button != NULL);
  g_return_if_fail (GTK_IS_SPIN_BUTTON (spin_button));

  if (spin_button->adjustment != adjustment)
    {
      if (spin_button->adjustment)
        {
          gtk_signal_disconnect_by_data (GTK_OBJECT (spin_button->adjustment),
                                         (gpointer) spin_button);
          gtk_object_unref (GTK_OBJECT (spin_button->adjustment));
        }
      spin_button->adjustment = adjustment;
      if (adjustment)
        {
          gtk_object_ref (GTK_OBJECT (adjustment));
	  gtk_object_sink (GTK_OBJECT (adjustment));
          gtk_signal_connect (GTK_OBJECT (adjustment), "value_changed",
			      (GtkSignalFunc) gtk_spin_button_value_changed,
			      (gpointer) spin_button);
	  gtk_signal_connect (GTK_OBJECT (adjustment), "changed",
			      (GtkSignalFunc) spinbutton_adjustment_changed_cb,
			      (gpointer) spin_button);
        }
    }
  sb = GTK_WIDGET(spin_button)->proxy;
  [sb->stepper setMinValue:adjustment->lower];
  [sb->stepper setMaxValue:adjustment->upper];
}


