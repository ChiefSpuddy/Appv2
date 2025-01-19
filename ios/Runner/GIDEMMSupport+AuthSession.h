#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>

@interface GIDEMMSupport (AuthSession)
@property (nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
@property (nonatomic, strong, nullable) OIDAuthState *authState;
@end
