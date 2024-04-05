//
//  gtknotebook.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Oct 06 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkTabView.h"
#import "NSGtkTabViewItem.h"

#include <gtk/gtk.h>

gint gtk_notebook_page_compare        (gconstpointer     a, gconstpointer     b);
void
gtk_notebook_init (GtkNotebook *notebook)
{
  NSGtkTabView *tab;

  GTK_WIDGET_SET_FLAGS (notebook, GTK_CAN_FOCUS);
  GTK_WIDGET_UNSET_FLAGS (notebook, GTK_NO_WINDOW);

  notebook->cur_page = NULL;
  notebook->children = NULL;
  notebook->first_tab = NULL;
  notebook->focus_tab = NULL;
  notebook->panel = NULL;
  notebook->menu = NULL;

  notebook->tab_hborder = 2;
  notebook->tab_vborder = 2;

  notebook->show_tabs = TRUE;
  notebook->show_border = TRUE;
  notebook->tab_pos = GTK_POS_TOP;
  notebook->scrollable = FALSE;
  notebook->in_child = 0;
  notebook->click_child = 0;
  notebook->button = 0;
  notebook->need_timer = 0;
  notebook->child_has_focus = FALSE;
  notebook->have_visible_child = FALSE;
  tab = [[NSGtkTabView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
  [tab setAutoresizesSubviews:FALSE];
  [tab setDelegate:tab];
  [tab setAllowsTruncatedLabels:YES];
  [tab setFont:[NSFont labelFontOfSize:10]];
  [tab setControlSize:NSSmallControlSize];
//  [tab setTabViewType:NSNoTabsLineBorder];
  [GTK_WIDGET(notebook)->proxy release];
  GTK_WIDGET(notebook)->proxy = tab;
  GTK_WIDGET(notebook)->window = tab;
  tab->proxy = notebook;
  tab->current = 0;
  [tab computeMaxTabs:FALSE];
}

void
gtk_notebook_insert_page_menu (GtkNotebook *notebook,
			       GtkWidget   *child,
			       GtkWidget   *tab_label,
			       GtkWidget   *menu_label,
			       gint         position)
{
  GtkNotebookPage *page;
  NSGtkTabViewItem *item;
  gint nchildren;
  gchar *label_text;

  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));
  g_return_if_fail (child != NULL);

  page = g_new (GtkNotebookPage, 1);
  page->child = child;
  page->requisition.width = 0;
  page->requisition.height = 0;
  page->allocation.x = 0;
  page->allocation.y = 0;
  page->allocation.width = 0;
  page->allocation.height = 0;
  page->default_menu = FALSE;
  page->default_tab = FALSE;
   
  nchildren = g_list_length (notebook->children);
  if ((position < 0) || (position > nchildren))
    position = nchildren;

  notebook->children = g_list_insert (notebook->children, page, position);

  if (!tab_label)
    {
      page->default_tab = TRUE;
      if (notebook->show_tabs)
	tab_label = gtk_label_new ("");
    }
  page->tab_label = tab_label;
  page->menu_label = menu_label;
  page->expand = FALSE;
  page->fill = TRUE;
  page->pack = GTK_PACK_START;

  if (!menu_label)
    page->default_menu = TRUE;
  else  
    {
      gtk_widget_ref (page->menu_label);
      gtk_object_sink (GTK_OBJECT(page->menu_label));
    }

 item = [[NSGtkTabViewItem alloc] initWithIdentifier:nil];
  
 if(tab_label)
 {
 	gtk_label_get(page->tab_label,&label_text);
   	[item setLabel:[NSString stringWithCString:label_text]];
 }
 [item setView:child->proxy];

 [GTK_WIDGET(notebook)->proxy insertTabViewItem:item atIndex:position];

  child->parent = notebook;
/*
  if (notebook->menu)
    gtk_notebook_menu_item_create (notebook,
				   g_list_find (notebook->children, page));

  gtk_notebook_update_labels (notebook);

  if (!notebook->first_tab)
    notebook->first_tab = notebook->children;
  gtk_widget_set_parent (child, GTK_WIDGET (notebook));
  if (tab_label)
    gtk_widget_set_parent (tab_label, GTK_WIDGET (notebook));
*/

  if (!notebook->cur_page)
    {
      gtk_notebook_switch_page (notebook, page, 0);
 //     gtk_notebook_switch_focus_tab (notebook, NULL);
    }

  if (GTK_WIDGET_REALIZED (child->parent))
    gtk_widget_realize (child);

  if (GTK_WIDGET_VISIBLE (notebook))
    {
      if (GTK_WIDGET_VISIBLE (child))
	{
	  if (GTK_WIDGET_MAPPED (notebook) &&
	      !GTK_WIDGET_MAPPED (child) &&
	      notebook->cur_page == page)
	    gtk_widget_map (child);
	  
	  gtk_widget_queue_resize (child);
	}

      if (tab_label)
	{
	  if (notebook->show_tabs && GTK_WIDGET_VISIBLE (child))
	    {
	      if (!GTK_WIDGET_VISIBLE (tab_label))
		gtk_widget_show (tab_label);
	      
	      if (GTK_WIDGET_REALIZED (notebook) &&
		  !GTK_WIDGET_REALIZED (tab_label))
		gtk_widget_realize (tab_label);
	      
	      if (GTK_WIDGET_MAPPED (notebook) &&
		  !GTK_WIDGET_MAPPED (tab_label))
		gtk_widget_map (tab_label);
	    }
	  else if (GTK_WIDGET_VISIBLE (tab_label))
	    gtk_widget_hide (tab_label);
	}
   }

}

