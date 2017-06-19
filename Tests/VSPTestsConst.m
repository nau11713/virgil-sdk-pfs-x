//
//  VSPTestsConst.m
//  VirgilSDK
//
//  Created by Oleksandr Deundiak on 10/24/16.
//  Copyright © 2016 VirgilSecurity. All rights reserved.
//

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)

#import "VSPTestsConst.h"

@implementation VSPTestsConst

- (NSString *)applicationToken {
    return @STRINGIZE2(APPLICATION_TOKEN);
}

- (NSString *)applicationPrivateKeyBase64 {
    return @STRINGIZE2(APPLICATION_PRIVATE_KEY_BASE64);
}

- (NSString *)applicationPrivateKeyPassword {
    return @STRINGIZE2(APPLICATION_PRIVATE_KEY_PASSWORD);
}

- (NSString *)applicationIdentityType {
    return @STRINGIZE2(APPLICATION_IDENTITY_TYPE);
}

- (NSString *)applicationId {
    return @STRINGIZE2(APPLICATION_ID);
}

- (NSURL *)cardsServiceURL {
    NSString *str = [@STRINGIZE2(CARDS_SERVICE_URL) stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return [[NSURL alloc] initWithString:str];
}

- (NSURL *)cardsServiceROURL {
    NSString *str = [@STRINGIZE2(CARDS_SERVICE_RO_URL) stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return [[NSURL alloc] initWithString:str];
}

- (NSURL *)registrationAuthorityURL {
    NSString *str = [@STRINGIZE2(REGISTRATION_AUTHORITY_URL) stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return [[NSURL alloc] initWithString:str];
}

- (NSURL *)pfsServiceURL {
    NSString *str = [@STRINGIZE2(PFS_URL) stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return [[NSURL alloc] initWithString:str];
}

@end