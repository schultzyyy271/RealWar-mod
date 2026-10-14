#import "GemState.h"

NSString *const GemStateDidChangeNotification = @"GemStateDidChangeNotification";
static NSString *const kGemsDefaultsKey = @"RealWarMod.gems.fallback";

@interface GemState ()
@property (nonatomic, readwrite) NSInteger gems;
@property (nonatomic, readwrite) BOOL isLive;
@end

@implementation GemState

+ (instancetype)shared {
    static GemState *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [GemState new]; });
    return s;
}

- (instancetype)init {
    if ((self = [super init])) {
        _isLive = NO;
        _gems = [NSUserDefaults.standardUserDefaults integerForKey:kGemsDefaultsKey];
    }
    return self;
}

- (void)refresh {
    // For now, just use local storage (IL2CPP integration needs debugging)
    _gems = [NSUserDefaults.standardUserDefaults integerForKey:kGemsDefaultsKey];
}

- (BOOL)updateGems:(NSInteger)gems {
    gems = MAX(gems, 0);
    _gems = gems;
    [NSUserDefaults.standardUserDefaults setInteger:gems forKey:kGemsDefaultsKey];
    [self postNotification];
    return YES;
}

- (BOOL)addGems:(NSInteger)amount {
    return [self updateGems:self.gems + amount];
}

- (void)postNotification {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:GemStateDidChangeNotification object:self];
}

@end
