#import <Foundation/Foundation.h>

@interface OKProtobufHelper : NSObject

// 主要方法
+ (id)receiveOne:(id)messages response:(NSString *)response error:(NSError **)error;
+ (id)checkCall:(id)jsonData error:(NSError **)error;
+ (NSDictionary *)decodeProtocol:(NSData *)data error:(NSError **)error;
+ (id)createMessageFromType:(id)messages typeId:(NSInteger)typeId error:(NSError **)error;
+ (NSString *)buildOne:(id)messages name:(NSString *)name data:(NSDictionary *)data error:(NSError **)error;

// 工具方法
+ (NSData *)hexStringToData:(NSString *)hexString;
+ (NSString *)dataToHexString:(NSData *)data;

@end 