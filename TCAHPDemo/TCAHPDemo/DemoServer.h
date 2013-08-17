#import "TCAsyncHashProtocol.h"

@interface DemoServer : NSObject
-(void)run;
@property(nonatomic) Class transportClass;
@end