@interface OKLogger : NSObject

+ (void)log:(NSString *)message;
+ (void)logError:(NSString *)error;
+ (void)logSuccess:(NSString *)message;
+ (void)logInfo:(NSString *)message;

@end 