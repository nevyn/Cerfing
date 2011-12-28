#import "NSString+UUID.h"

@implementation NSString (UUID)
+(NSString*)dt_uuid;
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidS = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
	return uuidS;
}
@end
