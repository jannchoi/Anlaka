//
//  Environment.swift
//  Anlaka
//
//  Created by 최정안 on 5/16/25.
//

import Foundation

public enum Environment {
    enum Keys {
        enum Plist {
            static let kakaoKey = "KAKAO_NATIVE_KEY"
            static let apiKey = "API_KEY"
            static let baseURL = "BASE_URL"
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

    
    public static let kakaoKey: String = {
        guard let key = infoDict[Keys.Plist.kakaoKey] as? String else {
            fatalError("KAKAO_NATIVE_KEY not set in plist")
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

