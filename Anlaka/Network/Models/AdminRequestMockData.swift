//
//  AdminRequestMockData.swift
//  Anlaka
//
//  Created by 최정안 on 6/14/25.
//

import Foundation

struct AdminRequestMockData: Codable {
    let category: String
    let title: String
    let introduction: String
    let reservation_price: Int
    let thumbnails: [String]
    let description: String
    let deposit: Int
    let monthly_rent: Int
    let built_year: String
    let maintenance_fee: Int
    let area: Double
    let parking_count: Int
    let floors: Int
    let is_safe_estate: Bool
    let is_recommended: Bool
    let options: Options
    let longitude: Double
    let latitude: Double

    struct Options: Codable {
        let refrigerator: Bool
        let washer: Bool
        let air_conditioner: Bool
        let closet: Bool
        let shoe_rack: Bool
        let microwave: Bool
        let sink: Bool
        let tv: Bool
    }

    init() {
        let categories = ["오피스텔", "원룸", "아파트", "빌라", "상가"]
        self.category = categories.randomElement()!

        let randomInt = Int.random(in: 1...100)
        self.title = "정아니의 해피하우스 \(randomInt)"
        self.introduction = "사랑을 느낄 수 있는 안락한 집 \(randomInt)"
        self.reservation_price = Int.random(in: 10...900)
       let availableThumbnails = [
    "/data/estates/example_1_1747104960999.jpg",
    "/data/estates/francesca-tosolini-w1RE0lBbREo-unsplash_1747105244716.jpg",
    "/data/estates/aaron-huber-G7sE2S4Lab4-unsplash_1747105359870.jpg",
    "/data/estates/house11_1747146326584.png",
    "/data/estates/house10_1747146288434.png",
    "/data/estates/house8_1747146288397.png",
    "/data/estates/house10_1747146288434.png",
    "/data/estates/house10_1747146288434.png",
    "/data/estates/house4_1747146245264.png",
    "/data/estates/house15_1747146326683.png",
    "/data/estates/house15_1747146326683.png",
    "/data/estates/francesca-tosolini-tHkJAMcO3QE-unsplash_1747106704053.jpg",
    "/data/estates/house14_1747146326667.png"
]
self.thumbnails = [availableThumbnails.randomElement()!]

        self.description = "역세권! 슬세권! 붕세권!"
        self.deposit = Int.random(in: 10_000...100_000_000)
        self.monthly_rent = Int.random(in: 300_000...10_000_000)

        // built_year: 2020-01-01 ~ 2025-06-14 범위 내의 랜덤 날짜 생성
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2020, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2025, month: 6, day: 14))!
        let randomDate = Date(timeIntervalSince1970: Double.random(in: startDate.timeIntervalSince1970...endDate.timeIntervalSince1970))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.built_year = formatter.string(from: randomDate)

        self.maintenance_fee = Int.random(in: 50_000...100_000)
        self.area = Double.random(in: 10...100).rounded(toPlaces: 1)
        self.parking_count = Int.random(in: 1...10)
        self.floors = Int.random(in: 1...10)
        self.is_safe_estate = Bool.random()
        self.is_recommended = Bool.random()
        self.options = Options(
            refrigerator: Bool.random(),
            washer: Bool.random(),
            air_conditioner: Bool.random(),
            closet: Bool.random(),
            shoe_rack: Bool.random(),
            microwave: Bool.random(),
            sink: Bool.random(),
            tv: Bool.random()
        )
        // 서울 관악구 근방 임의 좌표
        self.longitude = Double.random(in: 126.920...126.940).rounded(toPlaces: 6)
        self.latitude = Double.random(in: 37.460...37.490).rounded(toPlaces: 6)
    }
}

// 소수점 자르기 helper
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


