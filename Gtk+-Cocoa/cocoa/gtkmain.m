/*
 *  gtkmain.c
 *  Gtk+
 *
 *  Created by Paolo Costabel on Sat Aug 10 2002.
 *  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
 *
 */
#import <AppKit/AppKit.h>
#import "GtkApplication.h"
#import "GtkAppDelegate.h"

#include "gdk/gdktypes.h"
#include "gdk/gdk.h"

#include "gtkmain.h"

#define gtk_warning printf
#define	kGtkPeriodicDelay  0.0
#define kGtkPeriodicPeriod 0.001 // 1msec


#include "gtkwindow.h"
#include "gtkprivate.h"
#include "gdk/gdki18n.h"
#include "gtkdebug.h"
#include "gtkintl.h"

extern GSList *main_loops;      /* stack of currently executing main loops */
					    
extern GList *init_functions ;	   // A list of init functions.
extern GList *quit_functions ;	   // A list of quit functions.

static guint gtk_main_loop_level = 0;

/* Private type definitions
 */
typedef struct _GtkInitFunction		 GtkInitFunction;
typedef struct _GtkQuitFunction		 GtkQuitFunction;
typedef struct _GtkClosure	         GtkClosure;
typedef struct _GtkKeySnooperData	 GtkKeySnooperData;

struct _GtkInitFunction
{
  GtkFunction function;
  gpointer data;
};

struct _GtkQuitFunction
{
  guint id;
  guint main_level;
  GtkCallbackMarshal marshal;
  GtkFunction function;
  gpointer data;
  GtkDestroyNotify destroy;
};

struct _GtkClosure
{
  GtkCallbackMarshal marshal;
  gpointer data;
  GtkDestroyNotify destroy;
};

struct _GtkKeySnooperData
{
  GtkKeySnoopFunc func;
  gpointer func_data;
  guint id;
};

GtkAppDelegate *				gtkAppDel = nil;
NSMapTable *				gtkViewList = NULL;	
NSMapTable *				gtkMenuList = NULL;

gboolean
gtk_init_check	(int *argc, char ***argv)
{
    NSBundle *mainBndl;
    NSString *bndlPath;
    NSMenu *menu,*apple_menu;
	NSMenuItem *item;
	BOOL res;
    	
	if (NSApp != nil)
    {
        return TRUE;
    }
	
  	gtk_type_init ();
  	gtk_object_post_arg_parsing_init ();
  	gtk_signal_init ();

	/* Initialize our application instance */
	(void) [[NSAutoreleasePool alloc] init];
	NSApp = [NSApplication sharedApplication];
    gtkAppDel = [[GtkAppDelegate alloc] init];
    [NSApp setDelegate:gtkAppDel];
  

  	apple_menu = [NSMenu new];
	item = [[NSMenuItem alloc] initWithTitle:@"About Storyboard Lite" action:nil keyEquivalent:@""];
 	[apple_menu addItem: item];
  	[NSApp setAppleMenu: apple_menu];

  	menu = [NSMenu new];
  	[NSApp setMainMenu: menu];

   	res = [NSBundle loadNibNamed:@"MainMenu" owner:NSApp];
    mainBndl = [NSBundle mainBundle];
    bndlPath = [mainBndl resourcePath];
    chdir([bndlPath cString]);

    gtkViewList		= NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 4);
    gtkMenuList		= NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 4);

   return TRUE;
}

void
gtk_init (int *argc, char ***argv)
{
  if (!gtk_init_check (argc, argv))
    {
      gtk_warning ("cannot open display");
      exit(1);
    }
}

void
gtk_main (void)
{
  GList *tmp_list;
  GList *functions;
  GtkInitFunction *init;
  GMainLoop *loop;

  gtk_main_loop_level++;
  
  loop = g_main_new (TRUE);
  main_loops = g_slist_prepend (main_loops, loop);

  tmp_list = functions = init_functions;
  init_functions = NULL;
  
  while (tmp_list)
    {
      init = tmp_list->data;
      tmp_list = tmp_list->next;
      
      (* init->function) (init->data);
      g_free (init);
    }
  g_list_free (functions);

  if (g_main_is_running (main_loops->data))
    {
/*
      GDK_THREADS_LEAVE ();
      g_main_run (loop);
      GDK_THREADS_ENTER ();
      gdk_flush ();
*/    [NSApp run];
   
    }

  if (quit_functions)
    {
      GList *reinvoke_list = NULL;
      GtkQuitFunction *quitf;

      while (quit_functions)
	{
	  quitf = quit_functions->data;

	  tmp_list = quit_functions;
	  quit_functions = g_list_remove_link (quit_functions, quit_functions);
	  g_list_free_1 (tmp_list);

	  if ((quitf->main_level && quitf->main_level != gtk_main_loop_level) ||
	      gtk_quit_invoke_function (quitf))
	    {
	      reinvoke_list = g_list_prepend (reinvoke_list, quitf);
	    }
	  else
	    {
	      gtk_quit_destroy (quitf);
	    }
	}
      if (reinvoke_list)
	{
	  GList *work;
	  
	  work = g_list_last (reinvoke_list);
	  if (quit_functions)
	    quit_functions->prev = work;
	  work->next = quit_functions;
	  quit_functions = work;
	}

      //gdk_flush ();
    }
	      
  main_loops = g_slist_remove (main_loops, loop);

  g_main_destroy (loop);

  gtk_main_loop_level--;


}

void
gtk_main_quit()
{
	[NSApp terminate:0];
}

guint
gtk_main_level (void)
{
  return gtk_main_loop_level;
}

@interface TimerData : NSObject
{
	void *data;
	GtkFunction function;
}
- (void)fire:(NSTimer *)timer;
@end

@implementation TimerData

- (void)fire:(NSTimer *)timer
{
	(*function)(data);	
	gdk_idle_hook();
}

guint
gtk_timeout_add (guint32     interval,
		 GtkFunction function,
		 gpointer    data)
{
  TimerData *timer_data;
  int timer;

  timer_data = [[TimerData alloc] init];
  timer_data->data = data;
  timer_data->function = function;

  timer =  [NSTimer scheduledTimerWithTimeInterval:(float)interval/1000 target:timer_data  selector:@selector(fire:) userInfo:timer_data repeats:YES];
  [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode];
  
  return timer;
}

void
gtk_timeout_remove (guint tag)
{
	NSTimer *timer = (NSTimer *)tag;
 	[timer invalidate]; 
}


