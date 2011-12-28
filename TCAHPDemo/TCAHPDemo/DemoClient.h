#import "TCAsyncHashProtocol.h"

@interface DemoClient : NSObject <TCAsyncHashProtocolDelegate>
@property(copy) NSString *host;
@property(copy) NSString *messageToSet;
-(void)run;
@end
