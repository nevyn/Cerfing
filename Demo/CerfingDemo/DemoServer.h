#import <Foundation/Foundation.h>

@interface DemoServer : NSObject
-(void)run;
@property(nonatomic) Class transportClass;
@end