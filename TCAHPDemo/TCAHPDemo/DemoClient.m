#import "DemoClient.h"
#import "TCAHPTransport.h"

@interface DemoClient ()  <TCAsyncHashProtocolDelegate, TCAHPTransportDelegate>
{
	TCAHPTransport *_transport;
	TCAsyncHashProtocol *_proto;
}
@end

@implementation DemoClient
@synthesize host=_host;
@synthesize messageToSet=_messageToSet;
-init;
{
	if(!(self = [super init])) return nil;
	
	return self;
}
-(void)run;
{
	NSLog(@"Client connecting to %@", _host);
	// Exactly equivalent to  [[[AsyncSocket alloc] initWithDelegate:self] connectToHost:_host onPort:kPort error:nil]
	_transport = [[self.transportClass alloc] initConnectingToHost:_host port:kPort delegate:self];
}
- (void)transportDidConnect:(TCAHPTransport*)transport;
{
	NSLog(@"Client connected!");
	_proto = [[TCAsyncHashProtocol alloc] initWithTransport:transport delegate:self];
	
	// Dispatch on selector of the incoming command instead of using delegate methods.
	_proto.autoDispatchCommands = YES;
	
	// Start reading from the socket.
	[_proto readHash];
	
	if(_messageToSet)
		[_proto requestHash:@{
			@"command": @"setMessage",
			@"contents": _messageToSet
		} response:^(NSDictionary *response) {
			if([response[@"success"] boolValue])
				NSLog(@"Successfully updated message!");
			else
				NSLog(@"Couldn't set message :( %@", response[@"reason"]);
			exit(0);
		}];
}

- (void)transport:(TCAHPTransport *)transport willDisconnectWithError:(NSError *)err
{
	NSLog(@"Client transport disconnection: %@", err);
}

-(void)command:(TCAsyncHashProtocol*)proto displayMessage:(NSDictionary*)hash;
{
	NSLog(@"Incoming message: %@", hash[@"contents"]);
}


-(void)protocol:(TCAsyncHashProtocol*)proto receivedHash:(NSDictionary*)hash payload:(NSData*)payload;
{
	// If we reach this delegate, command delegation failed and we don't understand
	// the command
	NSLog(@"Invalid command: %@", hash);
	[proto.transport disconnect];
}
-(void)protocol:(TCAsyncHashProtocol*)proto receivedRequest:(NSDictionary*)hash payload:(NSData*)payload responder:(TCAsyncHashProtocolResponseCallback)responder;
{
	NSLog(@"Invalid request: %@", hash);
	[proto.transport disconnect];
}
@end