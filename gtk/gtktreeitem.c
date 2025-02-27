/* GTK - The GIMP Toolkit
 * Copyright (C) 1995-1997 Peter Mattis, Spencer Kimball and Josh MacDonald
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/*
 * Modified by the GTK+ Team and others 1997-1999.  See the AUTHORS
 * file for a list of people on the GTK+ Team.  See the ChangeLog
 * files for a list of changes.  These files are distributed with
 * GTK+ at ftp://ftp.gtk.org/pub/gtk/. 
 */

#include "gtklabel.h"
#include "gtktree.h"
#include "gtktreeitem.h"
#include "gtkeventbox.h"
#include "gtkpixmap.h"
#include "gtkmain.h"
#include "gtksignal.h"

#include "tree_plus.xpm"
#include "tree_minus.xpm"

#define DEFAULT_DELTA 9

enum {
  COLLAPSE_TREE,
  EXPAND_TREE,
  LAST_SIGNAL
};

typedef struct _GtkTreePixmaps GtkTreePixmaps;

struct _GtkTreePixmaps {
  gint refcount;
  GdkColormap *colormap;
  
  GdkPixmap *pixmap_plus;
  GdkPixmap *pixmap_minus;
  GdkBitmap *mask_plus;
  GdkBitmap *mask_minus;
};

static GList *pixmaps = NULL;
static void gtk_tree_item_class_init (GtkTreeItemClass *klass);
static void gtk_tree_item_init       (GtkTreeItem      *tree_item);
static void gtk_tree_item_realize       (GtkWidget        *widget);
static void gtk_tree_item_size_request  (GtkWidget        *widget,
					 GtkRequisition   *requisition);
static void gtk_tree_item_size_allocate (GtkWidget        *widget,
					 GtkAllocation    *allocation);
static void gtk_tree_item_draw          (GtkWidget        *widget,
					 GdkRectangle     *area);
static void gtk_tree_item_draw_focus    (GtkWidget        *widget);
static void gtk_tree_item_paint         (GtkWidget        *widget,
					 GdkRectangle     *area);
static gint gtk_tree_item_button_press  (GtkWidget        *widget,
					 GdkEventButton   *event);
static gint gtk_tree_item_expose        (GtkWidget        *widget,
					 GdkEventExpose   *event);
static gint gtk_tree_item_focus_in      (GtkWidget        *widget,
					 GdkEventFocus    *event);
static gint gtk_tree_item_focus_out     (GtkWidget        *widget,
					 GdkEventFocus    *event);
static void gtk_tree_item_forall        (GtkContainer    *container,
					 gboolean         include_internals,
					 GtkCallback      callback,
					 gpointer         callback_data);

static void gtk_real_tree_item_select   (GtkItem          *item);
static void gtk_real_tree_item_deselect (GtkItem          *item);
static void gtk_real_tree_item_toggle   (GtkItem          *item);
static void gtk_real_tree_item_expand   (GtkTreeItem      *item);
static void gtk_real_tree_item_collapse (GtkTreeItem      *item);
static void gtk_real_tree_item_expand   (GtkTreeItem      *item);
static void gtk_real_tree_item_collapse (GtkTreeItem      *item);
static void gtk_tree_item_destroy        (GtkObject *object);
static void gtk_tree_item_subtree_button_click (GtkWidget *widget);
static void gtk_tree_item_subtree_button_changed_state (GtkWidget *widget);

static void gtk_tree_item_map(GtkWidget*);
static void gtk_tree_item_unmap(GtkWidget*);

static void gtk_tree_item_add_pixmaps    (GtkTreeItem       *tree_item);
static void gtk_tree_item_remove_pixmaps (GtkTreeItem       *tree_item);

static GtkItemClass *parent_class = NULL;
static guint tree_item_signals[LAST_SIGNAL] = { 0 };

GtkType
gtk_tree_item_get_type (void)
{
  static GtkType tree_item_type = 0;

  if (!tree_item_type)
    {
      static const GtkTypeInfo tree_item_info =
      {
	"GtkTreeItem",
	sizeof (GtkTreeItem),
	sizeof (GtkTreeItemClass),
	(GtkClassInitFunc) gtk_tree_item_class_init,
	(GtkObjectInitFunc) gtk_tree_item_init,
	/* reserved_1 */ NULL,
        /* reserved_2 */ NULL,
        (GtkClassInitFunc) NULL,
      };

      tree_item_type = gtk_type_unique (gtk_item_get_type (), &tree_item_info);
    }

  return tree_item_type;
}

