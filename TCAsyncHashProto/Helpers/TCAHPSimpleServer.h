//
//  TCAHPSimpleServer.h
//  TCAHPDemo
//
//  Created by Joachim Bengtsson on 2012-10-06.
//
//

#import <Foundation/Foundation.h>
#import "TCAsyncHashProtocol.h"

// Does some bonjour and listen socket boiler plate for you. Just set it up and implement some command: or request: methods on your delegate.
@interface TCAHPSimpleServer : NSObject
- (id)initOnBasePort:(int)port serviceType:(NSString*)serviceType serviceName:(NSString*)serviceName delegate:(id)delegate error:(NSError**)err;
- (void)broadcast:(NSDictionary*)hash;
@end

@protocol TCAHPSimpleServerDelegate <NSObject, TCAsyncHashProtocolDelegate>
@optional
- (void)server:(TCAHPSimpleServer*)server acceptedNewClient:(TCAsyncHashProtocol*)proto;
- (void)server:(TCAHPSimpleServer *)server lostClient:(TCAsyncHashProtocol*)proto;
@end