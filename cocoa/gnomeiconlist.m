//
//  gnomeiconlist.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 10 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "NSGtkMatrix.h"

#include <gtk/gtk.h>
#include "gnome-icon-list.h"

/* Aliases to minimize screen use in my laptop */
#define GIL(x)       GNOME_ICON_LIST(x)
#define GIL_CLASS(x) GNOME_ICON_LIST_CLASS(x)
#define IS_GIL(x)    GNOME_IS_ICON_LIST(x)

/* default spacings */
#define DEFAULT_ROW_SPACING  4
#define DEFAULT_COL_SPACING  2
#define DEFAULT_TEXT_SPACING 2
#define DEFAULT_ICON_BORDER  2

/* Autoscroll timeout in milliseconds */
#define SCROLL_TIMEOUT 30

typedef GnomeIconList Gil;
typedef GnomeIconListClass GilClass;
typedef GnomeIconListPrivate GilPrivate;

/* Icon structure */
typedef struct {
	/* Icon image and text items */
	GdkImlibImage *image;
	char *text;

	/* Filename of the icon file. */
	gchar *icon_filename;

	/* User data and destroy notify function */
	gpointer data;
	GDestroyNotify destroy;

	/* ID for the text item's event signal handler */
	guint text_event_id;

	/* Whether the icon is selected, and temporary storage for rubberband
         * selections.
	 */
	guint selected : 1;
	guint tmp_selected : 1;
} Icon;

/* A row of icons */
typedef struct {
	GList *line_icons;
	gint16 y;
	gint16 icon_height, text_height;
} IconLine;

/* Private data of the GnomeIconList structure */
struct _GnomeIconListPrivate {
	/* List of icons */
	GArray *icon_list;

	/* List of rows of icons */
	GList *lines;

	Icon *editing_icon;

	/* Separators used to wrap the text below icons */
	char *separators;

	Icon *last_selected_icon;

	/* Rubberband rectangle */
	void *sel_rect;

	/* Saved event for a pending selection */
	GdkEvent select_pending_event;

	/* Max of the height of all the icon rows and window height */
	int total_height;

	/* Selection mode */
	GtkSelectionMode selection_mode;

	/* A list of integers with the indices of the currently selected icons */
	GList *selection;

	/* The icon that has keyboard focus */
	gint focus_icon;

	/* Number of icons in the list */
	int icons;

	/* Freeze count */
	int frozen;

	/* Width allocated for icons */
	int icon_width;

	/* Spacing values */
	int row_spacing;
	int col_spacing;
	int text_spacing;
	int icon_border;

	/* Index and pointer to last selected icon */
	int last_selected_idx;

	/* Timeout ID for autoscrolling */
	guint timer_tag;

	/* Change the adjustment value by this amount when autoscrolling */
	int value_diff;

	/* Mouse position for autoscrolling */
	int event_last_x;
	int event_last_y;

	/* Selection start position */
	int sel_start_x;
	int sel_start_y;

	int icons_per_row;

	/* Modifier state when the selection began */
	guint sel_state;

	/* Whether the icon texts are editable */
	guint is_editable : 1;

	/* Whether the icon texts need to be copied */
	guint static_text : 1;

	/* Whether the icons need to be laid out */
	guint dirty : 1;

	/* Whether the user is performing a rubberband selection */
	guint selecting : 1;

	/* Whether editing an icon is pending after a button press */
	guint edit_pending : 1;

	/* Whether selection is pending after a button press */
	guint select_pending : 1;

	/* Whether the icon that is pending selection was selected to begin with */
	guint select_pending_was_selected : 1;
};

