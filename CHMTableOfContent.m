//
//  CHMTableOfContent.m
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMTableOfContent.h"
#import <libxml/HTMLparser.h>
#import "CHMDocument.h"

@implementation LinkItem

- (id)init
{
	_children = [[NSMutableArray alloc] init];
	_name = nil;
	_path = nil;
	return self;
}

- (void) dealloc
{
	[_children release];
	[_path release];
	[_name release];
	[super dealloc];
}

- (id)initWithName:(NSString *)name Path:(NSString *)path
{
	[self init];
	_name = name;
	_path = path;
	[_name retain];
	[_path retain];
	return self;
}

- (void)setName:(NSString *)name
{
	[_name release];
	_name = name;
	[_name retain];
}

- (void)setPath:(NSString *)path
{
	[_path release];
	_path = path;
	[_path retain];
}

- (int)numberOfChildren
{
	return _children ? [_children count] : 0;
}

- (LinkItem *)childAtIndex:(int)n
{
	return [_children objectAtIndex:n];
}

- (NSString *)name
{
	return _name;
}

- (NSString *)path
{
	return _path;
}

- (void)appendChild:(LinkItem *)item
{
	if(!_children)
		_children = [[NSMutableArray alloc] init];
	[_children addObject:item];
}

- (LinkItem*)find_by_path:(NSString *)path withStack:(NSMutableArray*)stack
{
	if ([_path isEqualToString:path] ||
		[_path isEqualToString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]])
		return self;
	
	if(!_children)
		return nil;
	
	for (LinkItem* item in _children) {
		LinkItem * rslt = [item find_by_path:path withStack:stack];
		if (rslt != nil)
		{
			if(stack)
				[stack addObject:self];
			return rslt;
		}
	}
	
	return nil;
}
@end

@interface CHMTableOfContent (Private)
- (LinkItem *)curItem;
- (void)push_item;
- (void)pop_item;
- (void)new_item;
@end

@implementation CHMTableOfContent

static void elementDidStart( CHMTableOfContent *toc, const xmlChar *name, const xmlChar **atts );
static void elementDidEnd( CHMTableOfContent *toc, const xmlChar *name );

static htmlSAXHandler saxHandler = {
NULL, /* internalSubset */
NULL, /* isStandalone */
NULL, /* hasInternalSubset */
NULL, /* hasExternalSubset */
NULL, /* resolveEntity */
NULL, /* getEntity */
NULL, /* entityDecl */
NULL, /* notationDecl */
NULL, /* attributeDecl */
NULL, /* elementDecl */
NULL, /* unparsedEntityDecl */
NULL, /* setDocumentLocator */
NULL, /* startDocument */
NULL, /* endDocument */
(startElementSAXFunc) elementDidStart, /* startElement */
(endElementSAXFunc) elementDidEnd, /* endElement */
NULL, /* reference */
NULL, /* characters */
NULL, /* ignorableWhitespace */
NULL, /* processingInstruction */
NULL, /* comment */
NULL, /* xmlParserWarning */
NULL, /* xmlParserError */
NULL, /* xmlParserError */
NULL, /* getParameterEntity */
};

- (id)initWithData:(NSData *)data encodingName:(NSString*)encodingName
{
	itemStack = [[NSMutableArray alloc] init];
	rootItems = [[LinkItem alloc] initWithName:@"root"	Path:@"/"];
	curItem = rootItems;
	
	if(!encodingName || [encodingName length] == 0)
		encodingName = @"iso_8859_1";
	
	htmlDocPtr doc = htmlSAXParseDoc( (xmlChar *)[data bytes], [encodingName UTF8String],
									  &saxHandler, self);
	[itemStack release];
	
	if( doc ) {
	    xmlFreeDoc( doc );
	}
	
	return self;
}

- (void) dealloc
{
	[rootItems release];

	[super dealloc];
}

- (LinkItem *)itemForPath:(NSString*)path withStack:(NSMutableArray*)stack
{
	if( [path hasPrefix:@"/"] ) {
		path = [path substringFromIndex:1];
    }
	
	return [rootItems find_by_path:path withStack:stack];
}

