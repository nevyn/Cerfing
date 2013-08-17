#import "TCAsyncHashProtocol.h"

@interface DemoClient : NSObject
@property(copy) NSString *host;
@property(copy) NSString *messageToSet;
@property(nonatomic) Class transportClass;
-(void)run;
@end
