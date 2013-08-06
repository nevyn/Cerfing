#import "TCAHPEmiConnectionTransport.h"

@interface TCAHPEmiConnectionTransport () <EmiConnectionDelegate>

@end

@implementation TCAHPEmiConnectionTransport
- (id)initWithConnection:(EmiConnection*)connection
{
	if(self = [super init]) {
		_connection = connection;
		[_connection setDelegate:self delegateQueue:dispatch_get_main_queue()];
	}
	return self;
}

- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag
{

}

- (void)writeData:(NSData*)data withTimeout:(NSTimeInterval)timeout
{

}

- (void)disconnect
{

}

- (BOOL)isConnected
{
	return _connection.open;
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
	[self.delegate transport:self didReadData:data withTag:<#(long)#>]
}

@end