static void
gtk_tree_item_class_init (GtkTreeItemClass *class)
{
  GtkObjectClass *object_class;
  GtkWidgetClass *widget_class;
  GtkContainerClass *container_class;
  GtkItemClass *item_class;

  object_class = (GtkObjectClass*) class;
  widget_class = (GtkWidgetClass*) class;
  item_class = (GtkItemClass*) class;
  container_class = (GtkContainerClass*) class;

  parent_class = gtk_type_class (gtk_item_get_type ());
  
  tree_item_signals[EXPAND_TREE] =
    gtk_signal_new ("expand",
		    GTK_RUN_FIRST,
		    object_class->type,
		    GTK_SIGNAL_OFFSET (GtkTreeItemClass, expand),
		    gtk_marshal_NONE__NONE,
		    GTK_TYPE_NONE, 0);
  tree_item_signals[COLLAPSE_TREE] =
    gtk_signal_new ("collapse",
		    GTK_RUN_FIRST,
		    object_class->type,
		    GTK_SIGNAL_OFFSET (GtkTreeItemClass, collapse),
		    gtk_marshal_NONE__NONE,
		    GTK_TYPE_NONE, 0);

  gtk_object_class_add_signals (object_class, tree_item_signals, LAST_SIGNAL);

  object_class->destroy = gtk_tree_item_destroy;

  widget_class->realize = gtk_tree_item_realize;
  widget_class->size_request = gtk_tree_item_size_request;
  widget_class->size_allocate = gtk_tree_item_size_allocate;
  widget_class->draw = gtk_tree_item_draw;
  widget_class->draw_focus = gtk_tree_item_draw_focus;
  widget_class->button_press_event = gtk_tree_item_button_press;
  widget_class->expose_event = gtk_tree_item_expose;
  widget_class->focus_in_event = gtk_tree_item_focus_in;
  widget_class->focus_out_event = gtk_tree_item_focus_out;
  widget_class->map = gtk_tree_item_map;
  widget_class->unmap = gtk_tree_item_unmap;

  container_class->forall = gtk_tree_item_forall;

  item_class->select = gtk_real_tree_item_select;
  item_class->deselect = gtk_real_tree_item_deselect;
  item_class->toggle = gtk_real_tree_item_toggle;

  class->expand = gtk_real_tree_item_expand;
  class->collapse = gtk_real_tree_item_collapse;
}

/* callback for event box mouse event */
static void 
gtk_tree_item_subtree_button_click (GtkWidget *widget)
{
  GtkTreeItem* item;
  
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_EVENT_BOX (widget));
  
  item = (GtkTreeItem*) gtk_object_get_user_data (GTK_OBJECT (widget));
  if (!GTK_WIDGET_IS_SENSITIVE (item))
    return;
  
  if (item->expanded)
    gtk_tree_item_collapse (item);
  else
    gtk_tree_item_expand (item);
}

/* callback for event box state changed */
static void
gtk_tree_item_subtree_button_changed_state (GtkWidget *widget)
{
#if 0
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_EVENT_BOX (widget));
  
  if (GTK_WIDGET_VISIBLE (widget))
    {
      
      if (widget->state == GTK_STATE_NORMAL)
	gdk_window_set_background (widget->window, &widget->style->base[widget->state]);
      else
	gdk_window_set_background (widget->window, &widget->style->bg[widget->state]);
      
      if (GTK_WIDGET_DRAWABLE (widget))
	gdk_window_clear_area (widget->window, 0, 0, 
			       widget->allocation.width, widget->allocation.height);
    }
#endif
}