void
gnome_icon_list_instance_init (Gil *gil)
{
	NSGtkMatrix *m;
	NSButtonCell *cell;

	gil->hadj = 0;
	gil->adj = 0;
	gil->_priv = g_new0 (GnomeIconListPrivate, 1);

	gil->_priv->icon_list = g_array_new(FALSE, FALSE, sizeof(gpointer));
	gil->_priv->row_spacing = DEFAULT_ROW_SPACING;
	gil->_priv->col_spacing = DEFAULT_COL_SPACING;
	gil->_priv->text_spacing = DEFAULT_TEXT_SPACING;
	gil->_priv->icon_border = DEFAULT_ICON_BORDER;
	gil->_priv->separators = g_strdup (" ");

	gil->_priv->selection_mode = GTK_SELECTION_SINGLE;
	gil->_priv->dirty = TRUE;

	gil->_priv->focus_icon = -1;

	GTK_WIDGET_SET_FLAGS (gil, GTK_CAN_FOCUS);
	cell = [NSButtonCell alloc];
	[cell setButtonType:NSOnOffButton];
	[cell setImagePosition:NSImageAbove];
	[cell setFont:[NSFont labelFontOfSize:8]];
	[cell setTitle:@""];
	[cell setWraps:YES];
	m = [[NSGtkMatrix alloc] initWithFrame:NSMakeRect(0,0,100,100) mode:NSRadioModeMatrix  prototype:cell numberOfRows:1 numberOfColumns:1];
	[cell release];
	[m setCellSize:NSMakeSize(64,80)];
	[m setIntercellSpacing:NSMakeSize(10,10)];
    [m setAction: @selector (select_icon:)];
    [m setTarget: m];
	[GTK_WIDGET(gil)->proxy release];
	GTK_WIDGET(gil)->proxy = m;
	m->proxy = gil;
}

int
icon_list_append (Gil *gil, Icon *icon)
{
	GnomeIconListPrivate *priv;
	int pos;
	NSMatrix *m;
	NSCell *cell;

	priv = gil->_priv;

	pos = priv->icons++;
	g_array_append_val(priv->icon_list, icon);

	switch (priv->selection_mode) {
	case GTK_SELECTION_BROWSE:
		gnome_icon_list_select_icon (gil, 0);
		break;

	default:
		break;
	}

	if (!priv->frozen) {
		/* FIXME: this should only layout the last line */
		gil_layout_all_icons (gil);
		gil_scrollbar_adjust (gil);
	} else
		priv->dirty = TRUE;

	m = GTK_WIDGET(gil)->proxy;
	[m renewRows:(priv->icons+4)/5 columns:MIN(priv->icons,5)];
	cell = [m cellAtRow:(pos/5) column:(pos%5)];
	[cell setImage:icon->image];
	[cell setTitle:[NSString stringWithCString:icon->text]];
//	[cell setToolTip:[NSString stringWithCString:icon->text]];
	return priv->icons - 1;
}

/**
 * gnome_icon_list_clear:
 * @gil: An icon list.
 *
 * Clears the contents for the icon list by removing all the icons.  If destroy
 * handlers were specified for any of the icons, they will be called with the
 * appropriate data.
 */
void
gnome_icon_list_clear (GnomeIconList *gil)
{
	NSMatrix *m;
	NSCell *cell;
	GnomeIconListPrivate *priv;
	int i;

	g_return_if_fail (gil != NULL);
	g_return_if_fail (IS_GIL (gil));

	priv = gil->_priv;

	m = GTK_WIDGET(gil)->proxy;
	for (i = 0; i < priv->icon_list->len; i++)
	{
		icon_destroy (g_array_index (priv->icon_list, Icon*, i));
		cell = [m cellAtRow:(i/5) column:(i%5)];
		[cell setImage:nil];
		[cell setTitle:@""];
	}

	gil_free_line_info (gil);

	g_list_free (priv->selection);
	priv->selection = NULL;
	g_array_set_size(priv->icon_list, 0);
	priv->icons = 0;
	priv->focus_icon = -1;
	priv->last_selected_idx = -1;
	priv->last_selected_icon = NULL;

	if (!priv->frozen) {
		gil_layout_all_icons (gil);
		gil_scrollbar_adjust (gil);
	} else
		priv->dirty = TRUE;

}

void
gil_adj_value_changed (GtkAdjustment *adj, Gil *gil)
{
	NSMatrix *m;
	m = GTK_WIDGET(gil)->proxy;
	
	NSRect rect = [m frame];
    if(adj->value >=0)
		rect.size.height = GTK_WIDGET(gil)->allocation.height+adj->value;
    //rect.origin.y =  adj->value -( adj->upper - GTK_WIDGET(gil)->allocation.height)+18;
	[m setFrame:rect];
  	[m setNeedsDisplay:TRUE];
}


