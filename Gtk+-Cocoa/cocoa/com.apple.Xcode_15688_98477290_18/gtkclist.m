//
//  gtkclist.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSGtkTableView.h"

#include <gtk/gtk.h>

#define CLIST_OPTIMUM_SIZE 64

/* minimum allowed width of a column */
#define COLUMN_MIN_WIDTH 5

/* this defigns the base grid spacing */
#define CELL_SPACING 1

/* added the horizontal space at the beginning and end of a row*/
#define COLUMN_INSET 3

/* used for auto-scrolling */
#define SCROLL_TIME  100

/* gives the top pixel of the given row in context of
 * the clist's voffset */
#define ROW_TOP_YPIXEL(clist, row) (((clist)->row_height * (row)) + \
				    (((row) + 1) * CELL_SPACING) + \
				    (clist)->voffset)

/* returns the row index from a y pixel location in the 
 * context of the clist's voffset */
#define ROW_FROM_YPIXEL(clist, y)  (((y) - (clist)->voffset) / \
				    ((clist)->row_height + CELL_SPACING))

/* gives the left pixel of the given column in context of
 * the clist's hoffset */
#define COLUMN_LEFT_XPIXEL(clist, colnum)  ((clist)->column[(colnum)].area.x + \
					    (clist)->hoffset)

/* returns the total height of the list */
#define LIST_HEIGHT(clist)         (((clist)->row_height * ((clist)->rows)) + \
				    (CELL_SPACING * ((clist)->rows + 1)))

gint LIST_WIDTH (GtkCList * clist);
 
/* returns the GList item for the nth row */
#define	ROW_ELEMENT(clist, row)	(((row) == (clist)->rows - 1) ? \
				 (clist)->row_list_end : \
				 g_list_nth ((clist)->row_list, (row)))

#define GTK_CLIST_CLASS_FW(_widget_) GTK_CLIST_CLASS (((GtkObject*) (_widget_))->klass)

/* redraw the list if it's not frozen */
#define CLIST_UNFROZEN(clist)     (((GtkCList*) (clist))->freeze_count == 0)
#define	CLIST_REFRESH(clist)	G_STMT_START { \
  if (CLIST_UNFROZEN (clist)) \
    GTK_CLIST_CLASS_FW (clist)->refresh ((GtkCList*) (clist)); \
} G_STMT_END


/* Signals */
enum {
  SELECT_ROW,
  UNSELECT_ROW,
  ROW_MOVE,
  CLICK_COLUMN,
  RESIZE_COLUMN,
  TOGGLE_FOCUS_ROW,
  SELECT_ALL,
  UNSELECT_ALL,
  UNDO_SELECTION,
  START_SELECTION,
  END_SELECTION,
  TOGGLE_ADD_MODE,
  EXTEND_SELECTION,
  SCROLL_VERTICAL,
  SCROLL_HORIZONTAL,
  ABORT_COLUMN_RESIZE,
  LAST_SIGNAL
};

enum {
  SYNC_REMOVE,
  SYNC_INSERT
};

extern guint clist_signals[LAST_SIGNAL];

gint default_compare        (GtkCList      *clist, gconstpointer  row1, gconstpointer  row2);
gint list_requisition_width      (GtkCList *clist);

void
gtk_clist_init (GtkCList *clist)
{
  NSScrollView *sw;
  NSGtkTableView *tv;
  NSTableHeaderView *thv;
  clist->flags = 0;

  GTK_WIDGET_UNSET_FLAGS (clist, GTK_NO_WINDOW);
  GTK_WIDGET_SET_FLAGS (clist, GTK_CAN_FOCUS);
  GTK_CLIST_SET_FLAG (clist, CLIST_CHILD_HAS_FOCUS);
  GTK_CLIST_SET_FLAG (clist, CLIST_DRAW_DRAG_LINE);
  GTK_CLIST_SET_FLAG (clist, CLIST_USE_DRAG_ICONS);

  clist->row_mem_chunk = NULL;
  clist->cell_mem_chunk = NULL;

  clist->freeze_count = 0;

  clist->rows = 0;
  clist->row_center_offset = 0;
  clist->row_height = 0;
  clist->row_list = NULL;
  clist->row_list_end = NULL;

  clist->columns = 0;

  clist->title_window = NULL;
  clist->column_title_area.x = 0;
  clist->column_title_area.y = 0;
  clist->column_title_area.width = 1;
  clist->column_title_area.height = 1;

  clist->clist_window = NULL;
  clist->clist_window_width = 1;
  clist->clist_window_height = 1;

  clist->hoffset = 0;
  clist->voffset = 0;

  clist->shadow_type = GTK_SHADOW_IN;
  clist->vadjustment = NULL;
  clist->hadjustment = NULL;

  clist->button_actions[0] = GTK_BUTTON_SELECTS | GTK_BUTTON_DRAGS;
  clist->button_actions[1] = GTK_BUTTON_IGNORED;
  clist->button_actions[2] = GTK_BUTTON_IGNORED;
  clist->button_actions[3] = GTK_BUTTON_IGNORED;
  clist->button_actions[4] = GTK_BUTTON_IGNORED;

  clist->cursor_drag = NULL;
  clist->xor_gc = NULL;
  clist->fg_gc = NULL;
  clist->bg_gc = NULL;
  clist->x_drag = 0;

  clist->selection_mode = GTK_SELECTION_SINGLE;
  clist->selection = NULL;
  clist->selection_end = NULL;
  clist->undo_selection = NULL;
  clist->undo_unselection = NULL;

  clist->focus_row = -1;
  clist->undo_anchor = -1;

  clist->anchor = -1;
  clist->anchor_state = GTK_STATE_SELECTED;
  clist->drag_pos = -1;
  clist->htimer = 0;
  clist->vtimer = 0;

  clist->click_cell.row = -1;
  clist->click_cell.column = -1;

  clist->compare = default_compare;
  clist->sort_type = GTK_SORT_ASCENDING;
  clist->sort_column = 0;

  sw =[[NSScrollView alloc] initWithFrame:NSMakeRect(0,0,100,100)];
//  [sw setHasVerticalScroller:YES];
  [sw setBorderType:NSLineBorder];
  tv = [[NSGtkTableView alloc] initWithFrame:NSMakeRect(0,0,1000,100)];
  [GTK_WIDGET(clist)->proxy release];
  GTK_WIDGET(clist)->proxy = sw;
  tv->proxy = clist;
  [sw setDocumentView:tv];
  tv->lock_size = FALSE;
  [tv setDataSource:tv];
  thv = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0,0,100,17)];
  [tv setHeaderView:thv];
  //[tv addSubview:thv];
  [tv setAutoresizesSubviews:FALSE];
  [tv setAllowsColumnReordering:FALSE];
}

