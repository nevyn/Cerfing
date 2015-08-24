#import <Foundation/Foundation.h>
#import "TCAHPTransport.h"
@class AsyncSocket;

@protocol TCAsyncHashProtocolDelegate;

/**
	@typedef TCAsyncHashProtocolResponseCallback
	@abstract Called when you have a response to a request.
	You can store an instance of TCAsyncHashProtocolResponseCallback and
	call it later if you wish; you don't need to call it immediately
	after the request comes in.
*/
typedef void(^TCAsyncHashProtocolResponseCallback)(NSDictionary *response);

/**
	@typedef TCAsyncHashProtocolRequestCanceller
	@abstract Used to cancel (stop listening for) an outstanding request.
	Does not tell other party that request has been cancelled.
*/
typedef void(^TCAsyncHashProtocolRequestCanceller)();



/**
	@class TCAsyncHashProtocol
	@abstract Send and receive dictionaries with plist-safe values over a network connection.

	I like constructing simple network protocols from plist/json-safe dicts, and
	transmit them over the wire as json. Easy to prototype with, easy to debug.
	Give TCAsyncHashProtocol a socket, and this is what it'll do for you, plus
	support for request-response, and arbitrary NSData attachments.
*/
@interface TCAsyncHashProtocol : NSObject
@property(nonatomic,strong,readonly) TCAHPTransport *transport;
@property(nonatomic,weak,readwrite) id<TCAsyncHashProtocolDelegate> delegate;

/** Start using the socket 'transport' as a TCAHP transport. You can use `transport`'s normal
	send and receive methods, but if you want to send or receive dictionaries, you can call
	"readHash" and "sendHash" on it instead. If you want to dedicate the socket to sending and
	receiving dictionaries, use it with `autoReadHash` set to YES.
	@param transport   A transport wrapping a socket. Does not need to be connected yet.
	@param delegate	   A TCAHPDelegate. This delegate can also optionally respond to TCAHPTransportDelegate methods,
					   as well as the delegate methods of the socket that the transport is wrapping.
*/
-(id)initWithTransport:(TCAHPTransport*)transport delegate:(id<TCAsyncHashProtocolDelegate>)delegate;

/** Like -initWithTransport:delegate:, but a convenience method creating a transport wrapper around
	an AsyncSocket instance. Fails if you haven't compiled TCAHPAsyncSocketTransport.m into your target.*/
-(id)initWithSocket:(AsyncSocket*)sock delegate:(id<TCAsyncHashProtocolDelegate>)delegate;

/** Send any dictionary containing plist-safe types. */
-(void)sendHash:(NSDictionary*)hash;

/** Like above, but also attach an arbitrary payload. */
-(void)sendHash:(NSDictionary*)hash payload:(NSData*)payload;

/** like above, but you can define a callback for when the other side responds. */
-(TCAsyncHashProtocolRequestCanceller)requestHash:(NSDictionary*)hash response:(TCAsyncHashProtocolResponseCallback)response;

/** Ask this TCAHP to ask its AsyncSocket to listen for another hash.
	@note Must not be called while a hash is already being waited for. */
-(void)readHash;

/** @property autoReadHash
	@default YES
	Call readHash after each message. Un-set this to interleave TCAHP
	messages with your own custom protocol over the AsyncSocket. Will also
	call readHash after connection, but if you give TCAHP the socket after it's
	connected, you'll have to call readHash one initial time.
*/
@property(nonatomic) BOOL autoReadHash;

/** @property autoDispatchCommands
	@default NO
	If the incoming hash has the key 'command', use its value as the name of the selector
	to call instead of the delegate method, if implemented. Signature patterns, where %@ is the key:
	For command: -(void)command:(TCAsyncHashProtocol*)proto %@:(NSDictionary*)hash (optional payload:(NSData*)payload)
	For request: -(void)request:(TCAsyncHashProtocol*)proto %@:(NSDictionary*)hash responder:(TCAsyncHashProtocolResponseCallback)callback (optional payload:(NSData*)payload)
*/
@property(nonatomic) BOOL autoDispatchCommands;
@end


/** @protocol TCAsyncHashProtocolDelegate
	Hash, request and payload delivery and customization delegate methods.
	
	@note If you have set autoReadHash to NO, call readHash some time after receiving any of these
	      callbacks in order to continue receiving hashes.
*/
@protocol TCAsyncHashProtocolDelegate <NSObject, TCAHPTransportDelegate>
@optional
-(void)protocol:(TCAsyncHashProtocol*)proto receivedHash:(NSDictionary*)hash payload:(NSData*)payload;
-(void)protocol:(TCAsyncHashProtocol*)proto receivedRequest:(NSDictionary*)hash payload:(NSData*)payload responder:(TCAsyncHashProtocolResponseCallback)responder;

@optional
/** By default, TCAHP JSON serializes hashes. Implement these two methods to use some other serialization,
	such as plist, NSCoding, or gzipped json. */
- (NSData*)protocol:(TCAsyncHashProtocol*)proto serializeHash:(NSDictionary*)hash;
- (NSDictionary*)protocol:(TCAsyncHashProtocol*)proto unserializeHash:(NSData*)unhash;
@end

/** @abstract If used as a key in the sent hash, enables the behavior described
			  in @property autoDispatchCommands.
*/
extern NSString *const kTCCommand; /* = @"command" */