static void
gtk_tree_item_init (GtkTreeItem *tree_item)
{
  GtkWidget *eventbox, *pixmapwid;
  
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));

  tree_item->expanded = FALSE;
  tree_item->subtree = NULL;
  GTK_WIDGET_SET_FLAGS (tree_item, GTK_CAN_FOCUS);
  
  /* create an event box containing one pixmaps */
  eventbox = gtk_event_box_new();
  gtk_widget_set_events (eventbox, GDK_BUTTON_PRESS_MASK);
  gtk_signal_connect(GTK_OBJECT(eventbox), "state_changed",
		     (GtkSignalFunc)gtk_tree_item_subtree_button_changed_state, 
		     (gpointer)NULL);
  gtk_signal_connect(GTK_OBJECT(eventbox), "realize",
		     (GtkSignalFunc)gtk_tree_item_subtree_button_changed_state, 
		     (gpointer)NULL);
  gtk_signal_connect(GTK_OBJECT(eventbox), "button_press_event",
		     (GtkSignalFunc)gtk_tree_item_subtree_button_click,
		     (gpointer)NULL);
  gtk_object_set_user_data(GTK_OBJECT(eventbox), tree_item);
  tree_item->pixmaps_box = eventbox;

  /* create pixmap for button '+' */
  pixmapwid = gtk_type_new (gtk_pixmap_get_type ());
  if (!tree_item->expanded) 
    gtk_container_add (GTK_CONTAINER (eventbox), pixmapwid);
  gtk_widget_show (pixmapwid);
  tree_item->plus_pix_widget = pixmapwid;
  gtk_widget_ref (tree_item->plus_pix_widget);
  gtk_object_sink (GTK_OBJECT (tree_item->plus_pix_widget));
  
  /* create pixmap for button '-' */
  pixmapwid = gtk_type_new (gtk_pixmap_get_type ());
  if (tree_item->expanded) 
    gtk_container_add (GTK_CONTAINER (eventbox), pixmapwid);
  gtk_widget_show (pixmapwid);
  tree_item->minus_pix_widget = pixmapwid;
  gtk_widget_ref (tree_item->minus_pix_widget);
  gtk_object_sink (GTK_OBJECT (tree_item->minus_pix_widget));
  
  gtk_widget_set_parent (eventbox, GTK_WIDGET (tree_item));
}


GtkWidget*
gtk_tree_item_new (void)
{
  GtkWidget *tree_item;

  tree_item = GTK_WIDGET (gtk_type_new (gtk_tree_item_get_type ()));

  return tree_item;
}

void
gtk_tree_item_set_subtree (GtkTreeItem *tree_item,
			   GtkWidget   *subtree)
{
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));
  g_return_if_fail (subtree != NULL);
  g_return_if_fail (GTK_IS_TREE (subtree));

  if (tree_item->subtree)
    {
      g_warning("there is already a subtree for this tree item\n");
      return;
    }

  tree_item->subtree = subtree; 
  GTK_TREE (subtree)->tree_owner = GTK_WIDGET (tree_item);

  /* show subtree button */
  if (tree_item->pixmaps_box)
    gtk_widget_show (tree_item->pixmaps_box);

  if (tree_item->expanded)
    gtk_widget_show (subtree);
  else
    gtk_widget_hide (subtree);

  gtk_widget_set_parent (subtree, GTK_WIDGET (tree_item)->parent);

  if (GTK_WIDGET_REALIZED (subtree->parent))
    gtk_widget_realize (subtree);

  if (GTK_WIDGET_VISIBLE (subtree->parent) && GTK_WIDGET_VISIBLE (subtree))
    {
      if (GTK_WIDGET_MAPPED (subtree->parent))
	gtk_widget_map (subtree);

      gtk_widget_queue_resize (subtree);
    }
}

void
gtk_tree_item_select (GtkTreeItem *tree_item)
{
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));

  gtk_item_select (GTK_ITEM (tree_item));
}

void
gtk_tree_item_deselect (GtkTreeItem *tree_item)
{
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));

  gtk_item_deselect (GTK_ITEM (tree_item));
}

void
gtk_tree_item_expand (GtkTreeItem *tree_item)
{
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));

  gtk_signal_emit (GTK_OBJECT (tree_item), tree_item_signals[EXPAND_TREE], NULL);
}

void
gtk_tree_item_collapse (GtkTreeItem *tree_item)
{
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));

  gtk_signal_emit (GTK_OBJECT (tree_item), tree_item_signals[COLLAPSE_TREE], NULL);
}

