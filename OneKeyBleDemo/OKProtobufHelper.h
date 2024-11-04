#import <Foundation/Foundation.h>

@interface OKProtobufHelper : NSObject

// 主要方法
+ (NSData *)buildOneWithMessages:(id)messages name:(NSString *)name data:(NSDictionary *)data;
+ (NSDictionary *)receiveOneWithMessages:(id)messages data:(NSString *)data;

// Protocol encode/decode helpers
+ (NSData *)encodeProtocolWithData:(NSData *)data messageType:(NSInteger)messageType;
+ (NSDictionary *)decodeProtocolWithData:(NSData *)data;

// Helper methods
+ (NSInteger)getMessageTypeFromName:(NSString *)name messages:(id)messages;
+ (NSData *)encodeProtobufWithMessage:(NSString *)name data:(NSDictionary *)data messages:(id)messages;
+ (NSString *)getMessageNameFromType:(NSInteger)typeId messages:(id)messages;
+ (NSDictionary *)decodeProtobufWithBuffer:(NSData *)buffer messageName:(NSString *)messageName messages:(id)messages;
+ (NSData *)hexStringToData:(NSString *)hexString;
+ (NSString *)dataToHexString:(NSData *)data;

+ (id)receiveOne:(id)messages response:(NSString *)response error:(NSError **)error;
+ (id)checkCall:(id)jsonData error:(NSError **)error;
+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error;
+ (id)createMessageFromType:(id)messages typeId:(NSInteger)typeId error:(NSError **)error;
+ (id)decodeProtobuf:(id)message buffer:(NSData *)buffer error:(NSError **)error;

@end 