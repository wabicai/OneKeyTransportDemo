#import <Foundation/Foundation.h>

@interface OKBleTransport : NSObject

@property (nonatomic, assign) BOOL configured;
@property (nonatomic, strong) NSDictionary *messages;

- (void)call:(NSString *)session name:(NSString *)name data:(NSDictionary *)data completion:(void (^)(id result, NSError *error))completion;

@end 