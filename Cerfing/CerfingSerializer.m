//
//  CerfingSerialization.m
//  CerfingDemo
//
//  Created by Nevyn Bengtsson on 2015-08-26.
//
//

#import "CerfingSerializer.h"

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

- (instancetype)initWithSerializer:(CerfingSerialize)serializer unserializer:(CerfingUnserialize)unserializer
{
	if(!(self = [super init]))
		return nil;
	
	_serialize = serializer;
	_unserialize = unserializer;
	
	return self;
}
@end
