//
//  ServiceDataType.swift
//
//
//  Created by Andrew Wang on 2022/6/30.
//

import Foundation
import SwiftyJSON

// https://github.com/onflow/fcl-js/blob/master/packages/fcl/src/current-user/normalize/open-id.js
/*
{
    "f_type": "Service",
    "f_vsn": "1.0.0",
    "type": "open-id",
    "uid": "uniqueDedupeKey",
    "method: "data",
    "data": {
        "profile": {
            "name": "Bob",
            "family_name": "Builder",
            "given_name": "Robert",
            "middle_name": "the",
            "nickname": "Bob the Builder",
            "perferred_username": "bob",
            "profile": "https://www.bobthebuilder.com/",
            "picture": "https://avatars.onflow.org/avatar/bob",
            "gender": "...",
            "birthday": "2001-01-18",
            "zoneinfo": "America/Vancouver",
            "locale": "en-us",
            "updated_at": "1614970797388"
        },
        "email": {
            "email": "bob@bob.bob",
            "email_verified": true
        },
        "address": {
            "address": "One Apple Park Way, Cupertino, CA 95014, USA"
        },
        "phone": {
            "phone_number": "+1 (xxx) yyy-zzzz",
            "phone_number_verified": true
        },
        "social": {
            "twitter": "@_qvvg",
            "twitter_verified": true
        },
    }
}
*/

public enum ServiceDataType {
    case openId(JSON)
    case accountProof(ServiceAccountProof)
    case json(JSON)
    case notExist
}
