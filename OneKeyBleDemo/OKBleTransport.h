#import <Foundation/Foundation.h>

@interface OKBleTransport : NSObject

@property (nonatomic, strong) id messages;
@property (nonatomic, assign) BOOL configured;
@property (nonatomic, assign) BOOL stopped;
@property (nonatomic, copy) NSString *baseUrl;

- (instancetype)init;
- (instancetype)initWithUrl:(NSString *)url;

- (void)call:(NSString *)session 
        name:(NSString *)name 
        data:(NSDictionary *)data 
  completion:(void (^)(id result, NSError *error))completion;

@end 