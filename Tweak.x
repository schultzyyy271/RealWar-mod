#import <UIKit/UIKit.h>
#import "GemOverlay.h"

// No method hooks: the dylib simply owns its own GemState and shows the
// overlay once the host app (the one in GemDebugDemo.plist) becomes active.
%ctor {
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *n) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{ [GemOverlay installIfNeeded]; });
    }];
}