void
gtk_notebook_size_allocate (GtkWidget     *widget,
			    GtkAllocation *allocation)
{
  NSGtkTabView *tab;
  GtkNotebook *notebook;
  GtkNotebookPage *page;
  GtkAllocation child_allocation;
  GList *children;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (widget));
  g_return_if_fail (allocation != NULL);

  notebook = GTK_NOTEBOOK (widget);
  if( notebook->show_tabs) 
  {
//  	allocation->width+=20;
 // 	allocation->height+=20;
  }
  widget->allocation = *allocation;
	// get rid of shadows
  tab = widget->proxy;
#if 0
  if (GTK_WIDGET_REALIZED (widget))
    gdk_window_move_resize (widget->window,
			    allocation->x, allocation->y,
			    allocation->width, allocation->height);
#endif
  if (notebook->children)
    {
      int tabw,tabh;

      // compute tab and border size
      //
      tabw = [tab frame].size.width - [tab contentRect].size.width;
      tabh = [tab frame].size.height - [tab contentRect].size.height;
	  switch (notebook->tab_pos)
	  {
		case GTK_POS_TOP:
      		child_allocation.x = GTK_CONTAINER (widget)->border_width + tabw/2;
      		child_allocation.y = 0;//GTK_CONTAINER (widget)->border_width; 
      		child_allocation.width = MAX (1, (gint)allocation->width - GTK_CONTAINER (widget)->border_width * 2-tabw);
            if(notebook->show_tabs)
                child_allocation.height = MAX (1, (gint)allocation->height - GTK_CONTAINER (widget)->border_width * 2-tabh/2-6);
            else
                child_allocation.height = MAX (1, (gint)allocation->height - GTK_CONTAINER (widget)->border_width * 2);
			break;
			
		case GTK_POS_LEFT:
      		child_allocation.x = GTK_CONTAINER (widget)->border_width + tabw;
      		child_allocation.y = GTK_CONTAINER (widget)->border_width ;//+ tabh/2; 
      		child_allocation.width = MAX (1, (gint)allocation->width - GTK_CONTAINER (widget)->border_width * 2- tabw);
      		if(notebook->show_tabs)
                child_allocation.height = MAX (1, (gint)allocation->height - GTK_CONTAINER (widget)->border_width * 2-tabh/2-6);
			else
                child_allocation.height = MAX (1, (gint)allocation->height - GTK_CONTAINER (widget)->border_width * 2);
			break;
	  }
printf("notebook child allocation %d %d %d %d\n",child_allocation.x, child_allocation.y, child_allocation.width, child_allocation.height);
#if 0

      if (notebook->show_tabs || notebook->show_border)
	{
	  //child_allocation.x += widget->style->klass->xthickness;
	  //child_allocation.y += widget->style->klass->ythickness;
	  child_allocation.width = MAX (1, (gint)child_allocation.width);// - (gint) widget->style->klass->xthickness * 2);
	  child_allocation.height = MAX (1, (gint)child_allocation.height); // - (gint) widget->style->klass->ythickness * 2);

	  if (notebook->show_tabs && notebook->children && notebook->cur_page)
	    {
	      switch (notebook->tab_pos)
		{
		case GTK_POS_TOP:
		  child_allocation.y += notebook->cur_page->requisition.height;
		case GTK_POS_BOTTOM:
		  child_allocation.height =
		    MAX (1, (gint)child_allocation.height -
			 (gint)notebook->cur_page->requisition.height);
		  break;
		case GTK_POS_LEFT:
		  child_allocation.x += notebook->cur_page->requisition.width;
		case GTK_POS_RIGHT:
		  child_allocation.width =
		    MAX (1, (gint)child_allocation.width -
			 (gint)notebook->cur_page->requisition.width);
		  break;
		}
	    }
	}
#endif

      children = notebook->children;
      while (children)
	{
	  page = children->data;
	  children = children->next;
	  
	  if (GTK_WIDGET_VISIBLE (page->child))
	    gtk_widget_size_allocate (page->child, &child_allocation);
	}

      //gtk_notebook_pages_allocate (notebook, allocation);
    }
    [tab setNeedsDisplay:TRUE];
