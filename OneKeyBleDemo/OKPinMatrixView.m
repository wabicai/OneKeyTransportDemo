#import "OKPinMatrixView.h"

@interface OKPinMatrixView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIView *pinDisplayView;
@property (nonatomic, strong) UILabel *pinDotsLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) NSMutableString *pinValue;
@property (nonatomic, strong) NSArray<UIButton *> *pinButtons;

@end

@implementation OKPinMatrixView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.pinValue = [NSMutableString string];
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    
    // Container
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor systemBackgroundColor];
    self.containerView.layer.cornerRadius = 16;
    [self addSubview:self.containerView];
    
    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"Enter PIN";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold];
    [self.containerView addSubview:self.titleLabel];
    
    // Description
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.text = @"Look at your device for number positions";
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.font = [UIFont systemFontOfSize:14];
    self.descriptionLabel.textColor = [UIColor secondaryLabelColor];
    [self.containerView addSubview:self.descriptionLabel];
    
    // PIN Display View
    [self setupPinDisplayView];
    
    // PIN Matrix
    [self setupPinMatrix];
    
    // Cancel Button
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:cancelButton];
    
    // Layout constraints
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.containerView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.containerView.widthAnchor constraintEqualToConstant:340],
        [self.containerView.heightAnchor constraintEqualToConstant:520]
    ]];
    
    // Additional layout constraints
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pinDisplayView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // Title
        [self.titleLabel.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:24],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        
        // Description
        [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:8],
        [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        
        // PIN Display
        [self.pinDisplayView.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor constant:20],
        [self.pinDisplayView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.pinDisplayView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [self.pinDisplayView.heightAnchor constraintEqualToConstant:60]
    ]];
    
    // Hide initially
    self.isVisible = NO;
    self.alpha = 0;
    
    // Add confirm button
    [self setupButtons];
}

- (void)setupPinDisplayView {
    self.pinDisplayView = [[UIView alloc] init];
    self.pinDisplayView.backgroundColor = [UIColor systemGrayColor];
    self.pinDisplayView.layer.cornerRadius = 8;
    [self.containerView addSubview:self.pinDisplayView];
    
    self.pinDotsLabel = [[UILabel alloc] init];
    self.pinDotsLabel.textAlignment = NSTextAlignmentCenter;
    self.pinDotsLabel.font = [UIFont systemFontOfSize:40];
    [self.pinDisplayView addSubview:self.pinDotsLabel];
    
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deleteButton setImage:[UIImage systemImageNamed:@"delete.left"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.pinDisplayView addSubview:self.deleteButton];
    
    // Layout constraints for pinDisplayView components
    self.pinDotsLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [NSLayoutConstraint activateConstraints:@[
        // PIN dots label
        [self.pinDotsLabel.leadingAnchor constraintEqualToAnchor:self.pinDisplayView.leadingAnchor constant:16],
        [self.pinDotsLabel.trailingAnchor constraintEqualToAnchor:self.deleteButton.leadingAnchor constant:-8],
        [self.pinDotsLabel.centerYAnchor constraintEqualToAnchor:self.pinDisplayView.centerYAnchor],
        
        // Delete button
        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.pinDisplayView.trailingAnchor constant:-16],
        [self.deleteButton.centerYAnchor constraintEqualToAnchor:self.pinDisplayView.centerYAnchor],
        [self.deleteButton.widthAnchor constraintEqualToConstant:44],
        [self.deleteButton.heightAnchor constraintEqualToConstant:44]
    ]];
}

