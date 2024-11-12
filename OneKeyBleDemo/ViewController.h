#import <UIKit/UIKit.h>
#import "OKBleTransport.h"
#import "OKPinMatrixView.h"

@interface ViewController : UIViewController <OKPinMatrixViewDelegate>

@property (nonatomic, strong, readonly) OKBleTransport *bleTransport;
@property (nonatomic, strong, readonly) UITextView *logTextView;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) UIButton *lockDeviceButton;
@property (nonatomic, copy, readonly) void (^pinCompletionHandler)(NSString *pin);

@end

