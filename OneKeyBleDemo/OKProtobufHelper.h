#import <Foundation/Foundation.h>
#import <Protobuf/GPBMessage.h>

@interface OKProtobufHelper : NSObject

// Main methods
+ (id)receiveOne:(id)messages response:(NSString *)response error:(NSError **)error;
+ (id)receiveOneWithData:(NSData *)data messages:(id)messages error:(NSError **)error;
+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error;
+ (id)createMessageFromType:(id)messages typeId:(NSInteger)typeId error:(NSError **)error;
+ (NSString *)buildOne:(id)messages name:(NSString *)name data:(NSDictionary *)data error:(NSError **)error;

// Tool methods
+ (NSData *)hexStringToData:(NSString *)hexString;
+ (NSString *)dataToHexString:(NSData *)data;

+ (NSData *)buildBuffersWithName:(NSString *)name 
                         params:(NSDictionary *)params 
                      messages:(NSDictionary *)messages;

// New methods
+ (NSDictionary *)parseMessageToDict:(GPBMessage *)message;
+ (id)transformValue:(id)value field:(GPBFieldDescriptor *)field;

@end 