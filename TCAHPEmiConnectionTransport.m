#import "TCAHPEmiConnectionTransport.h"
#import "EmiSocket.h"
#import "EmiSocketConfig.h"

@interface TCAHPEReadRequest : NSObject
@property(nonatomic) NSUInteger length;
@property(nonatomic) long tag;
- (id)initWithLength:(NSUInteger)length tag:(long)tag;
@end
@implementation TCAHPEReadRequest
- (id)initWithLength:(NSUInteger)length tag:(long)tag { if(self = [super init]) { _length = length; _tag = tag; } return self; }
@end

@interface TCAHPEmiConnectionTransport () <EmiConnectionDelegate, EmiSocketDelegate>
{
	NSMutableArray *_readRequests;
	NSMutableData *_incomingBuffer;
	EmiSocketConfig *_listenConfig;
	EmiSocket *_socket;
}

@end

@implementation TCAHPEmiConnectionTransport
- (id)initWithConnection:(EmiConnection*)connection delegate:(id<TCAHPTransportDelegate>)delegate
{
	if(self = [super init]) {
		self.delegate = delegate;
		_readRequests = [NSMutableArray new];
		_incomingBuffer = [[NSMutableData alloc] init];
		_connection = connection;
		[_connection setDelegate:self delegateQueue:dispatch_get_main_queue()];
	}
	return self;
}

- (id)initListeningOnPort:(int)port delegate:(id<TCAHPTransportDelegate>)delegate
{
	if(!(self = [super init]))
		return nil;
		
	self.delegate = delegate;
	
	_listenConfig = [EmiSocketConfig new];
	_listenConfig.acceptConnections = YES;
	_listenConfig.serverPort = port;
	if(![self listenAgain])
		return nil;
	
	return self;
}

- (BOOL)listenAgain
{
	_socket = [[EmiSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	NSError *err;
	if(![_socket startWithConfig:_listenConfig error:&err]) {
		[self.delegate transport:self willDisconnectWithError:err];
		return NO;
	}
	return YES;
}

- (id)initConnectingToHost:(NSString*)host port:(int)port delegate:(id<TCAHPTransportDelegate>)delegate
{
	if(!(self = [super init]))
		return nil;
	
	_socket = [[EmiSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	self.delegate = delegate;

	NSError *err;
	if(![_socket startWithError:&err]) {
		if([self.delegate respondsToSelector:@selector(transport:willDisconnectWithError:)])
			[self.delegate transport:self willDisconnectWithError:err];
		return nil;
	}
	
	if(![_socket connectToHost:host onPort:port delegate:self delegateQueue:dispatch_get_main_queue() userData:nil error:&err]) {
		if([self.delegate respondsToSelector:@selector(transport:willDisconnectWithError:)])
			[self.delegate transport:self willDisconnectWithError:err];
		return nil;
	}
	
	return self;
}

- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag
{
	[_readRequests addObject:[[TCAHPEReadRequest alloc] initWithLength:length tag:tag]];
	[self handleReadRequests];
}

- (void)writeData:(NSData*)data withTimeout:(NSTimeInterval)timeout
{
	NSError *err;
	BOOL success = [_connection send:data channelQualifier:EMI_CHANNEL_QUALIFIER_DEFAULT error:&err];
	(void)success;
	NSAssert(success == YES, @"Can't handle socket write failure %@", err);
}

- (void)disconnect
{
	[_connection close];
}

- (BOOL)isConnected
{
	return _connection.open;
}

- (void)handleReadRequests
{
	TCAHPEReadRequest *req = _readRequests.firstObject;
	while(req && req.length <= _incomingBuffer.length) {
		[_readRequests removeObjectAtIndex:0];
		
		NSData *chunk = [_incomingBuffer subdataWithRange:NSMakeRange(0, req.length)];
		[_incomingBuffer setData:[_incomingBuffer subdataWithRange:NSMakeRange(req.length, _incomingBuffer.length - req.length)]];
		if([self.delegate respondsToSelector:@selector(transport:didReadData:withTag:)])
			[self.delegate transport:self didReadData:chunk withTag:req.tag];
		req = _readRequests.firstObject;
	}
}

#pragma mark EmiSocket delegates
- (void)emiSocket:(EmiSocket *)socket gotConnection:(EmiConnection *)connection
{
	if(_listenConfig) {
		
		TCAHPEmiConnectionTransport *incomingTransport = [[TCAHPEmiConnectionTransport alloc] initWithConnection:connection delegate:self.delegate];
		[self.delegate listeningTransport:self acceptedConnection:incomingTransport];
		
		//[self listenAgain];
	} else { // connecting
		(void)[self initWithConnection:connection delegate:self.delegate];
		
		// TODO: figure out if this is needed, or if emiConnectionOpened: is used instead
		/*if([self.delegate respondsToSelector:@selector(transportDidConnect:)])
			[self.delegate transportDidConnect:self];*/
	}
}

#pragma mark EmiConnection delegates

- (void)emiConnectionOpened:(EmiConnection *)connection userData:(id)userData
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate emiConnectionOpened:connection userData:userData];
	if([self.delegate respondsToSelector:@selector(transportDidConnect:)])
		[self.delegate transportDidConnect:self];
}

- (void)emiConnectionFailedToConnect:(EmiSocket *)socket error:(NSError *)error userData:(id)userData
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate emiConnectionFailedToConnect:socket error:error userData:userData];
	if([self.delegate respondsToSelector:@selector(transportDidDisconnect:)])
		[self.delegate transportDidDisconnect:self];
}

- (void)emiConnectionDisconnect:(EmiConnection *)connection forReason:(EmiDisconnectReason)reason
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self emiConnectionDisconnect:connection forReason:reason];
	if([self.delegate respondsToSelector:@selector(transportDidDisconnect:)])
		[self.delegate transportDidDisconnect:self];
}

- (void)emiConnectionMessage:(EmiConnection *)connection channelQualifier:(EmiChannelQualifier)channelQualifier data:(NSData *)data;
{
	[_incomingBuffer appendData:data];
	[self handleReadRequests];
}

@end
