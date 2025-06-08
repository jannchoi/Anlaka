//
//  AppConfig.swift
//  Anlaka
//
//  Created by 최정안 on 5/16/25.
//

import Foundation

public enum AppConfig {
    enum Keys {
        enum Plist {
            static let kakaoNativeKey = "KAKAO_NATIVE_KEY"
            static let apiKey = "API_KEY"
            static let baseURL = "BASE_URL"
            static let kakaoRestKey = "KAKAO_REST_KEY"
        }
    }

    private static let infoDict: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found")
        }
        return dict
    }()

    public static let apiKey: String = {
        guard let key = infoDict[Keys.Plist.apiKey] as? String else {
            fatalError("API_KEY not set in plist")
        }
        return key
    }()

    
    public static let kakaoNativeKey: String = {
        guard let key = infoDict[Keys.Plist.kakaoNativeKey] as? String else {
            fatalError("KAKAO_NATIVE_KEY not set in plist")
        }
        return key
    }()
    public static let kakaoRestKey: String = {
        guard let key = infoDict[Keys.Plist.kakaoRestKey] as? String else {
            fatalError("KAKAO_REST_KEY not set in plist")
        }
        return key
    }()
    public static let baseURL: String = {
        guard let rawURL = infoDict[Keys.Plist.baseURL] as? String else {
            fatalError("BASE_URL not set in plist")
        }

        let cleanedURL = rawURL.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        print("cleanURL: ", cleanedURL)
        return cleanedURL
    }()

}

