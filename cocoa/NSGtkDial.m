//
//  NSGtkDial.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Mar 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//
#include <math.h>
#include <gtkdial.h>
#import "NSGtkDial.h"


@implementation NSGtkDial

- (void)value_changed:(id)sender
{
	GtkAdjustment *adj;
	GtkDial *dial = proxy;
	float angle,distance;

	adj = dial->adjustment;
	[sender getAngle:&angle andDistance:&distance];
	adj->value = (angle+M_PI)*100.0/(2*M_PI);
	adj->value = 50 - adj->value;
	if(adj->value < 0)
		adj->value +=100;
	gtk_signal_emit_by_name (GTK_OBJECT (adj), "value_changed");
	printf("adj %f\n",adj->value);
}

@end
