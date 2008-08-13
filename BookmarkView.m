//
//  BookmarkView.m
//  ichm
//
//  Created by Robin Lu on 8/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BookmarkView.h"


@implementation BookmarkView
- (void)keyUp:(NSEvent *)theEvent
{
	NSLog(@"keycode %d", [theEvent keyCode]);
	if ([theEvent keyCode] == 51)
	{
		[controller remove:self];
		NSError * error;
		[[controller managedObjectContext] save:&error];
	}
}
@end
