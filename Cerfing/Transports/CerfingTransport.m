#import "CerfingTransport.h"

@implementation CerfingTransport
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
@end
