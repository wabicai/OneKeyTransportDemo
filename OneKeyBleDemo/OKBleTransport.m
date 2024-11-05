#import "OKBleTransport.h"
#import "OKProtobufHelper.h"

@implementation OKBleTransport

- (void)call:(NSString *)session name:(NSString *)name data:(NSDictionary *)data completion:(void (^)(id _Nullable, NSError * _Nullable))completion {
    NSLog(@"\n=== 🚀 Transport Call Start ===");
    NSLog(@"📍 Session: %@\n📝 Name: %@\n📦 Data: %@", session, name, data);
    
    if (!self.messages) {
        NSLog(@"❌ Error: Transport not configured");
        completion(nil, [NSError errorWithDomain:@"com.onekey.ble" 
                                         code:-1 
                                     userInfo:@{NSLocalizedDescriptionKey: @"Transport not configured"}]);
        return;
    }
    
    // Build request buffers
    NSError *error = nil;
    NSArray<NSData *> *buffers = [OKProtobufHelper buildBuffer:self.messages name:name data:data error:&error];
    
    if (error || !buffers) {
        NSLog(@"❌ Error building request: %@", error);
        completion(nil, error);
        return;
    }
    NSLog(@"✅ Built %lu request buffers", (unsigned long)buffers.count, buffers);
    
    // For testing/mock purposes, we'll use a predefined response
    NSString *mockResponse;
    {
        mockResponse = @"00110000019a0a097472657a6f722e696f1002186320633218363232453636363843384235374237424131444346413432380140004a057a685f636e520a4f6e654b65792050726f60016a14a269ab719f0b18fb352c8c0102177e9cfb904a76800101980100a00100aa010154d80100e00100e80100f00101f00102f00103f00104f00105f00106f00107f0010af0010bf0010cf0010df00111f801008002018802009002009a0220bc1c207fb3888a3b97d418a9960feedf235becf6dfb716ea3e4ba976666148fea00200a80200b002c0cf24b80200c00200c80200aa1f0850726f2032444439b21f05322e332e32b81f01e21f06342e31302e30f21f05322e352e34fa1f0b54434234334a3030303441b2200761323639616237ba2013756e6b6e6f776e20626f6172646c6f61646572c02505c82500d22513756e6b6e6f776e20626f6172646c6f61646572e22505322e352e34f22505312e312e348a2606342e31302e30a2260b50524234334a3030303441b2260850726f2032444439ba2605322e332e32d22605312e312e33da2605312e312e33e22605312e312e33";
    }
    
    NSError *decodeError = nil;
    id decodedResponse = [OKProtobufHelper receiveOne:self.messages response:mockResponse error:&decodeError];
    
    if (decodeError) {
        completion(nil, decodeError);
    } else {
        completion(decodedResponse, nil);
    }
}

@end 
