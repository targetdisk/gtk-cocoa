//
//  NSGtkScrollbar.m
//  Gtk+
//
//  Created by Paolo Costabel on Mon Dec 30 2002.
//  Copyright (c) 2002 __MyCompanyName__. All rights reserved.
//

#import "NSGtkScrollbar.h"


@implementation NSGtkScrollbar

- (void)value_changed:(id)sender
{
	GtkAdjustment *adj;
	GtkRange *range = proxy;

	adj = range->adjustment;
	switch([sender hitPart])
	{
		case NSScrollerDecrementLine:
			[sender setFloatValue:(adj->value-adj->step_increment-adj->lower)/(adj->upper-adj->lower-adj->page_size)];
			break;
		case NSScrollerIncrementLine:
			[sender setFloatValue:(adj->value+adj->step_increment-adj->lower)/(adj->upper-adj->lower-adj->page_size)];
			break;
		case NSScrollerDecrementPage:
			[sender setFloatValue:(adj->value-adj->page_increment-adj->lower)/(adj->upper-adj->lower-adj->page_size)];
			break;
		case NSScrollerIncrementPage:
			[sender setFloatValue:(adj->value+adj->page_increment-adj->lower)/(adj->upper-adj->lower-adj->page_size)];
			break;
	}
	adj->value = [sender floatValue]*(adj->upper-adj->lower-adj->page_size)+adj->lower;
	gtk_signal_emit_by_name (GTK_OBJECT (adj), "value_changed");
	printf("adj %f\n",adj->value);
}

@end
