//
//  BookmarkController.h
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CHMFile;

@interface BookmarkController : NSWindowController {
	IBOutlet NSWindow* addPanel;
	IBOutlet NSTextField* titleField;
	IBOutlet NSTextField* tagField;
	IBOutlet NSMenu *bookmarkMenu;

	IBOutlet NSPanel* managePanel;
	
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
}

- (IBAction)showAddBookmark:(id)sender;
- (IBAction)endAddBookmark:(id)sender;
- (IBAction)openBookmark:(id)sender;
- (void)addBookmarkDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (CHMFile *)fileByPath:(NSString*)path;
@end
