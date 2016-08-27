//
//  UINavigationController+Extension.h
//  UINavigationTest
//
//  Created by 胡鹏 on 8/27/16.
//  Copyright © 2016 Vince. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UINavigationController (Extension)

/// 自定义全屏拖拽返回手势
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *hp_popGestureRecognizer;

@end
