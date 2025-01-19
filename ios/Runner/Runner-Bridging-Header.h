#ifndef Runner_Bridging_Header_h
#define Runner_Bridging_Header_h

#import "GeneratedPluginRegistrant.h"
@import GoogleSignIn;
@import GTMAppAuth;
@import GTMSessionFetcher;
@import AppAuth;

@class GTMAppAuthFetcherAuthorization;

@protocol GTMAuthSessionDelegate <NSObject>
- (void)didFinishWithAuth:(GTMAppAuthFetcherAuthorization *)authorization 
                   error:(nullable NSError *)error;
@end

typedef NS_ENUM(NSInteger, GIDEMMErrorCode) {
    GIDEMMErrorCodeUnknown = -1,
    GIDEMMErrorCodeMissingConfiguration = 1,
};

@interface GIDEMMSupport : NSObject <GTMAuthSessionDelegate>
@property(nonatomic, strong, nullable) OIDAuthState *authState;
@property(nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
- (void)didFinishWithAuth:(nullable GTMAppAuthFetcherAuthorization *)authorization 
                   error:(nullable NSError *)error;
@end

#endif /* Runner_Bridging_Header_h */