static void
gtk_tree_item_add_pixmaps (GtkTreeItem *tree_item)
{
#if 0
  GList *tmp_list;
  GdkColormap *colormap;
  GtkTreePixmaps *pixmap_node = NULL;

  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));

  if (tree_item->pixmaps)
    return;

  colormap = gtk_widget_get_colormap (GTK_WIDGET (tree_item));

  tmp_list = pixmaps;
  while (tmp_list)
    {
      pixmap_node = (GtkTreePixmaps *)tmp_list->data;

      if (pixmap_node->colormap == colormap)
	break;
      
      tmp_list = tmp_list->next;
    }

  if (tmp_list)
    {
      pixmap_node->refcount++;
      tree_item->pixmaps = tmp_list;
    }
  else
    {
      pixmap_node = g_new (GtkTreePixmaps, 1);

      pixmap_node->colormap = colormap;
      gdk_colormap_ref (colormap);

      pixmap_node->refcount = 1;

      /* create pixmaps for plus icon */
      pixmap_node->pixmap_plus = 
	gdk_pixmap_create_from_xpm_d (GTK_WIDGET (tree_item)->window,
				      &pixmap_node->mask_plus,
				      NULL,
				      tree_plus);
      
      /* create pixmaps for minus icon */
      pixmap_node->pixmap_minus = 
	gdk_pixmap_create_from_xpm_d (GTK_WIDGET (tree_item)->window,
				      &pixmap_node->mask_minus,
				      NULL,
				      tree_minus);

      tree_item->pixmaps = pixmaps = g_list_prepend (pixmaps, pixmap_node);
    }
  
  gtk_pixmap_set (GTK_PIXMAP (tree_item->plus_pix_widget), 
		  pixmap_node->pixmap_plus, pixmap_node->mask_plus);
  gtk_pixmap_set (GTK_PIXMAP (tree_item->minus_pix_widget), 
		  pixmap_node->pixmap_minus, pixmap_node->mask_minus);
#endif
}

static void
gtk_tree_item_remove_pixmaps (GtkTreeItem *tree_item)
{
#if 0
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));

  if (tree_item->pixmaps)
    {
      GtkTreePixmaps *pixmap_node = (GtkTreePixmaps *)tree_item->pixmaps->data;
      
      g_assert (pixmap_node->refcount > 0);
      
      if (--pixmap_node->refcount == 0)
	{
	  gdk_colormap_unref (pixmap_node->colormap);
	  gdk_pixmap_unref (pixmap_node->pixmap_plus);
	  gdk_bitmap_unref (pixmap_node->mask_plus);
	  gdk_pixmap_unref (pixmap_node->pixmap_minus);
	  gdk_bitmap_unref (pixmap_node->mask_minus);
	  
	  pixmaps = g_list_remove_link (pixmaps, tree_item->pixmaps);
	  g_list_free_1 (tree_item->pixmaps);
	  g_free (pixmap_node);
	}

      tree_item->pixmaps = NULL;
    }
#endif
}

static void
gtk_tree_item_realize (GtkWidget *widget)
{    
#if 0
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));

  if (GTK_WIDGET_CLASS (parent_class)->realize)
    (* GTK_WIDGET_CLASS (parent_class)->realize) (widget);
  
  gdk_window_set_background (widget->window, 
			     &widget->style->base[GTK_STATE_NORMAL]);

  gtk_tree_item_add_pixmaps (GTK_TREE_ITEM (widget));
#endif
}

static void
gtk_tree_item_size_request (GtkWidget      *widget,
			    GtkRequisition *requisition)
{
  GtkBin *bin;
  GtkTreeItem* item;
  GtkRequisition child_requisition;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));
  g_return_if_fail (requisition != NULL);

  bin = GTK_BIN (widget);
  item = GTK_TREE_ITEM(widget);

  requisition->width = (GTK_CONTAINER (widget)->border_width) *2;
//			widget->style->klass->xthickness) * 2;
  requisition->height = GTK_CONTAINER (widget)->border_width * 2;

  if (bin->child && GTK_WIDGET_VISIBLE (bin->child))
    {
      GtkRequisition pix_requisition;
      
      gtk_widget_size_request (bin->child, &child_requisition);

      requisition->width += child_requisition.width;

      gtk_widget_size_request (item->pixmaps_box, 
			       &pix_requisition);
      requisition->width += pix_requisition.width + DEFAULT_DELTA + 
	GTK_TREE (widget->parent)->current_indent;

      requisition->height += MAX (child_requisition.height,
				  pix_requisition.height);
    }
}

static void
gtk_tree_item_size_allocate (GtkWidget     *widget,
			     GtkAllocation *allocation)
{
  GtkBin *bin;
  GtkTreeItem* item;
  GtkAllocation child_allocation;
  gint border_width;
  int temp;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));
  g_return_if_fail (allocation != NULL);

  widget->allocation = *allocation;
#if 0
  if (GTK_WIDGET_REALIZED (widget))
    gdk_window_move_resize (widget->window,
			    allocation->x, allocation->y,
			    allocation->width, allocation->height);