//   gtk_notebook_set_shape (notebook);
}

#define ARROW_SIZE 16
#define ARROW_SPACING 2
#define FOCUS_WIDTH 10
#define TAB_CURVATURE 0
#define TAB_OVERLAP 0
#define STEP_NEXT 0

void
gtk_notebook_size_request (GtkWidget      *widget,
			   GtkRequisition *requisition)
{

  GtkNotebook *notebook;
  GtkNotebookPage *page;
  GList *children;
  GtkRequisition child_requisition;
  gboolean switch_page = FALSE;
  gint vis_pages;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (widget));
  g_return_if_fail (requisition != NULL);

  notebook = GTK_NOTEBOOK (widget);
  widget->requisition.width = 0;
  widget->requisition.height = 0;

  for (children = notebook->children, vis_pages = 0; children;
       children = children->next)
    {
      page = children->data;

      if (GTK_WIDGET_VISIBLE (page->child))
	{
	  vis_pages++;
	  gtk_widget_size_request (page->child, &child_requisition);
	  
	  widget->requisition.width = MAX (widget->requisition.width,
					   child_requisition.width);
	  widget->requisition.height = MAX (widget->requisition.height,
					    child_requisition.height);

	  if (GTK_WIDGET_MAPPED (page->child) && page != notebook->cur_page)
	    gtk_widget_unmap (page->child);
	  if (notebook->menu && page->menu_label->parent &&
	      !GTK_WIDGET_VISIBLE (page->menu_label->parent))
	    gtk_widget_show (page->menu_label->parent);
	}
      else
	{
	  if (page == notebook->cur_page)
	    switch_page = TRUE;
	  if (notebook->menu && page->menu_label->parent &&
	      GTK_WIDGET_VISIBLE (page->menu_label->parent))
	    gtk_widget_hide (page->menu_label->parent);
	}
    }

  if (notebook->show_border || notebook->show_tabs)
    {
      //widget->requisition.width += widget->style->klass->xthickness * 2;
      //widget->requisition.height += widget->style->klass->ythickness * 2;

      if (notebook->show_tabs)
	{
	  gint tab_width = 0;
	  gint tab_height = 0;
	  gint tab_max = 0;
	  gint padding;
	  
	  for (children = notebook->children; children;
	       children = children->next)
	    {
	      page = children->data;
	      
	      if (GTK_WIDGET_VISIBLE (page->child))
		{
		  if (!GTK_WIDGET_VISIBLE (page->tab_label))
		    gtk_widget_show (page->tab_label);

		  gtk_widget_size_request (page->tab_label,
					   &child_requisition);

		  page->requisition.width = 
		    child_requisition.width ; //+ 2 * widget->style->klass->xthickness;
		  page->requisition.height = 
		    child_requisition.height ; //+ 2 * widget->style->klass->ythickness;
		  
		  switch (notebook->tab_pos)
		    {
		    case GTK_POS_TOP:
		    case GTK_POS_BOTTOM:
		      page->requisition.height += 2 * (notebook->tab_vborder +
						       FOCUS_WIDTH);
		      tab_height = MAX (tab_height, page->requisition.height);
		      tab_max = MAX (tab_max, page->requisition.width);
		      break;
		    case GTK_POS_LEFT:
		    case GTK_POS_RIGHT:
		      page->requisition.width += 2 * (notebook->tab_hborder +
						      FOCUS_WIDTH);
		      tab_width = MAX (tab_width, page->requisition.width);
		      tab_max = MAX (tab_max, page->requisition.height);
		      break;
		    }
		}
	      else if (GTK_WIDGET_VISIBLE (page->tab_label))
		gtk_widget_hide (page->tab_label);
	    }

	  children = notebook->children;

	  if (vis_pages)
	    {
	      switch (notebook->tab_pos)
		{
		case GTK_POS_TOP:
		case GTK_POS_BOTTOM:
		  if (tab_height == 0)
		    break;

		  if (notebook->scrollable && vis_pages > 1 && 
		      widget->requisition.width < tab_width)
		    tab_height = MAX (tab_height, ARROW_SIZE);

		  padding = 2 * (TAB_CURVATURE + FOCUS_WIDTH +
				 notebook->tab_hborder) - TAB_OVERLAP;
		  tab_max += padding;
		  while (children)
		    {
		      page = children->data;
		      children = children->next;
		  
		      if (!GTK_WIDGET_VISIBLE (page->child))
			continue;

		      if (notebook->homogeneous)
			page->requisition.width = tab_max;
		      else
			page->requisition.width += padding;

		      tab_width += page->requisition.width;
		      page->requisition.height = tab_height;
		    }

		  if (notebook->scrollable && vis_pages > 1 &&
		      widget->requisition.width < tab_width)
		    tab_width = tab_max + 2 * (ARROW_SIZE + ARROW_SPACING);

                  if (notebook->homogeneous && !notebook->scrollable)
                    widget->requisition.width = MAX (widget->requisition.width,
                                                     vis_pages * tab_max +
                                                     TAB_OVERLAP);
                  else
                    widget->requisition.width = MAX (widget->requisition.width,
                                                     tab_width + TAB_OVERLAP);

		  widget->requisition.height += tab_height;
		  break;
		case GTK_POS_LEFT:
		case GTK_POS_RIGHT:
		  if (tab_width == 0)
		    break;

		  if (notebook->scrollable && vis_pages > 1 && 
		      widget->requisition.height < tab_height)
		    tab_width = MAX (tab_width, ARROW_SPACING +2 * ARROW_SIZE);

		  padding = 2 * (TAB_CURVATURE + FOCUS_WIDTH +
				 notebook->tab_vborder) - TAB_OVERLAP;
		  tab_max += padding;

		  while (children)
		    {
		      page = children->data;
		      children = children->next;

		      if (!GTK_WIDGET_VISIBLE (page->child))
			continue;

		      page->requisition.width   = tab_width;

		      if (notebook->homogeneous)
			page->requisition.height = tab_max;
		      else
			page->requisition.height += padding;

		      tab_height += page->requisition.height;
		    }

		  if (notebook->scrollable && vis_pages > 1 && 
		      widget->requisition.height < tab_height)
		    tab_height = tab_max + ARROW_SIZE + ARROW_SPACING;

		  widget->requisition.width += tab_width;

                  if (notebook->homogeneous && !notebook->scrollable)
                    widget->requisition.height =
		      MAX (widget->requisition.height,
			   vis_pages * tab_max + TAB_OVERLAP);
                  else
                    widget->requisition.height =
		      MAX (widget->requisition.height,
			   tab_height + TAB_OVERLAP);

		  if (!notebook->homogeneous || notebook->scrollable)
		    vis_pages = 1;
		  widget->requisition.height = MAX (widget->requisition.height,
						    vis_pages * tab_max +
						    TAB_OVERLAP);
		  break;
		}
	    }
	}
      else
	{
	  for (children = notebook->children; children;
	       children = children->next)
	    {
	      page = children->data;
	      
	      if (page->tab_label && GTK_WIDGET_VISIBLE (page->tab_label))
		gtk_widget_hide (page->tab_label);
	    }
	}
    }

  widget->requisition.width += GTK_CONTAINER (widget)->border_width * 2;
  widget->requisition.height += GTK_CONTAINER (widget)->border_width * 2;

  if (switch_page)
    {
      if (vis_pages)
	{
	  for (children = notebook->children; children;
	       children = children->next)
	    {
	      page = children->data;
	      if (GTK_WIDGET_VISIBLE (page->child))
		{
		  gtk_notebook_switch_page (notebook, page, -1);
		  break;
		}
	    }
	}
      else if (GTK_WIDGET_VISIBLE (widget))
	{
	  widget->requisition.width = GTK_CONTAINER (widget)->border_width * 2;
	  widget->requisition.height= GTK_CONTAINER (widget)->border_width * 2;
	}
    }
  if (vis_pages && !notebook->cur_page)
    {
      children = gtk_notebook_search_page (notebook, NULL, STEP_NEXT, TRUE);
      if (children)
	{
	  notebook->first_tab = children;
	  gtk_notebook_switch_page (notebook, GTK_NOTEBOOK_PAGE (children),-1);
	}
    }
}

