//
//  ValidationManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import Foundation

final class ValidationManager {
    static let shared = ValidationManager()
    private init() {}

    /// 닉네임은 . , ? * - @ 포함 불가
    func isValidNick(_ nick: String?) -> Bool {
        guard let nick = nick, !nick.isEmpty else { return false }
        let invalidCharacterRegex = "[.,?*@-]" // 금지된 특수문자
        return nick.range(of: invalidCharacterRegex, options: .regularExpression) == nil
    }

    /// 이메일 형식: 예: user@example.com
    func isValidEmail(_ email: String?) -> Bool {
        guard let email = email, !email.isEmpty else { return false }
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    /// 비밀번호: 최소 8자, 영문자+숫자+특수문자(@$!%*#?&) 포함
    func isValidPassword(_ password: String?) -> Bool {
        guard let password = password, !password.isEmpty else { return false }
        let passwordRegex = #"^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$"#
        return NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
    }
}
