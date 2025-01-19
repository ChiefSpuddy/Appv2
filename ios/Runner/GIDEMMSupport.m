#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>

@implementation GIDEMMSupport {
    GTMAppAuthFetcherAuthorization *_authorization;
    OIDAuthState *_authState;
}

- (GTMAppAuthFetcherAuthorization *)authorization {
    return _authorization;
}

- (void)setAuthorization:(GTMAppAuthFetcherAuthorization *)authorization {
    _authorization = authorization;
}

- (OIDAuthState *)authState {
    return _authState;
}

- (void)setAuthState:(OIDAuthState *)authState {
    _authState = authState;
}

- (void)didFinishWithAuth:(GTMAppAuthFetcherAuthorization *)authorization 
                   error:(NSError *)error {
    if (error) {
        NSLog(@"EMM Auth error: %@", error);
        return;
    }
    
    self.authorization = authorization;
    self.authState = authorization.authState;
}

@end
