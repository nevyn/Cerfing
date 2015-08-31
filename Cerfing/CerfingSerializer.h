#import <Foundation/Foundation.h>

typedef NSData *(^CerfingSerialize)(NSDictionary *dict);
typedef NSDictionary *(^CerfingUnserialize)(NSData *data);

/*!
	@class CerfingSerializer
	@abstract Defines a serialization and unserialization function for converting
	between NSDictionary <> wire format (NSData). This serializer also defines what
	data types are valid as Cerfing message contents.
*/
@interface CerfingSerializer : NSObject
+ (instancetype)JSONSerializer;
+ (instancetype)GZIPJSONSerializer;
+ (instancetype)keyedArchiverSerializerWithSecureCoding:(BOOL)requiresSecureCoding;
//+ (instancetype)propertyListSerializer;

- (instancetype)initWithSerializer:(CerfingSerialize)serializer unserializer:(CerfingUnserialize)unserializer;
@property(nonatomic,copy) CerfingSerialize serialize;
@property(nonatomic,copy) CerfingUnserialize unserialize;
@end
