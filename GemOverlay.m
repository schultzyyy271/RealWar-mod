#import "GemOverlay.h"
#import "GemState.h"

static UIWindow *s_overlayWindow = nil;

@implementation GemOverlay

+ (void)installIfNeeded {
    if (s_overlayWindow) return;
    
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:UIWindowScene.class] && s.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if (!scene) return;
    
    // Create passthrough window
    s_overlayWindow = [[GemPassthroughWindow alloc] initWithWindowScene:scene];
    s_overlayWindow.frame = scene.coordinateSpace.bounds;
    s_overlayWindow.windowLevel = UIWindowLevelAlert + 100;
    s_overlayWindow.backgroundColor = UIColor.clearColor;
    s_overlayWindow.hidden = NO;
    
    // Empty root VC with passthrough view
    GemOverlayVC *vc = [GemOverlayVC new];
    s_overlayWindow.rootViewController = vc;
    
    // Add button
    CGFloat size = 50;
    CGFloat margin = 8;
    GemOverlay *btn = [[GemOverlay alloc] initWithFrame:CGRectMake(
        s_overlayWindow.bounds.size.width - size - margin,
        s_overlayWindow.bounds.size.height * 0.4,
        size, size
    )];
    btn.tag = 9999; // Tag to identify our button
    [vc.view addSubview:btn];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.9];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 4;
        self.layer.borderWidth = 2;
        self.layer.borderColor = UIColor.whiteColor.CGColor;
        
        UIImageConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightBold];
        UIImage *gem = [UIImage systemImageNamed:@"diamond.fill" withConfiguration:cfg];
        [self setImage:gem forState:UIControlStateNormal];
        self.tintColor = UIColor.whiteColor;
        
        UILabel *plus = [UILabel new];
        plus.text = @"+1";
        plus.font = [UIFont systemFontOfSize:9 weight:UIFontWeightBold];
        plus.textColor = UIColor.whiteColor;
        plus.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:plus];
        [NSLayoutConstraint activateConstraints:@[
            [plus.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [plus.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
        ]];
        
        [self addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragged:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)tapped {
    // Safe gem add - just log if not ready
    @try {
        [[GemState shared] addGems:1];
        NSLog(@"[RealWarMod] Added 1 gem");
    } @catch (NSException *e) {
        NSLog(@"[RealWarMod] Gem add failed: %@", e);
    }
    
    // Pulse animation
    [UIView animateWithDuration:0.08 animations:^{
        self.transform = CGAffineTransformMakeScale(1.3, 1.3);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.08 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)dragged:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    CGFloat newY = self.center.y + translation.y;
    CGFloat minY = self.bounds.size.height / 2 + 50;
    CGFloat maxY = self.superview.bounds.size.height - self.bounds.size.height / 2 - 50;
    newY = MAX(minY, MIN(maxY, newY));
    self.center = CGPointMake(self.center.x, newY);
    [pan setTranslation:CGPointZero inView:self.superview];
}

@end

#pragma mark - Passthrough Window

@implementation GemPassthroughWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // Only handle touches on the gem button, pass everything else through
    for (UIView *subview in self.rootViewController.view.subviews) {
        if (subview.tag == 9999) {
            CGPoint converted = [self convertPoint:point toView:subview];
            if ([subview pointInside:converted withEvent:event]) {
                return YES;
            }
        }
    }
    return NO;
}

@end

#pragma mark - Passthrough View Controller

@implementation GemOverlayVC

- (void)loadView {
    self.view = [GemPassthroughView new];
    self.view.backgroundColor = UIColor.clearColor;
}

- (BOOL)shouldAutorotate { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }

@end

@implementation GemPassthroughView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *subview in self.subviews) {
        if (subview.tag == 9999) {
            CGPoint converted = [self convertPoint:point toView:subview];
            if ([subview pointInside:converted withEvent:event]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
