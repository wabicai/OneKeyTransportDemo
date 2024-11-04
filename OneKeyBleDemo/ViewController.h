
#import <UIKit/UIKit.h>
#import "OKBleTransport.h"

@interface ViewController : UIViewController

@property (nonatomic, strong, readonly) OKBleTransport *bleTransport;
@property (nonatomic, strong, readonly) UITextView *logTextView;

@end

