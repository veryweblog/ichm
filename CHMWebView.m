//
//  CHMWebView.m
//  ichm
//
//  Created by Robin Lu on 7/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMWebView.h"
#import <WebKit/WebKit.h>

@implementation CHMWebView

@synthesize webView;
@synthesize searchField;

- (id) init
{
	if (![super initWithNibName:@"CHMWebView" bundle:nil])
		return nil;
	[self loadView];
	[self hideFindPanel:self];
	return self;
}

- (IBAction)hideFindPanel:(id)sender
{
	if ([findPanel isHidden])
		return;
	[findPanel setHidden:YES];
	float webViewHeight = [webView frame].size.height;
	webViewHeight = webViewHeight + 27;
	[webView setFrame:NSMakeRect([webView frame].origin.x, [webView frame].origin.y, [webView frame].size.width, webViewHeight)];
	[webView setNeedsDisplay:YES];
}

- (IBAction)showFindPanel:(id)sender
{
	if ([findPanel isHidden])
	{
		[findPanel setHidden:NO];
		float webViewHeight = [webView frame].size.height;
		webViewHeight = webViewHeight - 27;
		[webView setFrame:NSMakeRect([webView frame].origin.x, [webView frame].origin.y, [webView frame].size.width, webViewHeight)];
		[webView setNeedsDisplay:YES];
	}
	[[[self view] window] makeFirstResponder:searchField];
}

@end
