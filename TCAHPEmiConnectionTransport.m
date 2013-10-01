#import "TCAHPEmiConnectionTransport.h"
#import <EmiNet/EmiSocket.h>
#import <EmiNet/EmiSocketConfig.h>

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
	int _listenPort;
	BOOL _isListening;
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
	_isListening = YES;
	_listenPort = port;
	if(![self startListening])
		return nil;
	
	return self;
}

- (BOOL)startListening
{
	NSLog(@"TCAHPECT about to listen");
	EmiSocketConfig *listenConfig = [EmiSocketConfig new];
	listenConfig.acceptConnections = YES;
	listenConfig.serverPort = _listenPort;
	_socket = [[EmiSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	NSError *err;
	if(![_socket startWithConfig:listenConfig error:&err]) {
		[self.delegate transport:self willDisconnectWithError:err];
		return NO;
	}
	
	NSLog(@"TCAHPECT listening");
	return YES;
}

- (id)initConnectingToHost:(NSString*)host port:(int)port delegate:(id<TCAHPTransportDelegate>)delegate
{
	if(!(self = [super init]))
		return nil;
	
	self.delegate = delegate;
	_socket = [[EmiSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	NSError *err;
	
	EmiSocketConfig *connectionConfig = [EmiSocketConfig new];
	if(![_socket startWithConfig:connectionConfig error:&err]) {
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
	TCAHPEReadRequest *req = _readRequests.count ? _readRequests[0] : nil;
	while(req && req.length <= _incomingBuffer.length) {
		[_readRequests removeObjectAtIndex:0];
		
		NSData *chunk = [_incomingBuffer subdataWithRange:NSMakeRange(0, req.length)];
		[_incomingBuffer setData:[_incomingBuffer subdataWithRange:NSMakeRange(req.length, _incomingBuffer.length - req.length)]];
		if([self.delegate respondsToSelector:@selector(transport:didReadData:withTag:)])
			[self.delegate transport:self didReadData:chunk withTag:req.tag];
		req = _readRequests.count ? _readRequests[0] : nil;
	}
}

#pragma mark EmiSocket delegates
- (void)emiSocket:(EmiSocket *)socket gotConnection:(EmiConnection *)connection
{
	NSAssert(_isListening, @"Should only get connection if listen");
		
	TCAHPEmiConnectionTransport *incomingTransport = [[TCAHPEmiConnectionTransport alloc] initWithConnection:connection delegate:self.delegate];
	[self.delegate listeningTransport:self acceptedConnection:incomingTransport];
}

#pragma mark EmiConnection delegates

- (void)emiConnectionOpened:(EmiConnection *)connection userData:(id)userData
{
	NSAssert(!_isListening, @"Should only get connection opened if not listen");
	(void)[self initWithConnection:connection delegate:self.delegate];
	
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate emiConnectionOpened:connection userData:userData];
	if([self.delegate respondsToSelector:@selector(transportDidConnect:)])
		[self.delegate transportDidConnect:self];
}

- (void)emiConnectionFailedToConnect:(EmiSocket *)socket error:(NSError *)error userData:(id)userData
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate emiConnectionFailedToConnect:socket error:error userData:userData];
	if([self.delegate respondsToSelector:@selector(transport:willDisconnectWithError:)])
		[self.delegate transport:self willDisconnectWithError:error];
}

- (void)emiConnectionDisconnect:(EmiConnection *)connection forReason:(EmiDisconnectReason)reason
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self emiConnectionDisconnect:connection forReason:reason];
	if([self.delegate respondsToSelector:@selector(transport:willDisconnectWithError:)])
		[self.delegate transport:self willDisconnectWithError:[NSError
			errorWithDomain:@"eminet.reason"
			code:reason
			userInfo:@{
				NSLocalizedDescriptionKey:
					reason==EMI_REASON_THIS_HOST_CLOSED ? @"this host closed" :
					reason==EMI_REASON_OTHER_HOST_CLOSED ? @"other host closed" :
					reason==EMI_REASON_CONNECTION_TIMED_OUT? @"timeout" :
					reason==EMI_REASON_OTHER_HOST_DID_NOT_RESPOND ? @"other host did not respond" :
					@"unknown"
			}
		]];
	if([self.delegate respondsToSelector:@selector(transportDidDisconnect:)])
		[self.delegate transportDidDisconnect:self];
}

- (void)emiConnectionMessage:(EmiConnection *)connection channelQualifier:(EmiChannelQualifier)channelQualifier data:(NSData *)data;
{
	[_incomingBuffer appendData:data];
	[self handleReadRequests];
}

@end