/* Constructors */
void
gtk_clist_construct (GtkCList *clist,
		     gint      columns,
		     gchar    *titles[])
{
  NSGtkTableView *tv = [GTK_WIDGET(clist)->proxy documentView];
  NSTableColumn *tc;
  guint i;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));
  g_return_if_fail (columns > 0);
  g_return_if_fail (GTK_OBJECT_CONSTRUCTED (clist) == FALSE);

  /* mark the object as constructed */
  gtk_object_constructed (GTK_OBJECT (clist));

  /* initalize memory chunks, if this has not been done by any
   * possibly derived widget
   */
  if (!clist->row_mem_chunk)
    clist->row_mem_chunk = g_mem_chunk_new ("clist row mem chunk",
					    sizeof (GtkCListRow),
					    sizeof (GtkCListRow) *
					    CLIST_OPTIMUM_SIZE, 
					    G_ALLOC_AND_FREE);

  if (!clist->cell_mem_chunk)
    clist->cell_mem_chunk = g_mem_chunk_new ("clist cell mem chunk",
					     sizeof (GtkCell) * columns,
					     sizeof (GtkCell) * columns *
					     CLIST_OPTIMUM_SIZE, 
					     G_ALLOC_AND_FREE);

  /* set number of columns, allocate memory */
  clist->columns = columns;
  clist->column = columns_new (clist);

  /* there needs to be at least one column button 
   * because there is alot of code that will break if it
   * isn't there*/
  //column_button_create (clist, 0);

  if (titles)
    {
      
      GTK_CLIST_SET_FLAG (clist, CLIST_SHOW_TITLES);
      for (i = 0; i < columns; i++)
	  {
		tc = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithCString:titles[i]]];
		[[tc headerCell] setStringValue:[NSString stringWithCString:titles[i]]];
		[tc setEditable:FALSE];
		[tv addTableColumn:tc];
		gtk_clist_set_column_title (clist, i, titles[i]);
	  }
    }
  else
    {
      for (i = 0; i < columns; i++)
	  {
		tc = [[NSTableColumn alloc] init];
		[tc setEditable:FALSE];
		[tv addTableColumn:tc];
	  }
      GTK_CLIST_UNSET_FLAG (clist, CLIST_SHOW_TITLES);
    }
}

void
column_button_create (GtkCList *clist,
		      gint      column)
{
#if 0
  GtkWidget *button;

  gtk_widget_push_composite_child ();
  button = clist->column[column].button = gtk_button_new ();
  gtk_widget_pop_composite_child ();

  if (GTK_WIDGET_REALIZED (clist) && clist->title_window)
    gtk_widget_set_parent_window (clist->column[column].button,
				  clist->title_window);
  gtk_widget_set_parent (button, GTK_WIDGET (clist));

  gtk_signal_connect (GTK_OBJECT (button), "clicked",
		      (GtkSignalFunc) column_button_clicked,
		      (gpointer) clist);

  if (clist->column[column].button_passive)
    set_column_title_active (clist, column, FALSE);
  
  gtk_widget_show (button);
#endif
}

