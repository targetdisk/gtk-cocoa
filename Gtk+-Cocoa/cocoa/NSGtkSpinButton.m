//
//  NSGtkSpinButton.m
//  Gtk+
//
//  Created by Paolo Costabel on Mon Jan 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "NSGtkSpinButton.h"
@implementation NSGtkStepper

- (void)takeIntValueFrom : (id)sender
{
	
    gtk_adjustment_set_value (GTK_SPIN_BUTTON(proxy)->adjustment, [sender intValue]);
	gdk_idle_hook();
} 
@end

@implementation NSGtkSpinButton

- (id) initWithFrame: (NSRect) frame entry:(NSGtkEntry *) anEntry
{
	self = [super initWithFrame:frame];
	stepper = [[NSStepper alloc] initWithFrame:NSMakeRect(frame.size.width-20, 0,20,25)];
  	[stepper setValueWraps:NO];
	[stepper display];
	[self addSubview:stepper];
	frame.size.width-=21;
	entry = anEntry;
	[entry setFrame:frame];
	[self addSubview:entry];
	formatter = [[NSNumberFormatter alloc] init];
	[entry  setFormatter:formatter];
	[formatter setFormat:@"0"];
	[entry setIntValue:0];
	[entry setTarget:stepper];
	[entry setAction:@selector(takeIntValueFrom:)];
	[stepper setTarget:entry];
	[stepper setAction:@selector(takeIntValueFrom:)];
	
	return self;
}

- (void) setEnabled: (BOOL)flag
{
	[entry setEnabled:flag];
	[stepper setEnabled:flag];
}

-(void)setStringValue:(NSString *)aString
{
	[entry setIntValue:[aString intValue]];	
	[stepper setIntValue:[aString intValue]];	
}


@end
