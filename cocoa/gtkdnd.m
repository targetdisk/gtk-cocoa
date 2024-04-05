//
//  gtkdnd.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#import "NSGtkDnD.h"

#include <gtk/gtk.h>

typedef struct _GtkDragSourceSite GtkDragSourceSite;
typedef struct _GtkDragSourceInfo GtkDragSourceInfo;
typedef struct _GtkDragDestSite GtkDragDestSite;
typedef struct _GtkDragDestInfo GtkDragDestInfo;
typedef struct _GtkDragAnim GtkDragAnim;
typedef struct _GtkDragFindData GtkDragFindData;


extern GdkPixmap   *default_icon_pixmap;
extern GdkPixmap   *default_icon_mask;
extern GdkColormap *default_icon_colormap;
extern gint         default_icon_hot_x;
extern gint         default_icon_hot_y;
extern const char *drag_default_xpm[];

typedef enum 
{
  GTK_DRAG_STATUS_DRAG,
  GTK_DRAG_STATUS_WAIT,
  GTK_DRAG_STATUS_DROP
} GtkDragStatus;

struct _GtkDragSourceSite 
{
  GdkModifierType    start_button_mask;
  GtkTargetList     *target_list;        /* Targets for drag data */
  GdkDragAction      actions;            /* Possible actions */
  GdkColormap       *colormap;	         /* Colormap for drag icon */
  GdkPixmap         *pixmap;             /* Icon for drag data */
  GdkBitmap         *mask;

  /* Stored button press information to detect drag beginning */
  gint               state;
  gint               x, y;
};
  
struct _GtkDragSourceInfo 
{
  GtkWidget         *widget;
  GtkTargetList     *target_list; /* Targets for drag data */
  GdkDragAction      possible_actions; /* Actions allowed by source */
  GdkDragContext    *context;	  /* drag context */
  GtkWidget         *icon_window; /* Window for drag */
  GtkWidget         *ipc_widget;  /* GtkInvisible for grab, message passing */
  GdkCursor         *cursor;	  /* Cursor for drag */
  gint hot_x, hot_y;		  /* Hot spot for drag */
  gint button;			  /* mouse button starting drag */

  GtkDragStatus      status;	  /* drag status */
  GdkEvent          *last_event;  /* motion event waiting for response */

  gint               start_x, start_y; /* Initial position */
  gint               cur_x, cur_y;     /* Current Position */

  GList             *selections;  /* selections we've claimed */
  
  GtkDragDestInfo   *proxy_dest;  /* Set if this is a proxy drag */

  guint              drop_timeout;     /* Timeout for aborting drop */
  guint              destroy_icon : 1; /* If true, destroy icon_window
					*/
};

struct _GtkDragDestSite 
{
  GtkDestDefaults    flags;
  GtkTargetList     *target_list;
  GdkDragAction      actions;
  GdkWindow         *proxy_window;
  GdkDragProtocol    proxy_protocol;
  gboolean           do_proxy : 1;
  gboolean           proxy_coords : 1;
  gboolean           have_drag : 1;
};
  
struct _GtkDragDestInfo 
{
  GtkWidget         *widget;	   /* Widget in which drag is in */
  GdkDragContext    *context;	   /* Drag context */
  GtkDragSourceInfo *proxy_source; /* Set if this is a proxy drag */
  GtkSelectionData  *proxy_data;   /* Set while retrieving proxied data */
  gboolean           dropped : 1;     /* Set after we receive a drop */
  guint32            proxy_drop_time; /* Timestamp for proxied drop */
  gboolean           proxy_drop_wait : 1; /* Set if we are waiting for a
					   * status reply before sending
					   * a proxied drop on.
					   */
  gint               drop_x, drop_y; /* Position of drop */
};

#define DROP_ABORT_TIME 300000

#define ANIM_STEP_TIME 50
#define ANIM_STEP_LENGTH 50
#define ANIM_MIN_STEPS 5
#define ANIM_MAX_STEPS 10

void      gtk_drag_dest_site_destroy   (gpointer            data);
void gtk_drag_source_site_destroy       (gpointer           data);
gint gtk_drag_source_event_cb           (GtkWidget         *widget,
						GdkEvent          *event,
						gpointer           data);

/*************************************************************
 * gtk_drag_source_set:
 *     Register a drop site, and possibly add default behaviors.
 *   arguments:
 *     widget:
 *     start_button_mask: Mask of allowed buttons to start drag
 *     targets:           Table of targets for this source
 *     n_targets:
 *     actions:           Actions allowed for this source
 *   results:
 *************************************************************/

