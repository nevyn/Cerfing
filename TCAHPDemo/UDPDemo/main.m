//
//  main.m
//  UDPDemo
//
//  Created by Nevyn Bengtsson on 2015-07-05.
//
//

#import <Foundation/Foundation.h>
#import "AsyncUdpSocket.h"

@interface UDPDemo : NSObject
@end
@implementation UDPDemo
{
	AsyncUdpSocket *_server;
	AsyncUdpSocket *_client;
}
- (void)main
{
	_server = [[AsyncUdpSocket alloc] initWithDelegate:self];
	_server.reusingPort = YES;

	NSError *err;
	if(![_server bindToAddress:@"localhost" port:12347 error:&err]) {
		NSLog(@"Bind error: %@", err);
		exit(1);
	}
	[_server receiveWithTimeout:-1 tag:0];
	
	_client = [[AsyncUdpSocket alloc] initWithDelegate:self];
	_client.reusingPort = YES;
	if(![_client connectToHost:@"localhost" onPort:12348 error:&err]) {
		NSLog(@"Connect error: %@", err);
		exit(1);
	}
	
	[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(tick) userInfo:NULL repeats:YES];
}
- (void)tick
{
	NSData *tosend = [[[[[NSProcessInfo processInfo] arguments] subarrayWithRange:NSMakeRange(1, [[[NSProcessInfo processInfo] arguments] count]-1)] componentsJoinedByString:@" "] dataUsingEncoding:NSUTF8StringEncoding];
	[_client	sendData:tosend withTimeout:-1 tag:0];
}
- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock
     didReceiveData:(NSData *)data
            withTag:(long)tag
           fromHost:(NSString *)host
               port:(UInt16)port
{
	NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"Incoming: %@", s);
	[_server receiveWithTimeout:-1 tag:0];
	return YES;
}
@end

int main(int argc, const char * argv[]) {
	@autoreleasepool {
		UDPDemo *demo = [UDPDemo new];
		[demo main];
		[[NSRunLoop mainRunLoop] run];
	}
    return 0;
}
