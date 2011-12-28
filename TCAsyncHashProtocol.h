#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

#if __has_feature(objc_arc)
#define TCAHP_WEAK weak
#else
#define TCAHP_WEAK unsafe_unretained
#endif

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
	@abstract Send and receive dicts with plist-safe values over an AsyncSocket.

	I like constructing simple network protocols from plist/json-safe dicts, and
	transmit them over the wire as json. Easy to prototype with, easy to debug.
	Give TCAsyncHashProtocol an AsyncSocket, and this is what it'll do for you, plus
	support for request-response, and arbitrary NSData attachments.
	
*/
@interface TCAsyncHashProtocol : NSObject <AsyncSocketDelegate>
@property(nonatomic,strong,readonly) AsyncSocket *socket;
@property(nonatomic,TCAHP_WEAK,readwrite) id<TCAsyncHashProtocolDelegate> delegate;

-(id)initWithSocket:(AsyncSocket*)sock delegate:(id<TCAsyncHashProtocolDelegate>)delegate;

/// Send any dictionary containing plist-safe types.
-(void)sendHash:(NSDictionary*)hash;

/// Like above, but also attach an arbitrary payload.
-(void)sendHash:(NSDictionary*)hash payload:(NSData*)payload;

/// like above, but you can define a callback for when the other side responds.
-(TCAsyncHashProtocolRequestCanceller)requestHash:(NSDictionary*)hash response:(TCAsyncHashProtocolResponseCallback)response;

/// Ask this TCAHP to ask its AsyncSocket to listen for another hash.
/// Must not be called while a hash is already being waited for.
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
	For command: -(void)command:(TCAsyncHashProtocol*)proto %@:(NSDictionary*)hash
	For request: -(void)request:(TCAsyncHashProtocol*)proto %@:(NSDictionary*)hash responder:(TCAsyncHashProtocolResponseCallback)callback
*/
@property(nonatomic) BOOL autoDispatchCommands;
@end


/** @protocol TCAsyncHashProtocolDelegate
	Hash, request and payload delivery delegate methods. Also extends AsyncSocketDelegate, so you can
	implement some of those as well if you want.
	
	@note If you have set autoReadHash to NO, call readHash some time after receiving any of these
	      callbacks in order to continue receiving hashes.
*/
@protocol TCAsyncHashProtocolDelegate <NSObject, AsyncSocketDelegate>
-(void)protocol:(TCAsyncHashProtocol*)proto receivedHash:(NSDictionary*)hash payload:(NSData*)payload;
-(void)protocol:(TCAsyncHashProtocol*)proto receivedRequest:(NSDictionary*)hash payload:(NSData*)payload responder:(TCAsyncHashProtocolResponseCallback)responder;
@end

/** @abstract If used as a key in the sent hash, enables the behavior described
			  in @property autoDispatchCommands.
*/
extern NSString *const kTCCommand; /* = @"command" */
