//
//  NSGtkEntry.m
//  Gtk+
//
//  Created by Paolo Costabel on Mon Dec 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSGtkEntry.h"
#import "NSGtkMenuItem.h"

@implementation NSGtkEntry


- (void)activate:(id)sender
{
	gtk_signal_emit_by_name(proxy,"activate",proxy);
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	if([[theEvent charactersIgnoringModifiers] isEqualToString:@"v"])
	{
		return [NSApp sendAction:@selector(paste:) to:nil from:self];
	}
	return FALSE;
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
  	GtkEditable *editable;
    GtkEntry *entry;
	NSString *s =  [[aNotification object] stringValue];
	gchar *text = [s cString];
  	gint tmp_pos;

	if(locked) return;
	locked = TRUE;
    editable = GTK_EDITABLE (proxy);
    entry = GTK_ENTRY (proxy);
  
    gtk_entry_delete_text_gtk (editable, 0, entry->text_length);

	tmp_pos = 0;
	gtk_entry_insert_text_gtk (editable, text, strlen (text), &tmp_pos);
	editable->current_pos = tmp_pos;

	editable->selection_start_pos = 0;
	editable->selection_end_pos = 0;
        
        // hack for spinbutton
    if(sb)
    	gtk_adjustment_set_value (sb->adjustment, [s intValue]);
        
	gtk_signal_emit_by_name(proxy,"changed",proxy);
	locked = FALSE;
	printf("text changed: %s\n", text);
}

- (void)takeIntValueFrom : (id)sender
{
   [super takeIntValueFrom: sender];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NSControlTextDidChangeNotification" object: self];

	// this entry is connected to a spin button
	//
    gtk_adjustment_set_value (GTK_SPIN_BUTTON(proxy)->adjustment, [sender intValue]);
	gdk_idle_hook();
} 
@end
