//
//  gtkctree.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSGtkTree.h"

#include <gtk/gtk.h>

#define GTK_CLIST_CLASS_FW(_widget_) GTK_CLIST_CLASS (((GtkObject*) (_widget_))->klass)
#define CLIST_UNFROZEN(clist)     (((GtkCList*) (clist))->freeze_count == 0)
#define CLIST_REFRESH(clist)    G_STMT_START { \
  if (CLIST_UNFROZEN (clist)) \
    GTK_CLIST_CLASS_FW (clist)->refresh ((GtkCList*) (clist)); \
} G_STMT_END

enum
{
  TREE_SELECT_ROW,
  TREE_UNSELECT_ROW,
  TREE_EXPAND,
  TREE_COLLAPSE,
  TREE_MOVE,
  CHANGE_FOCUS_ROW_EXPANSION,
  LAST_SIGNAL
};

extern  guint ctree_signals[LAST_SIGNAL];

void
gtk_ctree_init (GtkCTree *ctree)
{
  NSScrollView *sw;
  NSGtkTree *tree;
  NSTableHeaderView *thv;
  GtkCList *clist;

  GTK_CLIST_SET_FLAG (ctree, CLIST_DRAW_DRAG_RECT);
  GTK_CLIST_SET_FLAG (ctree, CLIST_DRAW_DRAG_LINE);

  clist = GTK_CLIST (ctree);

  ctree->tree_indent    = 20;
  ctree->tree_spacing   = 5;
  ctree->tree_column    = 0;
  ctree->line_style     = GTK_CTREE_LINES_SOLID;
  ctree->expander_style = GTK_CTREE_EXPANDER_SQUARE;
  ctree->drag_compare   = NULL;
  ctree->show_stub      = TRUE;

  clist->button_actions[0] |= GTK_BUTTON_EXPANDS;

  sw =[[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
  [sw setHasVerticalScroller:YES];
  [sw setBorderType:NSLineBorder];
  tree = [[NSGtkTree  alloc] initWithFrame:NSMakeRect(0,0,100,10)];
  tree->proxy = ctree;
  [sw setDocumentView:tree];
  tree->tag = 0;
  [tree setDataSource:tree];
  [tree setDelegate:tree];
  [GTK_WIDGET(ctree)->proxy release];
  GTK_WIDGET(ctree)->proxy = sw;
  thv = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0,0,100,17)];
  [tree setHeaderView:thv];
//  [tree addSubview:thv];
  [tree setAutoresizesSubviews:FALSE];
  [tree setAllowsColumnReordering:FALSE];
  [tree setAction: @selector (tree_select_row:)];
  [tree setTarget: tree];
  [tree registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
}
 
gint
ctree_real_insert_row (GtkCList *clist,
		 gint      row,
		 gchar    *text[])
{
  GtkCTreeNode *parent = NULL;
  GtkCTreeNode *sibling;
  GtkCTreeNode *node;
  NSGtkTree *tree = [GTK_WIDGET(clist)->proxy documentView];

  g_return_val_if_fail (clist != NULL, -1);
  g_return_val_if_fail (GTK_IS_CTREE (clist), -1);

  sibling = GTK_CTREE_NODE (g_list_nth (clist->row_list, row));
  if (sibling)
    parent = GTK_CTREE_ROW (sibling)->parent;

  node = gtk_ctree_insert_node (GTK_CTREE (clist), parent, sibling, text, 5,
				NULL, NULL, NULL, NULL, TRUE, FALSE);

  if (GTK_CLIST_AUTO_SORT (clist) || !sibling)
    return g_list_position (clist->row_list, (GList *) node);
  
 [tree setOutlineTableColumn: [[tree tableColumns] objectAtIndex: 0]]; 
 if(CLIST_UNFROZEN(tree))
 {
	 [tree reloadData];
	 [tree noteNumberOfRowsChanged];
  }
  return row;
}

void
ctree_real_remove_row (GtkCList *clist,
		 gint      row)
{
  GtkCTreeNode *node;
  NSGtkTree *tree = [GTK_WIDGET(clist)->proxy documentView];

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CTREE (clist));

  node = GTK_CTREE_NODE (g_list_nth (clist->row_list, row));

  if (node)
    gtk_ctree_remove_node (GTK_CTREE (clist), node);
 
 if(CLIST_UNFROZEN(clist))
 {
 	[tree reloadData];
	[tree noteNumberOfRowsChanged];
 }
}

