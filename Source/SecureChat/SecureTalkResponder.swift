//
//  SecureTalkResponder.swift
//  VirgilSDKPFS
//
//  Created by Oleksandr Deundiak on 6/22/17.
//  Copyright © 2017 VirgilSecurity. All rights reserved.
//

import Foundation
import VirgilSDK
import VirgilCrypto

class SecureTalkResponder: SecureTalk {
    public let secureChatKeyHelper: SecureChatKeyHelper
    public let initiatorIdCard: CardEntry
    
    init(crypto: VSSCryptoProtocol, myPrivateKey: VSSPrivateKey, sessionHelper: SecureChatSessionHelper, additionalData: Data?, secureChatKeyHelper: SecureChatKeyHelper, initiatorCardEntry: CardEntry, ephPublicKeyData: Data, receiverLtcId: String, receiverOtcId: String?, creationDate: Date, expirationDate: Date) throws {
        self.secureChatKeyHelper = secureChatKeyHelper
        self.initiatorIdCard = initiatorCardEntry
        
        super.init(crypto: crypto, myPrivateKey: myPrivateKey, wasRecovered: true, sessionHelper: sessionHelper, additionalData: additionalData, creationDate: creationDate, expirationDate: expirationDate)
        
        try self.initiateSession(ephPublicKeyData: ephPublicKeyData, receiverLtcId: receiverLtcId, receiverOtcId: receiverOtcId)
    }
    
    init(crypto: VSSCryptoProtocol, myPrivateKey: VSSPrivateKey, sessionHelper: SecureChatSessionHelper, additionalData: Data?, secureChatKeyHelper: SecureChatKeyHelper, initiatorCardEntry: CardEntry, creationDate: Date, expirationDate: Date) {
        self.initiatorIdCard = initiatorCardEntry
        self.secureChatKeyHelper = secureChatKeyHelper
        
        super.init(crypto: crypto, myPrivateKey: myPrivateKey, wasRecovered: false, sessionHelper: sessionHelper, additionalData: additionalData, creationDate: creationDate, expirationDate: expirationDate)
    }
}

// Encryption
extension SecureTalkResponder {
    override func encrypt(_ message: String) throws -> Data {
        guard self.isSessionInitialized else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Session is still not initialized."])
        }
        
        return try super.encrypt(message)
    }
    
    func decrypt(_ initiationMessage: InitiationMessage) throws -> String {
        if !self.isSessionInitialized {
            try self.initiateSession(withInitiationMessage: initiationMessage)
        }
        
        guard self.isSessionInitialized else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Session is still not initialized."])
        }
        
        guard let sessionId = self.pfs.session?.identifier else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Session id is missing."])
        }
        
        let message = Message(sessionId: sessionId, salt: initiationMessage.salt, cipherText: initiationMessage.cipherText)
        
        return try self.decrypt(encryptedMessage: message)
    }
    
    override func decrypt(_ encryptedMessage: Data) throws -> String {
        if let initiationMessage = try? SecureTalkResponder.extractInitiationMessage(encryptedMessage) {
            return try self.decrypt(initiationMessage)
        }
        else if let msg = try? SecureTalk.extractMessage(encryptedMessage) {
            guard self.isSessionInitialized else {
                throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Session is still not initialized."])
            }
            
            return try super.decrypt(encryptedMessage: msg)
        }
        else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown message format."])
        }
    }
}

// Session initialization
extension SecureTalkResponder {
    fileprivate func initiateSession(withInitiationMessage initiationMessage: InitiationMessage) throws {
        guard let initiatorPublicKey = self.crypto.importPublicKey(from: self.initiatorIdCard.publicKeyData) else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Error importing initiator public key from identity card."])
        }
        
        do {
            try self.crypto.verify(initiationMessage.ephPublicKey, withSignature: initiationMessage.ephPublicKeySignature, using: initiatorPublicKey)
        }
        catch {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Error validating initiator signature."])
        }
        
        guard initiationMessage.initiatorIcId == self.initiatorIdCard.identifier else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Initiator identity card id for this talk and InitiationMessage doesn't match."])
        }
        
        try self.initiateSession(ephPublicKeyData: initiationMessage.ephPublicKey, receiverLtcId: initiationMessage.responderLtcId, receiverOtcId: initiationMessage.responderOtcId)
    }
    
    fileprivate func initiateSession(ephPublicKeyData: Data, receiverLtcId: String, receiverOtcId: String?) throws {
        let privateKeyData = self.crypto.export(self.myPrivateKey, withPassword: nil)
        
        let myLtPrivateKey = try self.secureChatKeyHelper.getLtPrivateKey(withName: receiverLtcId)
        let myOtPrivateKey = receiverOtcId != nil ? try self.secureChatKeyHelper.getOtPrivateKey(name: receiverOtcId!) : nil
        
        let ltPrivateKeyData = self.crypto.export(myLtPrivateKey, withPassword: nil)
        let otPrivateKeyData = myOtPrivateKey != nil ? self.crypto.export(myOtPrivateKey!, withPassword: nil) : nil
        guard let privateKey = VSCPfsPrivateKey(key: privateKeyData, password: nil),
            let ltPrivateKey = VSCPfsPrivateKey(key: ltPrivateKeyData, password: nil) else {
                throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Error while convering crypto keys to pfs keys."])
        }
        
        let otPrivateKey = otPrivateKeyData != nil ? VSCPfsPrivateKey(key: otPrivateKeyData!, password: nil) : nil
        
        guard let responderPrivateInfo = VSCPfsResponderPrivateInfo(identityPrivateKey: privateKey, longTermPrivateKey: ltPrivateKey, oneTime: otPrivateKey) else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Error instantiating responderPrivateInfo."])
        }
        
        guard let initiatorEphPublicKey = VSCPfsPublicKey(key: ephPublicKeyData),
            let initiatorIdPublicKey = VSCPfsPublicKey(key: self.initiatorIdCard.publicKeyData) else {
                throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Error while convering crypto keys to pfs keys."])
        }
        
        guard let initiatorPublicInfo = VSCPfsInitiatorPublicInfo(identityPublicKey: initiatorIdPublicKey, ephemeralPublicKey: initiatorEphPublicKey) else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Error instantiating initiatorPublicInfo."])
        }
        
        guard let session = self.pfs.startResponderSession(with: responderPrivateInfo, initiatorPublicInfo: initiatorPublicInfo, additionalData: self.additionalData) else {
            throw NSError(domain: SecureTalk.ErrorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey: "Error while initiating responder session."])
        }
        
        if !self.wasRecovered {
            let sessionId = session.identifier
            let session = ResponderSessionState(creationDate: self.creationDate, expirationDate: self.expirationDate, sessionId: sessionId, additionalData: self.additionalData, ephPublicKeyData: ephPublicKeyData, recipientIdentityCardId: self.initiatorIdCard.identifier, recipientIdentityPublicKey: self.initiatorIdCard.publicKeyData, recipientLongTermCardId: receiverLtcId, recipientOneTimeCardId: receiverOtcId)
            try self.sessionHelper.saveSessionState(session, forRecipientCardId: self.initiatorIdCard.identifier)
        }
    }
}
