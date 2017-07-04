//
//  VSP002_SessionTests.m
//  VirgilSDKPFS
//
//  Created by Oleksandr Deundiak on 6/22/17.
//  Copyright © 2017 VirgilSecurity. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "VSPTestsConst.h"
#import "VSPTestUtils.h"
@import VirgilSDK;
@import VirgilSDKPFS;

static const NSTimeInterval kEstimatedRequestCompletionTime = 8.;

@interface VSP002_SecureChatTests : XCTestCase

@property (nonatomic) VSPSecureChat *initiatorSecureChat;
@property (nonatomic) VSPSecureChat *initiatorSecureChat2;
@property (nonatomic) VSPSecureChat *responderSecureChat;
@property (nonatomic) VSPSecureChat *responderSecureChat2;
@property (nonatomic) VSSClient *virgilClient;
@property (nonatomic) VSPClient *client;
@property (nonatomic) id<VSSCrypto> crypto;
@property (nonatomic) VSPTestsConst *consts;
@property (nonatomic) VSPTestUtils *utils;
@property (nonatomic) NSUInteger numberOfCards;
@property (nonatomic) NSTimeInterval longTermKeysTtl;
@property (nonatomic) NSTimeInterval sessionTtl;
@property (nonatomic) NSString *message1;
@property (nonatomic) NSString *message2;
@property (nonatomic) NSString *message3;
@property (nonatomic) NSString *message4;

@end

@implementation VSP002_SecureChatTests

- (void)setUp {
    [super setUp];
    self.consts = [[VSPTestsConst alloc] init];
    self.utils = [[VSPTestUtils alloc] init];
    self.crypto = [[VSSCrypto alloc] init];
    
    VSSServiceConfig *virgilConfig = [VSSServiceConfig serviceConfigWithToken:self.consts.applicationToken];
    
    VSSCardValidator *validator = [[VSSCardValidator alloc] initWithCrypto:self.crypto];
    VSSPrivateKey *privateKey = [self.crypto importPrivateKeyFromData:[[NSData alloc] initWithBase64EncodedString:self.consts.applicationPrivateKeyBase64 options:0]  withPassword:self.consts.applicationPrivateKeyPassword];
    VSSPublicKey *publicKey = [self.crypto extractPublicKeyFromPrivateKey:privateKey];
    NSData *publicKeyData = [self.crypto exportPublicKey:publicKey];
    XCTAssert([validator addVerifierWithId:self.consts.applicationId publicKeyData:publicKeyData]);
    validator.useVirgilServiceVerifiers = NO;
    virgilConfig.cardValidator = validator;
    
    virgilConfig.cardsServiceURL = self.consts.cardsServiceURL;
    virgilConfig.cardsServiceROURL = self.consts.cardsServiceROURL;
    virgilConfig.registrationAuthorityURL = self.consts.registrationAuthorityURL;
    
    self.virgilClient = [[VSSClient alloc] initWithServiceConfig:virgilConfig];
    
    VSPServiceConfig *config = [[VSPServiceConfig alloc] initWithToken:self.consts.applicationToken ephemeralServiceURL:self.consts.pfsServiceURL];
    self.client = [[VSPClient alloc] initWithServiceConfig:config];
    
    self.numberOfCards = 5;
    self.longTermKeysTtl = 60*60*24*7;
    self.sessionTtl = 60*60*24*3;
    
    self.message1 = @"message1";
    self.message2 = @"message2";
    self.message3 = @"message3";
    self.message4 = @"message4";
}

- (void)tearDown {
    [super tearDown];
}

