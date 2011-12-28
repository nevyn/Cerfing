#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "TCAsyncHashProtocol.h"
#import "DemoServer.h"
#import "DemoClient.h"

static const int kPort = 12345;

// Start with no args to start a client and server,
// start with one arg (hostname) to start a client
int main (int argc, const char * argv[])
{
	// Split into a server and client process.
	pid_t child = 0;
	if(argc == 1)
		child = fork();
	
	if(argc == 1 && child) { // parent process
		@autoreleasepool {
			DemoServer *server = [DemoServer new];
			[server run];
			[[NSRunLoop currentRunLoop] run];
		}
	} else {
		@autoreleasepool {
			sleep(1); // allow server to start. don't do this in a real app...
			DemoClient *client = [DemoClient new];
			client.host = argc>=2?[NSString stringWithUTF8String:argv[1]]:@"localhost";
			client.messageToSet = argc>=3?[NSString stringWithUTF8String:argv[2]]:nil;
			[client run];
			[[NSRunLoop currentRunLoop] run];
		}
	}
	return 0;
}
