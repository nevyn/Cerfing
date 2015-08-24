#import <Foundation/Foundation.h>
@protocol TCAHPTransportDelegate;

/** Abstracts the transport from the protocol, so that we can use
	TCHAP over other things than AsyncSockets. Abstract subclass. */
@interface TCAHPTransport : NSObject
@property(nonatomic,weak) id<TCAHPTransportDelegate> delegate;
@end

@interface TCAHPTransport (AbstractMethods)
// For creating Transports without caring about the type of transport.
- (id)initListeningOnPort:(int)port delegate:(id<TCAHPTransportDelegate>)delegate;
- (id)initConnectingToHost:(NSString*)host port:(int)port delegate:(id<TCAHPTransportDelegate>)delegate;

// These methods have the same semantics as in AsyncSocket. Override them in your subclass.
- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)writeData:(NSData*)data withTimeout:(NSTimeInterval)timeout;
- (void)disconnect;
- (BOOL)isConnected;
@end

@protocol TCAHPTransportDelegate <NSObject>
@optional
// Connected transport
- (void)transportDidConnect:(TCAHPTransport*)transport;
- (void)transport:(TCAHPTransport*)transport didReadData:(NSData*)data withTag:(long)tag;

// Listening transport
- (void)listeningTransport:(TCAHPTransport*)listener acceptedConnection:(TCAHPTransport*)incoming;

// Any transport
- (void)transport:(TCAHPTransport*)transport willDisconnectWithError:(NSError*)err;
- (void)transportDidDisconnect:(TCAHPTransport*)transport;
@end