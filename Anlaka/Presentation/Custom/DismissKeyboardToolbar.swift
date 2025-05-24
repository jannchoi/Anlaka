//
//  DismissKeyboardToolbar.swift
//  Anlaka
//
//  Created by 최정안 on 5/16/25.
//

import SwiftUI
struct DismissKeyboardToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        // 키보드 내리기
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
    }
}

extension View {
    // 기존 isFocused 바인딩 받는 함수와 달리, 바인딩 없이 키보드 내리기 버튼만 추가하는 함수
    func dismissKeyboardToolbar() -> some View {
        self.modifier(DismissKeyboardToolbar())
    }
}
