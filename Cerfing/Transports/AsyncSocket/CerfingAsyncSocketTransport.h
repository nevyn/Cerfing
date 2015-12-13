#import <Cerfing/Transports/CerfingTransport.h>
#import "AsyncSocket.h"

/** Wraps an AsyncSocket and uses it as transport for a CerfingConnection. */
@interface CerfingAsyncSocketTransport : CerfingTransport
@property(nonatomic,readonly,retain) AsyncSocket *socket;
- (id)initWithSocket:(AsyncSocket*)socket delegate:(id<CerfingTransportDelegate>)delegate;
@end
