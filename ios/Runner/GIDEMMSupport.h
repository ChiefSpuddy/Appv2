#import <Foundation/Foundation.h>
#import <GTMAppAuth/GTMAppAuth.h>

NS_ASSUME_NONNULL_BEGIN

@interface GIDEMMSupport : NSObject <OIDAuthStateChangeDelegate>

@property(nonatomic, strong, nullable) GTMAppAuthFetcherAuthorization *authorization;
@property(nonatomic, strong, nullable) OIDAuthState *authState;

- (void)didChangeState:(OIDAuthState *)state;

@end

NS_ASSUME_NONNULL_END
