#import "CerfingConnection.h"

// Shadow interface. Not doing an import, so that a Cerfing library user can choose
// to not compile in AsyncSocket support.
@interface CerfingAsyncSocketTransport : CerfingTransport
- (id)initWithSocket:(AsyncSocket*)socket delegate:(id<CerfingTransportDelegate>)delegate;
@end


#if !__has_feature(objc_arc)
#error This file must be compiled with -fobjc-arc.
#endif

#define TC_DEBUG_HASHPROTO 0

#if TC_DEBUG_HASHPROTO
#define TCLog(...) NSLog(__VA_ARGS__)
#else
#define TCLog(...)
#endif

static NSString *TCUUID(void);

enum {
	kTagLength = 1001,
	kTagData,
	kTagPayload,
};

// Private keys
static NSString *const kCerfingRequestKey = @"__cerfing-requestKey";
static NSString *const kCerfingResponseKey = @"__cerfing-responseKey";
static NSString *const kCerfingPayloadSizeKey = @"__cerfing-payloadSize";
// Public keys
NSString *const kCerfingCommand = @"command";

@interface CerfingConnection () <CerfingTransportDelegate>
@property(nonatomic,strong,readwrite) CerfingTransport *transport;
@end

@implementation CerfingConnection {
	NSMutableDictionary *requests;
	NSDictionary *savedHash;
	BOOL _hasOutstandingHashRead;
}
@synthesize transport = _transport, delegate = _delegate, automaticallyReadsDicts = _automaticallyReadsDicts;
@synthesize automaticallyDispatchCommands = _automaticallyDispatchCommands;

-(id)initWithTransport:(CerfingTransport*)transport delegate:(id<CerfingConnectionDelegate>)delegate
{
	if(!transport) return nil;
	
	if(!(self = [super init])) return nil;
	
	self.transport = transport;
	self.serializer = [CerfingSerializer JSONSerializer];
	_automaticallyReadsDicts = YES;
	_transport.delegate = self;
	_delegate = delegate;
	requests = [NSMutableDictionary dictionary];
	
	return self;
}

-(id)initWithSocket:(AsyncSocket*)sock delegate:(id<CerfingConnectionDelegate>)delegate
{
	return [self initWithTransport:[(CerfingAsyncSocketTransport*)[NSClassFromString(@"CerfingAsyncSocketTransport") alloc] initWithSocket:sock delegate:self] delegate:delegate];
}

-(void)dealloc;
{
	_transport.delegate = nil;
}

// Forward Transport delegates.
-(NSMethodSignature*)methodSignatureForSelector:(SEL)aSelector;
{
	if([super respondsToSelector:aSelector]) return [super methodSignatureForSelector:aSelector];
	if([_delegate respondsToSelector:aSelector]) return [(id)_delegate methodSignatureForSelector:aSelector];
	return nil;
}
- (id)forwardingTargetForSelector:(SEL)aSelector
{
	if([_delegate respondsToSelector:aSelector])
		return _delegate;
	return [super forwardingTargetForSelector:aSelector];
}
-(BOOL)respondsToSelector:(SEL)aSelector;
{
	return [super respondsToSelector:aSelector] || [_delegate respondsToSelector:aSelector];
}

#pragma mark Serialization
/*
	Cerfing doesn't really care about the encoding of the payload. JSON and plist
	are easy to debug, and also ensures that only our standard 'PODdy' classes
	are ever instantiated. Using NSCoding archiving is incredibly powerful,
	but opens up for remote code execution if we're not careful. Adding a layer of
	compression here would be trivial. You could even use protobuf for your transport,
	if you mapped hashes to protobuf messages (by looking at the 'command' key), once you're
	done prototyping your protocol.
*/
-(NSData*)serialize:(id)thing;
{
	return self.serializer.serialize(thing);
}
-(id)unserialize:(NSData*)unthing;
{
	return self.serializer.unserialize(unthing);
}

#pragma mark Transport
- (void)transportDidConnect:(CerfingTransport*)transport
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate transportDidConnect:transport];
	
	if(self.automaticallyReadsDicts)
		[self readDict];
}

