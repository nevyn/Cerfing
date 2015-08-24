#import "TCAsyncHashProtocol.h"
#import "TCAHPAsyncSocketTransport.h"

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
	kTagLength,
	kTagData,
	kTagPayload,
};

// Private keys
static NSString *const kTCAsyncHashProtocolRequestKey = @"__tcahp-requestKey";
static NSString *const kTCAsyncHashProtocolResponseKey = @"__tcahp-responseKey";
static NSString *const kTCAsyncHashProtocolPayloadSizeKey = @"__tcahp-payloadSize";
// Public keys
       NSString *const kTCCommand = @"command";

@interface TCAsyncHashProtocol () <TCAHPTransportDelegate>
@property(nonatomic,strong,readwrite) TCAHPTransport *transport;
@end

@implementation TCAsyncHashProtocol {
	NSMutableDictionary *requests;
	NSDictionary *savedHash;
	BOOL _hasOutstandingHashRead;
	BOOL _customSerialization;
}
@synthesize transport = _transport, delegate = _delegate, autoReadHash = _autoReadHash;
@synthesize autoDispatchCommands = _autoDispatchCommands;

-(id)initWithTransport:(TCAHPTransport*)transport delegate:(id<TCAsyncHashProtocolDelegate>)delegate
{
	if(!transport) return nil;
	
	if(!(self = [super init])) return nil;
	
	self.transport = transport;
	_autoReadHash = YES;
	_transport.delegate = self;
	_delegate = delegate;
	requests = [NSMutableDictionary dictionary];
	
	BOOL supportsSerialization = [delegate respondsToSelector:@selector(protocol:serializeHash:)];
	BOOL supportsUnserialization = [delegate respondsToSelector:@selector(protocol:unserializeHash:)];
	_customSerialization = supportsSerialization && supportsUnserialization;
	NSAssert(~(supportsSerialization ^ supportsUnserialization), @"Must support neither, or both.");
	
	return self;
}