void
gtk_clist_size_request (GtkWidget      *widget,
			GtkRequisition *requisition)
{
  GtkCList *clist;
  gint i;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_CLIST (widget));
  g_return_if_fail (requisition != NULL);

  clist = GTK_CLIST (widget);

  requisition->width = 0;
  requisition->height = 0;

  /* compute the size of the column title (title) area */
  clist->column_title_area.height = 0;
  if (GTK_CLIST_SHOW_TITLES(clist))
    for (i = 0; i < clist->columns; i++)
      if (clist->column[i].button)
	{
	  GtkRequisition child_requisition;
	  
	  gtk_widget_size_request (clist->column[i].button,
				   &child_requisition);
	  clist->column_title_area.height =
	    MAX (clist->column_title_area.height,
		 child_requisition.height);
	}

  requisition->width += (//widget->style->klass->xthickness +
			 GTK_CONTAINER (widget)->border_width) * 2;
  requisition->height += (clist->column_title_area.height +
			  (//widget->style->klass->ythickness +
			   GTK_CONTAINER (widget)->border_width) * 2);

  /* if (!clist->hadjustment) */
  requisition->width += list_requisition_width (clist);
  /* if (!clist->vadjustment) */
  requisition->height += LIST_HEIGHT (clist);
}

void
gtk_clist_size_allocate (GtkWidget     *widget,
			 GtkAllocation *allocation)
{
  GtkCList *clist;
  GtkAllocation clist_allocation;
  gint border_width;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_CLIST (widget));
  g_return_if_fail (allocation != NULL);

  clist = GTK_CLIST (widget);
  widget->allocation = *allocation;
  border_width = GTK_CONTAINER (widget)->border_width;

#if 0
  if (GTK_WIDGET_REALIZED (widget))
    {
      gdk_window_move_resize (widget->window,
			      allocation->x + border_width,
			      allocation->y + border_width,
			      allocation->width - border_width * 2,
			      allocation->height - border_width * 2);
    }

  /* use internal allocation structure for all the math
   * because it's easier than always subtracting the container
   * border width */
  clist->internal_allocation.x = 0;
  clist->internal_allocation.y = 0;
  clist->internal_allocation.width = MAX (1, (gint)allocation->width -
					  border_width * 2);
  clist->internal_allocation.height = MAX (1, (gint)allocation->height -
					   border_width * 2);
	
  /* allocate clist window assuming no scrollbars */
  clist_allocation.x = (clist->internal_allocation.x);
			//widget->style->klass->xthickness);
  clist_allocation.y = (clist->internal_allocation.y);
			//widget->style->klass->ythickness +
			//clist->column_title_area.height);
  clist_allocation.width = MAX (1, (gint)clist->internal_allocation.width ); 
			//	(2 * (gint)widget->style->klass->xthickness));
  clist_allocation.height = MAX (1, (gint)clist->internal_allocation.height);
				 //(2 * (gint)widget->style->klass->ythickness) -
				 //(gint)clist->column_title_area.height);
  
  clist->clist_window_width = clist_allocation.width;
  clist->clist_window_height = clist_allocation.height;
  
  if (GTK_WIDGET_REALIZED (widget))
    {
      gdk_window_move_resize (clist->clist_window,
			      clist_allocation.x,
			      clist_allocation.y,
			      clist_allocation.width,
			      clist_allocation.height);
    }
  
  /* position the window which holds the column title buttons */
  clist->column_title_area.x = widget->style->klass->xthickness;
  clist->column_title_area.y = widget->style->klass->ythickness;
  clist->column_title_area.width = clist_allocation.width;
  
  if (GTK_WIDGET_REALIZED (widget))
    {
      gdk_window_move_resize (clist->title_window,
			      clist->column_title_area.x,
			      clist->column_title_area.y,
			      clist->column_title_area.width,
			      clist->column_title_area.height);
    }
  
  /* column button allocation */
  size_allocate_columns (clist, FALSE);
  size_allocate_title_buttons (clist);
#endif

  adjust_adjustments (clist, TRUE);
}

void
gtk_clist_set_column_widget (GtkCList  *clist,
			     gint       column,
			     GtkWidget *widget)
{
  NSGtkTableView *tv = [GTK_WIDGET(clist)->proxy documentView];
  NSTableColumn *tc;
	char *title;

	gtk_label_get(widget,&title);
    tc  = [[tv tableColumns] objectAtIndex:column];
	if(!tc)
	{
		tc = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithCString:title]];
		[tv addTableColumn:tc];
	}
	else
		[tc setIdentifier:[NSString stringWithCString:title]];
	[[tc headerCell] setStringValue:[NSString stringWithCString:title]];
	
#if 0
  gint new_button = 0;
  GtkWidget *old_widget;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  if (column < 0 || column >= clist->columns)
    return;

  /* if the column button doesn't currently exist,
   * it has to be created first */
  if (!clist->column[column].button)
    {
      column_button_create (clist, column);
      new_button = 1;
    }

  column_title_new (clist, column, NULL);

  /* remove and destroy the old widget */
  old_widget = GTK_BIN (clist->column[column].button)->child;
  if (old_widget)
    gtk_container_remove (GTK_CONTAINER (clist->column[column].button),
			  old_widget);

  /* add and show the widget */
  if (widget)
    {
      gtk_container_add (GTK_CONTAINER (clist->column[column].button), widget);
      gtk_widget_show (widget);
    }

  /* if this button didn't previously exist, then the
   * column button positions have to be re-computed */
  if (GTK_WIDGET_VISIBLE (clist) && new_button)
    size_allocate_title_buttons (clist);
