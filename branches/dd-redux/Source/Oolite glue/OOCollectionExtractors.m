#import "OOCollectionExtractors.h"
#import "OOStringParsing.h"


Vector OOVectorFromObject(id object, Vector defaultValue)
{
	Vector				result = defaultValue;
	NSDictionary		*dict = nil;
	
	if ([object isKindOfClass:[NSString class]])
	{
		// This will only write result if a valid vector is found, and will write an error message otherwise.
		ScanVectorFromString(object, &result);
	}
	else if ([object isKindOfClass:[NSArray class]] && [object count] == 3)
	{
		result.x = [object floatAtIndex:0];
		result.y = [object floatAtIndex:1];
		result.z = [object floatAtIndex:2];
	}
	else if ([object isKindOfClass:[NSDictionary class]])
	{
		dict = object;
		// Require at least one of the keys x, y, or z
		if ([dict objectForKey:@"x"] != nil ||
			[dict objectForKey:@"y"] != nil ||
			[dict objectForKey:@"z"] != nil)
		{
			// Note: uses 0 for unknown components rather than components of defaultValue.
			result.x = [dict floatForKey:@"x" defaultValue:0.0f];
			result.y = [dict floatForKey:@"y" defaultValue:0.0f];
			result.z = [dict floatForKey:@"z" defaultValue:0.0f];
		}
	}
	
	return result;
}


Quaternion OOQuaternionFromObject(id object, Quaternion defaultValue)
{
	Quaternion			result = defaultValue;
	NSDictionary		*dict = nil;
	
	if ([object isKindOfClass:[NSString class]])
	{
		// This will only write result if a valid quaternion is found, and will write an error message otherwise.
		ScanQuaternionFromString(object, &result);
	}
	else if ([object isKindOfClass:[NSArray class]] && [object count] == 4)
	{
		result.w = [object floatAtIndex:0];
		result.x = [object floatAtIndex:1];
		result.y = [object floatAtIndex:2];
		result.z = [object floatAtIndex:3];
	}
	else if ([object isKindOfClass:[NSDictionary class]])
	{
		dict = object;
		// Require at least one of the keys w, x, y, or z
		if ([dict objectForKey:@"w"] != nil ||
			[dict objectForKey:@"x"] != nil ||
			[dict objectForKey:@"y"] != nil ||
			[dict objectForKey:@"z"] != nil)
		{
			// Note: uses 0 for unknown components rather than components of defaultValue.
			result.w = [dict floatForKey:@"w" defaultValue:0.0f];
			result.x = [dict floatForKey:@"x" defaultValue:0.0f];
			result.y = [dict floatForKey:@"y" defaultValue:0.0f];
			result.z = [dict floatForKey:@"z" defaultValue:0.0f];
		}
	}
	
	return result;
}


NSDictionary *OOPropertyListFromVector(Vector value)
{
	return [NSArray arrayWithObjects:[NSNumber numberWithFloat:value.x], [NSNumber numberWithFloat:value.y], [NSNumber numberWithFloat:value.z], nil];
}


NSDictionary *OOPropertyListFromQuaternion(Quaternion value)
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:value.w], @"w",
			[NSNumber numberWithFloat:value.x], @"x",
			[NSNumber numberWithFloat:value.y], @"y",
			[NSNumber numberWithFloat:value.z], @"z",
			nil];
}