-(id)initWithSocket:(AsyncSocket*)sock delegate:(id<TCAsyncHashProtocolDelegate>)delegate
{
	return [self initWithTransport:[(TCAHPAsyncSocketTransport*)[NSClassFromString(@"TCAHPAsyncSocketTransport") alloc] initWithSocket:sock delegate:self] delegate:delegate];
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
	TCAHP doesn't really care about the encoding of the payload. JSON and plist
	are easy to debug, and also ensures that only our standard 'PODdy' classes
	are ever instantiated. Using NSCoding archiving is incredibly powerful,
	but opens up for remote code execution if we're not careful. Adding a layer of
	compression here would be trivial. You could even use protobuf for your transport,
	if you mapped hashes to protobuf messages (by looking at the 'command' key), once you're
	done prototyping your protocol.
*/
-(NSData*)serialize:(id)thing;
{
	if(_customSerialization)
		return [_delegate protocol:self serializeHash:thing];
	NSError *err = nil;
	return [NSJSONSerialization dataWithJSONObject:thing options:0 error:&err];
}
-(id)unserialize:(NSData*)unthing;
{
	if(_customSerialization)
		return [_delegate protocol:self unserializeHash:unthing];
	NSError *err = nil;
	return [NSJSONSerialization JSONObjectWithData:unthing options:0 error:&err];
}

#pragma mark Transport
- (void)transportDidConnect:(TCAHPTransport*)transport
{
	if([self.delegate respondsToSelector:_cmd])
		[(id)self.delegate transportDidConnect:transport];
	
	if(self.autoReadHash)
		[self readHash];
}

-(BOOL)needsReadHashAfterDelegating:(NSDictionary*)hash payload:(NSData*)payload;
{
	NSString *reqKey = hash[kTCAsyncHashProtocolRequestKey];
	NSString *respKey = hash[kTCAsyncHashProtocolResponseKey];
	if(reqKey) {
		
		TCLog(@"INC REQU: %@ %@", [hash objectForKey:kTCCommand], reqKey);
		
		TCAsyncHashProtocolResponseCallback cb = ^(NSDictionary *response) {
			NSMutableDictionary *resp2 = [response mutableCopy];
			resp2[kTCAsyncHashProtocolResponseKey] = reqKey;
			[self sendHash:resp2];
		};
		
		SEL sel = NSSelectorFromString([NSString stringWithFormat:@"request:%@:responder:", hash[@"command"]]);
		SEL payloadSel = NSSelectorFromString([NSString stringWithFormat:@"request:%@:responder:payload:", hash[@"command"]]);
		
		if(self.autoDispatchCommands && hash[kTCCommand] && [_delegate respondsToSelector:sel]) {
            ((void(*)(id, SEL, id, id, TCAsyncHashProtocolResponseCallback))[(id)_delegate methodForSelector:sel])(_delegate, sel, self, hash, cb);
		} else 	if(self.autoDispatchCommands && hash[kTCCommand] && [_delegate respondsToSelector:payloadSel]) {
            ((void(*)(id, SEL, id, id, TCAsyncHashProtocolResponseCallback, id))[(id)_delegate methodForSelector:payloadSel])(_delegate, sel, self, hash, cb, payload);

		} else if([_delegate respondsToSelector:@selector(protocol:receivedRequest:payload:responder:)]) {
			[_delegate protocol:self receivedRequest:hash payload:payload responder:cb];
        } else {
            NSLog(@"%@: Invalid request '%@' for delegate %@", self, hash[kTCCommand], _delegate);
            [_transport disconnect];
        }
	}
	if(respKey) {
		TCLog(@"INC RESP: %@ %@", [hash objectForKey:kTCCommand], respKey);
		TCAsyncHashProtocolResponseCallback cb = requests[respKey];
		if(cb) cb(hash);
		else NSLog(@"Discarded response: %@", hash);
		[requests removeObjectForKey:respKey];
		return YES; // we're not calling delegate at all, so MUST readHash here
	} 
	if(!reqKey && !respKey) {
		NSString *command = hash[kTCCommand];
		
		TCLog(@"INC COMM: %@", [hash objectForKey:kTCCommand]);
		
		SEL sel = NSSelectorFromString([NSString stringWithFormat:@"command:%@:", command]);
		SEL payloadSel = NSSelectorFromString([NSString stringWithFormat:@"command:%@:payload:", command]);
		
		if(self.autoDispatchCommands && hash[kTCCommand] && [_delegate respondsToSelector:sel]) {
            ((void(*)(id, SEL, id, id))[(id)_delegate methodForSelector:sel])(_delegate, sel, self, hash);
		} else 	if(self.autoDispatchCommands && hash[kTCCommand] && [_delegate respondsToSelector:payloadSel]) {
            ((void(*)(id, SEL, id, id, id))[(id)_delegate methodForSelector:payloadSel])(_delegate, sel, self, hash, payload);
		} else if([_delegate respondsToSelector:@selector(protocol:receivedHash:payload:)]) {
            [_delegate protocol:self receivedHash:hash payload:payload];
        } else {
            NSLog(@"%@: Invalid command '%@' for delegate %@", self, hash[kTCCommand], _delegate);
            [_transport disconnect];
        }
	}
	
	return NO;
}
- (void)transport:(TCAHPTransport*)transport didReadData:(NSData*)inData withTag:(long)tag
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
		
		NSNumber *payloadSize = hash[kTCAsyncHashProtocolPayloadSizeKey];
		if(payloadSize) {
			savedHash = hash;
			[transport readDataToLength:payloadSize.longValue withTimeout:-1 tag:kTagPayload];
		} else {
			_hasOutstandingHashRead = NO;
			if([self needsReadHashAfterDelegating:hash payload:nil] || self.autoReadHash)
				[self readHash];
		}
			
	} else if(tag == kTagPayload) {
		NSDictionary *hash = savedHash; savedHash = nil;
		_hasOutstandingHashRead = NO;
		
		if([self needsReadHashAfterDelegating:hash payload:inData] || self.autoReadHash)
			[self readHash];
		
	} else if([_delegate respondsToSelector:_cmd])
		[(id)_delegate transport:transport didReadData:inData withTag:tag];
}
-(void)sendHash:(NSDictionary*)hash;
{
	[self sendHash:hash payload:nil];
}
-(void)sendHash:(NSDictionary*)hash payload:(NSData*)payload;
{
	if(payload) {
		hash = [hash mutableCopy];
		((NSMutableDictionary*)hash)[kTCAsyncHashProtocolPayloadSizeKey] = @(payload.length);
	}
	NSData *unthing = [self serialize:hash];
	
	TCLog(@"OUT %@: %@ %@", [hash objectForKey:kTCAsyncHashProtocolRequestKey]?@"REQU":[hash objectForKey:kTCAsyncHashProtocolResponseKey]?@"RESP":@"COMM", [hash objectForKey:kTCCommand], [hash objectForKey:kTCAsyncHashProtocolRequestKey]?:[hash objectForKey:kTCAsyncHashProtocolResponseKey]);
	
	NSMutableData *toSend = [[NSMutableData alloc] initWithCapacity:4 + unthing.length + payload.length];
	
	uint32_t writeLength = htonl(unthing.length);
	[toSend appendBytes:&writeLength length:4];
	
	[toSend appendData:unthing];
	if(payload)
		[toSend appendData:payload];

	[_transport writeData:toSend withTimeout:-1];
}
-(TCAsyncHashProtocolRequestCanceller)requestHash:(NSDictionary*)hash response:(TCAsyncHashProtocolResponseCallback)response;
{
	NSString *uuid = TCUUID();
	requests[uuid] = [response copy];
	TCAsyncHashProtocolRequestCanceller canceller = ^{ [requests removeObjectForKey:uuid]; };
	
	NSMutableDictionary *hash2 = [hash mutableCopy];
	hash2[kTCAsyncHashProtocolRequestKey] = uuid;
	
	[self sendHash:hash2];
	
	return canceller;
}
-(void)readHash;
{
	NSAssert(_hasOutstandingHashRead == NO, @"-[readHash] can't be called again until the previous request has finished");
	_hasOutstandingHashRead = YES;
	[_transport readDataToLength:4 withTimeout:-1 tag:kTagLength];
}
-(NSString*)description;
{
	return [NSString stringWithFormat:@"<TCAsyncHashProtocol@%p over %@>", self, _transport];
}
@end

static NSString *TCUUID(void)
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidS = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
	return uuidS;
}
