//
//  IdentifiableString.swift
//  Anlaka
//
//  Created by 최정안 on 6/8/25.
//

import Foundation
// String을 Identifiable로 감싸는 래퍼 타입
struct IdentifiableString: Identifiable {
    let id: String
}
