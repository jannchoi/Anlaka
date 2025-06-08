//
//  PresentationMapper.swift
//  Anlaka
//
//  Created by 최정안 on 6/6/25.
//

import Foundation

enum PresentationMapper {
    static func mapString(_ value: String?) -> String {
        return value ?? "알 수 없음"
    }
    
    static func mapInt(_ value: Int?) -> String {
        return value.map(String.init) ?? "알 수 없음"
    }
    
    static func mapDouble(_ value: Double?) -> String {
        return value.map { String(format: "%.2f", $0) } ?? "알 수 없음"
    }
    
    static func mapBool(_ value: Bool?) -> String {
        guard let value = value else { return "알 수 없음" }
        return value ? "예" : "아니오"
    }
    
    static func mapArray(_ value: [String]?) -> String {
        return value?.joined(separator: ", ") ?? "알 수 없음"
    }
    /// 3자리마다 쉼표 추가 (ex: 1234567.89 -> "1,234,567.89")
    static func formatDecimalWithComma(_ value: Double?) -> String {
        guard let value = value else { return "알 수 없음" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    /// 만/억 단위로 줄여서 표현 (ex: 12000 -> "1.2만", 100000000 -> "1억")
    static func formatToShortUnitString(_ value: Double?) -> String {
        guard let value = value else { return "알 수 없음" }
        
        if value >= 100_000_000 {
            let result = value / 100_000_000
            return trimmedNumber(result) + "억"
        } else if value >= 10_000 {
            let result = value / 10_000
            return trimmedNumber(result) + "만"
        } else {
            return formatDecimalWithComma(value)
        }
    }
    
    /// 소수점 두 자리까지 표현하되 .0으로 끝나면 제거
    private static func trimmedNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    /// Double을 "숫자㎡" 형태로 포맷 (예: 84.32 -> "84.32㎡")
    static func formatArea(_ value: Double?) -> String {
        guard let value = value else { return "알 수 없음" }
        return "\(trimmedNumber(value))㎡"
    }
    
    /// Int를 "숫자층" 형태로 포맷 (예: 3 -> "3층")
    static func formatFloor(_ value: Int?) -> String {
        guard let value = value else { return "알 수 없음" }
        if value < 0 {
            return "지하 \(abs(value))층"
        } else {
            return "\(value)층"
        }
    }
    static func formatCount(_ value: Int?) -> String {
        guard let value = value else { return "알 수 없음" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formatted)개"
    }
    static func formatBuiltYear(_ builtYear: String?) -> String {
        guard let year = builtYear, !year.isEmpty else {
            return "알 수 없음"
        }
        return "\(year)년"
    }

    
}