- (void)test001_CreateAndInitializeSecureChat {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created"];
    
    NSUInteger numberOfRequests = 3;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *keyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *identityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:keyPair];
    
    [self.virgilClient createCardWithRequest:identityRequest completion:^(VSSCard *card, NSError *error) {
        sleep(5);
        
        VSPSecureChatPreferences *preferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:card.identifier myPrivateKey:keyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
        
        self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:preferences];
        
        [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
            XCTAssert(error == nil);
            
            [ex fulfill];
        }];
    }];
        
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test002_InitiateTalk {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated."];
    
    NSUInteger numberOfRequests = 4;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *keyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *identityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:keyPair];
    
    [self.virgilClient createCardWithRequest:identityRequest completion:^(VSSCard *card, NSError *error) {
        sleep(5);
        
        VSPSecureChatPreferences *preferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:card.identifier myPrivateKey:keyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
        
        self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:preferences];
        
        [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
            [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:card.identifier additionalData:nil completion:^(VSPSecureTalk *talk, NSError *error) {
                XCTAssert(error == nil);
                XCTAssert(talk != nil);
                [ex fulfill];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test003_SetupSession {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created."];
    
    NSUInteger numberOfRequests = 8;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSError *err;
                        NSData *encryptedMessage = [initiatorTalk encrypt:self.message1 error:&err];
                        XCTAssert(err == nil);
                        XCTAssert(encryptedMessage.length > 0);
                        
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage additionalData:nil error:&err];
                        XCTAssert(err == nil);
                        XCTAssert(responderTalk != nil);
                        NSString *decryptedMessage = [responderTalk decrypt:encryptedMessage error:&err];
                        XCTAssert(err == nil);
                        XCTAssert([self.message1 isEqualToString:decryptedMessage]);
                            
                        [ex fulfill];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test004_SetupSessionEncryptDecrypt {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created. Further encryption/decryption should work."];
    
    NSUInteger numberOfRequests = 8;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSData *encryptedMessage1 = [initiatorTalk encrypt:self.message1 error:nil];
                        
                        NSError *err;
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage1 additionalData:nil error:&err];
                        XCTAssert(err == nil);
                        XCTAssert(responderTalk != nil);
                        NSString *decryptedMessage1 = [responderTalk decrypt:encryptedMessage1 error:&err];
                        XCTAssert(err == nil);
                        XCTAssert([self.message1 isEqualToString:decryptedMessage1]);
                        
                        NSData *encryptedMessage2 = [initiatorTalk encrypt:self.message2 error:&err];
                        XCTAssert(err == nil);
                        NSString *message2 = [responderTalk decrypt:encryptedMessage2 error:&err];
                        XCTAssert(err == nil);
                        XCTAssert([self.message2 isEqualToString:message2]);
                        
                        NSData *encryptedMessage3 = [responderTalk encrypt:self.message3 error:&err];
                        XCTAssert(err == nil);
                        NSString *message3 = [initiatorTalk decrypt:encryptedMessage3 error:&err];
                        XCTAssert(err == nil);
                        XCTAssert([self.message3 isEqualToString:message3]);
                        
                        [ex fulfill];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test005_RecoverInitiatorSession {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created. Initiator talk should be recovered. Further encryption/decryption should work."];
    
    NSUInteger numberOfRequests = 9;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSData *encryptedMessage1 = [initiatorTalk encrypt:self.message1 error:nil];
                        
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage1 additionalData:nil error:nil];
                        
                        [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *recoveredInitiatorTalk, NSError *error) {
                            XCTAssert(error == nil);
                            XCTAssert(recoveredInitiatorTalk != nil);
                            NSError *err;
                            NSData *encryptedMessage2 = [recoveredInitiatorTalk encrypt:self.message2 error:&err];
                            XCTAssert(err == nil);
                            NSString *message2 = [responderTalk decrypt:encryptedMessage2 error:&err];
                            XCTAssert(err == nil);
                            XCTAssert([self.message2 isEqualToString:message2]);
                            
                            [ex fulfill];
                        }];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test006_RecoverInitiatorSessionWithMessage {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created. Initiator talk should be recovered using message. Further encryption/decryption should work."];
    
    NSUInteger numberOfRequests = 9;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSData *encryptedMessage1 = [initiatorTalk encrypt:self.message1 error:nil];
                        
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage1 additionalData:nil error:nil];
                        NSData *encryptedMessage2 = [responderTalk encrypt:self.message2 error:nil];
                        
                        NSError *err;
                        VSPSecureTalk *recoveredInitiatorTalk = [self.initiatorSecureChat respondToTalkWithInitiatorWithCard:responderCard message:encryptedMessage2 additionalData:nil error:&err];
                        XCTAssert(err == nil);
                        XCTAssert(recoveredInitiatorTalk != nil);
                        NSString *message2 = [recoveredInitiatorTalk decrypt:encryptedMessage2 error:&err];
                        XCTAssert(err == nil);
                        XCTAssert([self.message2 isEqualToString:message2]);
                        
                        [ex fulfill];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test007_RecoverResponderSession {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created. Responder talk should be recovered. Further encryption/decryption should work."];
    
    NSUInteger numberOfRequests = 9;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSData *encryptedMessage1 = [initiatorTalk encrypt:self.message1 error:nil];
                        
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage1 additionalData:nil error:nil];
                        
                        [self.responderSecureChat initiateTalkWithRecipientWithCardId:initiatorCard.identifier additionalData:nil completion:^(VSPSecureTalk *recoveredResponderTalk, NSError *error) {
                            XCTAssert(error == nil);
                            XCTAssert(recoveredResponderTalk != nil);
                            NSError *err;
                            NSData *encryptedMessage2 = [initiatorTalk encrypt:self.message2 error:&err];
                            XCTAssert(err == nil);
                            NSString *message2 = [recoveredResponderTalk decrypt:encryptedMessage2 error:&err];
                            XCTAssert(err == nil);
                            XCTAssert([self.message2 isEqualToString:message2]);
                            
                            [ex fulfill];
                        }];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test008_RecoverResponderSessionWithMessage {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created. Responder talk should be recovered using message. Further encryption/decryption should work."];
    
    NSUInteger numberOfRequests = 9;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSData *encryptedMessage1 = [initiatorTalk encrypt:self.message1 error:nil];
                        
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage1 additionalData:nil error:nil];
                        
                        NSData *encryptedMessage2 = [initiatorTalk encrypt:self.message2 error:nil];
                        
                        NSError *err;
                        VSPSecureTalk *recoveredResponderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage2 additionalData:nil error:&err];
                        NSString *message2 = [recoveredResponderTalk decrypt:encryptedMessage2 error:&err];
                        XCTAssert(err == nil);
                        XCTAssert(recoveredResponderTalk != nil);
                        XCTAssert([self.message2 isEqualToString:message2]);
                        
                        [ex fulfill];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test009_ExpireInitiatorSession {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created. Initiator secure chat should be initialized."];
    
    NSUInteger numberOfRequests = 9;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSData *encryptedMessage1 = [initiatorTalk encrypt:self.message1 error:nil];
                        
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage1 additionalData:nil error:nil];
                        
                        NSData *encryptedMessage2 = [initiatorTalk encrypt:self.message2 error:nil];
                        
                        self.initiatorSecureChat2 = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
                        
                        [self.initiatorSecureChat2 initializeWithCompletion:^(NSError *error) {
                            XCTAssert(error == nil);
                            
                            [ex fulfill];
                        }];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test010_ExpireResponderSession {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. Security talk should be initiated. Security talk should be responded. Session should be created. Responder secure chat should be initialized."];
    
    NSUInteger numberOfRequests = 9;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime + 200;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    VSSKeyPair *responderKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    VSSCreateCardRequest *responderIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:responderKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        [self.virgilClient createCardWithRequest:responderIdentityRequest completion:^(VSSCard *responderCard, NSError *error) {
            sleep(5);
            
            VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            VSPSecureChatPreferences *responderPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:responderCard.identifier myPrivateKey:responderKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
            
            self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
            self.responderSecureChat = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
            
            [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                [self.responderSecureChat initializeWithCompletion:^(NSError * error) {
                    [self.initiatorSecureChat initiateTalkWithRecipientWithCardId:responderCard.identifier additionalData:nil completion:^(VSPSecureTalk *initiatorTalk, NSError *error) {
                        NSData *encryptedMessage1 = [initiatorTalk encrypt:self.message1 error:nil];
                        
                        VSPSecureTalk *responderTalk = [self.responderSecureChat respondToTalkWithInitiatorWithCard:initiatorCard message:encryptedMessage1 additionalData:nil error:nil];
                        
                        NSData *encryptedMessage2 = [initiatorTalk encrypt:self.message2 error:nil];
                            
                        self.responderSecureChat2 = [[VSPSecureChat alloc] initWithPreferences:responderPreferences];
                        
                        [self.responderSecureChat2 initializeWithCompletion:^(NSError *error) {
                            XCTAssert(error == nil);
                            
                            [ex fulfill];
                        }];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test011_ExpireLongTermCard {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. LongTerm card should be added."];
    
    NSUInteger numberOfRequests = 7;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    
    NSString * __block identityId1, * __block identityId2, * __block longTermId1, * __block longTermId2, * __block oneTimeId1, * __block oneTimeId2;
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        sleep(5);
        
        VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:self.numberOfCards longTermKeysTtl:5 sessionTtl:self.sessionTtl];
        
        self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
        
        [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
            [self.client getRecipientCardsSetForCardsIds:@[initiatorCard.identifier] completion:^(NSArray<VSPRecipientCardsSet *> *cardsSet, NSError *error) {
                XCTAssert(error == nil);
                XCTAssert(cardsSet.count == 1);
                VSPRecipientCardsSet *cardSet = cardsSet[0];
                identityId1 = cardSet.identityCard.identifier;
                longTermId1 = cardSet.longTermCard.identifier;
                oneTimeId1 = cardSet.oneTimeCard.identifier;
                
                sleep(5);
                
                [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
                    [self.client getRecipientCardsSetForCardsIds:@[initiatorCard.identifier] completion:^(NSArray<VSPRecipientCardsSet *> *cardsSet, NSError *error) {
                        XCTAssert(error == nil);
                        XCTAssert(cardsSet.count == 1);
                        VSPRecipientCardsSet *cardSet = cardsSet[0];
                        identityId2 = cardSet.identityCard.identifier;
                        longTermId2 = cardSet.longTermCard.identifier;
                        oneTimeId2 = cardSet.oneTimeCard.identifier;
                        
                        XCTAssert(identityId1.length > 0);
                        XCTAssert(identityId2.length > 0);
                        XCTAssert([identityId1 isEqualToString:identityId2]);
                        
                        XCTAssert(longTermId1.length > 0);
                        XCTAssert(longTermId2.length > 0);
                        XCTAssert(![longTermId1 isEqualToString:longTermId2]);
                        
                        XCTAssert(oneTimeId1.length > 0);
                        XCTAssert(oneTimeId2.length > 0);
                        XCTAssert(![oneTimeId1 isEqualToString:oneTimeId2]);
                        
                        [ex fulfill];
                    }];
                }];
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

- (void)test012_ForceWeakSession {
    XCTestExpectation *ex = [self expectationWithDescription:@"Identity card should be created. Security talk should be created. LongTerm card should be added."];
    
    NSUInteger numberOfRequests = 7;
    NSTimeInterval timeout = numberOfRequests * kEstimatedRequestCompletionTime;
    
    VSSKeyPair *initiatorKeyPair = [self.crypto generateKeyPair];
    
    VSSCreateCardRequest *initiatorIdentityRequest = [self.utils instantiateCreateCardRequestWithKeyPair:initiatorKeyPair];
    
    [self.virgilClient createCardWithRequest:initiatorIdentityRequest completion:^(VSSCard *initiatorCard, NSError *error) {
        sleep(5);
        
        VSPSecureChatPreferences *initiatorPreferences = [[VSPSecureChatPreferences alloc] initWithMyCardId:initiatorCard.identifier myPrivateKey:initiatorKeyPair.privateKey crypto:self.crypto keyStorage:[[VSSKeyStorage alloc] init] serviceConfig:self.client.serviceConfig virgilServiceConfig:self.virgilClient.serviceConfig deviceManager:[[VSSDeviceManager alloc] init] numberOfActiveOneTimeCards:1 longTermKeysTtl:self.longTermKeysTtl sessionTtl:self.sessionTtl];
        
        self.initiatorSecureChat = [[VSPSecureChat alloc] initWithPreferences:initiatorPreferences];
        
        [self.initiatorSecureChat initializeWithCompletion:^(NSError *error) {
            [self.client getRecipientCardsSetForCardsIds:@[initiatorCard.identifier] completion:^(NSArray<VSPRecipientCardsSet *> *cardsSet, NSError *error) {
                XCTAssert(cardsSet[0].oneTimeCard.identifier.length > 0);
            
                [self.client getRecipientCardsSetForCardsIds:@[initiatorCard.identifier] completion:^(NSArray<VSPRecipientCardsSet *> *cardsSet, NSError *error) {
                    XCTAssert(error == nil);
                    XCTAssert(cardsSet[0].identityCard != nil);
                    XCTAssert(cardsSet[0].longTermCard != nil);
                    XCTAssert(cardsSet[0].oneTimeCard == nil);
                    
                    [ex fulfill];
                }];
                
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:timeout handler:^(NSError *error) {
        if (error != nil)
            XCTFail(@"Expectation failed: %@", error);
    }];
}

@end
