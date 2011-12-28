#import "DemoClient.h"

@implementation DemoClient {
	AsyncSocket *_socket;
	TCAsyncHashProtocol *_proto;
}
@synthesize host=_host;
@synthesize messageToSet=_messageToSet;
-init;
{
	if(!(self = [super init])) return nil;
	
	_socket = [[AsyncSocket alloc] initWithDelegate:self];
	
	
	return self;
}
-(void)run;
{
	[_socket connectToHost:_host onPort:kPort error:nil];
}
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
{
	_proto = [[TCAsyncHashProtocol alloc] initWithSocket:sock delegate:self];
	
	// Dispatch on selector of the incoming command instead of using delegate methods.
	_proto.autoDispatchCommands = YES;
	
	// Start reading from the socket.
	[_proto readHash];
	
	
	if(_messageToSet)
		[_proto requestHash:[NSDictionary dictionaryWithObjectsAndKeys:
			@"setMessage", @"command",
			_messageToSet, @"contents",
		nil] response:^(NSDictionary *response) {
			if([[response objectForKey:@"success"] boolValue])
				NSLog(@"Successfully updated message!");
			else
				NSLog(@"Couldn't set message :( %@", [response objectForKey:@"reason"]);
			exit(0);
		}];

}

-(void)command:(TCAsyncHashProtocol*)proto displayMessage:(NSDictionary*)hash;
{
	NSLog(@"Incoming message: %@", [hash objectForKey:@"contents"]);
}


-(void)protocol:(TCAsyncHashProtocol*)proto receivedHash:(NSDictionary*)hash payload:(NSData*)payload;
{
	// If we reach this delegate, command delegation failed and we don't understand
	// the command
	NSLog(@"Invalid command: %@", hash);
	[proto.socket disconnect];
}
-(void)protocol:(TCAsyncHashProtocol*)proto receivedRequest:(NSDictionary*)hash payload:(NSData*)payload responder:(TCAsyncHashProtocolResponseCallback)responder;
{
	NSLog(@"Invalid request: %@", hash);
	[proto.socket disconnect];
}
@end