#endif

  bin = GTK_BIN (widget);
  item = GTK_TREE_ITEM(widget);

  if (bin->child)
    {
      border_width = (GTK_CONTAINER (widget)->border_width );
		      //widget->style->klass->xthickness);

      child_allocation.x = border_width + GTK_TREE(widget->parent)->current_indent;
      child_allocation.y = allocation->y + GTK_CONTAINER (widget)->border_width;

      child_allocation.width = item->pixmaps_box->requisition.width;
      child_allocation.height = item->pixmaps_box->requisition.height;
      
      temp = allocation->height - child_allocation.height;
      child_allocation.y += ( temp / 2 ) + ( temp % 2 );

      gtk_widget_size_allocate (item->pixmaps_box, &child_allocation);

      child_allocation.y = GTK_CONTAINER (widget)->border_width;
      child_allocation.height = MAX (1, (gint)allocation->height - child_allocation.y * 2);
	  child_allocation.y += allocation->y;
      child_allocation.x += item->pixmaps_box->requisition.width+DEFAULT_DELTA;

      child_allocation.width = 
	MAX (1, (gint)allocation->width - ((gint)child_allocation.x + border_width));

      gtk_widget_size_allocate (bin->child, &child_allocation);
    }
}

static void 
gtk_tree_item_draw_lines (GtkWidget *widget) 
{
#if 0
  GtkTreeItem* item;
  GtkTree* tree;
  guint lx1, ly1, lx2, ly2;
  GdkGC* gc;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));

  item = GTK_TREE_ITEM(widget);
  tree = GTK_TREE(widget->parent);

  if (!tree->view_line)
    return;

  gc = widget->style->text_gc[GTK_STATE_NORMAL];

  /* draw vertical line */
  lx1 = item->pixmaps_box->allocation.width;
  lx1 = lx2 = ((lx1 / 2) + (lx1 % 2) + 
	       GTK_CONTAINER (widget)->border_width + 1 + tree->current_indent);
  ly1 = 0;
  ly2 = widget->allocation.height;

  if (g_list_last (tree->children)->data == widget)
    ly2 = (ly2 / 2) + (ly2 % 2);

  if (tree != tree->root_tree)
    gdk_draw_line (widget->window, gc, lx1, ly1, lx2, ly2);

  /* draw vertical line for subtree connecting */
  if(g_list_last(tree->children)->data != (gpointer)widget)
    ly2 = (ly2 / 2) + (ly2 % 2);
  
  lx2 += DEFAULT_DELTA;

  if (item->subtree && item->expanded)
    gdk_draw_line (widget->window, gc,
		   lx2, ly2, lx2, widget->allocation.height);

  /* draw horizontal line */
  ly1 = ly2;
  lx2 += 2;

  gdk_draw_line (widget->window, gc, lx1, ly1, lx2, ly2);

  lx2 -= DEFAULT_DELTA+2;
  ly1 = 0;
  ly2 = widget->allocation.height;

  if (tree != tree->root_tree)
    {
      item = GTK_TREE_ITEM (tree->tree_owner);
      tree = GTK_TREE (GTK_WIDGET (tree)->parent);
      while (tree != tree->root_tree)
	{
	  lx1 = lx2 -= tree->indent_value;
	  
	  if (g_list_last (tree->children)->data != item)
	    gdk_draw_line (widget->window, gc, lx1, ly1, lx2, ly2);
	  item = GTK_TREE_ITEM (tree->tree_owner);
	  tree = GTK_TREE (GTK_WIDGET (tree)->parent);
	} 
    }
#endif
}

static void
gtk_tree_item_paint (GtkWidget    *widget,
		     GdkRectangle *area)
{
#if 0
  GtkBin *bin;
  GdkRectangle child_area, item_area;
  GtkTreeItem* tree_item;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));
  g_return_if_fail (area != NULL);

  /* FIXME: We should honor tree->view_mode, here - I think
   * the desired effect is that when the mode is VIEW_ITEM,
   * only the subitem is drawn as selected, not the entire
   * line. (Like the way that the tree in Windows Explorer
   * works).
   */
  if (GTK_WIDGET_DRAWABLE (widget))
    {
      bin = GTK_BIN (widget);
      tree_item = GTK_TREE_ITEM(widget);

      if (widget->state == GTK_STATE_NORMAL)
	{
	  gdk_window_set_back_pixmap (widget->window, NULL, TRUE);
	  gdk_window_clear_area (widget->window, area->x, area->y, area->width, area->height);
	}
      else 
	{
	  if (!GTK_WIDGET_IS_SENSITIVE (widget)) 
	    gtk_paint_flat_box(widget->style, widget->window,
			       widget->state, GTK_STATE_INSENSITIVE,
			       area, widget, "treeitem",
			       0, 0, -1, -1);
	  else
	    gtk_paint_flat_box(widget->style, widget->window,
			       widget->state, GTK_SHADOW_ETCHED_OUT,
			       area, widget, "treeitem",
			       0, 0, -1, -1);
	}

      /* draw left size of tree item */
      item_area.x = 0;
      item_area.y = 0;
      item_area.width = (tree_item->pixmaps_box->allocation.width + DEFAULT_DELTA +
			 GTK_TREE (widget->parent)->current_indent + 2);
      item_area.height = widget->allocation.height;


      if (gdk_rectangle_intersect(&item_area, area, &child_area)) 
	{
	  
	  gtk_tree_item_draw_lines(widget);

	  if (tree_item->pixmaps_box && 
	      GTK_WIDGET_VISIBLE(tree_item->pixmaps_box) &&
	      gtk_widget_intersect (tree_item->pixmaps_box, area, &child_area))
	    gtk_widget_draw (tree_item->pixmaps_box, &child_area);
	}

      if (GTK_WIDGET_HAS_FOCUS (widget))
	gtk_paint_focus (widget->style, widget->window,
			 NULL, widget, "treeitem",
			 0, 0,
			 widget->allocation.width - 1,
			 widget->allocation.height - 1);
      
    }
