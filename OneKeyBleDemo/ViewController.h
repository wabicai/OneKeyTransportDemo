//
//  ViewController.h
//  OneKeyBleDemo
//
//  Created by 蔡凯升 on 2024/11/1.
//

#import <UIKit/UIKit.h>
#import "OKBleTransport.h"

@interface ViewController : UIViewController

@property (nonatomic, strong, readonly) OKBleTransport *bleTransport;
@property (nonatomic, strong, readonly) UITextView *logTextView;

@end

