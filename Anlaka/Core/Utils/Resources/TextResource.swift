//
//  TextResource.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation

enum TextResource {
    enum Global {
        case isLoggedIn
        
        var text: String {
            switch self {
            case .isLoggedIn:
                return "isLoggedIn"
            }
        }
    }
    
    enum Validation {
        case emailValid
        case emailInvalid
        case passwordValid
        case passwordInvalid
        case nickValid
        case nickInvalid
        
        var text: String {
            switch self {
            case .emailValid:
                "유효한 이메일 형식 입니다."
            case .emailInvalid:
                "유효하지 않은 이메일 형식 입니다."
            case .passwordValid:
                "유효한 비밀번호 형식 입니다."
            case .passwordInvalid:
                "비밀번호는 최소 8자 이상이며, 영문자, 숫자, 특수문자(@$!%*#?&)를 각각 1개 이상 포함해야 합니다."
            case .nickValid:
                "유효한 닉네임 형식 입니다."
            case .nickInvalid:
                "닉네임에 . , ? * - @ 는 사용할 수 없습니다."
            }
        }
    }
    
    enum Categories: CaseIterable {
        case Apartment
        case Officetel
        case OneRoom
        case Storefront
        case Villa
        
        var text: String {
            switch self {
            case .Apartment:
                return "아파트"
            case .Officetel:
                return "오피스텔"
            case .OneRoom:
                return "원룸"
            case .Storefront:
                return "상가"
            case .Villa:
                return "빌라"
            }
        }
    }
}

/*
 getGeoEstates 호출: lon=127.04542827699848, lat=37.65225820584809, maxD=387.17485781376143
 getGeoEstates 호출: lon=127.04542827699848, lat=37.65225820584809, maxD=387.17485781376143
 getGeoEstates 호출: lon=127.04976372314174, lat=37.654972870220334, maxD=387.16070370932397
 getGeoEstates 호출: lon=127.04976372314174, lat=37.654972870220334, maxD=387.16070370932397
 */

enum DefaultValues {

    
    enum Geolocation {
        case longitude
        case latitude
        case maxDistanse
        
        var value: Double {
            switch self {
            case .longitude:
                return 127.045432300312 //126.977733
            case .latitude:
                return 37.6522582058481//37.576175
            case .maxDistanse:
                return 0.0 //
            }
        }
    }
}
