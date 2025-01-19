#import "GoogleSignIn-Bridging.h"

@implementation GIDEMMSupport

@synthesize authState = _authState;
@synthesize authorization = _authorization;

- (void)didFinishWithAuth:(nullable GTMAppAuthFetcherAuthorization *)authorization 
                   error:(nullable NSError *)error {
    if (error) {
        NSLog(@"Auth error: %@", error);
        return;
    }
    
    self.authorization = authorization;
    self.authState = authorization.authState;
}

@end
