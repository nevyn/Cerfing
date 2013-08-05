#import "TCAHPTransport.h"

@implementation TCAHPTransport
@synthesize delegate = _delegate;

// Forward delegates.
-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector;
{
	if([super respondsToSelector:aSelector]) return [super methodSignatureForSelector:aSelector];
	if([_delegate respondsToSelector:aSelector]) return [(id)_delegate methodSignatureForSelector:aSelector];
	return nil;
}
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if([_delegate respondsToSelector:aSelector])
		return _delegate;
	return [super forwardingTargetForSelector:aSelector];
}
-(BOOL)respondsToSelector:(SEL)aSelector;
{
	return [super respondsToSelector:aSelector] || [_delegate respondsToSelector:aSelector];
}

// Abstract methods
- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[NSException raise:NSInvalidArgumentException format:@"Not implemented"];
}
- (void)writeData:(NSData*)data withTimeout:(NSTimeInterval)timeout
{
	[NSException raise:NSInvalidArgumentException format:@"Not implemented"];
}
- (void)disconnect
{
	[NSException raise:NSInvalidArgumentException format:@"Not implemented"];
}
@end
