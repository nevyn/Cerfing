#import "TCAsyncHashProtocol.h"

@interface DemoServer : NSObject <TCAsyncHashProtocolDelegate>
-(void)run;
@property(nonatomic) Class transportClass;
@end