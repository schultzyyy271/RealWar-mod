#import "GemOverlay.h"
#import "GemState.h"
#import "IL2CPPBridge.h"

static UIWindow *s_overlayWindow = nil;
static const NSInteger kButtonTagBase = 9999;

typedef NS_ENUM(NSInteger, ModButtonType) {
    ModButtonTypeGem = 0,
    ModButtonTypeCoin = 1,
};

@implementation GemOverlay {
    ModButtonType _type;
}

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
    
    GemOverlayVC *vc = [GemOverlayVC new];
    s_overlayWindow.rootViewController = vc;
    
    CGFloat size = 50;
    CGFloat margin = 8;
    CGFloat spacing = 8;
    CGFloat startY = s_overlayWindow.bounds.size.height * 0.35;
    CGFloat x = s_overlayWindow.bounds.size.width - size - margin;
    
    // Gem button
    GemOverlay *gemBtn = [[GemOverlay alloc] initWithFrame:CGRectMake(x, startY, size, size) type:ModButtonTypeGem];
    gemBtn.tag = kButtonTagBase;
    [vc.view addSubview:gemBtn];
    
    // Coin button (below gem)
    GemOverlay *coinBtn = [[GemOverlay alloc] initWithFrame:CGRectMake(x, startY + size + spacing, size, size) type:ModButtonTypeCoin];
    coinBtn.tag = kButtonTagBase + 1;
    [vc.view addSubview:coinBtn];
}

- (instancetype)initWithFrame:(CGRect)frame type:(ModButtonType)type {
    if ((self = [super initWithFrame:frame])) {
        _type = type;
        
        // Colors based on type
        UIColor *bgColor;
        NSString *iconName;
        NSString *labelText;
        
        if (type == ModButtonTypeGem) {
            bgColor = [UIColor.systemBlueColor colorWithAlphaComponent:0.9];
            iconName = @"diamond.fill";
            labelText = @"+1";
        } else {
            bgColor = [UIColor.systemYellowColor colorWithAlphaComponent:0.9];
            iconName = @"dollarsign.circle.fill";
            labelText = @"+1k";
        }
        
        self.backgroundColor = bgColor;
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.shadowColor = UIColor.blackColor.CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 4;
        self.layer.borderWidth = 2;
        self.layer.borderColor = UIColor.whiteColor.CGColor;
        
        UIImageConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold];
        UIImage *icon = [UIImage systemImageNamed:iconName withConfiguration:cfg];
        [self setImage:icon forState:UIControlStateNormal];
        self.tintColor = UIColor.whiteColor;
        
        UILabel *label = [UILabel new];
        label.text = labelText;
        label.font = [UIFont systemFontOfSize:8 weight:UIFontWeightBold];
        label.textColor = UIColor.whiteColor;
        label.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:label];
        [NSLayoutConstraint activateConstraints:@[
            [label.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-4],
        ]];
        
        [self addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragged:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    return [self initWithFrame:frame type:ModButtonTypeGem];
}

- (void)tapped {
    @try {
        if (_type == ModButtonTypeGem) {
            [[GemState shared] addGems:1];
        } else {
            [IL2CPPBridge addCoins:1000];
        }
    } @catch (NSException *e) {
        NSLog(@"[RealWarMod] Tap failed: %@", e);
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
    for (UIView *subview in self.rootViewController.view.subviews) {
        if (subview.tag >= kButtonTagBase) {
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
        if (subview.tag >= kButtonTagBase) {
            CGPoint converted = [self convertPoint:point toView:subview];
            if ([subview pointInside:converted withEvent:event]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
