#import <Foundation/Foundation.h>

extern NSString *const GemStateDidChangeNotification;

@interface GemState : NSObject

@property (nonatomic, readonly) NSInteger gems;
@property (nonatomic, readonly) BOOL isLive;

+ (instancetype)shared;

/// Add gems. Returns YES if successfully added to game state.
- (BOOL)addGems:(NSInteger)amount;

@end
