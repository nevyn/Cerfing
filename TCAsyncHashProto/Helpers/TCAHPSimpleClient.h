//
//  TCAHPSimpleClient.h
//  TCAHPDemo
//
//  Created by Joachim Bengtsson on 2012-10-06.
//
//

#import <Foundation/Foundation.h>
#import "TCAsyncHashProtocol.h"
#import "AsyncSocket.h"

// Just finds the first Bonjour service it can find, connects, and forwards commands to you if it's connected.
@interface TCAHPSimpleClient : NSObject
@property(strong) TCAsyncHashProtocol *proto;
- (id)initConnectingToAnyHostOfType:(NSString*)serviceType delegate:(id<TCAsyncHashProtocolDelegate>)delegate;
- (void)reconnect;
@end