- (void)setupPinMatrix {
    // 使用 "?" 代替具体数字，因为实际数字要看设备屏幕
    NSArray *keyboardMap = @[@"?", @"?", @"?", @"?", @"?", @"?", @"?", @"?", @"?"];
    NSMutableArray *buttons = [NSMutableArray array];
    
    CGFloat buttonSize = 60;
    CGFloat spacing = 24;
    
    for (NSInteger i = 0; i < 9; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        // 使用 7-8-9-4-5-6-1-2-3 的顺序存储实际值
        NSInteger value = 0;
        switch (i) {
            case 0: value = 7; break;
            case 1: value = 8; break;
            case 2: value = 9; break;
            case 3: value = 4; break;
            case 4: value = 5; break;
            case 5: value = 6; break;
            case 6: value = 1; break;
            case 7: value = 2; break;
            case 8: value = 3; break;
        }
        button.tag = value;
        
        // 其他按钮设置保持不变...
        button.backgroundColor = [UIColor systemGray5Color];
        button.layer.cornerRadius = buttonSize/2;
        
        // Add dot in center
        UIView *dot = [[UIView alloc] init];
        dot.backgroundColor = [UIColor labelColor];
        dot.layer.cornerRadius = 5;
        [button addSubview:dot];
        
        [button addTarget:self action:@selector(pinButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [button addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
        
        [buttons addObject:button];
        [self.containerView addSubview:button];
        
        // Calculate position
        NSInteger row = i / 3;
        NSInteger col = i % 3;
        
        // Setup constraints
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [button.widthAnchor constraintEqualToConstant:buttonSize],
            [button.heightAnchor constraintEqualToConstant:buttonSize],
            [button.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:(20 + col * (buttonSize + spacing))],
            [button.topAnchor constraintEqualToAnchor:self.pinDisplayView.bottomAnchor constant:(40 + row * (buttonSize + spacing))]
        ]];
        
        // Dot constraints
        dot.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [dot.widthAnchor constraintEqualToConstant:10],
            [dot.heightAnchor constraintEqualToConstant:10],
            [dot.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
            [dot.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
        ]];
    }
    
    self.pinButtons = buttons;
}

- (void)setupButtons {
    // Confirm Button
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [confirmButton setTitle:@"Confirm" forState:UIControlStateNormal];
    confirmButton.backgroundColor = [UIColor systemBlueColor];
    [confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    confirmButton.layer.cornerRadius = 8;
    [confirmButton addTarget:self action:@selector(confirmButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:confirmButton];
    
    // Cancel Button (already exists, just need to style it)
    UIButton *cancelButton = [self.containerView.subviews lastObject];
    
    // Layout constraints
    confirmButton.translatesAutoresizingMaskIntoConstraints = NO;
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Get the last pin button's bottom constraint
    UIButton *lastPinButton = self.pinButtons.lastObject;
    
    [NSLayoutConstraint activateConstraints:@[
        // Confirm button
        [confirmButton.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [confirmButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [confirmButton.topAnchor constraintEqualToAnchor:lastPinButton.bottomAnchor constant:40],
        [confirmButton.heightAnchor constraintEqualToConstant:44],
        
        // Cancel button
        [cancelButton.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [cancelButton.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [cancelButton.topAnchor constraintEqualToAnchor:confirmButton.bottomAnchor constant:12],
        [cancelButton.heightAnchor constraintEqualToConstant:44],
        [cancelButton.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-20]
    ]];
}

- (void)confirmButtonTapped {
    // Hide keyboard first
    [self hide];
    
    // Send PIN to device via delegate
    if ([self.delegate respondsToSelector:@selector(pinMatrixView:didEnterPin:)]) {
        [self.delegate pinMatrixView:self didEnterPin:[self.pinValue copy]];
    }
    
    // Clear PIN for security
    [self clearPin];
}

- (void)showErrorAlert:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                 message:message
                                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil];
    [alert addAction:okAction];
    
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [topVC presentViewController:alert animated:YES completion:nil];
}

- (void)show {
    if (self.isVisible) return;
    
    self.isVisible = YES;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)hide {
    if (!self.isVisible) return;
    
    self.isVisible = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

- (void)clearPin {
    [self.pinValue setString:@""];
    self.pinDotsLabel.text = @"";
}

- (void)pinButtonTapped:(UIButton *)sender {
    if (self.pinValue.length >= 9) return;  // 修改最大长度为 9
    
    // 使用按钮的 tag 值作为实际输入值
    [self.pinValue appendString:[NSString stringWithFormat:@"%ld", (long)sender.tag]];
    NSString *dots = [@"" stringByPaddingToLength:self.pinValue.length 
                                     withString:@"●" 
                                startingAtIndex:0];
    self.pinDotsLabel.text = dots;
}

- (void)deleteButtonTapped {
    if (self.pinValue.length > 0) {
        [self.pinValue deleteCharactersInRange:NSMakeRange(self.pinValue.length - 1, 1)];
        NSString *dots = [@"" stringByPaddingToLength:self.pinValue.length 
                                         withString:@"●" 
                                    startingAtIndex:0];
        self.pinDotsLabel.text = dots;
    }
}

- (void)cancelButtonTapped {
    [self.delegate pinMatrixViewDidCancel:self];
}

- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.backgroundColor = [UIColor systemGray3Color];
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
    }];
}

- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.backgroundColor = [UIColor systemGray5Color];
        sender.transform = CGAffineTransformIdentity;
    }];
}

@end