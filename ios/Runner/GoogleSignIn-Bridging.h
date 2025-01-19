#import <Foundation/Foundation.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import <AppAuth/AppAuth.h>

@protocol GTMAuthSessionDelegate <NSObject>
@required
- (void)didFinishWithAuth:(GTMAppAuthFetcherAuthorization *)authorization error:(NSError *)error;
@end

@interface GIDEMMSupport : NSObject <GTMAuthSessionDelegate>
@property(nonatomic, strong) OIDAuthState *authState;
@property(nonatomic, strong) GTMAppAuthFetcherAuthorization *authorization;
@end
