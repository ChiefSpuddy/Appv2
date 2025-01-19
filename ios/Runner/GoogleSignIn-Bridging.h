#import <GoogleSignIn/GoogleSignIn.h>
#import <GTMAppAuth/GTMAppAuth.h>
#import <AppAuth/AppAuth.h>

@protocol GTMAuthSessionDelegate;
@class OIDAuthState;

@interface GIDEMMSupport : NSObject <GTMAuthSessionDelegate>
@property(nonatomic, strong) OIDAuthState *authState;
@end