/* Private GtkNotebook Page Switch Methods:
 *
 * gtk_notebook_real_switch_page
 */
void
gtk_notebook_real_switch_page (GtkNotebook     *notebook,
			       GtkNotebookPage *page,
			       guint            page_num)
{
  NSGtkTabView *nb =GTK_WIDGET(notebook)->proxy;
  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));
  g_return_if_fail (page != NULL);
  
  if (notebook->cur_page == page || !GTK_WIDGET_VISIBLE (page->child))
    return; 
    
  nb =GTK_WIDGET(notebook)->proxy;
  notebook->cur_page = page;
  nb->proxy = NULL;
  [GTK_WIDGET(notebook)->proxy selectTabViewItemAtIndex:page_num];
  nb->proxy = notebook;
 
  if (notebook->cur_page && GTK_WIDGET_MAPPED (notebook->cur_page->child))
    gtk_widget_unmap (notebook->cur_page->child);
  

  if (!notebook->focus_tab ||
      notebook->focus_tab->data != (gpointer) notebook->cur_page)
    notebook->focus_tab = 
      g_list_find (notebook->children, notebook->cur_page);

  if (GTK_WIDGET_MAPPED (notebook))
    gtk_widget_map (notebook->cur_page->child);

  gtk_widget_queue_resize (GTK_WIDGET (notebook));
}

