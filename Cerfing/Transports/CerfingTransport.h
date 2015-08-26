#import <Foundation/Foundation.h>
@protocol CerfingTransportDelegate;

/** Abstracts the transport from the protocol, so that we can use
	TCHAP over other things than AsyncSockets. Abstract superclass. */
@interface CerfingTransport : NSObject
@property(nonatomic,weak) id<CerfingTransportDelegate> delegate;
@end

@interface CerfingTransport (AbstractMethods)
// For creating Transports without caring about the type of transport.
- (id)initListeningOnPort:(int)port delegate:(id<CerfingTransportDelegate>)delegate;
- (id)initConnectingToHost:(NSString*)host port:(int)port delegate:(id<CerfingTransportDelegate>)delegate;

// These methods have the same semantics as in AsyncSocket. Override them in your subclass.
- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)writeData:(NSData*)data withTimeout:(NSTimeInterval)timeout;
- (void)disconnect;
- (BOOL)isConnected;
@end

@protocol CerfingTransportDelegate <NSObject>
@optional
// Connected transport
- (void)transportDidConnect:(CerfingTransport*)transport;
- (void)transport:(CerfingTransport*)transport didReadData:(NSData*)data withTag:(long)tag;

// Listening transport
- (void)listeningTransport:(CerfingTransport*)listener acceptedConnection:(CerfingTransport*)incoming;

// Any transport
- (void)transport:(CerfingTransport*)transport willDisconnectWithError:(NSError*)err;
- (void)transportDidDisconnect:(CerfingTransport*)transport;
@end