#endif
}

/* PRIVATE INSERT/REMOVE ROW FUNCTIONS
 *   real_insert_row
 *   real_remove_row
 *   real_clear
 *   real_row_move
 */
gint
real_insert_row (GtkCList *clist,
		 gint      row,
		 gchar    *text[])
{
  gint i;
  GtkCListRow *clist_row;

  g_return_val_if_fail (clist != NULL, -1);
  g_return_val_if_fail (GTK_IS_CLIST (clist), -1);
  g_return_val_if_fail (text != NULL, -1);

  /* return if out of bounds */
  if (row < 0 || row > clist->rows)
    return -1;

  /* create the row */
  clist_row = row_new (clist);

  /* set the text in the row's columns */
  for (i = 0; i < clist->columns; i++)
    if (text[i])
      GTK_CLIST_CLASS_FW (clist)->set_cell_contents
	(clist, clist_row, i, GTK_CELL_TEXT, text[i], 0, NULL ,NULL);

  if (!clist->rows)
    {
      clist->row_list = g_list_append (clist->row_list, clist_row);
      clist->row_list_end = clist->row_list;
    }
  else
    {
      if (GTK_CLIST_AUTO_SORT(clist))   /* override insertion pos */
	{
	  GList *work;
	  
	  row = 0;
	  work = clist->row_list;
	  
	  if (clist->sort_type == GTK_SORT_ASCENDING)
	    {
	      while (row < clist->rows &&
		     clist->compare (clist, clist_row,
				     GTK_CLIST_ROW (work)) > 0)
		{
		  row++;
		  work = work->next;
		}
	    }
	  else
	    {
	      while (row < clist->rows &&
		     clist->compare (clist, clist_row,
				     GTK_CLIST_ROW (work)) < 0)
		{
		  row++;
		  work = work->next;
		}
	    }
	}
      
      /* reset the row end pointer if we're inserting at the end of the list */
      if (row == clist->rows)
	clist->row_list_end = (g_list_append (clist->row_list_end,
					      clist_row))->next;
      else
	clist->row_list = g_list_insert (clist->row_list, clist_row, row);

    }
  clist->rows++;

  if (row < ROW_FROM_YPIXEL (clist, 0))
    clist->voffset -= (clist->row_height + CELL_SPACING);

  /* syncronize the selection list */
  sync_selection (clist, row, SYNC_INSERT);

  if (clist->rows == 1)
    {
      clist->focus_row = 0;
      if (clist->selection_mode == GTK_SELECTION_BROWSE)
	gtk_clist_select_row (clist, 0, -1);
    }

  /* redraw the list if it isn't frozen */
  if (CLIST_UNFROZEN (clist))
    {
      adjust_adjustments (clist, FALSE);

      if (gtk_clist_row_is_visible (clist, row) != GTK_VISIBILITY_NONE)
	draw_rows (clist, NULL);
    }

  	[[GTK_WIDGET(clist)->proxy documentView] reloadData];
  	[[GTK_WIDGET(clist)->proxy documentView] noteNumberOfRowsChanged];
  [[GTK_WIDGET(clist)->proxy documentView] setNeedsDisplay];
  return row;
}

void
real_remove_row (GtkCList *clist,
		 gint      row)
{
  gint was_visible, was_selected;
  GList *list;
  GtkCListRow *clist_row;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  /* return if out of bounds */
  if (row < 0 || row > (clist->rows - 1))
    return;

  was_visible = (gtk_clist_row_is_visible (clist, row) != GTK_VISIBILITY_NONE);
  was_selected = 0;

  /* get the row we're going to delete */
  list = ROW_ELEMENT (clist, row);
  g_assert (list != NULL);
  clist_row = list->data;

  /* if we're removing a selected row, we have to make sure
   * it's properly unselected, and then sync up the clist->selected
   * list to reflect the deincrimented indexies of rows after the
   * removal */
  if (clist_row->state == GTK_STATE_SELECTED)
    gtk_signal_emit (GTK_OBJECT (clist), clist_signals[UNSELECT_ROW],
		     row, -1, NULL);

  sync_selection (clist, row, SYNC_REMOVE);

  /* reset the row end pointer if we're removing at the end of the list */
  clist->rows--;
  if (clist->row_list == list)
    clist->row_list = g_list_next (list);
  if (clist->row_list_end == list)
    clist->row_list_end = g_list_previous (list);
  g_list_remove (list, clist_row);

  /*if (clist->focus_row >=0 &&
      (row <= clist->focus_row || clist->focus_row >= clist->rows))
      clist->focus_row--;*/

  if (row < ROW_FROM_YPIXEL (clist, 0))
    clist->voffset += clist->row_height + CELL_SPACING;

  if (clist->selection_mode == GTK_SELECTION_BROWSE && !clist->selection &&
      clist->focus_row >= 0)
    gtk_signal_emit (GTK_OBJECT (clist), clist_signals[SELECT_ROW],
		     clist->focus_row, -1, NULL);

  /* toast the row */
  row_delete (clist, clist_row);

  /* redraw the row if it isn't frozen */
  if (CLIST_UNFROZEN (clist))
    {
      adjust_adjustments (clist, FALSE);

      if (was_visible)
	draw_rows (clist, NULL);
  	[[GTK_WIDGET(clist)->proxy documentView] reloadData];
  	[[GTK_WIDGET(clist)->proxy documentView] noteNumberOfRowsChanged];
    }
  [[GTK_WIDGET(clist)->proxy documentView] setNeedsDisplay];
}

