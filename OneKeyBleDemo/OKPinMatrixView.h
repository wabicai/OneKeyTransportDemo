#import <UIKit/UIKit.h>

@protocol OKPinMatrixViewDelegate <NSObject>
- (void)pinMatrixView:(UIView *)view didEnterPin:(NSString *)pin;
- (void)pinMatrixViewDidCancel:(UIView *)view;
@end

@interface OKPinMatrixView : UIView

@property (nonatomic, weak) id<OKPinMatrixViewDelegate> delegate;
@property (nonatomic, assign) BOOL isVisible;

- (void)show;
- (void)hide;
- (void)clearPin;

@end