#endif
}

static void
gtk_tree_item_draw (GtkWidget    *widget,
		    GdkRectangle *area)
{
  GtkBin *bin;
  GdkRectangle child_area;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));
  g_return_if_fail (area != NULL);

  if (GTK_WIDGET_DRAWABLE (widget))
    {
      bin = GTK_BIN (widget);

      gtk_tree_item_paint (widget, area);
     
      if (bin->child && 
	  gtk_widget_intersect (bin->child, area, &child_area))
	gtk_widget_draw (bin->child, &child_area);

    }
}

static void
gtk_tree_item_draw_focus (GtkWidget *widget)
{
  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));

  gtk_widget_draw(widget, NULL);
}

static gint
gtk_tree_item_button_press (GtkWidget      *widget,
			    GdkEventButton *event)
{

  g_return_val_if_fail (widget != NULL, FALSE);
  g_return_val_if_fail (GTK_IS_TREE_ITEM (widget), FALSE);
  g_return_val_if_fail (event != NULL, FALSE);

  if (event->type == GDK_BUTTON_PRESS
	&& GTK_WIDGET_IS_SENSITIVE(widget)
     	&& !GTK_WIDGET_HAS_FOCUS (widget))
      gtk_widget_grab_focus (widget);

  return FALSE;
}

static gint
gtk_tree_item_expose (GtkWidget      *widget,
		      GdkEventExpose *event)
{
  GdkEventExpose child_event;
  GtkBin *bin;

  g_return_val_if_fail (widget != NULL, FALSE);
  g_return_val_if_fail (GTK_IS_TREE_ITEM (widget), FALSE);
  g_return_val_if_fail (event != NULL, FALSE);

  if (GTK_WIDGET_DRAWABLE (widget))
    {
      bin = GTK_BIN (widget);
      
      gtk_tree_item_paint (widget, &event->area);

      child_event = *event;
      if (bin->child && GTK_WIDGET_NO_WINDOW (bin->child) &&
	  gtk_widget_intersect (bin->child, &event->area, &child_event.area))
	gtk_widget_event (bin->child, (GdkEvent*) &child_event);
   }

  return FALSE;
}

static gint
gtk_tree_item_focus_in (GtkWidget     *widget,
			GdkEventFocus *event)
{
  g_return_val_if_fail (widget != NULL, FALSE);
  g_return_val_if_fail (GTK_IS_TREE_ITEM (widget), FALSE);
  g_return_val_if_fail (event != NULL, FALSE);

  GTK_WIDGET_SET_FLAGS (widget, GTK_HAS_FOCUS);
  gtk_widget_draw_focus (widget);


  return FALSE;
}

static gint
gtk_tree_item_focus_out (GtkWidget     *widget,
			 GdkEventFocus *event)
{
  g_return_val_if_fail (widget != NULL, FALSE);
  g_return_val_if_fail (GTK_IS_TREE_ITEM (widget), FALSE);
  g_return_val_if_fail (event != NULL, FALSE);

  GTK_WIDGET_UNSET_FLAGS (widget, GTK_HAS_FOCUS);
  gtk_widget_draw_focus (widget);


  return FALSE;
}

