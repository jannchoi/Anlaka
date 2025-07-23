//
//  LazyView.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import SwiftUI

/// 뷰가 실제로 표시될 때만 생성되는 지연 로딩 뷰
struct LazyView<Content: View>: View {
    private let build: () -> Content
    @State private var isVisible = false
    
    // 클로저를 받는 초기화
    init(_ build: @escaping () -> Content) {
        self.build = build
    }
    
    // 뷰 인스턴스를 받는 초기화
    init(content: @autoclosure @escaping () -> Content) {
        self.build = content
    }
    
    var body: some View {
        Group {
            if isVisible {
                build()
            } else {
                Color.clear
                    .onAppear {
                        isVisible = true
                    }
            }
        }
    }
}
