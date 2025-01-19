#import "GIDEMMSupport+AuthSession.h"
#import <objc/runtime.h>

static void *AuthorizationKey = &AuthorizationKey;
static void *AuthStateKey = &AuthStateKey;

@implementation GIDEMMSupport (AuthSession)

- (GTMAppAuthFetcherAuthorization *)authorization {
    return objc_getAssociatedObject(self, AuthorizationKey);
}

- (void)setAuthorization:(GTMAppAuthFetcherAuthorization *)authorization {
    objc_setAssociatedObject(self, AuthorizationKey, authorization, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (OIDAuthState *)authState {
    return objc_getAssociatedObject(self, AuthStateKey);
}

- (void)setAuthState:(OIDAuthState *)authState {
    objc_setAssociatedObject(self, AuthStateKey, authState, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
