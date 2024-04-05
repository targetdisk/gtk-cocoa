//Test
//  gdkimlib.m
//  Gtk+
//
//  Created by Paolo Costabel on Sun Aug 11 2002.
//  Copyright (c) 2002 Zebra Development. All rights reserved.
//
#import <AppKit/AppKit.h>
#include "gdk_imlib.h"
 

GdkImlibImage      * 
gdk_imlib_load_image(char *file)
{
	NSData *imageData;
    unsigned char *bitplanes[5];
	NSImage *img;
	NSImageRep *rep;
	GdkImlibImage *image;
	NSString *path = [NSString stringWithCString:file];

	img = gdk_pixmap_create_from_ppm (file);
/*	if(!img)
	{
		img = [NSImage alloc];
		img = [img initWithContentsOfFile:path]; 
	}
*/	if(!img)
    {
		NSURL *url = [[NSURL alloc] initFileURLWithPath: path];
		NSMovie *movie = [[NSMovie alloc] initWithURL: url byReference:YES];
		if(movie)
		{
			PicHandle picHandle = (PicHandle)GetMoviePict([movie QTMovie],
				 GetMovieDuration([movie QTMovie]));   // Get last frame of movie
			NSData *imageData = [NSData dataWithBytes: (*picHandle) length:GetHandleSize((Handle)picHandle)];
			NSPICTImageRep *imageRep = [NSPICTImageRep imageRepWithData:imageData];
     		img = [[NSImage alloc] initWithSize:[imageRep size]];
			[img lockFocus];
	    	[imageRep drawAtPoint:NSMakePoint(0,0)];  // Convert frame into a  useable image.
     		[img unlockFocus];
			KillPicture(picHandle);
		}
		[url release];
     	[movie release];
	}
	if(!img)	
		return NULL; 
	image = malloc(sizeof(GdkImlibImage));
	image->pixmap = img;
	imageData  = [img TIFFRepresentation];
	rep = [[NSBitmapImageRep alloc] initWithData:imageData];
	image->rgb_width = [rep pixelsWide];
	image->rgb_height = [rep pixelsHigh];
	image->filename=strdup(file);
	
    [rep getBitmapDataPlanes:bitplanes];
    image->rgb_data = bitplanes[0];
	return image;
}
 
GdkImlibImage      *
gdk_imlib_create_image_from_xpm_data(char **data)
{
	NSImageRep *rep;
	GdkImlibImage *image = malloc(sizeof(GdkImlibImage));

	image->pixmap = gdk_pixmap_create_from_xpm_d(NULL, NULL, NULL, data);
	rep = [image->pixmap bestRepresentationForDevice:nil];
	image->rgb_width = [rep pixelsWide];
	image->rgb_height = [rep pixelsHigh];
	image->filename="";
    [rep release];
	return image;
}

gint                
gdk_imlib_render(GdkImlibImage * image, gint width, gint height)
{
//	[image->pixmap setSize:NSMakeSize(width,height)];
	return 0;
}

GdkImlibImage      *
gdk_imlib_clone_scaled_image(GdkImlibImage * im, int w, int h)
{
	GdkImlibImage      *scaled = malloc(sizeof(GdkImlibImage));
	NSImage *image;
	NSBitmapImageRep *rep;
	NSData *data;
	unsigned char *bitplanes[5];
	int i;
	
	image = [[NSImage alloc] initWithSize:NSMakeSize(w,h)];
	rep = [im->pixmap bestRepresentationForDevice:nil];
//	[image addRepresentation:rep];
//	[image setScalesWhenResized:YES];
//	[image  lockFocusOnRepresentation:rep];
	[image  lockFocus];
	[rep drawInRect:NSMakeRect(0,0,w,h)];
	[image unlockFocus];
	data  = [image TIFFRepresentation];
	rep = [[NSBitmapImageRep alloc] initWithData:data];
	[rep getBitmapDataPlanes:bitplanes];	
	// check if fucking Cocoa added an alpha channel just to piss me off
	if([rep bitsPerPixel]==32)
	{
		for(i=0;i<w*h;i++)
		{
			bitplanes[0][i*3] = bitplanes[0][i*4];
			bitplanes[0][i*3+1] = bitplanes[0][i*4+1];
			bitplanes[0][i*3+2] = bitplanes[0][i*4+2];
		}
	}
	scaled->pixmap = image;
	scaled->rgb_data = bitplanes[0];
	scaled->rgb_width = w;
	scaled->rgb_height = h;
	[image addRepresentation:rep];
	[rep release];
	return scaled;
}


GdkPixmap          *
gdk_imlib_copy_image(GdkImlibImage * image)
{
//	GdkImlibImage *copy = malloc(sizeof(GdkImlibImage));
	NSImageRep *rep;
	unsigned char *bitplanes[5];

//	*copy = *image;
//	copy->pixmap = [image->pixmap copy];
//	rep = [copy->pixmap bestRepresentationForDevice:nil];
//	[rep getBitmapDataPlanes:bitplanes];	
//	copy->rgb_data = bitplanes[0];
//	return copy;
	
	return [image->pixmap copy];
}

void                
gdk_imlib_destroy_image(GdkImlibImage * image)
{
	[image->pixmap release];
	free(image);
}


void                
gdk_imlib_kill_image(GdkImlibImage * image)
{
	[image->pixmap release];
	free(image);
}

gint                
gdk_imlib_save_image(GdkImlibImage * im, char *file, GdkImlibSaveInfo * info)
{
	NSBitmapImageRep *rep;
	NSDictionary *imageProperties;
	NSData *imageData;
	NSString *path = [NSString stringWithCString:file];
    NSArray *reps;
    int i,res;
    
	if(!strcasecmp(file+strlen(file)-3,"tga"))
	{
		return saver_tga(im, file, info);
	}
	if(!strcasecmp(file+strlen(file)-3,"ppm"))
	{
		return saver_ppm(im, file, info);
	}
    [im->pixmap lockFocus];
	rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0,0,im->rgb_width,im->rgb_height)];
    [im->pixmap unlockFocus];
	if(!strcasecmp(file+strlen(file)-3,"jpg"))
	{
		imageProperties=[NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithFloat:0.9], NSImageCompressionFactor,
             nil]; 
		 imageData = [rep representationUsingType:NSJPEGFileType
                          properties:imageProperties];
	}
	if(!strcasecmp(file+strlen(file)-3,"gif"))
	{
		imageProperties=[NSDictionary dictionaryWithObjectsAndKeys:
             [NSNumber numberWithBool:FALSE], NSImageDitherTransparency,
             nil]; 
		 imageData = [rep representationUsingType:NSGIFFileType
                          properties:imageProperties];
	}
	if(!strcasecmp(file+strlen(file)-3,"tif"))
	{
		 imageData = [rep representationUsingType:NSTIFFFileType
                          properties:NULL];
	}
	if(!strcasecmp(file+strlen(file)-3,"png"))
	{
		 imageData = [rep representationUsingType:NSPNGFileType
                          properties:NULL];
	}
	res = [imageData writeToFile:path atomically:YES]; 
    [rep release];
   	return res;
}

