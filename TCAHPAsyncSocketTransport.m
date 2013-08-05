#import "TCAHPAsyncSocketTransport.h"

@interface TCAHPAsyncSocketTransport () <AsyncSocketDelegate>
@end

@implementation TCAHPAsyncSocketTransport
@synthesize socket = _socket;

- (id)initWithSocket:(AsyncSocket*)socket
{
	if(self = [super init]) {
		_socket = socket;
		_socket.delegate = self;
	}
	return self;
}

- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[_socket readDataToLength:length withTimeout:timeout tag:tag];
}

- (void)writeData:(NSData*)data withTimeout:(NSTimeInterval)timeout
{
	[_socket writeData:data withTimeout:timeout tag:0];
}

- (void)disconnect
{
	[_socket disconnect];
}

- (BOOL)isConnected
{
	return [_socket isConnected];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate onSocket:sock didConnectToHost:host port:port];
	
	[self.delegate transportDidConnect:self];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate onSocketDidDisconnect:sock];
	if([self.delegate respondsToSelector:@selector(transportDidDisconnect:)])
		[self.delegate transportDidDisconnect:self];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate onSocket:sock didReadData:data withTag:tag];
	
	[self.delegate transport:self didReadData:data withTag:tag];
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"<%@ @ %p - %@>", NSStringFromClass([self class]), self, _socket];
}

@end
