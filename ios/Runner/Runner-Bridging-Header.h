#ifndef Runner_Bridging_Header_h
#define Runner_Bridging_Header_h

#import "GeneratedPluginRegistrant.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import <AppAuth/AppAuth.h>

@protocol GTMAuthSessionDelegate <NSObject>
@required
- (void)didFinishWithAuth:(GTMAppAuthFetcherAuthorization *)authorization error:(NSError *)error;
@end

@interface GIDEMMSupport : NSObject <GTMAuthSessionDelegate>
@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
@end

#endif /* Runner_Bridging_Header_h */
