@compatibility_alias OOColor NSColor;


@interface NSColor (OOColorExtensions)

+ (id) colorFromString:(NSString*) colorFloatString;
+ (id) colorWithDescription:(id)description;
- (NSArray *)normalizedArray;

- (BOOL) isBlack;

@end