void
gtk_notebook_set_tab_pos (GtkNotebook     *notebook,
			  GtkPositionType  pos)
{
  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));

  if (notebook->tab_pos != pos)
    {
      notebook->tab_pos = pos;
//      if (GTK_WIDGET_VISIBLE (notebook))
//	gtk_widget_queue_resize (GTK_WIDGET (notebook));
    }
	
	switch(pos)
	{
		case GTK_POS_LEFT:
  			[GTK_WIDGET(notebook)->proxy setTabViewType:NSLeftTabsBezelBorder];
			break;
  		case GTK_POS_RIGHT:
  			[GTK_WIDGET(notebook)->proxy setTabViewType:NSRightTabsBezelBorder];
			break;
  		case GTK_POS_TOP:
  			[GTK_WIDGET(notebook)->proxy setTabViewType:NSTopTabsBezelBorder];
			break;
  		case GTK_POS_BOTTOM:
  			[GTK_WIDGET(notebook)->proxy setTabViewType:NSBottomTabsBezelBorder];
			break;
	}
	[GTK_WIDGET(notebook)->proxy computeMaxTabs:FALSE];
}

void
gtk_notebook_set_show_tabs (GtkNotebook *notebook,
			    gboolean     show_tabs)
{
  GtkNotebookPage *page;
  GList *children;

  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));

  show_tabs = show_tabs != FALSE;

  if (notebook->show_tabs == show_tabs)
    return;

  notebook->show_tabs = show_tabs;
  children = notebook->children;

  if(!show_tabs)
  	[GTK_WIDGET(notebook)->proxy setTabViewType:NSNoTabsNoBorder];
  else
	gtk_notebook_set_tab_pos (notebook, notebook->tab_pos);
	
