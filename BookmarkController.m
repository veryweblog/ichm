//
//  BookmarkController.m
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BookmarkController.h"
#import "CHMDocument.h"
#import "CHMFile.h"
#import "CHMBookmark.h"


@implementation BookmarkController
- (id)init
{
    if (![super initWithWindowNibName:@"Bookmark"])
        return nil;
    return self;
}

- (void)windowDidLoad
{
    NSLog(@"Nib file is loaded");
}

- (IBAction)showAddBookmark:(id)sender
{
	// force load of nib
	[self window];
	
	
	CHMDocument *doc = (CHMDocument*)sender;
	[titleField setStringValue:[doc currentTitle]];
	[titleField selectText:self];
	[NSApp beginSheet:addPanel modalForWindow:[doc windowForSheet] modalDelegate:self didEndSelector:@selector(addBookmarkDidEnd:returnCode:contextInfo:) contextInfo:doc];

}

- (IBAction)endAddBookmark:(id)sender
{
	unsigned int tag = [sender tag];
	[NSApp endSheet:addPanel returnCode:tag];
	[addPanel orderOut:sender];
}

- (void)addBookmarkDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSLog(@"add bookmark ended with return code:%d", returnCode);
	if( 0 == returnCode || !contextInfo)
		return;
	
	CHMDocument *doc = contextInfo;
	NSError *error = nil;
	NSManagedObjectContext *context =[self managedObjectContext];
	
	CHMFile *chmFile = [self fileByPath:[doc filePath]] ;
	if (!chmFile)
	{
		chmFile = [NSEntityDescription
				   insertNewObjectForEntityForName:@"File"
				   inManagedObjectContext:context];
		[chmFile setPath:[doc filePath]];
		[context save:&error];
		if ( ![context save:&error] )
			NSLog(@"Can not fetch file info: %d",error );
	}
	
	CHMBookmark *bookmark = [NSEntityDescription
							 insertNewObjectForEntityForName:@"Bookmark"
							 inManagedObjectContext:context];
	[bookmark setPath:[doc currentURL]];
	[bookmark setTitle:[titleField stringValue]];
	[bookmark setCreatedAt:[NSDate date]];
	[bookmark setFile:chmFile];
	if ( ![context save:&error] )
	{
		NSLog(@"Can not fetch file info: %d",error );
		return;
	}
	
	NSMenuItem *newitem = [[[NSMenuItem alloc] init] autorelease];
	[newitem setTitle:bookmark.title];
	[newitem setTarget:self];
	[newitem setAction:@selector(openBookmark:)];
	[newitem setRepresentedObject:bookmark];
	[newitem setEnabled:YES];
	[bookmarkMenu insertItem:newitem atIndex:3];
}

#pragma mark CoreData context
- (NSString *)applicationSupportFolder {
	
    NSString *applicationSupportFolder = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ( [paths count] == 0 ) {
        NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
        [[NSApplication sharedApplication] terminate:self];
    } else {
        applicationSupportFolder = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"iChm"];
    }
    return applicationSupportFolder;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel) return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}

- (NSManagedObjectContext *) managedObjectContext {
    NSError *error;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSFileManager *fileManager;
    NSPersistentStoreCoordinator *coordinator;
    
    if (managedObjectContext) {
        return managedObjectContext;
    }
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"Bookmarks.sqlite"]];
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
        [[NSApplication sharedApplication] presentError:error];
    }    
    [coordinator release];
    
    return managedObjectContext;
}

#pragma mark data accessing
- (CHMFile *)fileByPath:(NSString*)path
{
	if (!path)
		return nil;
	
	NSManagedObjectContext *context =[self managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *fileEntity = [NSEntityDescription
									   entityForName:@"File" inManagedObjectContext:context];
	[request setEntity:fileEntity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"path == %@", path];
	[request setPredicate:predicate];
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Can not fetch file info: %d",error );
		return nil;
	}
	if ([array count] == 0)
	{
		NSLog(@"Can not fetch file with path: %%",path );
		return nil;
	}
	return [array objectAtIndex:0];
}

#pragma mark Bookmark Menu

#define BOOKMAKR_LIMIT 15

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSDocumentController *controller = [NSDocumentController sharedDocumentController];
	[[menu itemWithTag:0] setEnabled:(nil != [controller currentDocument])];

	while ([menu numberOfItems] > 3)
	{
		[menu removeItemAtIndex:3];
	}
	
	NSManagedObjectContext *context =[self managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *bookmarkEntity = [NSEntityDescription
									   entityForName:@"Bookmark" inManagedObjectContext:context];
	[request setEntity:bookmarkEntity];
	[request setFetchLimit:BOOKMAKR_LIMIT];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:@"createdAt" ascending:NO];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];

	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Can not fetch file info: %d",error );
		return;
	}
	for (CHMBookmark* bm in array) {
		NSMenuItem *newitem = [[[NSMenuItem alloc] init] autorelease];
		[newitem setTitle:[bm title]];
		[newitem setTarget:self];
		[newitem setAction:@selector(openBookmark:)];
		[newitem setRepresentedObject:bm];
		[newitem setEnabled:YES];
		[menu addItem:newitem];
	}
}

- (IBAction)openBookmark:(id)sender
{
	NSDocumentController *controller = [NSDocumentController sharedDocumentController];
	NSError *error = nil;
	CHMBookmark * bm = (CHMBookmark*)[sender representedObject];
	NSURL *url = [NSURL fileURLWithPath:bm.file.path];
	CHMDocument* doc = [controller openDocumentWithContentsOfURL:url display:YES error:&error];
	[doc loadURL:[NSURL URLWithString:bm.path]];
}
@end
