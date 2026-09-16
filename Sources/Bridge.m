#import "Bridge.h"
#import <dlfcn.h>

// Private macOS 27 surface. Resolve and check every selector at runtime.
@protocol FBConfiguration
- (id)initWithAllowedSystemItems:(NSArray *)items allowedBundleIdentifiers:(NSArray *)bundles;
@end
@protocol FBAssertion
- (void)activateWithConfiguration:(id)configuration completionHandler:(void (^)(NSError *))completion;
- (void)invalidate;
@end
static Class configurationClass, assertionClass;
BOOL FBAvailable(void) {
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        dlopen("/System/Library/PrivateFrameworks/MenuBarClientCore.framework/MenuBarClientCore", RTLD_LAZY);
        configurationClass = NSClassFromString(@"MBAssessmentModeConfiguration");
        assertionClass = NSClassFromString(@"MBAssessmentModeAssertion");
    });
    return [configurationClass instancesRespondToSelector:@selector(initWithAllowedSystemItems:allowedBundleIdentifiers:)]
        && [assertionClass instancesRespondToSelector:@selector(activateWithConfiguration:completionHandler:)]
        && [assertionClass instancesRespondToSelector:@selector(invalidate)];
}
id FBHide(NSArray<NSString *> *allowed, NSArray<NSNumber *> *systemItems, void (^completion)(NSError *)) {
    if (!FBAvailable()) return nil;
    @try {
        // Preserve all nine known system-item identifiers. The OS still suppresses
        // certain extras under an assertion; see README's explicit limitations.
        id config = [(id<FBConfiguration>)[configurationClass alloc]
            initWithAllowedSystemItems:systemItems
            allowedBundleIdentifiers:allowed];
        if (!config) return nil;
        id<FBAssertion> handle = [[assertionClass alloc] init];
        [handle activateWithConfiguration:config completionHandler:completion];
        return handle;
    } @catch (NSException *exception) {
        completion([NSError errorWithDomain:@"FoldBar" code:1 userInfo:@{NSLocalizedDescriptionKey:exception.reason ?: @"菜单栏接口异常"}]);
        return nil;
    }
}
void FBRestore(id assertion) {
    @try { [(id<FBAssertion>)assertion invalidate]; }
    @catch (NSException *exception) { NSLog(@"FoldBar restore: %@", exception); }
}
