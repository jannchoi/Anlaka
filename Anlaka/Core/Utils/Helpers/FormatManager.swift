//
//  FormatManager.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import Foundation

struct FormatManager {
    
    /// 보증금/월세 등의 금액을 "억", "만" 단위로 적절하게 포매팅하여 반환합니다.
    /// 예: 12345678 -> "1억 2,345만"
    static func formatCurrency(_ amount: Double) -> String {
        let intAmount = Int(amount)

        let trillion = intAmount / 1_0000_0000_0000       // 1조 = 1,0000 * 1,0000 * 1,0000
        let billion = (intAmount % 1_0000_0000_0000) / 100_000_000  // 억
        let tenThousand = (intAmount % 100_000_000) / 10_000       // 만

        var result = ""
        if trillion > 0 {
            result += "\(trillion)조"
        }
        if billion > 0 {
            if !result.isEmpty { result += " " }
            result += "\(billion)억"
        }
        if tenThousand > 0 {
            if !result.isEmpty { result += " " }
            result += "\(tenThousand)천만"
        }

        return result.isEmpty ? "0" : result
    }

    
    /// 이미지 경로를 받아 전체 URL로 반환합니다.
    /// 예: "/data/estates/house.png" -> "https://api.myserver.com/v1/data/estates/house.png"
    static func formatImageURL(_ path: String) -> String {
        print(BaseURL.baseV1 + path)
        return BaseURL.baseV1 + path
    }
    
    /// 면적을 소수점 첫째 자리까지 포맷하고 "m²"를 붙여 반환합니다.
    /// 예: 27.13 -> "27.1m²"
    static func formatArea(_ area: Double) -> String {
        return "\(String(format: "%.1f", area))m²"
    }
}

