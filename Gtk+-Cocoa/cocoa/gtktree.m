//
//  gtktree.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Sep 28 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSColorView.h"

#include <gtk/gtk.h>

void
gtk_tree_init (GtkTree *tree)
{
  NSColorView *view;

  tree->children = NULL;
  tree->root_tree = tree;
  tree->selection = NULL;
  tree->tree_owner = NULL;
  tree->selection_mode = GTK_SELECTION_SINGLE;
  tree->indent_value = 9;
  tree->current_indent = 0;
  tree->level = 0;
  tree->view_mode = GTK_TREE_VIEW_LINE;
  tree->view_line = 1;
  view = [NSColorView alloc];
  view->bgColor =  [NSColor whiteColor];
  [view  initWithFrame:NSMakeRect(0,0,100,100)]; 
  GTK_WIDGET(tree)->proxy = view;
  GTK_WIDGET(tree)->window = view;
}

void
gtk_tree_insert (GtkTree   *tree,
		 GtkWidget *tree_item,
		 gint       position)
{
  gint nchildren;
  
  g_return_if_fail (tree != NULL);
  g_return_if_fail (GTK_IS_TREE (tree));
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));
  
  nchildren = g_list_length (tree->children);
  
  if ((position < 0) || (position > nchildren))
    position = nchildren;
  
  if (position == nchildren)
    tree->children = g_list_append (tree->children, tree_item);
  else
    tree->children = g_list_insert (tree->children, tree_item, position);
  
  gtk_widget_set_parent (tree_item, GTK_WIDGET (tree));
  
#if 0
  if (GTK_WIDGET_REALIZED (tree_item->parent))
    gtk_widget_realize (tree_item);

  if (GTK_WIDGET_VISIBLE (tree_item->parent) && GTK_WIDGET_VISIBLE (tree_item))
    {
      if (GTK_WIDGET_MAPPED (tree_item->parent))
	gtk_widget_map (tree_item);

      gtk_widget_queue_resize (tree_item);
    }
#endif
}

void
gtk_tree_size_allocate (GtkWidget     *widget,
			GtkAllocation *allocation)
{
  GtkTree *tree;
  GtkWidget *child, *subtree;
  GtkAllocation child_allocation;
  GList *children;
  
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE (widget));
  g_return_if_fail (allocation != NULL);
  
  tree = GTK_TREE (widget);
  
  widget->allocation = *allocation;
#if 0
  if (GTK_WIDGET_REALIZED (widget))
    gdk_window_move_resize (widget->window,
			    allocation->x, allocation->y,
			    allocation->width, allocation->height);
#endif
  
  if (tree->children)
    {
      child_allocation.x = GTK_CONTAINER (tree)->border_width;
      child_allocation.y = allocation->y + GTK_CONTAINER (tree)->border_width;
      child_allocation.width = MAX (1, (gint)allocation->width - child_allocation.x * 2);
      
      children = tree->children;
      
      while (children)
	{
	  child = children->data;
	  children = children->next;
	  
	  if (GTK_WIDGET_VISIBLE (child))
	    {
	      GtkRequisition child_requisition;
	      gtk_widget_get_child_requisition (child, &child_requisition);
	      
	      child_allocation.height = child_requisition.height;
	      
	      gtk_widget_size_allocate (child, &child_allocation);
	      
	      child_allocation.y += child_allocation.height;
	      
	      if((subtree = GTK_TREE_ITEM(child)->subtree))
		if(GTK_WIDGET_VISIBLE (subtree))
		  {
		    child_allocation.height = subtree->requisition.height;
		    gtk_widget_size_allocate (subtree, &child_allocation);
		    child_allocation.y += child_allocation.height;
		  }
	    }
	}
    }
  
}