void
real_clear (GtkCList *clist)
{
  GList *list;
  GList *free_list;
  gint i;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  /* free up the selection list */
  g_list_free (clist->selection);
  g_list_free (clist->undo_selection);
  g_list_free (clist->undo_unselection);

  clist->selection = NULL;
  clist->selection_end = NULL;
  clist->undo_selection = NULL;
  clist->undo_unselection = NULL;
  clist->voffset = 0;
  clist->focus_row = -1;
  clist->anchor = -1;
  clist->undo_anchor = -1;
  clist->anchor_state = GTK_STATE_SELECTED;
  clist->drag_pos = -1;

  /* remove all the rows */
  GTK_CLIST_SET_FLAG (clist, CLIST_AUTO_RESIZE_BLOCKED);
  free_list = clist->row_list;
  clist->row_list = NULL;
  clist->row_list_end = NULL;
  clist->rows = 0;
  for (list = free_list; list; list = list->next)
    row_delete (clist, GTK_CLIST_ROW (list));
  g_list_free (free_list);
  GTK_CLIST_UNSET_FLAG (clist, CLIST_AUTO_RESIZE_BLOCKED);
  for (i = 0; i < clist->columns; i++)
    if (clist->column[i].auto_resize)
      {
	if (GTK_CLIST_SHOW_TITLES(clist) && clist->column[i].button)
	  gtk_clist_set_column_width
	    (clist, i, (clist->column[i].button->requisition.width -
			(CELL_SPACING + (2 * COLUMN_INSET))));
	else
	  gtk_clist_set_column_width (clist, i, 0);
      }
  /* zero-out the scrollbars */
  if (clist->vadjustment)
    {
      gtk_adjustment_set_value (clist->vadjustment, 0.0);
      CLIST_REFRESH (clist);
    }
  else
    gtk_widget_queue_resize (GTK_WIDGET (clist));
  if(CLIST_UNFROZEN(clist))
  {
  	[[GTK_WIDGET(clist)->proxy documentView] reloadData];
  	[[GTK_WIDGET(clist)->proxy documentView] noteNumberOfRowsChanged];
  }
}

void
real_row_move (GtkCList *clist,
	       gint      source_row,
	       gint      dest_row)
{
  GtkCListRow *clist_row;
  GList *list;
  gint first, last;
  gint d;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  if (GTK_CLIST_AUTO_SORT(clist))
    return;

  if (source_row < 0 || source_row >= clist->rows ||
      dest_row   < 0 || dest_row   >= clist->rows ||
      source_row == dest_row)
    return;

  gtk_clist_freeze (clist);

  /* unlink source row */
  clist_row = ROW_ELEMENT (clist, source_row)->data;
  if (source_row == clist->rows - 1)
    clist->row_list_end = clist->row_list_end->prev;
  clist->row_list = g_list_remove (clist->row_list, clist_row);
  clist->rows--;

  /* relink source row */
  clist->row_list = g_list_insert (clist->row_list, clist_row, dest_row);
  if (dest_row == clist->rows)
    clist->row_list_end = clist->row_list_end->next;
  clist->rows++;

  /* sync selection */
  if (source_row > dest_row)
    {
      first = dest_row;
      last  = source_row;
      d = 1;
    }
  else
    {
      first = source_row;
      last  = dest_row;
      d = -1;
    }

  for (list = clist->selection; list; list = list->next)
    {
      if (list->data == GINT_TO_POINTER (source_row))
	list->data = GINT_TO_POINTER (dest_row);
      else if (first <= GPOINTER_TO_INT (list->data) &&
	       last >= GPOINTER_TO_INT (list->data))
	list->data = GINT_TO_POINTER (GPOINTER_TO_INT (list->data) + d);
    }
  
  if (clist->focus_row == source_row)
    clist->focus_row = dest_row;
  else if (clist->focus_row > first)
    clist->focus_row += d;

  gtk_clist_thaw (clist);
  [[GTK_WIDGET(clist)->proxy documentView] setNeedsDisplay];
}