-(BOOL)needsReadHashAfterDelegating:(NSDictionary*)hash payload:(NSData*)payload;
{
	NSString *reqKey = hash[kCerfingRequestKey];
	NSString *respKey = hash[kCerfingResponseKey];
	if(reqKey) {
		
		TCLog(@"INC REQU: %@ %@", [hash objectForKey:kCerfingCommand], reqKey);
		
		CerfingResponseCallback cb = ^(NSDictionary *response) {
			NSMutableDictionary *resp2 = [response mutableCopy];
			resp2[kCerfingResponseKey] = reqKey;
			[self sendDict:resp2];
		};
		
		SEL sel = NSSelectorFromString([NSString stringWithFormat:@"request:%@:responder:", hash[@"command"]]);
		SEL payloadSel = NSSelectorFromString([NSString stringWithFormat:@"request:%@:responder:payload:", hash[@"command"]]);
		
		if(self.automaticallyDispatchCommands && hash[kCerfingCommand] && [_delegate respondsToSelector:sel]) {
            ((void(*)(id, SEL, id, id, CerfingResponseCallback))[(id)_delegate methodForSelector:sel])(_delegate, sel, self, hash, cb);
		} else 	if(self.automaticallyDispatchCommands && hash[kCerfingCommand] && [_delegate respondsToSelector:payloadSel]) {
            ((void(*)(id, SEL, id, id, CerfingResponseCallback, id))[(id)_delegate methodForSelector:payloadSel])(_delegate, sel, self, hash, cb, payload);

		} else if([_delegate respondsToSelector:@selector(connection:receivedRequest:payload:responder:)]) {
			[_delegate connection:self receivedRequest:hash payload:payload responder:cb];
        } else {
            NSLog(@"%@: Invalid request '%@' for delegate %@", self, hash[kCerfingCommand], _delegate);
            [_transport disconnect];
        }
	}
	if(respKey) {
		TCLog(@"INC RESP: %@ %@", [hash objectForKey:kCerfingCommand], respKey);
		CerfingResponseCallback cb = requests[respKey];
		if(cb) cb(hash);
		else NSLog(@"Discarded response: %@", hash);
		[requests removeObjectForKey:respKey];
		return YES; // we're not calling delegate at all, so MUST readDict here
	} 
	if(!reqKey && !respKey) {
		NSString *command = hash[kCerfingCommand];
		
		TCLog(@"INC COMM: %@", [hash objectForKey:kCerfingCommand]);
		
		SEL sel = NSSelectorFromString([NSString stringWithFormat:@"command:%@:", command]);
		SEL payloadSel = NSSelectorFromString([NSString stringWithFormat:@"command:%@:payload:", command]);
		
		if(self.automaticallyDispatchCommands && hash[kCerfingCommand] && [_delegate respondsToSelector:sel]) {
            ((void(*)(id, SEL, id, id))[(id)_delegate methodForSelector:sel])(_delegate, sel, self, hash);
		} else 	if(self.automaticallyDispatchCommands && hash[kCerfingCommand] && [_delegate respondsToSelector:payloadSel]) {
            ((void(*)(id, SEL, id, id, id))[(id)_delegate methodForSelector:payloadSel])(_delegate, sel, self, hash, payload);
		} else if([_delegate respondsToSelector:@selector(connection:receivedDict:payload:)]) {
            [_delegate connection:self receivedDict:hash payload:payload];
        } else {
            NSLog(@"%@: Invalid command '%@' for delegate %@", self, hash[kCerfingCommand], _delegate);
            [_transport disconnect];
        }
	}
	
	return NO;
}
- (void)transport:(CerfingTransport*)transport didReadData:(NSData*)inData withTag:(long)tag
{
	__typeof(self) surviveEvenIfReleasedByDelegate = self;
	(void)surviveEvenIfReleasedByDelegate;
	
	if(tag == kTagLength) {
		uint32_t readLength = 0;
		[inData getBytes:&readLength length:4];
		readLength = ntohl(readLength);
		[_transport readDataToLength:readLength withTimeout:-1 tag:kTagData];
	} else if(tag == kTagData) {
		NSDictionary *hash = [self unserialize:inData];
		NSAssert(hash != nil, @"really should be unserializable");
		
		NSNumber *payloadSize = hash[kCerfingPayloadSizeKey];
		if(payloadSize) {
			savedHash = hash;
			[transport readDataToLength:payloadSize.longValue withTimeout:-1 tag:kTagPayload];
		} else {
			_hasOutstandingHashRead = NO;
			if([self needsReadHashAfterDelegating:hash payload:nil] || self.automaticallyReadsDicts)
				[self readDict];
		}
			
	} else if(tag == kTagPayload) {
		NSDictionary *hash = savedHash; savedHash = nil;
		_hasOutstandingHashRead = NO;
		
		if([self needsReadHashAfterDelegating:hash payload:inData] || self.automaticallyReadsDicts)
			[self readDict];
		
	} else if([_delegate respondsToSelector:_cmd])
		[(id)_delegate transport:transport didReadData:inData withTag:tag];
}
-(void)sendDict:(NSDictionary*)hash;
{
	[self sendDict:hash payload:nil];
}
-(void)sendDict:(NSDictionary*)hash payload:(NSData*)payload;
{
	if(payload) {
		hash = [hash mutableCopy];
		((NSMutableDictionary*)hash)[kCerfingPayloadSizeKey] = @(payload.length);
	}
	NSData *unthing = [self serialize:hash];
	
	TCLog(@"OUT %@: %@ %@", [hash objectForKey:kCerfingRequestKey]?@"REQU":[hash objectForKey:kCerfingResponseKey]?@"RESP":@"COMM", [hash objectForKey:kCerfingCommand], [hash objectForKey:kCerfingRequestKey]?:[hash objectForKey:kCerfingResponseKey]);
	
	NSMutableData *toSend = [[NSMutableData alloc] initWithCapacity:4 + unthing.length + payload.length];
	
	uint32_t writeLength = htonl(unthing.length);
	[toSend appendBytes:&writeLength length:4];
	
	[toSend appendData:unthing];
	if(payload)
		[toSend appendData:payload];

	[_transport writeData:toSend withTimeout:-1];
}
-(CerfingRequestCanceller)requestDict:(NSDictionary*)dict response:(CerfingResponseCallback)response;
{
	NSString *uuid = TCUUID();
	requests[uuid] = [response copy];
	CerfingRequestCanceller canceller = ^{ [requests removeObjectForKey:uuid]; };
	
	NSMutableDictionary *hash2 = [dict mutableCopy];
	hash2[kCerfingRequestKey] = uuid;
	
	[self sendDict:hash2];
	
	return canceller;
}
-(void)readDict;
{
	NSAssert(_hasOutstandingHashRead == NO, @"-[readDict] can't be called again until the previous request has finished");
	_hasOutstandingHashRead = YES;
	[_transport readDataToLength:4 withTimeout:-1 tag:kTagLength];
}
-(NSString*)description;
{
	return [NSString stringWithFormat:@"<%@@%p over %@>", [self class], self, _transport];
}
@end

static NSString *TCUUID(void)
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidS = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
	return uuidS;
}
