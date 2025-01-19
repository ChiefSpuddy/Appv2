#import "GIDEMMSupport.h"

@implementation GIDEMMSupport

@synthesize authorization = _authorization;
@synthesize authState = _authState;

- (void)didChangeState:(OIDAuthState *)state {
    self.authorization = [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:state];
    self.authState = state;
}

@end
