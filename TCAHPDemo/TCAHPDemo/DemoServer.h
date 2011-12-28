#import "TCAsyncHashProtocol.h"

@interface DemoServer : NSObject <TCAsyncHashProtocolDelegate>
-(void)run;
@end