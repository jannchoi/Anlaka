import Foundation

struct CreateOrderRequestDTO: Encodable {
    let estateId: String
    let totalPrice: Int?

    enum CodingKeys: String, CodingKey {
        case estateId = "estate_id"
        case totalPrice = "total_price"
    }
}

struct CreateOrderResponseDTO: Decodable {
    let orderId: String?
    let orderCode: String?
    let totalPrice: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case totalPrice = "total_price"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}
struct CreateOrderEntity {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let createdAt: Date?
    let updatedAt: Date?
}
extension CreateOrderResponseDTO {
    func toEntity() -> CreateOrderEntity? {
        guard let orderId = orderId,
              let orderCode = orderCode,
              let totalPrice = totalPrice,
              let createdAt = PresentationMapper.formatISO8601ToDate(createdAt),
              let updatedAt = PresentationMapper.formatISO8601ToDate(updatedAt) else {
            return nil
        }
        
        return CreateOrderEntity(
            orderId: orderId,
            orderCode: orderCode,
            totalPrice: totalPrice,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

struct GetOrdersResponseDTO: Decodable {
    let data: [OrderResponseDTO]
}


struct OrderResponseDTO: Decodable {
    let orderId: String?
    let orderCode: String?
    let estate: EstateSummaryResponseDTO_Order?
    let paidAt: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderCode = "order_code"
        case estate
        case paidAt = "paidAt"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

struct EstateSummaryResponseDTO_Order: Decodable {
    let id: String?
    let category: String?
    let title: String?
    let introduction: String?
    let thumbnails: [String]?
    let deposit: Double?
    let monthlyRent: Double?
    let builtYear: String?
    let area: Double?
    let floors: Int?
    let geolocation: GeolocationDTO?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case category
        case title
        case introduction
        case thumbnails
        case deposit
        case monthlyRent = "monthly_rent"
        case builtYear = "built_year"
        case area
        case floors
        case geolocation
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
struct GetOrdersResponseEntity {
    let data: [OrderResponseEntity]
}
struct OrderResponseEntity {
    let orderId: String
    let orderCode: String
    let estate: EstateSummaryEntity_Order
    let paidAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
}

struct EstateSummaryEntity_Order {
    let id: String
    let category: String
    let title: String
    let introduction: String
    let thumbnails: [String]
    let deposit: Double
    let monthlyRent: Double
    let builtYear: String
    let area: Double
    let floors: Int
    let geolocation: GeolocationEntity
    let createdAt: Date?
    let updatedAt: Date?
}

extension GetOrdersResponseDTO {
    func toEntity() -> GetOrdersResponseEntity {
        return GetOrdersResponseEntity(
            data: data.compactMap { $0.toEntity() }
        )
    }
}

extension OrderResponseDTO {
    func toEntity() -> OrderResponseEntity? {
        guard let orderId = orderId,
              let orderCode = orderCode,
              let estate = estate,
              let paidAt = PresentationMapper.formatISO8601ToDate(paidAt),
              let createdAt = PresentationMapper.formatISO8601ToDate(createdAt),
              let updatedAt = PresentationMapper.formatISO8601ToDate(updatedAt),
              let estateEntity = estate.toEntity() else {
            return nil
        }
        
        return OrderResponseEntity(
            orderId: orderId,
            orderCode: orderCode,
            estate: estateEntity,
            paidAt: paidAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
extension EstateSummaryResponseDTO_Order {
    func toEntity() -> EstateSummaryEntity_Order? {
        guard let id = id,
              let category = category,
              let title = title,
              let introduction = introduction,
              let thumbnails = thumbnails,
              let deposit = deposit,
              let monthlyRent = monthlyRent,
              let builtYear = builtYear,
              let area = area,
              let floors = floors,
              let geolocation = geolocation?.toEntity() else {
            return nil
        }
        
        return EstateSummaryEntity_Order(
            id: id,
            category: category,
            title: title,
            introduction: introduction,
            thumbnails: thumbnails,
            deposit: deposit,
            monthlyRent: monthlyRent,
            builtYear: builtYear,
            area: area,
            floors: floors,
            geolocation: geolocation,
            createdAt: PresentationMapper.formatISO8601ToDate(createdAt),
            updatedAt: PresentationMapper.formatISO8601ToDate(updatedAt)
        )
    }
}
