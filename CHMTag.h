//
//  CHMTag.h
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class CHMBookmark;

@interface CHMTag :  NSManagedObject  
{
}

@property (retain) NSString * tag;
@property (retain) NSSet* bookmarks;

+ (CHMTag*)getTagByString:(NSString*)tagstr OnCreate:(BOOL)shouldCreate withContext:(NSManagedObjectContext*)context;
+ (NSArray*)allTagswithContext:(NSManagedObjectContext*)context;
@end

@interface CHMTag (CoreDataGeneratedAccessors)
- (void)addBookmarksObject:(CHMBookmark *)value;
- (void)removeBookmarksObject:(CHMBookmark *)value;
- (void)addBookmarks:(NSSet *)value;
- (void)removeBookmarks:(NSSet *)value;

@end