#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// Speed-only test build for LiveContainer.
// Ad SDK loading and completion callbacks remain untouched.
// This affects every AVPlayer in the target app, not only ad videos.
static IMP adspeed_originalSetRate = NULL;

static void adspeed_setRate(AVPlayer *player, SEL selector, float rate) {
    if (adspeed_originalSetRate == NULL) return;
    float adjustedRate = (rate > 0.0f) ? rate * 16.0f : rate;
    ((void (*)(id, SEL, float))adspeed_originalSetRate)(player, selector, adjustedRate);
}

__attribute__((constructor))
static void adspeed_initialize(void) {
    @autoreleasepool {
        Class playerClass = objc_getClass("AVPlayer");
        SEL selector = @selector(setRate:);
        Method method = playerClass ? class_getInstanceMethod(playerClass, selector) : NULL;
        if (method != NULL) {
            adspeed_originalSetRate = method_setImplementation(method, (IMP)adspeed_setRate);
            NSLog(@"[adspeed] speed-only mode loaded; positive AVPlayer rates multiplied by 16.");
        } else {
            NSLog(@"[adspeed] AVPlayer setRate: not found; playback unchanged.");
        }
    }
}
