//
//  Loadable.swift
//  Anlaka
//
//  Created by 최정안 on 5/18/25.
//

import Foundation

enum Loadable<T> {
    case idle       // 초기 상태
    case loading    // 네트워크 요청 중
    case success(T) // 성공적으로 데이터 수신
    case failure(String) // 에러 메시지
}
