#import <UIKit/UIKit.h>
#import "GemOverlay.h"
#import "IL2CPPBridge.h"

// Initialize when app becomes active (IL2CPP runtime should be ready)
%ctor {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *n) {
        // Delay to ensure Unity is fully initialized
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            // Setup IL2CPP bridge
            [IL2CPPBridge setup];
            // Show overlay button
            [GemOverlay installIfNeeded];
        });
    }];
}
