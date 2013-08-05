#import <Foundation/Foundation.h>
@protocol TCAHPTransportDelegate;

/** Abstracts the transport from the protocol, so that we can use
	TCHAP over other things than AsyncSockets. Abstract subclass. */
@interface TCAHPTransport : NSObject
@property(nonatomic,weak) id<TCAHPTransportDelegate> delegate;
@end

@interface TCAHPTransport (AbstractMethods)
// These methods have the same semantics as in AsyncSocket. Override them in your subclass.
- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag;
- (void)writeData:(NSData*)data withTimeout:(NSTimeInterval)timeout;
- (void)disconnect;
- (BOOL)isConnected;
@end

@protocol TCAHPTransportDelegate <NSObject>
- (void)transportDidConnect:(TCAHPTransport*)transport;
- (void)transport:(TCAHPTransport*)transport didReadData:(NSData*)data withTag:(long)tag;
@optional
- (void)transportDidDisconnect:(TCAHPTransport*)transport;
@end