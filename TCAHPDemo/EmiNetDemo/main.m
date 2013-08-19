#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "TCAsyncHashProtocol.h"
#import "TCAHPEmiConnectionTransport.h"
#import "DemoServer.h"
#import "DemoClient.h"


// Start with no args to start a client and server,
// start with one arg (hostname) to start a client
int main (int argc, const char * argv[])
{
	@autoreleasepool {
		if(argc == 1) {
			DemoServer *server = [DemoServer new];
			server.transportClass = [TCAHPEmiConnectionTransport class];
			[server run];
		}
		
		DemoClient *client = [DemoClient new];
		client.transportClass = [TCAHPEmiConnectionTransport class];
		client.host = argc>=2?@(argv[1]):@"10.0.1.2";
		client.messageToSet = argc>=3?@(argv[2]):nil;
		[client run];
		[[NSRunLoop currentRunLoop] run];
	}
	return 0;
}
