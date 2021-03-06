//
//  KGStatusBar.m
//
//  Created by Kevin Gibbon on 2/27/13.
//  Copyright 2013 Kevin Gibbon. All rights reserved.
//  @kevingibbon
//

#import "KGStatusBar.h"

CGFloat UIInterfaceOrientationAngleOfOrientation(UIInterfaceOrientation orientation) {
    CGFloat angle;
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            angle = -M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            angle = M_PI_2;
            break;
        default:
            angle = 0.0;
            break;
    }
    return angle;
}

UIInterfaceOrientationMask UIInterfaceOrientationMaskFromOrientation(UIInterfaceOrientation orientation) {
    return 1 << orientation;
}



@interface KGStatusBar ()
    @property (nonatomic, strong, readonly) UIWindow *overlayWindow;
    @property (nonatomic, strong, readonly) UIView *topBar;
    @property (nonatomic, strong) UILabel *stringLabel;
    @property (nonatomic, assign, readwrite) BOOL hidden;
@end

@implementation KGStatusBar

@synthesize topBar, overlayWindow, stringLabel;

+ (KGStatusBar*)sharedView {
    static dispatch_once_t once;
    static KGStatusBar *sharedView;
    dispatch_once(&once, ^ {
        sharedView = [[KGStatusBar alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [[NSNotificationCenter defaultCenter] addObserver:sharedView
                                                 selector:@selector(statusBarFrameOrOrientationChanged:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedView
                                                 selector:@selector(statusBarFrameOrOrientationChanged:)
                                                     name:UIApplicationDidChangeStatusBarFrameNotification
                                                   object:nil];
    });
    return sharedView;
}

+ (void)showSuccessWithStatus:(NSString*)status
{
    [KGStatusBar showWithStatus:status];
    [KGStatusBar performSelector:@selector(dismiss) withObject:self afterDelay:2.0 ];
}

+ (void)showWithStatus:(NSString*)status {
    [[KGStatusBar sharedView] showWithStatus:status barColor:[UIColor blackColor] textColor:[UIColor colorWithRed:191.0/255.0 green:191.0/255.0 blue:191.0/255.0 alpha:1.0]];
}

+ (void)showErrorWithStatus:(NSString*)status {
    [[KGStatusBar sharedView] showWithStatus:status barColor:[UIColor colorWithRed:97.0/255.0 green:4.0/255.0 blue:4.0/255.0 alpha:1.0] textColor:[UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [KGStatusBar performSelector:@selector(dismiss) withObject:self afterDelay:2.0 ];
}

+ (void)dismiss {
    [[KGStatusBar sharedView] dismiss];
}

- (id)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])) {
		self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
		self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.hidden = YES;
    }
    return self;
}

- (void)showWithStatus:(NSString *)status barColor:(UIColor*)barColor textColor:(UIColor*)textColor{
    [self showWithStatus:status barColor:barColor labelColor:[UIColor clearColor] textColor:textColor];
}

- (void)showWithStatus:(NSString *)status
              barColor:(UIColor*)barColor
            labelColor:(UIColor*)labelColor
             textColor:(UIColor*)textColor {
    if(!self.superview)
        [self.overlayWindow addSubview:self];
    self.hidden = NO;
    [self.overlayWindow setHidden:NO];
    [self.topBar setHidden:NO];
    self.topBar.backgroundColor = barColor;
    NSString *labelText = status;
    CGRect labelRect = CGRectZero;
    CGFloat stringWidth = 0;
    CGFloat stringHeight = 0;
    if(labelText) {
        CGSize stringSize = [labelText sizeWithFont:self.stringLabel.font constrainedToSize:CGSizeMake(self.topBar.frame.size.width, self.topBar.frame.size.height)];
        stringWidth = stringSize.width;
        stringHeight = stringSize.height;
        
        labelRect = CGRectMake((self.topBar.frame.size.width / 2) - (stringWidth / 2), 0, stringWidth, stringHeight);
    }
    self.stringLabel.frame = labelRect;
    self.stringLabel.alpha = 0.0;
    self.stringLabel.hidden = NO;
    self.stringLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.stringLabel.text = labelText;
    self.stringLabel.textColor = textColor;
    self.stringLabel.backgroundColor = labelColor;
    [UIView animateWithDuration:0.4 animations:^{
        self.stringLabel.alpha = 1.0;
    }];
    [self setNeedsDisplay];
}

- (void) dismiss
{
    [UIView animateWithDuration:0.4 animations:^{
        self.stringLabel.alpha = 0.0;
    } completion:^(BOOL finished) {
        [topBar removeFromSuperview];
        topBar = nil;
        
        [overlayWindow removeFromSuperview];
        overlayWindow = nil;
        
        self.hidden = YES;
    }];
}

- (UIWindow *)overlayWindow {
    if(!overlayWindow) {
        overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.userInteractionEnabled = NO;
        overlayWindow.windowLevel = UIWindowLevelStatusBar;
    }
    return overlayWindow;
}

- (UIView *)topBar {
    if(!topBar) {
        topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, overlayWindow.frame.size.width, 20.0)];
        [overlayWindow addSubview:topBar];
    }
    return topBar;
}

