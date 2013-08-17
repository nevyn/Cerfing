#import "TCAHPTransport.h"
#import "AsyncSocket.h"

/** Wraps an AsyncSocket and uses it as transport for a TCAsyncHashProtocol. */
@interface TCAHPAsyncSocketTransport : TCAHPTransport
@property(nonatomic,readonly,retain) AsyncSocket *socket;
- (id)initWithSocket:(AsyncSocket*)socket delegate:(id<TCAHPTransportDelegate>)delegate;
@end
