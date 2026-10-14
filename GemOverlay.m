#import "GemOverlay.h"
#import "GemState.h"

static UIWindow *s_overlayWindow = nil;

@implementation GemOverlay {
    CGFloat _dragStartY;
}

+ (void)installIfNeeded {
    if (s_overlayWindow) return; // Already installed
    
    // Get the active window scene
    UIWindowScene *scene = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if ([s isKindOfClass:UIWindowScene.class] && s.activationState == UISceneActivationStateForegroundActive) {
            scene = (UIWindowScene *)s;
            break;
        }
    }
    if (!scene) return;
    
    // Create a passthrough overlay window at a high window level
    s_overlayWindow = [[UIWindow alloc] initWithWindowScene:scene];
    s_overlayWindow.frame = scene.coordinateSpace.bounds;
    s_overlayWindow.windowLevel = UIWindowLevelAlert + 100; // Above everything
    s_overlayWindow.backgroundColor = UIColor.clearColor;
    s_overlayWindow.userInteractionEnabled = YES;
    s_overlayWindow.hidden = NO;
    
    // Make window pass through touches except on the button
    s_overlayWindow.rootViewController = [GemOverlayVC new];
    
    // Create and add the button
    CGFloat size = 50;
    CGFloat margin = 8;
    GemOverlay *btn = [[GemOverlay alloc] initWithFrame:CGRectMake(
        s_overlayWindow.bounds.size.width - size - margin,
        s_overlayWindow.bounds.size.height * 0.4,
        size, size
    )];
    [s_overlayWindow.rootViewController.view addSubview:btn];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Appearance: circular gem button
        self.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.9];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 4;
        self.layer.borderWidth = 2;
        self.layer.borderColor = UIColor.whiteColor.CGColor;
        
        // Gem icon
        UIImageConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightBold];
        UIImage *gem = [UIImage systemImageNamed:@"diamond.fill" withConfiguration:cfg];
        [self setImage:gem forState:UIControlStateNormal];
        self.tintColor = UIColor.whiteColor;
        
        // +1 label
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
        
        // Tap action
        [self addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        // Drag gesture (vertical only)
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragged:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)tapped {
    // Add +1 gem
    [[GemState shared] addGems:1];
    
    // Quick pulse animation feedback
    [UIView animateWithDuration:0.08 animations:^{
        self.transform = CGAffineTransformMakeScale(1.3, 1.3);
        self.alpha = 0.7;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.08 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.alpha = 1.0;
        }];
    }];
}

- (void)dragged:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    
    // Move only vertically, clamp to screen bounds
    CGFloat newY = self.center.y + translation.y;
    CGFloat minY = self.bounds.size.height / 2 + 50;  // Below status bar
    CGFloat maxY = self.superview.bounds.size.height - self.bounds.size.height / 2 - 50;
    newY = MAX(minY, MIN(maxY, newY));
    
    self.center = CGPointMake(self.center.x, newY);
    [pan setTranslation:CGPointZero inView:self.superview];
}

@end

#pragma mark - Passthrough View Controller

@implementation GemOverlayVC

- (void)loadView {
    self.view = [GemPassthroughView new];
    self.view.backgroundColor = UIColor.clearColor;
}

@end

@implementation GemPassthroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    // Only intercept touches on actual subviews (the button), pass through otherwise
    return (hit == self) ? nil : hit;
}

@end
