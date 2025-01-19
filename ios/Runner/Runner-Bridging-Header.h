#ifndef Runner_Bridging_Header_h
#define Runner_Bridging_Header_h

#import "GeneratedPluginRegistrant.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <GTMAppAuth/GTMAppAuthFetcherAuthorization.h>
#import <GTMAppAuth/GTMKeychainStore.h>
#import <GTMAppAuth/GTMOAuth2KeychainCompatibility.h>
#import <GTMSessionFetcher/GTMSessionFetcher.h>
#import <AppAuth/AppAuth.h>

@class GTMAppAuthFetcherAuthorization;
@class GTMKeychainStore;
@class GTMOAuth2ViewControllerTouch;
@class OIDAuthState;

@protocol GTMAuthSessionDelegate;
@protocol OIDAuthStateChangeDelegate;

@interface GTMKeychainStore : NSObject
@property(nonatomic, strong) id keychainHelper;
@end

@interface GIDEMMSupport : NSObject <GTMAuthSessionDelegate>
@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
- (void)didFinishWithAuth:(nullable GTMAppAuthFetcherAuthorization *)authorization 
                   error:(nullable NSError *)error;
@end

#endif /* Runner_Bridging_Header_h */
