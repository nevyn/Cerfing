#import <Foundation/Foundation.h>
#import "TCAsyncHashProtocol.h"
#import "TCAHPAsyncSocketTransport.h"
#import "DemoServer.h"
#import "DemoClient.h"

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
			server.transportClass = [TCAHPAsyncSocketTransport class];
			[server run];
			[[NSRunLoop currentRunLoop] run];
		}
	} else {
		@autoreleasepool {
			sleep(1); // allow server to start. don't do this in a real app...
			DemoClient *client = [DemoClient new];
			client.transportClass = [TCAHPAsyncSocketTransport class];
			client.host = argc>=2?@(argv[1]):@"localhost";
			client.messageToSet = argc>=3?@(argv[2]):nil;
			[client run];
			[[NSRunLoop currentRunLoop] run];
		}
	}
	return 0;
}
