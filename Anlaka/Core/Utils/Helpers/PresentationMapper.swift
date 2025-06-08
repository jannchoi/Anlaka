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
        guard var value = value else { return "알 수 없음" }
        //value *=  0.3025
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
    
    /// Date를 ISO8601 형식의 String으로 변환 (예: 2024-05-06T05:13:54.357Z)
    static func formatDateToISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
    
    /// ISO8601 형식의 String을 Date로 변환
    static func parseISO8601ToDate(_ dateString: String?) -> Date {
        guard let dateString = dateString else { return Date() }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // 대체 형식 시도 (예: 2024-05-06 05:13:54.357 +0000)
        let alternativeFormatter = DateFormatter()
        alternativeFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS Z"
        alternativeFormatter.locale = Locale(identifier: "en_US_POSIX")
        alternativeFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if let result = alternativeFormatter.date(from: dateString) {
            return result
        } else  {return Date()}
    }
    
    /// ISO8601 형식의 String을 "a h:mm" 형식으로 변환 (예: "오후 3:30")
    static func formatISO8601ToTimeString(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "알 수 없음" }
        
        let date = parseISO8601ToDate(dateString)
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: date)
    }
}
