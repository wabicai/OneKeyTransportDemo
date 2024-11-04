#import "OKProtocolParser.h"

@implementation OKProtocolParser

- (NSDictionary *)parseResponseData:(NSData *)data error:(NSError **)error {
    // Check if data length is at least header size
    if (data.length < 6) {
        if (error) {
            *error = [NSError errorWithDomain:@"OKProtocolParser" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Data too short"}];
        }
        return nil;
    }

    // Extract payload length from header
    uint16_t length;
    [data getBytes:&length range:NSMakeRange(4, 2)];
    length = CFSwapInt16BigToHost(length);

    // Check if data contains the full payload
    if (data.length < 6 + length) {
        if (error) {
            *error = [NSError errorWithDomain:@"OKProtocolParser" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Incomplete data"}];
        }
        return nil;
    }

    NSData *payloadData = [data subdataWithRange:NSMakeRange(6, length)];

    // Deserialize payload
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:payloadData options:0 error:error];
    if (error && *error) {
        return nil;
    }

    return response;
}

@end 