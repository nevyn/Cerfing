#import "CerfingAsyncSocketTransport.h"

@interface CerfingAsyncSocketTransport () <AsyncSocketDelegate>
@end

@implementation CerfingAsyncSocketTransport
@synthesize socket = _socket;

- (id)initListeningOnPort:(int)port delegate:(id<CerfingTransportDelegate>)delegate
{
	if(!(self = [self initWithSocket:[[AsyncSocket alloc] initWithDelegate:self] delegate:delegate]))
		return nil;
	
	NSError *err;
	if(![_socket acceptOnPort:port error:&err]) {
		if([delegate respondsToSelector:@selector(transport:willDisconnectWithError:)])
			[delegate transport:self willDisconnectWithError:err];
		return nil;
	}
	
	return self;
}

- (id)initConnectingToHost:(NSString*)host port:(int)port delegate:(id<CerfingTransportDelegate>)delegate
{
	if(!(self = [self initWithSocket:[[AsyncSocket alloc] initWithDelegate:self] delegate:delegate]))
		return nil;
	
	NSError *err;
	if(![_socket connectToHost:host onPort:port error:&err]) {
		if([delegate respondsToSelector:@selector(transport:willDisconnectWithError:)])
			[delegate transport:self willDisconnectWithError:err];
		return nil;
	}
	
	return self;
}


- (id)initWithSocket:(AsyncSocket*)socket delegate:(id<CerfingTransportDelegate>)delegate
{
	if(self = [super init]) {
		_socket = socket;
		_socket.delegate = self;
		self.delegate = delegate;
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

- (NSString*)description
{
	return [NSString stringWithFormat:@"<%@ @ %p - %@>", NSStringFromClass([self class]), self, _socket];
}

#pragma mark AsyncSocket delegates

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate onSocket:sock didAcceptNewSocket:newSocket];
	
	if([self.delegate respondsToSelector:@selector(listeningTransport:acceptedConnection:)]) {
		CerfingAsyncSocketTransport *newTransport = [[CerfingAsyncSocketTransport alloc] initWithSocket:newSocket delegate:self.delegate];
		[self.delegate listeningTransport:self acceptedConnection:newTransport];
	}
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate onSocket:sock didConnectToHost:host port:port];
	if([self.delegate respondsToSelector:@selector(transportDidConnect:)])
		[self.delegate transportDidConnect:self];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate onSocket:sock willDisconnectWithError:err];
	if([self.delegate respondsToSelector:@selector(transport:willDisconnectWithError:)])
		[self.delegate transport:self willDisconnectWithError:err];
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
	if([self.delegate respondsToSelector:@selector(transport:didReadData:withTag:)])
		[self.delegate transport:self didReadData:data withTag:tag];
}

@end
