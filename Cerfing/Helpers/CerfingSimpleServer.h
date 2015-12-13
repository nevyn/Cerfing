//
//  CerfingSimpleServer.h
//  CerfingDemo
//
//  Created by Joachim Bengtsson on 2012-10-06.
//
//

#import <Foundation/Foundation.h>
#import <Cerfing/CerfingConnection.h>

// Does some bonjour and listen socket boiler plate for you. Just set it up and implement some command: or request: methods on your delegate.
@interface CerfingSimpleServer : NSObject
- (id)initOnBasePort:(int)port serviceType:(NSString*)serviceType serviceName:(NSString*)serviceName delegate:(id)delegate error:(NSError**)err;
- (void)broadcast:(NSDictionary*)hash;
@end

@protocol CerfingSimpleServerDelegate <NSObject, CerfingConnectionDelegate>
@optional
- (void)server:(CerfingSimpleServer*)server acceptedNewClient:(CerfingConnection*)proto;
- (void)server:(CerfingSimpleServer *)server lostClient:(CerfingConnection*)proto;
@end