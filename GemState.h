#import <Foundation/Foundation.h>

extern NSString *const GemStateDidChangeNotification;

@interface GemState : NSObject
/// Current gems from game state, or local fallback if IL2CPP unavailable
@property (nonatomic, readonly) NSInteger gems;

/// YES if connected to actual game state via IL2CPP
@property (nonatomic, readonly) BOOL isLive;

+ (instancetype)shared;

/// Set gems to exact value. Works on live game state when available.
- (BOOL)setGems:(NSInteger)gems;

/// Add gems to current value. Works on live game state when available.
- (BOOL)addGems:(NSInteger)amount;

/// Force refresh from game state
- (void)refresh;
@end