static void
gtk_real_tree_item_select (GtkItem *item)
{    
  GtkTreeItem *tree_item;
  GtkWidget *widget;

  g_return_if_fail (item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (item));

  tree_item = GTK_TREE_ITEM (item);
  widget = GTK_WIDGET (item);

  gtk_widget_set_state (GTK_WIDGET (item), GTK_STATE_SELECTED);

  if (!widget->parent || GTK_TREE (widget->parent)->view_mode == GTK_TREE_VIEW_LINE)
    gtk_widget_set_state (GTK_TREE_ITEM (item)->pixmaps_box, GTK_STATE_SELECTED);
}

static void
gtk_real_tree_item_deselect (GtkItem *item)
{
  GtkTreeItem *tree_item;
  GtkWidget *widget;

  g_return_if_fail (item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (item));

  tree_item = GTK_TREE_ITEM (item);
  widget = GTK_WIDGET (item);

  gtk_widget_set_state (widget, GTK_STATE_NORMAL);

  if (!widget->parent || GTK_TREE (widget->parent)->view_mode == GTK_TREE_VIEW_LINE)
    gtk_widget_set_state (tree_item->pixmaps_box, GTK_STATE_NORMAL);
}

static void
gtk_real_tree_item_toggle (GtkItem *item)
{
  g_return_if_fail (item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (item));

  if(!GTK_WIDGET_IS_SENSITIVE(item))
    return;

  if (GTK_WIDGET (item)->parent && GTK_IS_TREE (GTK_WIDGET (item)->parent))
    gtk_tree_select_child (GTK_TREE (GTK_WIDGET (item)->parent),
			   GTK_WIDGET (item));
  else
    {
      /* Should we really bother with this bit? A listitem not in a list?
       * -Johannes Keukelaar
       * yes, always be on the safe side!
       * -timj
       */
      if (GTK_WIDGET (item)->state == GTK_STATE_SELECTED)
	gtk_widget_set_state (GTK_WIDGET (item), GTK_STATE_NORMAL);
      else
	gtk_widget_set_state (GTK_WIDGET (item), GTK_STATE_SELECTED);
    }
}

static void
gtk_real_tree_item_expand (GtkTreeItem *tree_item)
{
  GtkTree* tree;
  
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));
  
  if (tree_item->subtree && !tree_item->expanded)
    {
      tree = GTK_TREE (GTK_WIDGET (tree_item)->parent); 
      
      /* hide subtree widget */
      gtk_widget_show (tree_item->subtree);
      
      /* hide button '+' and show button '-' */
      if (tree_item->pixmaps_box)
	{
	  gtk_container_remove (GTK_CONTAINER (tree_item->pixmaps_box), 
				tree_item->plus_pix_widget);
	  gtk_container_add (GTK_CONTAINER (tree_item->pixmaps_box), 
			     tree_item->minus_pix_widget);
	}
      if (tree->root_tree)
	gtk_widget_queue_resize (GTK_WIDGET (tree->root_tree));
      tree_item->expanded = TRUE;
    }
}

static void
gtk_real_tree_item_collapse (GtkTreeItem *tree_item)
{
  GtkTree* tree;
  
  g_return_if_fail (tree_item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (tree_item));
  
  if (tree_item->subtree && tree_item->expanded) 
    {
      tree = GTK_TREE (GTK_WIDGET (tree_item)->parent);
      
      /* hide subtree widget */
      gtk_widget_hide (tree_item->subtree);
      
      /* hide button '-' and show button '+' */
      if (tree_item->pixmaps_box)
	{
	  gtk_container_remove (GTK_CONTAINER (tree_item->pixmaps_box), 
				tree_item->minus_pix_widget);
	  gtk_container_add (GTK_CONTAINER (tree_item->pixmaps_box), 
			     tree_item->plus_pix_widget);
	}
      if (tree->root_tree)
	gtk_widget_queue_resize (GTK_WIDGET (tree->root_tree));
      tree_item->expanded = FALSE;
    }
}