#if 0
  if (!show_tabs)
    {
      GTK_WIDGET_UNSET_FLAGS (notebook, GTK_CAN_FOCUS);
      
      while (children)
	{
	  page = children->data;
	  children = children->next;
	  if (page->default_tab)
	    {
	      gtk_widget_destroy (page->tab_label);
	      page->tab_label = NULL;
	    }
	  else
	    gtk_widget_hide (page->tab_label);
	}
      
      if (notebook->panel)
	gdk_window_hide (notebook->panel);
    }
  else
    {
      GTK_WIDGET_SET_FLAGS (notebook, GTK_CAN_FOCUS);
      gtk_notebook_update_labels (notebook);
    }
  gtk_widget_queue_resize (GTK_WIDGET (notebook));
#endif
}

void
gtk_notebook_remove_page (GtkNotebook *notebook,
			  gint         page_num)
{
  GList *list;
  NSGtkTabView *tab;
  
  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));
  
  tab = GTK_WIDGET(notebook)->proxy;
  if (page_num >= 0)
    {
      list = g_list_nth (notebook->children, page_num);
      if (list)
	gtk_notebook_real_remove (notebook, list);
    }
  else
    {
      list = g_list_last (notebook->children);
      if (list)
	gtk_notebook_real_remove (notebook, list);
    }
	[tab removeTabViewItem:[tab tabViewItemAtIndex:page_num]];
	if(page_num<tab->current)
		tab->current--;
}

void
gtk_notebook_set_tab_label (GtkNotebook *notebook,
			    GtkWidget   *child,
			    GtkWidget   *tab_label)
{
  NSGtkTabViewItem *item;
  NSTabView *nb;
  GtkNotebookPage *page;
  GList *list;

  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));
  g_return_if_fail (child != NULL);
  
  if (!(list = g_list_find_custom (notebook->children, child,
				   gtk_notebook_page_compare)))
      return;

  /* a NULL pointer indicates a default_tab setting, otherwise
   * we need to set the associated label
   */
  nb = GTK_WIDGET(notebook)->proxy;
  item = [nb tabViewItemAtIndex:g_list_index(notebook->children,list->data)];
  page = list->data;
  if (page->tab_label)
    gtk_widget_unparent (page->tab_label);

  if (tab_label)
    {
	 char *label_text;

      page->default_tab = FALSE;
      page->tab_label = tab_label;
	  gtk_label_get(tab_label, &label_text);
//      gtk_widget_set_parent (page->tab_label, GTK_WIDGET (notebook));
    [item setLabel:[NSString stringWithCString:label_text]];
    }
  else
    {
      page->default_tab = TRUE;
      page->tab_label = NULL;

      if (notebook->show_tabs)
	{
	  gchar string[32];

	  g_snprintf (string, sizeof(string), "Page %u", 
		      gtk_notebook_real_page_position (notebook, list));
	  page->tab_label = gtk_label_new (string);
//	  gtk_widget_set_parent (page->tab_label, GTK_WIDGET (notebook));
	}
    }

  if (notebook->show_tabs && GTK_WIDGET_VISIBLE (child))
    {
      gtk_widget_show (page->tab_label);
      gtk_widget_queue_resize (GTK_WIDGET (notebook));
    }
}

