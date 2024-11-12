#import "OKLogger.h"

@implementation OKLogger

+ (void)log:(NSString *)message {
    NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                      dateStyle:NSDateFormatterNoStyle
                                                      timeStyle:NSDateFormatterMediumStyle];
    NSLog(@"[%@] %@", timestamp, message);
}

+ (void)logError:(NSString *)error {
    [self log:[NSString stringWithFormat:@"❌ %@", error]];
}

+ (void)logSuccess:(NSString *)message {
    [self log:[NSString stringWithFormat:@"✅ %@", message]];
}

+ (void)logInfo:(NSString *)message {
    [self log:[NSString stringWithFormat:@"ℹ️ %@", message]];
}

@end 