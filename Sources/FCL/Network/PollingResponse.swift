//
//  PollingResponse.swift
//  
//
//  Created by Andrew Wang on 2022/7/1.
//

import Foundation

struct PollingResponse: Decodable {
    let fclType: String?
    let fclVersion: String?
    let status: Status
    var updates: Service?
    var local: Service?
    //    var data: AuthnData?
    //    let reason: String?
    //    let compositeSignature: AuthnData?
    //    var authorizationUpdates: Service?
    
    enum CodingKeys: String, CodingKey {
        case fclType = "f_type"
        case fclVersion = "f_vsn"
        case status
        case updates
        case local
        //        case data
        //        case reason
        //        case compositeSignature
        //        case authorizationUpdates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fType = try? container.decode(String.self, forKey: .fType)
        fVsn = try? container.decode(String.self, forKey: .fVsn)
        status = try container.decode(Status.self, forKey: .status)
        updates = try? container.decode(Service.self, forKey: .updates)
        do {
            local = try container.decode(Service.self, forKey: .local)
        } catch {
            let locals = try? container.decode([Service].self, forKey: .local)
            local = locals?.first
        }
        
        //        authorizationUpdates = try? container.decode(Service.self, forKey: .authorizationUpdates)
        //        data = try? container.decode(AuthnData.self, forKey: .data)
        //        reason = try? container.decode(String.self, forKey: .reason)
        //        compositeSignature = try? container.decode(AuthnData.self, forKey: .compositeSignature)
    }
}
