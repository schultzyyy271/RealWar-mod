#import "GemOverlay.h"
#import "GemState.h"

@implementation GemOverlay {
    CGFloat _dragStartY;
}

static UIWindow *GemKeyWindow(void) {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        if (scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ((UIWindowScene *)scene).windows) {
            if (w.isKeyWindow) return w;
        }
    }
    return nil;
}

+ (void)installIfNeeded {
    UIWindow *window = GemKeyWindow();
    if (!window) return;
    for (UIView *v in window.subviews) if ([v isKindOfClass:self]) return;

    CGFloat size = 50;
    CGFloat margin = 8;
    GemOverlay *btn = [[GemOverlay alloc] initWithFrame:CGRectMake(
        window.bounds.size.width - size - margin,
        window.bounds.size.height * 0.4,
        size, size
    )];
    [window addSubview:btn];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Appearance: circular gem button
        self.backgroundColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.85];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.3;
        self.layer.shadowRadius = 4;
        
        // Gem icon
        UIImageConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightBold];
        UIImage *gem = [UIImage systemImageNamed:@"diamond.fill" withConfiguration:cfg];
        [self setImage:gem forState:UIControlStateNormal];
        self.tintColor = UIColor.whiteColor;
        
        // +1 label
        UILabel *plus = [UILabel new];
        plus.text = @"+1";
        plus.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
        plus.textColor = UIColor.whiteColor;
        plus.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:plus];
        [NSLayoutConstraint activateConstraints:@[
            [plus.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [plus.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
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
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)dragged:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    
    // Move only vertically, clamp to screen bounds
    CGFloat newY = self.center.y + translation.y;
    CGFloat minY = self.bounds.size.height / 2 + self.superview.safeAreaInsets.top;
    CGFloat maxY = self.superview.bounds.size.height - self.bounds.size.height / 2 - self.superview.safeAreaInsets.bottom;
    newY = MAX(minY, MIN(maxY, newY));
    
    self.center = CGPointMake(self.center.x, newY);
    [pan setTranslation:CGPointZero inView:self.superview];
}

@end
