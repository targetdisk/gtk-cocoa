//
//  gtkmenuitem.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 13 2002.
//
#import <AppKit/AppKit.h>
#import "NSGtkButton.h"

#define BORDER_SPACING  3
#define SELECT_TIMEOUT  75

#include <gtk/gtk.h>
#import "NSGtkMenuItem.h"

void gtk_menu_item_detacher (GtkWidget     *widget, GtkMenu       *menu);
void gtk_menu_item_accel_width_foreach (GtkWidget *widget, gpointer data);

GtkWidget*
gtk_menu_item_new_with_label (const gchar *label)
{
  NSGtkMenuItem *l;
  GtkWidget *menu_item;
  GtkWidget *accel_label;

  menu_item = GTK_WIDGET (gtk_type_new (gtk_menu_item_get_type ()));
  accel_label = gtk_accel_label_new (label);
  gtk_misc_set_alignment (GTK_MISC (accel_label), 0.0, 0.5);

  gtk_container_add (GTK_CONTAINER (menu_item), accel_label);
  gtk_accel_label_set_accel_widget (GTK_ACCEL_LABEL (accel_label), menu_item);
  gtk_widget_show (accel_label);

  l = [[NSGtkMenuItem alloc] initWithTitle:[NSString stringWithCString:label] action:@selector(activated:)  keyEquivalent:@""];
  [l setTarget:l];
  [GTK_WIDGET(menu_item)->proxy release];
  GTK_WIDGET(menu_item)->proxy = l;
  GTK_WIDGET(menu_item)->window = l;
  l->proxy = menu_item;

  return menu_item;
}
 
void
gtk_menu_item_set_submenu (GtkMenuItem *menu_item,
			   GtkWidget   *submenu)
{
  NSPopUpButton *s;
  NSButton *m;
  NSRect frame;
 g_return_if_fail (submenu != NULL);
  g_return_if_fail (menu_item != NULL);
  g_return_if_fail (GTK_IS_MENU_ITEM (menu_item));
  
  if (menu_item->submenu != submenu)
    {
      gtk_menu_item_remove_submenu (menu_item);
      
      menu_item->submenu = submenu;
      gtk_menu_attach_to_widget (GTK_MENU (submenu),
				 GTK_WIDGET (menu_item),
				 gtk_menu_item_detacher);
      
      if (GTK_WIDGET (menu_item)->parent)
	gtk_widget_queue_resize (GTK_WIDGET (menu_item));
    }
	m = GTK_WIDGET(menu_item)->proxy;
	s = submenu->proxy;
    if([m respondsToSelector:@selector(frame)])
    {
  //      frame = [submenu->proxy frame];
  //      frame.size.width +=50; // get rid of arrow
  //      [s setFrame:frame];
  //      [m addSubview:submenu->proxy];
        [s setTitle:[m title]];
        [m setMenu:[s menu]];
        [m sizeToFit]; 
    }
    else
     [m setSubmenu:[s menu]];
}

void
gtk_menu_item_size_request (GtkWidget      *widget,
			    GtkRequisition *requisition)
{
  GtkMenuItem *menu_item;
  GtkBin *bin;
  guint accel_width;
  NSPopUpButton *mi;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_MENU_ITEM (widget));
  g_return_if_fail (requisition != NULL);
  
  mi = widget->proxy;
  if([mi respondsToSelector:@selector(frame)])
  {
        [mi sizeToFit];
        requisition->width = [mi frame].size.width-24;
        requisition->height = [mi frame].size.height;
        return;
  }
  bin = GTK_BIN (widget);
  menu_item = GTK_MENU_ITEM (widget);

  requisition->width = (GTK_CONTAINER (widget)->border_width +
//			widget->style->klass->xthickness +
			BORDER_SPACING) * 2;
  requisition->height = (GTK_CONTAINER (widget)->border_width 
//			+ widget->style->klass->ythickness
			) * 2;

  if (bin->child && GTK_WIDGET_VISIBLE (bin->child))
    {
      GtkRequisition child_requisition;
      
      gtk_widget_size_request (bin->child, &child_requisition);

      requisition->width += child_requisition.width;
      requisition->height += child_requisition.height;
    }

  if (menu_item->submenu && menu_item->show_submenu_indicator)
    requisition->width += 21;

  accel_width = 0;
  gtk_container_foreach (GTK_CONTAINER (menu_item),
			 gtk_menu_item_accel_width_foreach,
			 &accel_width);
  menu_item->accelerator_width = accel_width;
}