void
gtk_notebook_set_tab_label_text (GtkNotebook *notebook,
				 GtkWidget   *child,
				 const gchar *tab_text)
{
  GtkWidget *tab_label = NULL;

  if (tab_text)
    tab_label = gtk_label_new (tab_text);
  gtk_notebook_set_tab_label (notebook, child, tab_label);
}

void
gtk_notebook_reorder_child (GtkNotebook *notebook,
			    GtkWidget   *child,
			    gint         position)
{
  NSGtkTabViewItem *item;
  NSGtkTabView *nb;
  GList *list;
  GList *work;
  GtkNotebookPage *page = NULL;
  gint old_pos;
  gboolean select = FALSE;

  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));
  g_return_if_fail (child != NULL);
  g_return_if_fail (GTK_IS_WIDGET (child));

  for (old_pos = 0, list = notebook->children; list;
       list = list->next, old_pos++)
    {
      page = list->data;
      if (page->child == child)
	break;
    }

  if (!list || old_pos == position)
    return;

  notebook->children = g_list_remove_link (notebook->children, list);
  
  if (position <= 0 || !notebook->children)
    {
      list->next = notebook->children;
      if (list->next)
	list->next->prev = list;
      notebook->children = list;
    }
  else if (position > 0 && (work = g_list_nth (notebook->children, position)))
    {
      list->prev = work->prev;
      if (list->prev)
	list->prev->next = list;
      list->next = work;
      work->prev = list;
    }
  else
    {
      work = g_list_last (notebook->children);
      work->next = list;
      list->prev = work;
    }

  if (notebook->menu)
    {
      GtkWidget *menu_item;

      g_assert(page != NULL);

      menu_item = page->menu_label->parent;
      gtk_container_remove (GTK_CONTAINER (menu_item), page->menu_label);
      gtk_container_remove (GTK_CONTAINER (notebook->menu), menu_item);
   //   gtk_notebook_menu_item_create (notebook, list);
  //    gtk_widget_queue_resize (notebook->menu);
    }

//  gtk_notebook_update_labels (notebook);

  if (notebook->show_tabs)
    {
      gtk_notebook_pages_allocate (notebook,
				   &(GTK_WIDGET (notebook)->allocation));
 //     gtk_notebook_expose_tabs (notebook);
    }
  nb = GTK_WIDGET(notebook)->proxy;
  item = [nb tabViewItemAtIndex:old_pos];
  if(item == [nb selectedTabViewItem])
		select = TRUE;
  // do not send switch page message
  nb->proxy = NULL;
  [nb removeTabViewItem:item];
  nb->proxy = notebook;
  [nb insertTabViewItem:item atIndex:position];
  if(select)
	[nb selectTabViewItem:item];
}


/* Public GtkNotebook/Tab Style Functions
 *
 * gtk_notebook_set_show_border
 * gtk_notebook_set_show_tabs
 * gtk_notebook_set_tab_pos
 * gtk_notebook_set_homogeneous_tabs
 * gtk_notebook_set_tab_border
 * gtk_notebook_set_tab_hborder
 * gtk_notebook_set_tab_vborder
 * gtk_notebook_set_scrollable
 */
void
gtk_notebook_set_show_border (GtkNotebook *notebook,
			      gboolean     show_border)
{
  NSGtkTabView *nb;
  g_return_if_fail (notebook != NULL);
  g_return_if_fail (GTK_IS_NOTEBOOK (notebook));

  if (notebook->show_border != show_border)
    {
      notebook->show_border = show_border;

  		nb = GTK_WIDGET(notebook)->proxy;
		if(!show_border)
			[nb setTabViewType:NSNoTabsNoBorder];
      if (GTK_WIDGET_VISIBLE (notebook))
	gtk_widget_queue_resize (GTK_WIDGET (notebook));
    }
}


