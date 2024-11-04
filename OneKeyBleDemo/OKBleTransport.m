#import "OKBleTransport.h"
#import "OKProtobufHelper.h"

@interface OKBleTransport ()
@end

@implementation OKBleTransport

- (instancetype)init {
    return [self initWithUrl:@"http://127.0.0.1:21320"];
}

- (instancetype)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        self.baseUrl = url;
        self.configured = NO;
        self.stopped = NO;
    }
    return self;
}

- (void)call:(NSString *)session name:(NSString *)name data:(NSDictionary *)data completion:(void (^)(id _Nullable, NSError * _Nullable))completion {
    NSLog(@"=== Transport Call Start ===");
    NSLog(@"Session: %@, Name: %@, Data: %@", session, name, data);
    
    if (!self.messages) {
        NSLog(@"Error: Transport not configured");
        completion(nil, [NSError errorWithDomain:@"OKBleTransport" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Transport not configured"}]);
        return;
    }
    
    // Build request data using buildOne
    NSError *error = nil;
    NSString *requestString = [OKProtobufHelper buildOne:self.messages name:name data:data error:&error];
    
    // 添加更多日志
    NSLog(@"Request Hex String: %@", requestString);
    NSLog(@"Request Hex String Length: %lu", (unsigned long)requestString.length);
    
    if (error || !requestString) {
        NSLog(@"Error building request: %@", error);
        completion(nil, error);
        return;
    }
    
    // Convert hex string to binary data
    NSData *requestData = [self hexStringToData:requestString];
    
    // Create URL request
    NSString *urlString = [NSString stringWithFormat:@"%@/call/%@", self.baseUrl, session];
    NSLog(@"URL: %@", urlString);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    
    // 设置请求头
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json, text/plain, */*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"https://jssdk.onekey.so" forHTTPHeaderField:@"Origin"];

    // Set timeout for Initialize command
    if ([name isEqualToString:@"Initialize"]) {
        request.timeoutInterval = 10.0;
    }
    
    NSLog(@"=== Making HTTP Request ===");
    NSLog(@"Headers: %@", request.allHTTPHeaderFields);
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"=== Received Response ===");
        if (error) {
            NSLog(@"Network Error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Raw Response: %@", responseString);
        
        // Parse protobuf message
        NSError *protoError = nil;
        NSDictionary *jsonData = [OKProtobufHelper receiveOne:self.messages response:responseString error:&protoError];
        
        if (protoError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, protoError);
            });
            return;
        }
        
        NSLog(@"Parsed Response: %@", jsonData);
        NSLog(@"=== Transport Call End ===");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(jsonData, nil);
        });
    }];
    
    [task resume];
}

#pragma mark - Helper Methods

- (NSString *)dataToHexString:(NSData *)data {
    const unsigned char *bytes = data.bytes;
    NSMutableString *hex = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSInteger i = 0; i < data.length; i++) {
        [hex appendFormat:@"%02x", bytes[i]];
    }
    return hex;
}

- (NSData *)hexStringToData:(NSString *)hexString {
    NSMutableData *data = [NSMutableData dataWithCapacity:hexString.length / 2];
    for (NSInteger i = 0; i < hexString.length; i += 2) {
        NSString *hexByte = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:hexByte];
        unsigned int value;
        [scanner scanHexInt:&value];
        uint8_t byte = value;
        [data appendBytes:&byte length:1];
    }
    return data;
}

@end 