void
gtk_clist_set_column_width (GtkCList *clist,
			    gint      column,
			    gint      width)
{
  NSGtkTableView *tv;
  NSTableColumn *tc;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));
	
  if (column < 0 || column >= clist->columns)
    return;

  gtk_signal_emit (GTK_OBJECT (clist), clist_signals[RESIZE_COLUMN],
		   column, width);

  tv  = [GTK_WIDGET(clist)->proxy documentView];
  tc  = [[tv tableColumns] objectAtIndex:column];
  [tc setWidth:width]; 
}

void
gtk_clist_set_selection_mode (GtkCList         *clist,
			      GtkSelectionMode  mode)
{
  NSGtkTableView *tv;
  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  if (mode == clist->selection_mode)
    return;

  clist->selection_mode = mode;
  clist->anchor = -1;
  clist->anchor_state = GTK_STATE_SELECTED;
  clist->drag_pos = -1;
  clist->undo_anchor = clist->focus_row;

  g_list_free (clist->undo_selection);
  g_list_free (clist->undo_unselection);
  clist->undo_selection = NULL;
  clist->undo_unselection = NULL;

  tv  = [GTK_WIDGET(clist)->proxy documentView];
  switch (mode)
    {
    case GTK_SELECTION_MULTIPLE:
    case GTK_SELECTION_EXTENDED:
	[tv setAllowsMultipleSelection:TRUE];
      return;
    case GTK_SELECTION_BROWSE:
    case GTK_SELECTION_SINGLE:
	[tv setAllowsMultipleSelection:FALSE];
      gtk_clist_unselect_all (clist);
      break;
    }
}

void
gtk_clist_clear (GtkCList *clist)
{
  NSGtkTableView *tv;
  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));
  
  tv  = [GTK_WIDGET(clist)->proxy documentView];
  [tv deselectAll:tv];
  GTK_CLIST_CLASS_FW (clist)->clear (clist);
}

void
gtk_clist_set_column_visibility (GtkCList *clist,
				 gint      column,
				 gboolean  visible)
{
  NSGtkTableView *tv;
  NSTableColumn *tc;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  if (column < 0 || column >= clist->columns)
    return;
  if (clist->column[column].visible == visible)
    return;

  /* don't hide last visible column */
  if (!visible)
    {
      gint i;
      gint vis_columns = 0;

      for (i = 0, vis_columns = 0; i < clist->columns && vis_columns < 2; i++)
	if (clist->column[i].visible)
	  vis_columns++;

      if (vis_columns < 2)
	return;
    }

  clist->column[column].visible = visible;

  if (clist->column[column].button)
    {
      if (visible)
	gtk_widget_show (clist->column[column].button);
      else
	gtk_widget_hide (clist->column[column].button);
    }
  
  gtk_widget_queue_resize (GTK_WIDGET(clist));
  tv  = [GTK_WIDGET(clist)->proxy documentView];
  tc  = [[tv tableColumns] objectAtIndex:column];
  [tv removeTableColumn:tc];
}

/* get cell from coordinates
 *   get_selection_info
 *   gtk_clist_get_selection_info
 */
gint
get_selection_info (GtkCList *clist,
		    gint      x,
		    gint      y,
		    gint     *row,
		    gint     *column)
{
  NSGtkTableView *tv;
  gint trow, tcol;

  g_return_val_if_fail (clist != NULL, 0);
  g_return_val_if_fail (GTK_IS_CLIST (clist), 0);

  tv  = [GTK_WIDGET(clist)->proxy documentView];
  *row = [tv rowAtPoint:NSMakePoint(x,y)];
  *column = [tv columnAtPoint:NSMakePoint(x,y)];
  *row -=1;
 
  return 1;
}

void
gtk_clist_set_pixmap (GtkCList  *clist,
		      gint       row,
		      gint       column,
		      GdkPixmap *pixmap,
		      GdkBitmap *mask)
{
  NSGtkTableView *tv;
  NSTableColumn *tc;
  GtkCListRow *clist_row;

  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  if (row < 0 || row >= clist->rows)
    return;
  if (column < 0 || column >= clist->columns)
    return;

  tv  = [GTK_WIDGET(clist)->proxy documentView];
  clist_row = ROW_ELEMENT (clist, row)->data;
  tc = [[tv tableColumns] objectAtIndex: column];
  [tc setDataCell:[[NSImageCell alloc] init]];
  
  gdk_pixmap_ref (pixmap);
  
  if (mask) gdk_pixmap_ref (mask);
  
  GTK_CLIST_CLASS_FW (clist)->set_cell_contents
    (clist, clist_row, column, GTK_CELL_PIXMAP, NULL, 0, pixmap, mask);

  /* redraw the list if it's not frozen */
  if (CLIST_UNFROZEN (clist))
    {
      if (gtk_clist_row_is_visible (clist, row) != GTK_VISIBILITY_NONE)
	GTK_CLIST_CLASS_FW (clist)->draw_row (clist, NULL, row, clist_row);
    }
}

