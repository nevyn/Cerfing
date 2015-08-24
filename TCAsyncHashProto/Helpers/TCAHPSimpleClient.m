//
//  TCAHPSimpleClient.m
//  TCAHPDemo
//
//  Created by Joachim Bengtsson on 2012-10-06.
//
//

#import "TCAHPSimpleClient.h"

@interface TCAHPSimpleClient () <NSNetServiceBrowserDelegate, NSNetServiceDelegate>
@end

@implementation TCAHPSimpleClient {
    NSNetServiceBrowser *_browser;
    AsyncSocket *_connectingSocket;
    NSString *_serviceType;
    id<TCAsyncHashProtocolDelegate> _delegate;
    NSMutableSet *_pendingResolve;
    NSMutableSet *_resolved;
}
- (id)initConnectingToAnyHostOfType:(NSString*)serviceType delegate:(id<TCAsyncHashProtocolDelegate>)delegate
{
    if(!(self = [super init]))
        return nil;
    
    _pendingResolve = [NSMutableSet new];
    _resolved = [NSMutableSet new];
    
    _browser = [[NSNetServiceBrowser alloc] init];
    _browser.delegate = self;
    _serviceType = serviceType;
    [_browser searchForServicesOfType:serviceType inDomain:@""];
    
    _delegate = delegate;
    
    return self;
}

- (void)reconnect;
{
    [_proto.transport disconnect];
    [_connectingSocket disconnect];
    _proto = nil;
    _connectingSocket = nil;

    if(_resolved.count > 0)
        [self connectToNetService:_resolved.anyObject];
}

- (void)connectToNetService:(NSNetService*)aNetService
{
    NSLog(@"Attempting connection to %@", aNetService);
    
    NSError *err;
    _connectingSocket = [[AsyncSocket alloc] initWithDelegate:self];
    for(NSData *address in aNetService.addresses)
        if(![_connectingSocket connectToAddress:address error:&err])
            NSLog(@"Failed connection to %@: %@", aNetService, err);
        else
            break;
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    NSLog(@"Attempting resolution of %@", aNetService);
    [_pendingResolve addObject:aNetService];
    aNetService.delegate = self;
    [aNetService resolveWithTimeout:5];
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing;
{
    [_pendingResolve removeObject:aNetService];
    [_resolved removeObject:aNetService];
}

- (void)netServiceDidResolveAddress:(NSNetService *)aNetService
{
    [_resolved addObject:aNetService];
    [_pendingResolve removeObject:aNetService];
    
    if (_proto || _connectingSocket)
        return;
    
    [self connectToNetService:aNetService];
}
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
{
    NSLog(@"Failed to resolve %@: %@", sender, errorDict);
    [_pendingResolve removeObject:sender];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Connected to %@", host);
    self.proto = [[TCAsyncHashProtocol alloc] initWithSocket:sock delegate:_delegate];
    _connectingSocket = nil;
	_proto.autoDispatchCommands = YES;
	[_proto readHash];
}
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"Disconnected %@", sock);
    _connectingSocket = nil;
    self.proto = nil;
    [_browser searchForServicesOfType:_serviceType inDomain:@""];
}
@end
