#import <UIKit/UIKit.h>
#import "OKBleTransport.h"

@interface ViewController : UIViewController

@property (nonatomic, strong, readonly) OKBleTransport *bleTransport;
@property (nonatomic, strong, readonly) UITextView *logTextView;
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) UIButton *lockDeviceButton;

@end

