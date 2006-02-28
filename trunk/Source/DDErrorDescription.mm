/*
	DDErrorDescription.mm
	Dry Dock for Oolite
	$Id$
	
	Copyright © 2005-2006 Jens Ayton

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

#import "DDErrorDescription.h"
#import <Carbon/Carbon.h>
#import <zlib.h>


#define CASE(foo) case foo: return @#foo
#define CASE2(foo, bar) case foo: return @ #foo"/"#bar
#define CASE3(foo, bar, baz) case foo: return @ #foo"/"#bar"/"#baz


#ifndef NDEBUG
static NSString *GetGenericOSStatusString(OSStatus inCode);
#endif


NSString *OSStatusErrorNSString(OSStatus inCode)
{
	NSString					*result = nil;
	
	#ifndef NDEBUG
		result = GetGenericOSStatusString(inCode);
	#else
		if (noErr == inCode) result = @"no error";
	#endif
	
	if (nil == result) result = [NSString stringWithFormat:@"%i", (int)inCode];
	
	return result;
}


NSString *FourCharCodeToNSString(FourCharCode inCode)
{
	return [[[NSString alloc] initWithBytes:&inCode length:4 encoding:NSMacOSRomanStringEncoding] autorelease];
}


#ifndef NDEBUG
static NSString *GetGenericOSStatusString(OSStatus inCode)
{
	switch (inCode)
	{
		case noErr: return @"no error";
		
		CASE(paramErr);
		CASE(memFullErr);
		CASE(unimpErr);
		CASE(userCanceledErr);
		CASE(dskFulErr);
		CASE(fnfErr);
		CASE(errFSBadFSRef);
		CASE(gestaltUnknownErr);
		CASE(coreFoundationUnknownErr);
	}
	
	return nil;
}
#endif


NSString *ErrnoToNSString(int inErrno)
{
	NSString					*result = nil;
	
	#ifndef NDEBUG
		switch (inErrno)
		{
			CASE(EPERM);
			CASE(ENOENT);
			CASE(ESRCH);
			CASE(EINTR);
			CASE(EIO);
			CASE(ENXIO);
			CASE(E2BIG);
			CASE(ENOEXEC);
			CASE(EBADF);
			CASE(ECHILD);
			CASE(EDEADLK);
			CASE(ENOMEM);
			CASE(EACCES);
			CASE(EFAULT);
			CASE(EBUSY);
			CASE(EEXIST);
			CASE(EXDEV);
			CASE(ENODEV);
			CASE(ENOTDIR);
			CASE(EISDIR);
			CASE(EINVAL);
			CASE(ENFILE);
			CASE(EMFILE);
			CASE(ENOTTY);
			CASE(ETXTBSY);
			CASE(EFBIG);
			CASE(ENOSPC);
			CASE(ESPIPE);
			CASE(EROFS);
			CASE(EMLINK);
			CASE(EPIPE);
			CASE(EDOM);
			CASE(ERANGE);
			CASE(EWOULDBLOCK);
			CASE(EINPROGRESS);
			CASE(EALREADY);
			CASE(ENOTSOCK);
			CASE(EDESTADDRREQ);
			CASE(EMSGSIZE);
			CASE(EPROTOTYPE);
			CASE(ENOPROTOOPT);
			CASE(EPROTONOSUPPORT);
			CASE(EAFNOSUPPORT);
			CASE(EADDRINUSE);
			CASE(EADDRNOTAVAIL);
			CASE(ENETDOWN);
			CASE(ENETUNREACH);
			CASE(ENETRESET);
			CASE(ECONNABORTED);
			CASE(ECONNRESET);
			CASE(ENOBUFS);
			CASE(EISCONN);
			CASE(ENOTCONN);
			CASE(ETIMEDOUT);
			CASE(ECONNREFUSED);
			CASE(ELOOP);
			CASE(ENAMETOOLONG);
			CASE(EHOSTUNREACH);
			CASE(ENOTEMPTY);
			CASE(EDQUOT);
			CASE(ESTALE);
			CASE(ENOLCK);
			CASE(ENOSYS);
			CASE(EOVERFLOW);
			CASE(ECANCELED);
			CASE(EIDRM);
			CASE(ENOMSG);
			CASE(EILSEQ);
		/*
			CASE(EBADMSG);
			CASE(EMULTIHOP);
			CASE(ENODATA);
			CASE(ENOLINK);
			CASE(ENOSR);
			CASE(ENOSTR);
			CASE(EPROTO);
			CASE(ETIME);
		*/
		
		#ifndef _POSIX_C_SOURCE
			CASE(ENOTBLK);
			CASE(ESOCKTNOSUPPORT);
			CASE(EPFNOSUPPORT);
			CASE(ESHUTDOWN);
			CASE(ETOOMANYREFS);
			CASE(EHOSTDOWN);
			CASE(EPROCLIM);
			CASE(EUSERS);
			CASE(EREMOTE);
			CASE(EBADRPC);
			CASE(ERPCMISMATCH);
			CASE(EPROGUNAVAIL);
			CASE(EPROGMISMATCH);
			CASE(EPROCUNAVAIL);
			CASE(EFTYPE);
			CASE(EAUTH);
			CASE(ENEEDAUTH);
			CASE(EPWROFF);
			CASE(EDEVERR);
			CASE(EBADEXEC);
			CASE(EBADARCH);
			CASE(ESHLIBVERS);
			CASE(EBADMACHO);
			CASE(ENOATTR);
		#endif
		}
	#endif
	
	return [NSString stringWithFormat:@"%i", (int)inErrno];
}


NSString *ZLibErrorToNSString(int inCode)
{
	#ifndef NDEBUG
		switch (inCode)
		{
			CASE(Z_OK);
			CASE(Z_STREAM_END);
			CASE(Z_NEED_DICT);
			case Z_ERRNO:
				if (0 != errno) return ErrnoAsNSString();
				else return @"Z_ERRNO";
			
			CASE(Z_STREAM_ERROR);
			CASE(Z_DATA_ERROR);
			CASE(Z_MEM_ERROR);
			CASE(Z_BUF_ERROR);
			CASE(Z_VERSION_ERROR);
		}
	#endif
	
	return [NSString stringWithFormat:@"%i", (int)inCode];
}