void
gtk_clist_thaw (GtkCList *clist)
{
  g_return_if_fail (clist != NULL);
  g_return_if_fail (GTK_IS_CLIST (clist));

  if (clist->freeze_count)
    {
      clist->freeze_count--;
      CLIST_REFRESH (clist);
    }
	[[GTK_WIDGET(clist)->proxy documentView] setNeedsDisplay:TRUE];
	[[GTK_WIDGET(clist)->proxy documentView] thaw];
}

void
vadjustment_value_changed (GtkAdjustment *adjustment,
			   gpointer       data)
{
  GtkCList *clist;
  GdkRectangle area;
  gint diff, value;
  NSPoint p;

  g_return_if_fail (adjustment != NULL);
  g_return_if_fail (data != NULL);
  g_return_if_fail (GTK_IS_CLIST (data));

  clist = GTK_CLIST (data);

//  if (!GTK_WIDGET_DRAWABLE (clist) || adjustment != clist->vadjustment)
 //   return;

  value = adjustment->value;

  p = [[GTK_WIDGET(clist)->proxy documentView] bounds].origin;

  p.y = value;

  [[GTK_WIDGET(clist)->proxy documentView] scrollPoint:p];
#if 0
  if (value > -clist->voffset)
    {
      /* scroll down */
      diff = value + clist->voffset;

      /* we have to re-draw the whole screen here... */
      if (diff >= clist->clist_window_height)
	{
	  clist->voffset = -value;
	  draw_rows (clist, NULL);
	  return;
	}

      if ((diff != 0) && (diff != clist->clist_window_height))
	gdk_window_copy_area (clist->clist_window, clist->fg_gc,
			      0, 0, clist->clist_window, 0, diff,
			      clist->clist_window_width,
			      clist->clist_window_height - diff);

      area.x = 0;
      area.y = clist->clist_window_height - diff;
      area.width = clist->clist_window_width;
      area.height = diff;
    }
  else
    {
      /* scroll up */
      diff = -clist->voffset - value;

      /* we have to re-draw the whole screen here... */
      if (diff >= clist->clist_window_height)
	{
	  clist->voffset = -value;
	  draw_rows (clist, NULL);
	  return;
	}

      if ((diff != 0) && (diff != clist->clist_window_height))
	gdk_window_copy_area (clist->clist_window, clist->fg_gc,
			      0, diff, clist->clist_window, 0, 0,
			      clist->clist_window_width,
			      clist->clist_window_height - diff);

      area.x = 0;
      area.y = 0;
      area.width = clist->clist_window_width;
      area.height = diff;
    }

  clist->voffset = -value;
  if ((diff != 0) && (diff != clist->clist_window_height))
    check_exposures (clist);

  draw_rows (clist, &area);
#endif
}

