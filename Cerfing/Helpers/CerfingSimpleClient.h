//
//  CerfingSimpleClient.h
//  CerfingDemo
//
//  Created by Joachim Bengtsson on 2012-10-06.
//
//

#import <Foundation/Foundation.h>
#import "CerfingConnection.h"
#import "AsyncSocket.h"

// Just finds the first Bonjour service it can find, connects, and forwards commands to you if it's connected.
@interface CerfingSimpleClient : NSObject
@property(strong) CerfingConnection *proto;
- (id)initConnectingToAnyHostOfType:(NSString*)serviceType delegate:(id<CerfingConnectionDelegate>)delegate;
- (void)reconnect;
@end
