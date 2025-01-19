#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>

NS_ASSUME_NONNULL_BEGIN

@interface GIDEMMSupport : NSObject <GTMAppAuthFetcherAuthorizationDelegate>

@property(nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
@property(nonatomic, strong, nullable) OIDAuthState *authState;

- (void)signInWithCompletion:(void (^)(NSError * _Nullable error))completion;
- (void)signOut;
- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
- (void)didFinishWithAuth:(GTMAppAuthFetcherAuthorization *)authorization 
                   error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
