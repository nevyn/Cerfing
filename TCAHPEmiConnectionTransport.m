#import "TCAHPEmiConnectionTransport.h"

@interface TCAHPEReadRequest : NSObject
@property(nonatomic) NSUInteger length;
@property(nonatomic) long tag;
- (id)initWithLength:(NSUInteger)length tag:(long)tag;
@end
@implementation TCAHPEReadRequest
- (id)initWithLength:(NSUInteger)length tag:(long)tag { if(self = [super init]) { _length = length; _tag = tag; } return self; }
@end

@interface TCAHPEmiConnectionTransport () <EmiConnectionDelegate>
{
	NSMutableArray *_readRequests;
	NSMutableData *_incomingBuffer;
}

@end

@implementation TCAHPEmiConnectionTransport
- (id)initWithConnection:(EmiConnection*)connection
{
	if(self = [super init]) {
		_readRequests = [NSMutableArray new];
		_incomingBuffer = [[NSMutableData alloc] init];
		_connection = connection;
		[_connection setDelegate:self delegateQueue:dispatch_get_main_queue()];
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
		[self.delegate transport:self didReadData:chunk withTag:req.tag];
		req = _readRequests.firstObject;
	}
}


- (void)emiConnectionOpened:(EmiConnection *)connection userData:(id)userData
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate emiConnectionOpened:connection userData:userData];
	
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