static void
gtk_tree_item_destroy (GtkObject *object)
{
  GtkTreeItem* item;
  GtkWidget* child;

  g_return_if_fail (object != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (object));

#ifdef TREE_DEBUG
  g_message("+ gtk_tree_item_destroy [object %#x]\n", (int)object);
#endif /* TREE_DEBUG */

  item = GTK_TREE_ITEM(object);

  /* free sub tree if it exist */
  child = item->subtree;
  if (child)
    {
      gtk_widget_ref (child);
      gtk_widget_unparent (child);
      gtk_widget_destroy (child);
      gtk_widget_unref (child);
      item->subtree = NULL;
    }
  
  /* free pixmaps box */
  child = item->pixmaps_box;
  if (child)
    {
      gtk_widget_ref (child);
      gtk_widget_unparent (child);
      gtk_widget_destroy (child);
      gtk_widget_unref (child);
      item->pixmaps_box = NULL;
    }
  
  
  /* destroy plus pixmap */
  if (item->plus_pix_widget)
    {
      gtk_widget_destroy (item->plus_pix_widget);
      gtk_widget_unref (item->plus_pix_widget);
      item->plus_pix_widget = NULL;
    }
  
  /* destroy minus pixmap */
  if (item->minus_pix_widget)
    {
      gtk_widget_destroy (item->minus_pix_widget);
      gtk_widget_unref (item->minus_pix_widget);
      item->minus_pix_widget = NULL;
    }
  
  /* By removing the pixmaps here, and not in unrealize, we depend on
   * the fact that a widget can never change colormap or visual.
   */
  gtk_tree_item_remove_pixmaps (item);
  
  GTK_OBJECT_CLASS (parent_class)->destroy (object);
  
#ifdef TREE_DEBUG
  g_message("- gtk_tree_item_destroy\n");
#endif /* TREE_DEBUG */
}

void
gtk_tree_item_remove_subtree (GtkTreeItem* item) 
{
  g_return_if_fail (item != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM(item));
  g_return_if_fail (item->subtree != NULL);
  
  if (GTK_TREE (item->subtree)->children)
    {
      /* The following call will remove the children and call
       * gtk_tree_item_remove_subtree() again. So we are done.
       */
      gtk_tree_remove_items (GTK_TREE (item->subtree), 
			     GTK_TREE (item->subtree)->children);
      return;
    }

  if (GTK_WIDGET_MAPPED (item->subtree))
    gtk_widget_unmap (item->subtree);
      
  gtk_widget_unparent (item->subtree);
  
  if (item->pixmaps_box)
    gtk_widget_hide (item->pixmaps_box);
  
  item->subtree = NULL;

  if (item->expanded)
    {
      item->expanded = FALSE;
      if (item->pixmaps_box)
	{
	  gtk_container_remove (GTK_CONTAINER (item->pixmaps_box), 
				item->minus_pix_widget);
	  gtk_container_add (GTK_CONTAINER (item->pixmaps_box), 
			     item->plus_pix_widget);
	}
    }
}

static void
gtk_tree_item_map (GtkWidget *widget)
{
#if 0
  GtkBin *bin;
  GtkTreeItem* item;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));

  bin = GTK_BIN (widget);
  item = GTK_TREE_ITEM(widget);

  GTK_WIDGET_SET_FLAGS (widget, GTK_MAPPED);

  if(item->pixmaps_box &&
     GTK_WIDGET_VISIBLE (item->pixmaps_box) &&
     !GTK_WIDGET_MAPPED (item->pixmaps_box))
    gtk_widget_map (item->pixmaps_box);

  if (bin->child &&
      GTK_WIDGET_VISIBLE (bin->child) &&
      !GTK_WIDGET_MAPPED (bin->child))
    gtk_widget_map (bin->child);

  gdk_window_show (widget->window);
#endif
}

static void
gtk_tree_item_unmap (GtkWidget *widget)
{
#if 0
  GtkBin *bin;
  GtkTreeItem* item;

  g_return_if_fail (widget != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (widget));

  GTK_WIDGET_UNSET_FLAGS (widget, GTK_MAPPED);
  bin = GTK_BIN (widget);
  item = GTK_TREE_ITEM(widget);

  gdk_window_hide (widget->window);

  if(item->pixmaps_box &&
     GTK_WIDGET_VISIBLE (item->pixmaps_box) &&
     GTK_WIDGET_MAPPED (item->pixmaps_box))
    gtk_widget_unmap (bin->child);

  if (bin->child &&
      GTK_WIDGET_VISIBLE (bin->child) &&
      GTK_WIDGET_MAPPED (bin->child))
    gtk_widget_unmap (bin->child);
#endif
}

static void
gtk_tree_item_forall (GtkContainer *container,
		      gboolean      include_internals,
		      GtkCallback   callback,
		      gpointer      callback_data)
{
  GtkBin *bin;
  GtkTreeItem *tree_item;

  g_return_if_fail (container != NULL);
  g_return_if_fail (GTK_IS_TREE_ITEM (container));
  g_return_if_fail (callback != NULL);

  bin = GTK_BIN (container);
  tree_item = GTK_TREE_ITEM (container);

  if (bin->child)
    (* callback) (bin->child, callback_data);
  if (include_internals && tree_item->subtree)
    (* callback) (tree_item->subtree, callback_data);
}
