//
//  CHMWebView.h
//  ichm
//
//  Created by Robin Lu on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
@class CHMDocument;

@interface CHMWebView : WebView {
	CHMDocument* chmDocument;
}

- (void)setDocument:(CHMDocument*)doc;
@end