GtkCTreeNode * 
gtk_ctree_insert_node (GtkCTree     *ctree,
		       GtkCTreeNode *parent, 
		       GtkCTreeNode *sibling,
		       gchar        *text[],
		       guint8        spacing,
		       GdkPixmap    *pixmap_closed,
		       GdkBitmap    *mask_closed,
		       GdkPixmap    *pixmap_opened,
		       GdkBitmap    *mask_opened,
		       gboolean      is_leaf,
		       gboolean      expanded)
{
  GtkCList *clist;
  GtkCTreeRow *new_row;
  GtkCTreeNode *node;
  GList *list;
  gint i;
  NSGtkTree *tree = [GTK_WIDGET(ctree)->proxy documentView];
  NSGtkTreeNode *tree_node;

  g_return_val_if_fail (ctree != NULL, NULL);
  g_return_val_if_fail (GTK_IS_CTREE (ctree), NULL);
  if (sibling)
    g_return_val_if_fail (GTK_CTREE_ROW (sibling)->parent == parent, NULL);

  if (parent && GTK_CTREE_ROW (parent)->is_leaf)
    return NULL;

  clist = GTK_CLIST (ctree);

  /* create the row */
  new_row = ctree_row_new (ctree);
  list = g_malloc0 (sizeof(GtkCTreeNode));
  list->data = new_row;
  node = GTK_CTREE_NODE (list);

  if (text)
    for (i = 0; i < clist->columns; i++)
      if (text[i] && i != ctree->tree_column)
	GTK_CLIST_CLASS_FW (clist)->set_cell_contents
	  (clist, &(new_row->row), i, GTK_CELL_TEXT, text[i], 0, NULL, NULL);

  set_node_info (ctree, node, text ?
		 text[ctree->tree_column] : NULL, spacing, pixmap_closed,
		 mask_closed, pixmap_opened, mask_opened, is_leaf, expanded);

  /* sorted insertion */
  if (GTK_CLIST_AUTO_SORT (clist))
    {
      if (parent)
	sibling = GTK_CTREE_ROW (parent)->children;
      else
	sibling = GTK_CTREE_NODE (clist->row_list);

      while (sibling && clist->compare
	     (clist, GTK_CTREE_ROW (node), GTK_CTREE_ROW (sibling)) > 0)
	sibling = GTK_CTREE_ROW (sibling)->sibling;
    }

  gtk_ctree_link (ctree, node, parent, sibling, TRUE);

  if (text && !GTK_CLIST_AUTO_RESIZE_BLOCKED (clist) &&
      gtk_ctree_is_viewable (ctree, node))
    {
      for (i = 0; i < clist->columns; i++)
	if (clist->column[i].auto_resize)
	  column_auto_resize (clist, &(new_row->row), i, 0);
    }

  if (clist->rows == 1)
    {
      clist->focus_row = 0;
      if (clist->selection_mode == GTK_SELECTION_BROWSE)
	gtk_ctree_select (ctree, node);
    }


  CLIST_REFRESH (clist);

 [tree setOutlineTableColumn: [[tree tableColumns] objectAtIndex: 0]]; 
  tree_node = [NSGtkTreeNode alloc];
  node->proxy = tree_node;
  tree_node->node = node;
 if(CLIST_UNFROZEN(clist))
 {
 	[tree reloadData];
	[tree noteNumberOfRowsChanged];
  }
  return node;
}

