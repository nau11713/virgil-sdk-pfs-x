//
//  UploadOtcHTTPRequest.swift
//  VirgilSDKPFS
//
//  Created by Oleksandr Deundiak on 6/15/17.
//  Copyright © 2017 VirgilSecurity. All rights reserved.
//

import Foundation
import VirgilSDK

class UploadOtcHTTPRequest: PFSBaseHTTPRequest {
    let recipientId: String
    let otc: [String]
    
    private(set) var uploadOtcResponse: UploadOtcResponse?
    
    init(context: VSSHTTPRequestContext, recipientId: String, otc: [String]) {
        self.recipientId = recipientId
        self.otc = otc
        
        super.init(context: context)
    }
    
    override var methodPath: String {
        return "recipient/" + self.recipientId + "/actions/push-otcs"
    }
    
    override func handleResponse(_ candidate: NSObject?) -> Error? {
        guard let candidate = candidate else {
            return nil
        }
        
        let error = super.handleResponse(candidate)
        
        guard error == nil else {
            return error
        }
        
        
        self.uploadOtcResponse = UploadOtcResponse(dictionary: candidate)
        
        return nil
    }
}
