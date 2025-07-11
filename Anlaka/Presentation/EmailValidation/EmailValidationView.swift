//
//  EmailValidationView.swift
//  Anlaka
//
//  Created by 최정안 on 5/13/25.
//

import SwiftUI

struct EmailValidationView: View {
    @State private var email: String = ""
    @State private var isValid: Bool = false
    @State private var navigate: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("이메일")
                        .font(.headline)

                    TextField("example@email.com", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button("다음") {
                    if isValidEmail(email) {
                        isValid = true
                        navigate = true
                        errorMessage = nil
                    } else {
                        isValid = false
                        errorMessage = "유효한 이메일 형식이 아닙니다."
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)



                Spacer()
            }
            .padding()
            .navigationTitle("이메일 입력")
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
}

