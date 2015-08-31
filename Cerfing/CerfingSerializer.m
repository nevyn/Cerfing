#import "CerfingSerializer.h"

@interface NSData (GZIP)
- (nullable NSData *)gzippedData;
- (nullable NSData *)gunzippedData;
@end


@implementation CerfingSerializer
+ (instancetype)JSONSerializer
{
	return [[self alloc] initWithSerializer:^NSData *(NSDictionary *dict) {
		NSError *err = nil;
		return [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
	} unserializer:^NSDictionary *(NSData *data) {
		NSError *err = nil;
		return [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
	}];
}

+ (instancetype)GZIPJSONSerializer
{
	NSAssert([NSData instancesRespondToSelector:@selector(gzippedData)], @"GZIPJSONSerializer requires nicklockwood's GZIP library to be compiled into this app");
	
	return [[self alloc] initWithSerializer:^NSData *(NSDictionary *dict) {
		NSError *err = nil;
		return [[NSJSONSerialization dataWithJSONObject:dict options:0 error:&err] gzippedData];
	} unserializer:^NSDictionary *(NSData *data) {
		NSError *err = nil;
		return [NSJSONSerialization JSONObjectWithData:[data gunzippedData] options:0 error:&err];
	}];
}

+ (instancetype)keyedArchiverSerializerWithSecureCoding:(BOOL)requiresSecureCoding
{
	return [[self alloc] initWithSerializer:^NSData *(NSDictionary *dict) {
		NSMutableData *data = [NSMutableData new];
		NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		archiver.requiresSecureCoding = requiresSecureCoding;
		[archiver encodeObject:dict forKey:@"root"];
		[archiver finishEncoding];
		return data;
	} unserializer:^NSDictionary *(NSData *data) {
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		unarchiver.requiresSecureCoding = requiresSecureCoding;
		id root = [unarchiver decodeObjectOfClass:[NSDictionary class] forKey:@"root"];
		return root;
	}];

}

- (instancetype)initWithSerializer:(CerfingSerialize)serializer unserializer:(CerfingUnserialize)unserializer
{
	if(!(self = [super init]))
		return nil;
	
	_serialize = serializer;
	_unserialize = unserializer;
	
	return self;
}
@end
