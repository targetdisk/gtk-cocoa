//
//  gtkevents.m
//  Gtk+
//
//  Created by Paolo Costabel on Sat Aug 31 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//

#import "GtkEvents.h"

#include "gdk.h"
#include "gdktypes.h"
#include "gdkkeysyms.h"
#include "gdkprivate.h"

extern GdkEventFunc   event_func;
extern gpointer       event_data;
extern GdkEvent *gdk_event_new		(void);
GList *idle_funcs=NULL;
void gdk_idle_hook();
int _mouse_state = 0;

typedef struct 
{
	GSourceFunc function;
	GDestroyNotify destroy;
	gpointer data;
	gint priority;
} IdleHook;

guint gdk_idle_add_full    (gint priority, GSourceFunc function, gpointer data, GDestroyNotify destroy);
gboolean gdk_idle_remove_by_data (gpointer data);

void gdk_event_dispatch( GdkEvent *event);

gint hook_compare(gconstpointer a, gconstpointer b)
{
	IdleHook *hooka,*hookb;

	hooka = (IdleHook *)a;
	hookb = (IdleHook *)b;

	if(hooka->priority > hookb->priority) return 1;
	if(hooka->priority < hookb->priority) return -1;
	return 0;

}

guint
gdk_idle_add_full (gint priority, GSourceFunc function, gpointer data, GDestroyNotify destroy)
{
  IdleHook *hook;

  g_return_val_if_fail (function != NULL, FALSE);

printf("add idle\n");
  hook = g_new(IdleHook,1);

  hook->function = function;
  hook->priority = priority;
  hook->data = data;
  hook->destroy = destroy;

  idle_funcs = g_list_insert_sorted(idle_funcs,hook,hook_compare);
  return (guint)hook;
}

gboolean
gdk_idle_remove_by_data(gpointer data)
{
	GList *l;
	IdleHook *hook;

	for(l=idle_funcs;l;l=g_list_next(l))
	{
		hook = (IdleHook *)l->data;

		if(hook->data==data)
		{
			(*hook->destroy)(hook->data);
			idle_funcs = g_list_remove(idle_funcs, hook);
			g_free(hook);
			return TRUE;
		}
	}
	
	return FALSE;
}

void
gdk_idle_hook()
{
	GList *current_hook;
	static int count=0;
	gboolean res;
	IdleHook *hook;

	while(idle_funcs)
	{
//	printf("idle hook\n");
		for(current_hook = idle_funcs;current_hook;)
		{
			hook = (IdleHook *)current_hook->data;
			res = (*hook->function)(hook->data);
			current_hook = g_list_next(current_hook);
			if(!res)
			{
				if(hook->destroy)
					(*hook->destroy)(hook->data);
				idle_funcs = g_list_remove(idle_funcs,hook);
				g_free(hook);
			}
		}
	}
}

