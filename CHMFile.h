//
//  CHMFile.h
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class CHMBookmark;

@interface CHMFile :  NSManagedObject  
{
}

@property (retain) NSString * path;
@property (retain) NSSet* bookmarks;

@end

@interface CHMFile (CoreDataGeneratedAccessors)
- (void)addBookmarksObject:(CHMBookmark *)value;
- (void)removeBookmarksObject:(CHMBookmark *)value;
- (void)addBookmarks:(NSSet *)value;
- (void)removeBookmarks:(NSSet *)value;

@end

