#import <Foundation/Foundation.h>

@interface IL2CPPBridge : NSObject

/// Attempts to initialize. Returns YES if successful.
+ (BOOL)setup;

/// Returns YES if bridge is ready to modify gems
+ (BOOL)isReady;

/// Adds gems to the actual game state. Returns YES on success.
+ (BOOL)addGems:(int64_t)amount;

@end