void
hadjustment_value_changed (GtkAdjustment *adjustment,
			   gpointer       data)
{
  GtkCList *clist;
  GdkRectangle area;
  gint i;
  gint y = 0;
  gint diff = 0;
  gint value;

  g_return_if_fail (adjustment != NULL);
  g_return_if_fail (data != NULL);
  g_return_if_fail (GTK_IS_CLIST (data));

  clist = GTK_CLIST (data);

  if (!GTK_WIDGET_DRAWABLE (clist) || adjustment != clist->hadjustment)
    return;

  value = adjustment->value;

#if 0
  /* move the column buttons and resize windows */
  for (i = 0; i < clist->columns; i++)
    {
      if (clist->column[i].button)
	{
	  clist->column[i].button->allocation.x -= value + clist->hoffset;
	  
	  if (clist->column[i].button->window)
	    {
	      gdk_window_move (clist->column[i].button->window,
			       clist->column[i].button->allocation.x,
			       clist->column[i].button->allocation.y);
	      
	      if (clist->column[i].window)
		gdk_window_move (clist->column[i].window,
				 clist->column[i].button->allocation.x +
				 clist->column[i].button->allocation.width - 
				 (DRAG_WIDTH / 2), 0); 
	    }
	}
    }

  if (value > -clist->hoffset)
    {
      /* scroll right */
      diff = value + clist->hoffset;
      
      clist->hoffset = -value;
      
      /* we have to re-draw the whole screen here... */
      if (diff >= clist->clist_window_width)
	{
	  draw_rows (clist, NULL);
	  return;
	}

      if (GTK_WIDGET_CAN_FOCUS(clist) && GTK_WIDGET_HAS_FOCUS(clist) &&
	  !GTK_CLIST_CHILD_HAS_FOCUS(clist) && GTK_CLIST_ADD_MODE(clist))
	{
	  y = ROW_TOP_YPIXEL (clist, clist->focus_row);
	      
	  gdk_draw_rectangle (clist->clist_window, clist->xor_gc, FALSE, 0, y,
			      clist->clist_window_width - 1,
			      clist->row_height - 1);
	}
      gdk_window_copy_area (clist->clist_window,
			    clist->fg_gc,
			    0, 0,
			    clist->clist_window,
			    diff,
			    0,
			    clist->clist_window_width - diff,
			    clist->clist_window_height);

      area.x = clist->clist_window_width - diff;
    }
  else
    {
      /* scroll left */
      if (!(diff = -clist->hoffset - value))
	return;

      clist->hoffset = -value;
      
      /* we have to re-draw the whole screen here... */
      if (diff >= clist->clist_window_width)
	{
	  draw_rows (clist, NULL);
	  return;
	}
      
      if (GTK_WIDGET_CAN_FOCUS(clist) && GTK_WIDGET_HAS_FOCUS(clist) &&
	  !GTK_CLIST_CHILD_HAS_FOCUS(clist) && GTK_CLIST_ADD_MODE(clist))
	{
	  y = ROW_TOP_YPIXEL (clist, clist->focus_row);
	  
	  gdk_draw_rectangle (clist->clist_window, clist->xor_gc, FALSE, 0, y,
			      clist->clist_window_width - 1,
			      clist->row_height - 1);
	}

      gdk_window_copy_area (clist->clist_window,
			    clist->fg_gc,
			    diff, 0,
			    clist->clist_window,
			    0,
			    0,
			    clist->clist_window_width - diff,
			    clist->clist_window_height);
	  
      area.x = 0;
    }

  area.y = 0;
  area.width = diff;
  area.height = clist->clist_window_height;

  check_exposures (clist);

  if (GTK_WIDGET_CAN_FOCUS(clist) && GTK_WIDGET_HAS_FOCUS(clist) &&
      !GTK_CLIST_CHILD_HAS_FOCUS(clist))
    {
      if (GTK_CLIST_ADD_MODE(clist))
	{
	  gint focus_row;
	  
	  focus_row = clist->focus_row;
	  clist->focus_row = -1;
	  draw_rows (clist, &area);
	  clist->focus_row = focus_row;
	  
	  gdk_draw_rectangle (clist->clist_window, clist->xor_gc,
			      FALSE, 0, y, clist->clist_window_width - 1,
			      clist->row_height - 1);
	  return;
	}
      else
	{
	  gint x0;
	  gint x1;
	  
	  if (area.x == 0)
	    {
	      x0 = clist->clist_window_width - 1;
	      x1 = diff;
	    }
	  else
	    {
	      x0 = 0;
	      x1 = area.x - 1;
	    }
	  
	  y = ROW_TOP_YPIXEL (clist, clist->focus_row);
	  gdk_draw_line (clist->clist_window, clist->xor_gc,
			 x0, y + 1, x0, y + clist->row_height - 2);
	  gdk_draw_line (clist->clist_window, clist->xor_gc,
			 x1, y + 1, x1, y + clist->row_height - 2);
	  
	}
    }
  draw_rows (clist, &area);
#endif
}

void
adjust_adjustments (GtkCList *clist,
		    gboolean  block_resize)
{
  NSScrollView *sw = GTK_WIDGET(clist)->proxy;

  if (clist->vadjustment)
    {
      clist->vadjustment->page_size = [sw contentSize].height;
      clist->vadjustment->page_increment = clist->vadjustment->page_size/ 2;
      clist->vadjustment->step_increment = clist->row_height;
      clist->vadjustment->lower = 0;
      clist->vadjustment->upper = [[sw documentView] frame].size.height;//LIST_HEIGHT (clist);

      if ([sw contentSize].height - clist->voffset > [[sw documentView] frame].size.height ||
	  (clist->voffset + (gint)clist->vadjustment->value) != 0)
	{
	  clist->vadjustment->value = MAX (0, ([[sw documentView] frame].size.height -
					       clist->clist_window_height));
	  gtk_signal_emit_by_name (GTK_OBJECT (clist->vadjustment),
				   "value_changed");
	}
      gtk_signal_emit_by_name (GTK_OBJECT (clist->vadjustment), "changed");
    }

  if (clist->hadjustment)
    {
      clist->hadjustment->page_size = clist->clist_window_width;
      clist->hadjustment->page_increment = clist->clist_window_width / 2;
      clist->hadjustment->step_increment = 10;
      clist->hadjustment->lower = 0;
      clist->hadjustment->upper = LIST_WIDTH (clist);

      if (clist->clist_window_width - clist->hoffset > LIST_WIDTH (clist) ||
	  (clist->hoffset + (gint)clist->hadjustment->value) != 0)
	{
	  clist->hadjustment->value = MAX (0, (LIST_WIDTH (clist) -
					       clist->clist_window_width));
	  gtk_signal_emit_by_name (GTK_OBJECT (clist->hadjustment),
				   "value_changed");
	}
      gtk_signal_emit_by_name (GTK_OBJECT (clist->hadjustment), "changed");
    }

  if (!block_resize && (!clist->vadjustment || !clist->hadjustment))
    {
      GtkWidget *widget;
      GtkRequisition requisition;

      widget = GTK_WIDGET (clist);
      gtk_widget_size_request (widget, &requisition);

      if ((!clist->hadjustment &&
	   requisition.width != widget->allocation.width) ||
	  (!clist->vadjustment &&
	   requisition.height != widget->allocation.height))
	gtk_widget_queue_resize (widget);
    }
}


