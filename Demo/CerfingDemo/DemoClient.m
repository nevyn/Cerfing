#import "DemoClient.h"
#import <Cerfing/Cerfing.h>

@interface DemoClient ()  <CerfingConnectionDelegate, CerfingTransportDelegate>
{
	CerfingTransport *_transport;
	CerfingConnection *_proto;
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
- (void)transportDidConnect:(CerfingTransport*)transport;
{
	NSLog(@"Client connected!");
	_proto = [[CerfingConnection alloc] initWithTransport:transport delegate:self];
	
	// Dispatch on selector of the incoming command instead of using delegate methods.
	_proto.automaticallyDispatchCommands = YES;
	
	// Start reading from the socket.
	[_proto readDict];
	
	if(_messageToSet)
		[_proto requestDict:@{
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

- (void)transport:(CerfingTransport *)transport willDisconnectWithError:(NSError *)err
{
	NSLog(@"Client transport disconnection: %@", err);
}

// Command auto-dispatch will call this method since we're the proto's delegate when an incoming request dictionary contains
// the key-value pair {@"command": @"setMessage"}.
-(void)command:(CerfingConnection*)proto displayMessage:(NSDictionary*)hash;
{
	NSLog(@"Incoming message: %@", hash[@"contents"]);
}

@end