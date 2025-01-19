#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>

NS_ASSUME_NONNULL_BEGIN

@interface GIDEMMSupport : NSObject <OIDAuthStateChangeDelegate>

@property(nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
@property(nonatomic, strong, nullable) OIDAuthState *authState;

- (void)didFinishWithAuth:(nullable GTMAppAuthFetcherAuthorization *)authorization 
                   error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
