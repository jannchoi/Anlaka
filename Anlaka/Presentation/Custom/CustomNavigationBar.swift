//
//  CustomNavigationBar.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import SwiftUI

struct CustomNavigationBar<LeftButton: View, RightButton: View>: View {
    let title: String
    let leftButton: LeftButton?
    let rightButton: RightButton?
    
    // left, right 버튼 모두 있는 경우
    init(title: String, @ViewBuilder leftButton: () -> LeftButton, @ViewBuilder rightButton: () -> RightButton) {
        self.title = title
        self.leftButton = leftButton()
        self.rightButton = rightButton()
    }
    
    // left 버튼만 있는 경우
    init(title: String, @ViewBuilder leftButton: () -> LeftButton) where RightButton == EmptyView {
        self.title = title
        self.leftButton = leftButton()
        self.rightButton = nil
    }
    
    // right 버튼만 있는 경우
    init(title: String, @ViewBuilder rightButton: () -> RightButton) where LeftButton == EmptyView {
        self.title = title
        self.leftButton = nil
        self.rightButton = rightButton()
    }
    
    // 버튼이 없는 경우
    init(title: String) where LeftButton == EmptyView, RightButton == EmptyView {
        self.title = title
        self.leftButton = nil
        self.rightButton = nil
    }
    
    var body: some View {
        HStack {
            // Left Button
            if let leftButton = leftButton {
                leftButton
                    .frame(width: 60, height: 44)
            } else {
                // 왼쪽 버튼이 없을 때는 투명한 공간으로 균형 맞춤
                Color.clear
                    .frame(width: 60, height: 44)
            }
            
            Spacer()
            
            // Title
            Text(title)
                .font(.soyoHeadline)
                .foregroundColor(Color.MainTextColor)
            
            Spacer()
            
            // Right Button
            if let rightButton = rightButton {
                rightButton
                    .frame(width: 60, height: 44)
            } else {
                // 오른쪽 버튼이 없을 때는 투명한 공간으로 균형 맞춤
                Color.clear
                    .frame(width: 60, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .bottom
        )
    }
}
