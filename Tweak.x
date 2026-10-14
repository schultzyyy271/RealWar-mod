#import <UIKit/UIKit.h>
#import "GemOverlay.h"
#import "IL2CPPBridge.h"

// Initialize IL2CPP bridge when app becomes active (IL2CPP runtime is ready)
// and show the overlay UI.
%ctor {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *n) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            // Initialize IL2CPP bridge (idempotent)
            [IL2CPPBridge setup];
            // Show overlay
            [GemOverlay installIfNeeded];
        });
    }];
}