void
gtk_ctree_select (GtkCTree     *ctree, 
		  GtkCTreeNode *node)
{
  NSGtkTree *tree;
  NSGtkTreeNode *tree_node;  
  GtkCTreeRow *row_node;
  GtkCList *clist;
  gboolean expand;
  
  int row;
  
  g_return_if_fail (ctree != NULL);
  g_return_if_fail (GTK_IS_CTREE (ctree));
  g_return_if_fail (node != NULL);

  clist = GTK_CLIST (ctree);
  
 if (GTK_CTREE_ROW (node)->row.selectable)
    gtk_signal_emit (GTK_OBJECT (ctree), ctree_signals[TREE_SELECT_ROW],
		     node, -1);


  tree = [GTK_WIDGET(ctree)->proxy documentView];
  tree_node = node->proxy;
  expand = GTK_CLIST(ctree)->selection_mode == GTK_SELECTION_MULTIPLE;
  expand |= GTK_CLIST(ctree)->selection_mode == GTK_SELECTION_EXTENDED;
  row_node = GTK_CTREE_ROW(node);
  row = g_list_index(clist->row_list, row_node);


  [tree selectRow:row byExtendingSelection:expand];
  [tree setNeedsDisplay:YES];
}


void 
gtk_ctree_node_set_pixmap (GtkCTree     *ctree,
			   GtkCTreeNode *node,
			   gint          column,
			   GdkPixmap    *pixmap,
			   GdkBitmap    *mask)
{
  NSGtkTree *tree;
  NSTableColumn *tc;
  GtkCList *clist;

  g_return_if_fail (ctree != NULL);
  g_return_if_fail (GTK_IS_CTREE (ctree));
  g_return_if_fail (node != NULL);
  g_return_if_fail (pixmap != NULL);

  if (column < 0 || column >= GTK_CLIST (ctree)->columns)
    return;

  gdk_pixmap_ref (pixmap);
  if (mask) 
    gdk_pixmap_ref (mask);

  clist = GTK_CLIST (ctree);

  tree = [GTK_WIDGET(ctree)->proxy documentView];
  tc = [[tree tableColumns] objectAtIndex: column];
  [tc setDataCell:[[NSImageCell alloc] init]];

  GTK_CLIST_CLASS_FW (clist)->set_cell_contents
    (clist, &(GTK_CTREE_ROW (node)->row), column, GTK_CELL_PIXMAP,
     NULL, 0, pixmap, mask);
}

GtkCTreeNode *
gtk_ctree_node_nth (GtkCTree *ctree,
		    guint     row)
{
  NSGtkTree *tree;
  NSGtkTreeNode *tree_node;
  g_return_val_if_fail (ctree != NULL, NULL);
  g_return_val_if_fail (GTK_IS_CTREE (ctree), NULL);

  tree = [GTK_WIDGET(ctree)->proxy documentView];
  tree_node = [tree itemAtRow:row];
  if(!tree_node) return NULL;

  return tree_node->node;
}

void
ns_gtk_ctree_expand(GtkCTree *ctree,
					 GtkCTreeNode *node,
					 gpointer data)
{

	if(GTK_CTREE_ROW (node)->expanded)
		[[GTK_WIDGET(ctree)->proxy documentView] expandItem:node->proxy];
    else
        [[GTK_WIDGET(ctree)->proxy documentView] collapseItem:node->proxy];
    
     if (GTK_CTREE_ROW (node)->row.state == GTK_STATE_SELECTED)
        gtk_ctree_select(ctree, node);
}

void
gtk_ctree_node_set_foreground (GtkCTree     *ctree,
			       GtkCTreeNode *node,
			       GdkColor     *color)
{
  g_return_if_fail (ctree != NULL);
  g_return_if_fail (GTK_IS_CTREE (ctree));
  g_return_if_fail (node != NULL);

  if (color)
    {
      GTK_CTREE_ROW (node)->row.foreground = *color;
      GTK_CTREE_ROW (node)->row.fg_set = TRUE;
    }
  else
    GTK_CTREE_ROW (node)->row.fg_set = FALSE;


}


