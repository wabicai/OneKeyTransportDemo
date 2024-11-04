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

- (void)call:(NSString *)session name:(NSString *)name data:(NSDictionary *)data completion:(void (^)(id result, NSError *error))completion {
    if (!self.configured || !self.messages) {
        NSError *error = [NSError errorWithDomain:@"com.onekey.ble"
                                           code:-1
                                       userInfo:@{NSLocalizedDescriptionKey: @"Transport not configured"}];
        if (completion) {
            completion(nil, error);
        }
        return;
    }
    
    NSString *urlString = [NSString stringWithFormat:@"%@/call/%@", self.baseUrl, session];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [@"000000000000" dataUsingEncoding:NSUTF8StringEncoding];
    
    // 设置请求头
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json, text/plain, */*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"zh-CN,zh;q=0.9" forHTTPHeaderField:@"Accept-Language"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [request setValue:@"1" forHTTPHeaderField:@"DNT"];
    [request setValue:@"https://jssdk.onekey.so" forHTTPHeaderField:@"Origin"];
    [request setValue:@"no-cache" forHTTPHeaderField:@"Pragma"];
    [request setValue:@"empty" forHTTPHeaderField:@"Sec-Fetch-Dest"];
    [request setValue:@"cors" forHTTPHeaderField:@"Sec-Fetch-Mode"];
    [request setValue:@"cross-site" forHTTPHeaderField:@"Sec-Fetch-Site"];
    [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"\"Not?A_Brand\";v=\"99\", \"Chromium\";v=\"130\"" forHTTPHeaderField:@"sec-ch-ua"];
    [request setValue:@"?0" forHTTPHeaderField:@"sec-ch-ua-mobile"];
    [request setValue:@"\"macOS\"" forHTTPHeaderField:@"sec-ch-ua-platform"];
    
    // 修改日志输出格式
    NSMutableString *logString = [NSMutableString stringWithFormat:@"curl '%@' \\\n", urlString];
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [logString appendFormat:@"  -H '%@: %@' \\\n", key, value];
    }];
    
    NSString *bodyString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    [logString appendFormat:@"  --data-raw '%@'", bodyString];
    NSLog(@"%@", logString);
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error.localizedDescription);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        // 直接输出响应内容
        NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        NSLog(@"Raw Response: %@", responseString);
        
        // 使用 OKProtobufHelper 处理响应数据
        NSError *protoError;
        id jsonData = [OKProtobufHelper receiveOne:self.messages response:responseString error:&protoError];
        
        if (protoError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, protoError);
            });
            return;
        }
        
        // 检查响应结果
        id result = [OKProtobufHelper checkCall:jsonData error:&protoError];
        
        if (protoError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, protoError);
            });
            return;
        }
        
        // 返回处理后的结果
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, nil);
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