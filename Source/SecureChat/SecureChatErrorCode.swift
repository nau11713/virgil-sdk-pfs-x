//
//  SecureChatErrorCode.swift
//  VirgilSDKPFS
//
//  Created by Oleksandr Deundiak on 7/22/17.
//  Copyright © 2017 VirgilSecurity. All rights reserved.
//

import Foundation

/// Error codes for NSError instances thrown from SecureChat
@objc(VSPSecureChatErrorCode) public enum SecureChatErrorCode: Int {
    case sessionNotFound
    case addingVerifier
    case longTermCardValidation
    case oneTimeCardValidation
    case checkingForExistingSession
    case obtainingRecipientCardsSet
    case recipientSetEmpty
    case invalidMessageString
    case unknownMessageStructure
    case removingOtKey
    case oneOrMoreInitializationOperationsFailed
    case obtainingCardsStatus
    case bootstrapingEphemeralCards
    case addingOneTimeEphemeralCards
    case loadingPrivateKey
    case corruptedSavedSession
    case anotherRotateKeysInProgress
    case corruptedExhaustInfo
    case importingVerifier
    case deserializingVirgilCard
    
    case migrationV1_1UnknownSessionState
    case migrationV1_1InvalidDefaults
    case migrationV1_1ImportingEphPrivateKey
}
