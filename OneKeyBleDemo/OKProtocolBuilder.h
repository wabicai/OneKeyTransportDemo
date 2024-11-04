#import <Foundation/Foundation.h>
#import "OKProtocolDefines.h"

@interface OKProtocolBuilder : NSObject

// Build method to create request data
- (NSData *)buildMessageWithType:(OKMessageType)type payload:(NSDictionary *)payload error:(NSError **)error;

@end 