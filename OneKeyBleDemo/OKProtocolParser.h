#import <Foundation/Foundation.h>
#import "OKProtocolDefines.h"

@interface OKProtocolParser : NSObject

- (NSDictionary *)parseResponseData:(NSData *)data error:(NSError **)error;

@end 