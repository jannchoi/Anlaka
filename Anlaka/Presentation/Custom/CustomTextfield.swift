//
//  CustomTextfield.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    // 선택적 유효성 검사용
    var validationMessage: String? = nil
    var isValid: Bool? = nil

    // 비밀번호 보기 토글
    var showsToggleVisibilityButton: Bool = false
    @State private var isTextVisible: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .trailing) {
                if isSecure && !isTextVisible {
                    SecureField(title, text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(keyboardType)
                } else {
                    TextField(title, text: $text)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(keyboardType)
                }

                if showsToggleVisibilityButton {
                    Button(action: {
                        isTextVisible.toggle()
                    }) {
                        Image(systemName: isTextVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 12)
                    }
                }
            }

            if let validationMessage = validationMessage,
               let isValid = isValid {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(isValid ? .steelBlue : .tomatoRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
