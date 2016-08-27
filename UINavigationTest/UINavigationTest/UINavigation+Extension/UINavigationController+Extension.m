//
//  UINavigationController+Extension.m
//  UINavigationTest
//
//  Created by 胡鹏 on 8/27/16.
//  Copyright © 2016 Vince. All rights reserved.
//

#import "UINavigationController+Extension.h"
#import <objc/runtime.h>

@interface HPFullScreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;

@end

@implementation HPFullScreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    
    //只有一个视图控制器时(根视图)，返回NO
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    //如果正在转场动画，取消手势
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    //判断手指移动方向，手势相反时，返回NO
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    if (translation.x <= 0) {
        return NO;
    }
    
    return YES;
}

@end

@implementation UINavigationController (Extension)

+ (void)load {
    //截取方法
    Method originalMethod = class_getInstanceMethod([self class], @selector(pushViewController:animated:));
    Method swizzledMethod = class_getInstanceMethod([self class], @selector(hp_pushViewController:animated:));
    //交换方法
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (void)hp_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.hp_popGestureRecognizer]) {
        //不包含手势时，添加手势
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.hp_popGestureRecognizer];
        //获取系统手势的数组
        NSArray *targets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        //获取它的唯一对象，我们知道它是一个叫UIGestureRecognizerTarget的私有类，它有一个属性叫_target
        id internalTarget = [targets.firstObject valueForKey:@"target"];
        //获取_target:_UINavigationInteractiveTransition，它有一个方法叫handleNavigationTransition: 通过前面的打印，我们从控制台获取出来它的方法签名。
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        //创建一个与系统一模一样的手势，我们只把它的类改为UIPanGestureRecognizer
        self.hp_popGestureRecognizer.delegate = [self hp_fullScreenPopGestureRecognizerDelegate];
        [self.hp_popGestureRecognizer addTarget:internalTarget action:internalAction];
        
        // 禁用系统的交互手势
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    //调用pushViewController:animated:
    if (![self.viewControllers containsObject:viewController]) {
        [self hp_pushViewController:viewController animated:animated];
    }
}

- (HPFullScreenPopGestureRecognizerDelegate *)hp_fullScreenPopGestureRecognizerDelegate {
    HPFullScreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    if (!delegate) {
        delegate = [[HPFullScreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

//关联手势
- (UIPanGestureRecognizer *)hp_popGestureRecognizer {
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);
    
    if (panGestureRecognizer == nil) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}


@end