void 
gtk_drag_source_set (GtkWidget            *widget,
		     GdkModifierType       start_button_mask,
		     const GtkTargetEntry *targets,
		     gint                  n_targets,
		     GdkDragAction         actions)
{
  GtkDragSourceSite *site;

  g_return_if_fail (widget != NULL);

  site = gtk_object_get_data (GTK_OBJECT (widget), "gtk-site-data");

  gtk_widget_add_events (widget,
			 gtk_widget_get_events (widget) |
			 GDK_BUTTON_PRESS_MASK | GDK_BUTTON_RELEASE_MASK |
			 GDK_BUTTON_MOTION_MASK);

  if (site)
    {
      if (site->target_list)
	gtk_target_list_unref (site->target_list);
    }
  else
    {
      site = g_new0 (GtkDragSourceSite, 1);
      
      gtk_signal_connect (GTK_OBJECT (widget), "button_press_event",
			  GTK_SIGNAL_FUNC (gtk_drag_source_event_cb),
			  site);
      gtk_signal_connect (GTK_OBJECT (widget), "motion_notify_event",
			  GTK_SIGNAL_FUNC (gtk_drag_source_event_cb),
			  site);
      
      gtk_object_set_data_full (GTK_OBJECT (widget),
				"gtk-site-data", 
				site, gtk_drag_source_site_destroy);
    }

  site->start_button_mask = start_button_mask;

  if (targets)
    site->target_list = gtk_target_list_new (targets, n_targets);
  else
    site->target_list = NULL;

  site->actions = actions;
  
}

/*************************************************************
 * gtk_drag_dest_set:
 *     Register a drop site, and possibly add default behaviors.
 *   arguments:
 *     widget:    
 *     flags:     Which types of default drag behavior to use
 *     targets:   Table of targets that can be accepted
 *     n_targets: Number of of entries in targets
 *     actions:   
 *   results:
 *************************************************************/

void 
gtk_drag_dest_set   (GtkWidget            *widget,
		     GtkDestDefaults       flags,
		     const GtkTargetEntry *targets,
		     gint                  n_targets,
		     GdkDragAction         actions)
{
  GtkDragDestSite *site;
  
  g_return_if_fail (widget != NULL);

  /* HACK, do this in the destroy */
  site = gtk_object_get_data (GTK_OBJECT (widget), "gtk-drag-dest");
  if (site)
    gtk_signal_disconnect_by_data (GTK_OBJECT (widget), site);

  if (GTK_WIDGET_REALIZED (widget))
    gtk_drag_dest_realized (widget);

  gtk_signal_connect (GTK_OBJECT (widget), "realize",
		      GTK_SIGNAL_FUNC (gtk_drag_dest_realized), NULL);

  site = g_new (GtkDragDestSite, 1);

  site->flags = flags;
  site->have_drag = FALSE;
  if (targets)
    site->target_list = gtk_target_list_new (targets, n_targets);
  else
    site->target_list = NULL;

  site->actions = actions;
  site->do_proxy = FALSE;

  gtk_object_set_data_full (GTK_OBJECT (widget), "gtk-drag-dest",
			    site, gtk_drag_dest_site_destroy);
  [widget->proxy registerForDraggedTypes:[NSArray arrayWithObjects:NSStringPboardType, NSFilenamesPboardType, nil]];
}

NSImage *
ns_gtk_dnd_get_drag_source_image(GtkWidget *widget)
{
  GtkDragSourceSite *site;

  site = gtk_object_get_data (GTK_OBJECT (widget), "gtk-site-data");
  if(!site)
	return NULL;
  if(!site->pixmap)
  {
        if(! default_icon_pixmap)
             default_icon_pixmap =   gdk_pixmap_colormap_create_from_xpm_d (NULL,
                           default_icon_colormap,
                           &default_icon_mask,
                           NULL, (gchar **)drag_default_xpm);
        return default_icon_pixmap;
  }
  return site->pixmap;
}


ns_gtk_drag_and_drop(GtkWidget *src, GtkWidget *dst, int x, int y)
{ 
	GtkDragDestSite *dest;
    GtkDragSourceSite *source;
	GtkSelectionData selection_data;
  	GList *tmp_target;
    GList *tmp_source = NULL;
    GtkTargetPair *found = NULL;
	gboolean retval;
	
    memset(&selection_data, 0, sizeof(selection_data));
	source = gtk_object_get_data (src, "gtk-site-data");
	dest = gtk_object_get_data (dst, "gtk-drag-dest");
	if(!dest) return;
	if(!src) return;
  	tmp_target = dest->target_list->list;
  	while (tmp_target)
    {
      	GtkTargetPair *pair = tmp_target->data;
      	tmp_source = source->target_list->list;
		while (tmp_source)
		{
      		GtkTargetPair *other = tmp_source->data;
			if(other->info == pair->info)
			{
				if ((!(pair->flags & GTK_TARGET_SAME_APP) || src) &&
				  (!(pair->flags & GTK_TARGET_SAME_WIDGET) || (src == dst)))
				{	
					found = pair;
					goto found_target;
				}
				else
					break;
			}	
		  tmp_source = tmp_source->next;
		}
      	tmp_target = tmp_target->next;
    }
	if(!found) return;
found_target:
 	gtk_signal_emit_by_name (src, "drag_data_get",
				       NULL, &selection_data,
				       found->info, 
				       0);

	gtk_signal_emit_by_name (dst, 
					 "drag_data_received",
					 NULL, x, y,
					 &selection_data, 
					 found->info, 0);
    gtk_signal_emit_by_name (dst, "drag_drop",
			       NULL, x, y, 0, &retval);
}
