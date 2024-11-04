#import <Foundation/Foundation.h>

@interface OKBleTransport : NSObject

@property (nonatomic, copy) NSString *baseUrl;
@property (nonatomic, assign) BOOL configured;
@property (nonatomic, assign) BOOL stopped;
@property (nonatomic, strong) NSDictionary *messages;

- (void)enumerateDevicesWithCompletion:(void (^)(NSArray *devices, NSError *error))completion;
- (void)acquireDevice:(NSString *)path session:(NSString *)session completion:(void (^)(NSError *error))completion;
- (void)call:(NSString *)session name:(NSString *)name data:(NSDictionary *)data completion:(void (^)(id result, NSError *error))completion;
- (void)releaseSession:(NSString *)session completion:(void (^)(NSError *error))completion;

@end 