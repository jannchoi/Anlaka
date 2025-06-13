//
//  UserDefaultsManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation
enum UserDefaultsKey: String {
    case accessToken
    case refreshToken
    case profileData
    case deviceToken
    case appleIdToken
    case userNickname
    case kakaoToken
    case expAccess
    case expRefresh

    /// 이 키로 저장되는 값이 JWT 토큰인지 여부
    var requiresJWTDecoding: Bool {
        switch self {
        case .accessToken, .refreshToken:
            return true
        default:
            return false
        }
    }

    /// JWT 디코딩 시 저장할 만료 시간 키
    var correspondingExpKey: UserDefaultsKey? {
        switch self {
        case .accessToken: return .expAccess
        case .refreshToken: return .expRefresh
        default: return nil
        }
    }
}


final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Save

    func set<T>(_ value: T, forKey key: UserDefaultsKey) {
        defaults.set(value, forKey: key.rawValue)

        // JWT 토큰이라면 만료 시간도 저장
        if let token = value as? String,
           key.requiresJWTDecoding,
           let exp = JWTDecoder.decodeExpiration(from: token),
           let expKey = key.correspondingExpKey {
            defaults.set(exp, forKey: expKey.rawValue)
            print(expKey.rawValue, exp)
        }
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

    // MARK: - Check Existence

    func contains(_ key: UserDefaultsKey) -> Bool {
        defaults.object(forKey: key.rawValue) != nil
    }
}