- (UILabel *)stringLabel {
    if (stringLabel == nil) {
        stringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		stringLabel.textColor = [UIColor colorWithRed:191.0/255.0 green:191.0/255.0 blue:191.0/255.0 alpha:1.0];
		stringLabel.backgroundColor = [UIColor clearColor];
		stringLabel.adjustsFontSizeToFitWidth = YES;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 60000
        stringLabel.textAlignment = UITextAlignmentCenter;
#else
        stringLabel.textAlignment = NSTextAlignmentCenter;
#endif
		stringLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		stringLabel.font = [UIFont boldSystemFontOfSize:14.0];
		stringLabel.shadowColor = [UIColor blackColor];
		stringLabel.shadowOffset = CGSizeMake(0, -1);
        stringLabel.numberOfLines = 0;
    }
    
    if(!stringLabel.superview)
        [self.topBar addSubview:stringLabel];
    
    return stringLabel;
}


#pragma mark - Notifications

- (void)statusBarFrameOrOrientationChanged:(NSNotification *)notification {
    self.stringLabel.alpha = 0.0;
    
    [UIView animateWithDuration:0.3
                          delay:0.4
                        options:0
                     animations:^{
                         self.stringLabel.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                     }];
    
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat angle = UIInterfaceOrientationAngleOfOrientation(statusBarOrientation);
    CGSize statusBarSize = [UIApplication sharedApplication].statusBarFrame.size;
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    CGRect frame = [self rectInWindowBounds:self.window.bounds statusBarOrientation:statusBarOrientation statusBarSize:statusBarSize];
    
    [self setIfNotEqualTransform:transform frame:frame];
}

- (CGRect)rectInWindowBounds:(CGRect)windowBounds statusBarOrientation:(UIInterfaceOrientation)statusBarOrientation statusBarSize:(CGSize)statusBarSize {
    CGRect frame = windowBounds;
    
    switch (statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
            frame.origin = CGPointMake(0.0, 0.0);
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            frame.origin = CGPointMake(statusBarSize.width, statusBarSize.height);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            frame.origin = CGPointMake(0.0, 0.0);
            break;
        case UIInterfaceOrientationLandscapeRight:
            frame.origin = CGPointMake(windowBounds.size.width-statusBarSize.width, 0.0);
            break;
        default:
            break;
    }
    frame.size = statusBarSize;
    return frame;
}

- (void)setIfNotEqualTransform:(CGAffineTransform)transform frame:(CGRect)frame {
    
    [UIView beginAnimations:nil context:NULL]; // prevents animation of status bar
	[UIView setAnimationDuration:0];
    
    if(!CGAffineTransformEqualToTransform(self.topBar.transform, transform)) {
        self.topBar.transform = transform;
    }

    if(!CGRectEqualToRect(self.topBar.frame, frame)) {
        self.topBar.frame = frame;
    }
    
    [UIView commitAnimations];
}

@end