- (int)rootChildrenCount
{
	return [rootItems numberOfChildren];
}
# pragma mark NSOutlineView
- (int)outlineView:(NSOutlineView *)outlineView
numberOfChildrenOfItem:(id)item
{
	if (!item)
		item = rootItems;
	
    return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item
{
    return [item numberOfChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
			child:(int)theIndex
		   ofItem:(id)item
{
	if (!item)
		item = rootItems;
	
    return [item childAtIndex:theIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
		   byItem:(id)item
{
    return [item name];
}

- (LinkItem *)curItem
{
	return curItem;
}

- (void)push_item
{
	[itemStack addObject:curItem];
}

- (void)new_item
{
	curItem = [[LinkItem alloc] init];
	LinkItem * parent = [itemStack lastObject];
	[parent appendChild:curItem];
	[curItem release];
}

- (void)pop_item
{
	curItem = [itemStack lastObject];
	[itemStack removeLastObject];
}

# pragma mark NSXMLParser delegation
static void elementDidStart( CHMTableOfContent *context, const xmlChar *name, const xmlChar **atts ) 
{
    if ( !strcasecmp( "ul", (char *)name ) ) {
		[context push_item];
        return;
    }
	
    if ( !strcasecmp( "li", (char *)name ) ) {
		[context new_item];
        return;
    }
	
    if ( !strcasecmp( "param", (char *)name ) && ( atts != NULL ) ) {
		// Topic properties
		const xmlChar *type = NULL;
		const xmlChar *value = NULL;
		
		for( int i = 0; atts[ i ] != NULL ; i += 2 ) {
			if( !strcasecmp( "name", (char *)atts[ i ] ) ) {
				type = atts[ i + 1 ];
			}
			else if( !strcasecmp( "value", (char *)atts[ i ] ) ) {
				value = atts[ i + 1 ];
			}
		}
		
		if( ( type != NULL ) && ( value != NULL ) ) {
			if( !strcasecmp( "Name", (char *)type ) ) {
				// Name of the topic
				NSString *str = [[NSString alloc] initWithUTF8String:(char *)value];
				[[context curItem] setName:str];
				[str release];
			}
			else if( !strcasecmp( "Local", (char *)type ) ) {
				// Path of the topic
				NSString *str = [[NSString alloc] initWithUTF8String:(char *)value];
				[[context curItem] setPath:str]; 
				[str release];
			}
		}
        return;
    }
}

static void elementDidEnd( CHMTableOfContent *context, const xmlChar *name )
{
    if ( !strcasecmp( "ul", (char *)name ) ) {
		[context pop_item];
        return;
    }	
}
@end

@implementation CHMSearchResult

- (id) init
{
	rootItems = [[ScoredLinkItem alloc] initWithName:@"root"	Path:@"/" Score:0];
	return self;
}

- (id)initwithTOC:(CHMTableOfContent*)toc withIndex:(CHMTableOfContent*)index
{
	[self init];

	tableOfContent = toc;
	if (tableOfContent)
		[tableOfContent retain];
	
	indexContent = index;
	if (indexContent)
		[indexContent retain];
	
	return self;
}

- (void) dealloc
{
	if (tableOfContent)
		[tableOfContent release];

	if (indexContent)
		[indexContent release];
	[super dealloc];
}

- (void)addPath:(NSString*)path Score:(float)score
{
	LinkItem * item = nil;
	if (indexContent)
		item = [indexContent itemForPath:path withStack:nil];
	if (!item && tableOfContent)
		item = [tableOfContent itemForPath:path withStack:nil];
	
	if (!item)
		return;
	ScoredLinkItem * newitem = [[ScoredLinkItem alloc] initWithName:[item name] Path:[item path] Score:score];
	[rootItems appendChild:newitem];
}

- (void)sort
{
	[(ScoredLinkItem*)rootItems sort];
}
@end

@implementation ScoredLinkItem

@synthesize relScore;

- (void)sort
{
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"relScore" ascending:NO];
	NSMutableArray * sda = [[NSMutableArray alloc] init];
	[sda addObject:sd];
	[_children sortUsingDescriptors:sda];
	[sda release];
	[sd release];
}

- (id)initWithName:(NSString *)name Path:(NSString *)path Score:(float)score
{
	relScore = score;
	return [self initWithName:name Path:path];
}

@end
