/*
	DDUtilities.m
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

#import "DDUtilities.h"
#import "Logging.h"
#import <Cocoa/Cocoa.h>


NSString *ApplicationNameAndVersionString(void)
{
	NSBundle			*mainBundle;
	NSString			*marketingVersion, *buildVersion;
	
	mainBundle = [NSBundle mainBundle];
	
	marketingVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	buildVersion = [mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	
	return [NSString stringWithFormat:@"Dry Dock for Oolite %@ (%@)", marketingVersion, buildVersion];
}


extern NSString *LocationOfOoliteResources(void)
{
	TraceEnter();
	
	static id				oolitePath = nil;
	NSURL					*ooliteURL;
	NSBundle				*oolite;
	OSStatus				err;
	
	if (nil == oolitePath)
	{
		TraceMessage(@"Looking for Oolite.");
		err = LSFindApplicationForInfo('Ool8', (CFStringRef)@"org.aegidian.oolite", NULL, NULL, (CFURLRef *)&ooliteURL);
		if (noErr == err && [ooliteURL isFileURL])
		{
			TraceMessage(@"Oolite found at %@", [ooliteURL path]);
			oolite = [[NSBundle alloc] initWithPath:[ooliteURL path]];
			[ooliteURL release];
			
			oolitePath = [oolite resourcePath];
			[oolite release];
		}
		else
		{
			oolitePath = [NSNull null];
			TraceMessage(@"Oolite not found.");
		}
	}
	
	return ([NSNull null] == oolitePath) ? nil : oolitePath;
	TraceExit();
}


#if !TIGER_OR_LATER

BOOL TigerOrLater(void)
{
	static long			version = 0;
	OSErr				err;
	
	if (0 == version)
	{
		err = Gestalt(gestaltSystemVersion, &version);
		if (noErr != err) return NO;
	}
	
	return 0x1040 <= version;
}

#endif
