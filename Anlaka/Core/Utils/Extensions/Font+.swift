//
//  Font+.swift
//  Anlaka
//
//  Created by 최정안 on 7/10/25.
//

import SwiftUI

extension Font {
    // MARK: - Pretendard 폰트 (일반 텍스트용)
    static func pretendard(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        return Font(UIFont.pretendard(size: size, weight: weight))
    }
    
    // MARK: - SOYO 폰트 (제목 및 강조 텍스트용)
    static func soyo(size: CGFloat, weight: UIFont.Weight = .regular) -> Font {
        return Font(UIFont.soyo(size: size, weight: weight))
    }
    
    // MARK: - 미리 정의된 폰트 스타일들
    
    // Pretendard 폰트 스타일들
    static let pretendardLargeTitle = pretendard(size: 34, weight: .bold)
    static let pretendardTitle = pretendard(size: 28, weight: .bold)
    static let pretendardTitle2 = pretendard(size: 22, weight: .semibold)
    static let pretendardTitle3 = pretendard(size: 20, weight: .semibold)
    static let pretendardHeadline = pretendard(size: 16, weight: .semibold)
    static let pretendardBody = pretendard(size: 16, weight: .regular)
    static let pretendardCallout = pretendard(size: 15, weight: .regular)
    static let pretendardSubheadline = pretendard(size: 14, weight: .regular)
    static let pretendardFootnote = pretendard(size: 12, weight: .regular)
    static let pretendardCaption = pretendard(size: 11, weight: .regular)
    static let pretendardCaption2 = pretendard(size: 10, weight: .regular)
    
    // SOYO 폰트 스타일들 (제목 및 강조용)
    static let soyoLargeTitle = soyo(size: 34, weight: .bold)
    static let soyoTitle = soyo(size: 17, weight: .bold)
    static let soyoTitle2 = soyo(size: 16, weight: .bold)
    static let soyoTitle3 = soyo(size: 15, weight: .bold)
    static let soyoHeadline = soyo(size: 14, weight: .bold)
    static let soyoSubheadline = soyo(size: 13, weight: .bold) // 추가된 작은 크기
    static let soyoBody = soyo(size: 12, weight: .regular)
    static let soyoCaption = soyo(size: 10, weight: .regular)
    static let soyoCaption2 = soyo(size: 9, weight: .regular)
}
