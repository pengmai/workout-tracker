//
//  Datastore.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-08-20.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

class Datastore {
    static let tokenKey = "userToken"

    static func getToken() -> String? {
        return KeychainWrapper.standard.string(forKey: tokenKey)
    }

    static func saveToken(_ token: String) {
        KeychainWrapper.standard.set(token, forKey: tokenKey)
    }

    static func clearToken() {
        KeychainWrapper.standard.removeObject(forKey: tokenKey)
    }
}
