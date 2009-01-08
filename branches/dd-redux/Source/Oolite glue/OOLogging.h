#import "Logging.h"


#define OOLog(msgClass, format, ...)	LogWithFormat(format, ## __VA_ARGS__)
#define OOLogGenericParameterError()	OOLog(_, @"***** %s: bad parameters. (This is an internal programming error, please report it.)", __PRETTY_FUNCTION__)
#define OOLogGenericSubclassResponsibility()	OOLog(_, @"***** %s is a subclass responsibility. (This is an internal programming error, please report it.)", __PRETTY_FUNCTION__)


#define kOOLogAllocationFailure @"general.error.allocationFailure"


#define OOLogAlloc(obj) do{}while(0)
