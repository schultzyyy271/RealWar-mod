#import "GemOverlay.h"
#import "GemState.h"

@implementation GemOverlay {
    UILabel *_countLabel;
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
    for (UIView *v in window.subviews) if ([v isKindOfClass:self]) return; // already installed

    GemOverlay *overlay = [[GemOverlay alloc] initWithFrame:CGRectMake(0, 0, 220, 150)];
    overlay.center = CGPointMake(CGRectGetMidX(window.bounds), window.safeAreaInsets.top + 120);
    [window addSubview:overlay];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.92];
        self.layer.cornerRadius = 16;
        self.layer.masksToBounds = YES;

        UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"diamond.fill"]];
        icon.tintColor = UIColor.systemBlueColor;
        icon.contentMode = UIViewContentModeScaleAspectFit;

        UILabel *title = [UILabel new];
        title.text = @"Gem Debug Demo";
        title.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];

        _countLabel = [UILabel new];
        _countLabel.font = [UIFont monospacedDigitSystemFontOfSize:32 weight:UIFontWeightBold];
        [self refresh];

        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[icon, title, _countLabel]];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 6;

#if GEM_DEBUG_UI
        UIAction *action = [UIAction actionWithTitle:@"Set debug gems to 99,999"
                                               image:nil
                                          identifier:nil
                                             handler:^(__kindof UIAction *a) {
            [[GemState shared] set_gemsAmountBigIntegerObservedValue];
        }];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem primaryAction:action];
        button.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.backgroundColor = UIColor.systemBlueColor;
        button.layer.cornerRadius = 8;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        [button.heightAnchor constraintEqualToConstant:32].active = YES;
        [button.widthAnchor constraintEqualToConstant:190].active = YES;
        [stack addArrangedSubview:button];
#else
        UILabel *note = [UILabel new];
        note.text = @"Debug controls are unavailable in Release builds.";
        note.font = [UIFont systemFontOfSize:10];
        note.textColor = UIColor.secondaryLabelColor;
        note.numberOfLines = 0;
        note.textAlignment = NSTextAlignmentCenter;
        [stack addArrangedSubview:note];
#endif

        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [icon.heightAnchor constraintEqualToConstant:30],
            [stack.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [stack.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [stack.widthAnchor constraintLessThanOrEqualToAnchor:self.widthAnchor constant:-16],
        ]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh)
            name:GemStateDidChangeNotification object:nil];

        // Make it draggable so it never blocks the host UI.
        [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
    }
    return self;
}

- (void)refresh {
    NSNumberFormatter *f = [NSNumberFormatter new];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    _countLabel.text = [f stringFromNumber:@([GemState shared].gems)];
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [g setTranslation:CGPointZero inView:self.superview];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

@end
