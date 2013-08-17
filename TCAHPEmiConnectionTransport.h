#import "TCAHPTransport.h"
#import "EmiConnection.h"

/** Wraps an EmiConnection and uses it as a transport for a TCAsyncHashProtocol. */
@interface TCAHPEmiConnectionTransport : TCAHPTransport
@property(nonatomic,readonly,retain) EmiConnection *connection;
- (id)initWithConnection:(EmiConnection*)connection delegate:(id<TCAHPTransportDelegate>)delegate;
@end
