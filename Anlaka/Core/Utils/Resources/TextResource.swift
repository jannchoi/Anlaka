//
//  TextResource.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation

enum TextResource {
    
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
}
