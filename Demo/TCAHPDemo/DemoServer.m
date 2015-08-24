#import "DemoServer.h"
#import "TCAHPTransport.h"

@interface DemoServer () <TCAsyncHashProtocolDelegate, TCAHPTransportDelegate>
{
	TCAHPTransport *_listen;
	NSMutableArray *_clients;
	NSTimer *_timer;
	NSString *_message;
}
@end

@implementation DemoServer
-init;
{
	if(!(self = [super init])) return nil;
	_clients = [NSMutableArray new];
	_message = @"Hello world!";
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(scheduledBroadcast) userInfo:nil repeats:YES];
	
	return self;
}

-(void)run;
{
	// Exactly equivalent to [[[AsyncSocket alloc] initWithDelegate:self] acceptOnPort:kPort error:NULL]
	_listen = [[self.transportClass alloc] initListeningOnPort:kPort delegate:self];
	NSLog(@"Server running");
}

- (void)listeningTransport:(TCAHPTransport*)listener acceptedConnection:(TCAHPTransport*)incoming
{
	// The TCAHP takes ownership of the socket and becomes its delegate. We only need to implement
	// TCAHP's delegate now.
	TCAsyncHashProtocol *proto = [[TCAsyncHashProtocol alloc] initWithTransport:incoming delegate:self];
	
	// Dispatch on selector of the incoming command instead of using delegate methods.
	proto.autoDispatchCommands = YES;
	
	NSLog(@"Server accepted new socket %@", incoming);
	
	// Hang on to it, or else it has no owner and will disconnect.
	[_clients addObject:proto];
}

- (void)transport:(TCAHPTransport *)transport willDisconnectWithError:(NSError *)err
{
    if(transport == _listen)
		NSLog(@"Listen error: %@", err);
	else
		NSLog(@"Client %@ error: %@", transport, err);
}

- (void)transportDidDisconnect:(TCAHPTransport*)transport
{
	TCAsyncHashProtocol *proto = nil;
	for(TCAsyncHashProtocol *potential in _clients)
		if(potential.transport == transport) proto = potential;
	
	NSLog(@"Removing disconnected client %@", transport);
	
	[_clients removeObject:proto];
}

-(void)broadcast:(NSDictionary*)hash;
{
	for(TCAsyncHashProtocol *proto in _clients)
		[proto sendHash:hash];
}

-(void)scheduledBroadcast;
{
	[self broadcast:@{
		@"command": @"displayMessage",
		@"contents": _message
	}];
}

-(void)request:(TCAsyncHashProtocol*)proto setMessage:(NSDictionary*)hash responder:(TCAsyncHashProtocolResponseCallback)respond;
{
	NSString *newMessage = hash[@"contents"];
	
	NSLog(@"Changing message to %@", newMessage);
	
	if([newMessage rangeOfString:@"noob"].location != NSNotFound) {
		respond(@{
			@"success": @NO,
			@"reason": @"Be kind!"
		});
	} else {
		_message = newMessage;
		respond(@{
			@"success": @YES
		});
	}
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