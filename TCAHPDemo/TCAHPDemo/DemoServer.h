#import "TCAsyncHashProtocol.h"
#import "AsyncSocket.h"

@interface DemoServer : NSObject <TCAsyncHashProtocolDelegate>
-(void)run;
@end