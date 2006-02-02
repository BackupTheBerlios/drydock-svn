/*
	DDError.mm
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2006 Jens Ayton

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software
	and associated documentation files (the “Software”), to deal in the Software without
	restriction, including without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:
	
	The above copyright notice and this permission notice shall be included in all copies or
	substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
	BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
	DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "DDError.h"

NSString *kDDErrorDomain			= @"de.berlios.drydock ErrorDomain";


@implementation DDError


+ (id)errorWithCode:(int)inCode
{
	return [[[self alloc] initWithDomain:kDDErrorDomain code:inCode userInfo:nil] autorelease];
}


- (NSString *)localizedRecoverySuggestion
{
	NSString				*result;
	
	switch ([self code])
	{
		case kDDErrorAllocationFailed:
			result = NSLocalizedString(@"A memory allocation failed.", NULL);
			break;
		
		default:
			result = [super localizedRecoverySuggestion];
	}
	
	return result;
}

@end
