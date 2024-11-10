#import <Foundation/Foundation.h>
#import <Protobuf/GPBMessage.h>

@interface OKProtobufHelper : NSObject

// Main methods
+ (id)receiveOne:(id)messages response:(NSString *)response error:(NSError **)error;
+ (id)receiveOneWithData:(NSData *)data messages:(id)messages error:(NSError **)error;
+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error;
+ (id)createMessageFromType:(id)messages typeId:(NSInteger)typeId error:(NSError **)error;
+ (NSData *)buildBuffer:(NSString *)name params:(NSDictionary *)params messages:(NSDictionary *)messages;

// Utility methods
+ (NSData *)hexStringToData:(NSString *)hexString;
+ (NSString *)dataToHexString:(NSData *)data;
+ (NSDictionary *)parseMessageToDict:(GPBMessage *)message;

@end 