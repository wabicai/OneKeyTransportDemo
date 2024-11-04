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
    NSLog(@"Request Data: %@", requestString);
    NSLog(@"Request String Length: %lu", (unsigned long)requestString.length);
    
    if (error || !requestString) {
        NSLog(@"Error building request: %@", error);
        completion(nil, error);
        return;
    }
    
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

- (void)enumerateDevicesWithCompletion:(void (^)(NSArray *devices, NSError *error))completion {
    NSLog(@"=== Enumerate Devices Start ===");
    NSString *urlString = [NSString stringWithFormat:@"%@/enumerate", self.baseUrl];
    NSLog(@"Request URL: %@", urlString);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    [self addCommonHeaders:request];
    
    NSLog(@"Request Headers: %@", request.allHTTPHeaderFields);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"=== Enumerate Response ===");
        if (error) {
            NSLog(@"Network Error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(nil, error);
            });
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSLog(@"HTTP Status Code: %ld", (long)httpResponse.statusCode);
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"Raw Response: %@", responseString);
        
        NSError *jsonError = nil;
        NSArray *devices = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        NSLog(@"Parsed Devices: %@", devices);
        NSLog(@"=== Enumerate Devices End ===\n");
        
        completion(devices, jsonError);
    }];
    
    [task resume];
}

- (void)acquireDevice:(NSString *)path session:(NSString *)session completion:(void (^)(NSError *error))completion {
    NSLog(@"=== Acquire Device Start ===");
    NSString *urlString = [NSString stringWithFormat:@"%@/acquire/%@/%@", self.baseUrl, path, session];
    NSLog(@"Request URL: %@", urlString);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    [self addCommonHeaders:request];
    
    NSLog(@"Request Headers: %@", request.allHTTPHeaderFields);
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"=== Acquire Response ===");
        if (error) {
            NSLog(@"Network Error: %@", error);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"HTTP Status Code: %ld", (long)httpResponse.statusCode);
            
            if (data.length > 0) {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"Raw Response: %@", responseString);
            }
        }
        NSLog(@"=== Acquire Device End ===\n");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    }];
    
    [task resume];
}

- (void)releaseSession:(NSString *)session completion:(void (^)(NSError *error))completion {
    NSLog(@"=== Release Session Start ===");
    NSString *urlString = [NSString stringWithFormat:@"%@/release/%@", self.baseUrl, session];
    NSLog(@"Request URL: %@", urlString);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    request.HTTPMethod = @"POST";
    [self addCommonHeaders:request];
    
    NSLog(@"Request Headers: %@", request.allHTTPHeaderFields);
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"=== Release Response ===");
        if (error) {
            NSLog(@"Network Error: %@", error);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"HTTP Status Code: %ld", (long)httpResponse.statusCode);
            
            if (data.length > 0) {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"Raw Response: %@", responseString);
            }
        }
        NSLog(@"=== Release Session End ===\n");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(error);
        });
    }];
    
    [task resume];
}

- (void)addCommonHeaders:(NSMutableURLRequest *)request {
    [request setValue:@"application/json, text/plain, */*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"https://jssdk.onekey.so" forHTTPHeaderField:@"Origin"];
}

#pragma mark - Helper Methods

- (NSString *)dataToHexString:(NSData *)data {
    return [OKProtobufHelper dataToHexString:data];
}

- (NSData *)hexStringToData:(NSString *)hexString {
    return [OKProtobufHelper hexStringToData:hexString];
}

@end 
