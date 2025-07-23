//
//  UserDefaultsManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
enum UserDefaultsKey: String {
    case profileData
    case deviceToken
    case expAccess      // KeychainManager에서 관리하지만 UserDefaults에 저장
    case expRefresh     // KeychainManager에서 관리하지만 UserDefaults에 저장
    case deviceTokenChanged
    case pendingChatRoomId
    case badgeCount
}


final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Save

    func set<T>(_ value: T, forKey key: UserDefaultsKey) {
        defaults.set(value, forKey: key.rawValue)
    }

    func setObject<T: Codable>(_ object: T, forKey key: UserDefaultsKey) {
        do {
            let data = try JSONEncoder().encode(object)
            defaults.set(data, forKey: key.rawValue)
        } catch {
            print("❌ Failed to encode object for key \(key): \(error)")
        }
    }

    // MARK: - Get

    func getString(forKey key: UserDefaultsKey) -> String? {
        defaults.string(forKey: key.rawValue)
    }

    func getBool(forKey key: UserDefaultsKey) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }

    func getInt(forKey key: UserDefaultsKey) -> Int {
        defaults.integer(forKey: key.rawValue)
    }

    func getObject<T: Codable>(forKey key: UserDefaultsKey, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("❌ Failed to decode object for key \(key): \(error)")
            return nil
        }
    }

    // MARK: - Remove

    func remove(forKey key: UserDefaultsKey) {
        defaults.removeObject(forKey: key.rawValue)
    }
    
    func removeObject(forKey key: UserDefaultsKey) {
        remove(forKey: key)
    }

    // MARK: - Check Existence

    func contains(_ key: UserDefaultsKey) -> Bool {
        defaults.object(forKey: key.rawValue) != nil
    }
}

