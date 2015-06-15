//
//  TCAHPPeerToPeerNode.h
//  
//
//  Created by Nevyn Bengtsson on 2015-06-14.
//
//

#import <Foundation/Foundation.h>
#import "TCAsyncHashProtocol.h"

// Similar to TCAHPSimpleServer, except that it is both a client and server, and sets up a fully
// connected mesh to everyone with the same bonjour service.
@interface TCAHPPeerToPeerServer : NSObject
- (id)initOnBasePort:(int)port serviceType:(NSString*)serviceType serviceName:(NSString*)serviceName delegate:(id)delegate error:(NSError**)err;
- (void)broadcast:(NSDictionary*)hash;

@end

@interface TCAHPP2PPeer : NSObject
@property(nonatomic) TCAsyncHashProtocol *incoming;
@property(nonatomic) TCAsyncHashProtocol *outgoing;
@property(nonatomic) NSString *name;
@end

@protocol TCAHPPeerToPeerNodeDelegate <NSObject, TCAsyncHashProtocolDelegate>
@optional
- (void)server:(TCAHPPeerToPeerServer*)server acceptedNewPeer:(TCAsyncHashProtocol*)proto;
- (void)server:(TCAHPPeerToPeerServer*)server lostPeer:(TCAsyncHashProtocol*)proto;
@end