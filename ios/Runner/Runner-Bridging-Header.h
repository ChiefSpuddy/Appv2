#ifndef Runner_Bridging_Header_h
#define Runner_Bridging_Header_h

#import "GeneratedPluginRegistrant.h"
@import GoogleSignIn;
@import GTMAppAuth;
@import GTMSessionFetcher;
@import AppAuth;

@class GTMAppAuthFetcherAuthorization;
@class OIDAuthState;

@protocol GTMAuthSessionDelegate;
@protocol OIDAuthStateChangeDelegate;

@interface GIDEMMSupport : NSObject <GTMAuthSessionDelegate>
@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
- (void)didFinishWithAuth:(nullable GTMAppAuthFetcherAuthorization *)authorization 
                   error:(nullable NSError *)error;
@end

#endif /* Runner_Bridging_Header_h */
