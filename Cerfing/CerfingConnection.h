#import <Foundation/Foundation.h>
#import <Cerfing/Transports/CerfingTransport.h>
#import <Cerfing/CerfingSerializer.h>
@class AsyncSocket;
@protocol CerfingConnectionDelegate;

/*!
	@file CerfingConnection
	
	I like constructing simple network protocols from plist/json-safe dicts, and
	transmit them over the wire as json. Easy to prototype with, easy to debug.
	Give CerfingConnection a socket, and this is what it'll do for you, plus
	support for request-response, and arbitrary NSData attachments.
*/



/*!
	@typedef CerfingResponseCallback
	@abstract Called when you have a response to a request.
	You can store an instance of CerfingResponseCallback and
	call it later if you wish; you don't need to call it immediately
	after the request comes in.
*/
typedef void(^CerfingResponseCallback)(NSDictionary *response);

/*!
	@typedef CerfingRequestCanceller
	@abstract Used to cancel (stop listening for) an outstanding request.
	Does not tell other party that request has been cancelled.
*/
typedef void(^CerfingRequestCanceller)();



/*!
	@class CerfingConnection
	@abstract Send and receive dictionaries with plist-safe values over some kind
	of network connection (a 'transport').
*/
@interface CerfingConnection : NSObject

/*! 
	@method initWithTransport:delegate:
	@abstract Start using the socket 'transport' as a Cerfing transport. By default,
			  this connection takes over the transport and dedicates it to sending and
			  receiving commands and requests. @see 'automaticallyReadsDicts' if you
			  want to customize this behavior.
	@param transport   A transport wrapping a socket. Does not need to be connected yet.
	@param delegate	   A CerfingConnectionDelegate. This delegate can also optionally
					   respond to CerfingTransportDelegate methods, as well as the delegate
					   methods of the socket that the transport is wrapping.
*/
-(id)initWithTransport:(CerfingTransport*)transport delegate:(id<CerfingConnectionDelegate>)delegate;

/*!
	Like -initWithTransport:delegate:, but a convenience method creating a transport wrapper around
	an AsyncSocket instance. Fails if you haven't compiled CerfingAsyncSocketTransport.m into your target.
*/
-(id)initWithSocket:(AsyncSocket*)sock delegate:(id<CerfingConnectionDelegate>)delegate;


/*!
	@property transport
	@abstract Abstract wrapper around some kind of network connection. Cerfing is built
			  to work well with AsyncSocket, but Transports can also wrap other network
			  libraries. */
@property(nonatomic,strong,readonly) CerfingTransport *transport;

/*!
	@property delegate
	@abstract The delegate is the object that receives commands, requests and other
			  delegate methods related to the functionality of this connection. */
@property(nonatomic,weak,readwrite) id<CerfingConnectionDelegate> delegate;

/*!
	@property serializer
	@abstract Choose the wire format for serializing dictionary data
	@default +[CerfingSerializer JSONSerializer]
*/
@property(nonatomic,strong,readwrite) CerfingSerializer *serializer;


/*!
	Send any dictionary containing plist-safe types to the other side. Add the
	key 'command' to the dictionary to make it auto-dispatch (see 'automaticallyDispatchCommands')
*/
-(void)sendDict:(NSDictionary*)dictionary;

/*!
	Like sendDictionary:, but also attach an arbitrary NSData payload.
*/
-(void)sendDict:(NSDictionary*)dictionary payload:(NSData*)payload;

/*! Like 'sendDict:', but also indicating that you also want a response back.
	The 'response' callback will be called when the other side responds.
*/
-(CerfingRequestCanceller)requestDict:(NSDictionary*)dict response:(CerfingResponseCallback)response;

/*!
	@property automaticallyReadsDicts
	@default YES
	@abstract Dedicate the transport to being used exclusively for sending dicts using this
	CerfingConnection.
	
	You can set this property to NO to interleave Cerfing messages with your own custom protocol,
	and call 'readHash' manually whenever the next received message is expected to be a Cerfing message.
	
	@note If you create this Connection with the Transport *after* it's connected,
		  you need to manually call 'readDict' once, even if 'automaticallyReadsDicts' is set to YES.
*/
@property(nonatomic) BOOL automaticallyReadsDicts;

/*!
	@method readDict
	@abstract Ask this connection to ask its Transport (e g AsyncSocket) to listen for another dictionary.
	@note Must not be called while a dictionary is already being waited for. */
-(void)readDict;

/*! @property automaticallyDispatchCommands
	@default NO
	
	If the incoming dictionary has the key 'command', use its value as the name of the selector
	to call instead of the delegate method, if implemented. This lets you split handling of the network
	protocol into multiple methods without having a big 'else if' block in your delegate method.
	
	Selector signature patterns, where %@ is the value for the key 'command':
	For command: -(void)command:(CerfingConnection*)proto %@:(NSDictionary*)dict {optional payload:(NSData*)payload}
	For request: -(void)request:(CerfingConnection*)proto %@:(NSDictionary*)dict responder:(CerfingResponseCallback)callback {optional payload:(NSData*)payload}
*/
@property(nonatomic) BOOL automaticallyDispatchCommands;
@end


/** @protocol CerfingConnectionDelegate
	Dictionary, request and payload delivery and customization delegate methods.
	
	@note If you have set automaticallyReadsDicts to NO, call readDict some time after receiving any of these
	      callbacks in order to continue receiving hashes.
	
	@note If automaticallyDispatchCommands is on, this delegate will also receive
		  -command::: and -request:::: messages, even if none of the below methods
		  are implemented.
*/
@protocol CerfingConnectionDelegate <NSObject, CerfingTransportDelegate>
@optional
-(void)connection:(CerfingConnection*)proto receivedDict:(NSDictionary*)hash payload:(NSData*)payload;
-(void)connection:(CerfingConnection*)proto receivedRequest:(NSDictionary*)hash payload:(NSData*)payload responder:(CerfingResponseCallback)responder;
@end

/** @abstract If used as a key in the sent hash, enables the behavior described
			  in @property automaticallyDispatchCommands.
*/
extern NSString *const kCerfingCommand; /* = @"command" */
