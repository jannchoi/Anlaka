import Foundation

struct ReceiptPaymentRequestDTO: Encodable {
    let impUid: String

    enum CodingKeys: String, CodingKey {
        case impUid = "imp_uid"
    }
}

struct ReceiptOrderResponseDTO: Decodable {
    let paymentId: String?
    let orderItem: OrderResponseDTO?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case orderItem = "order_item"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
    }
}

struct ReceiptOrderResponseEntity {
    let paymentId: String
    let order: OrderResponseEntity
    let createdAt: Date?
    let updatedAt: Date?
}

extension ReceiptOrderResponseDTO {
    func toEntity() -> ReceiptOrderResponseEntity? {
        guard let paymentId = paymentId,
              let orderItem = orderItem,
              let createdAt = PresentationMapper.formatISO8601ToDate(createdAt),
              let updatedAt = PresentationMapper.formatISO8601ToDate(updatedAt),
              let orderEntity = orderItem.toEntity() else {
            return nil
        }
        
        return ReceiptOrderResponseEntity(
            paymentId: paymentId,
            order: orderEntity,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}


struct PaymentResponseDTO: Decodable {
    let impUid: String?
    let merchantUid: String?
    let payMethod: String?
    let channel: String?
    let pgProvider: String?
    let embPgProvider: String?
    let pgTid: String?
    let pgId: String?
    let escrow: Bool?
    let applyNum: String?
    let bankCode: String?
    let bankName: String?
    let cardCode: String?
    let cardName: String?
    let cardIssuerCode: String?
    let cardIssuerName: String?
    let cardPublisherCode: String?
    let cardPublisherName: String?
    let cardQuota: Int?
    let cardNumber: String?
    let cardType: Int?
    let vbankCode: String?
    let vbankName: String?
    let vbankNum: String?
    let vbankHolder: String?
    let vbankDate: Int?
    let vbankIssuedAt: Int?
    let name: String?
    let amount: Int?
    let currency: String?
    let buyerName: String?
    let buyerEmail: String?
    let buyerTel: String?
    let buyerAddr: String?
    let buyerPostcode: String?
    let customData: String?
    let userAgent: String?
    let status: String?
    let startedAt: String?
    let paidAt: String?
    let receiptUrl: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case impUid = "imp_uid"
        case merchantUid = "merchant_uid"
        case payMethod = "pay_method"
        case channel
        case pgProvider = "pg_provider"
        case embPgProvider = "emb_pg_provider"
        case pgTid = "pg_tid"
        case pgId = "pg_id"
        case escrow
        case applyNum = "apply_num"
        case bankCode = "bank_code"
        case bankName = "bank_name"
        case cardCode = "card_code"
        case cardName = "card_name"
        case cardIssuerCode = "card_issuer_code"
        case cardIssuerName = "card_issuer_name"
        case cardPublisherCode = "card_publisher_code"
        case cardPublisherName = "card_publisher_name"
        case cardQuota = "card_quota"
        case cardNumber = "card_number"
        case cardType = "card_type"
        case vbankCode = "vbank_code"
        case vbankName = "vbank_name"
        case vbankNum = "vbank_num"
        case vbankHolder = "vbank_holder"
        case vbankDate = "vbank_date"
        case vbankIssuedAt = "vbank_issued_at"
        case name
        case amount
        case currency
        case buyerName = "buyer_name"
        case buyerEmail = "buyer_email"
        case buyerTel = "buyer_tel"
        case buyerAddr = "buyer_addr"
        case buyerPostcode = "buyer_postcode"
        case customData = "custom_data"
        case userAgent = "user_agent"
        case status
        case startedAt
        case paidAt
        case receiptUrl = "receipt_url"
        case createdAt
        case updatedAt
    }
}

struct PaymentResponseEntity {
    let impUid: String
    let merchantUid: String
    let payMethod: String?
    let channel: String?
    let pgProvider: String?
    let embPgProvider: String?
    let pgTid: String?
    let pgId: String?
    let escrow: Bool?
    let applyNum: String?
    let bankCode: String?
    let bankName: String?
    let cardCode: String?
    let cardName: String?
    let cardIssuerCode: String?
    let cardIssuerName: String?
    let cardPublisherCode: String?
    let cardPublisherName: String?
    let cardQuota: Int?
    let cardNumber: String?
    let cardType: Int?
    let vbankCode: String?
    let vbankName: String?
    let vbankNum: String?
    let vbankHolder: String?
    let vbankDate: Int?
    let vbankIssuedAt: Int?
    let name: String?
    let amount: Int
    let currency: String
    let buyerName: String?
    let buyerEmail: String?
    let buyerTel: String?
    let buyerAddr: String?
    let buyerPostcode: String?
    let customData: String?
    let userAgent: String?
    let status: String
    let startedAt: Date?
    let paidAt: Date?
    let receiptUrl: String?
    let createdAt: Date?
    let updatedAt: Date?
}

extension PaymentResponseDTO {
    func toEntity() -> PaymentResponseEntity? {
        guard let impUid = impUid,
              let merchantUid = merchantUid,
              let amount = amount,
              let currency = currency,
              let status = status else {
            return nil
        }
        
        return PaymentResponseEntity(
            impUid: impUid,
            merchantUid: merchantUid,
            payMethod: payMethod,
            channel: channel,
            pgProvider: pgProvider,
            embPgProvider: embPgProvider,
            pgTid: pgTid,
            pgId: pgId,
            escrow: escrow,
            applyNum: applyNum,
            bankCode: bankCode,
            bankName: bankName,
            cardCode: cardCode,
            cardName: cardName,
            cardIssuerCode: cardIssuerCode,
            cardIssuerName: cardIssuerName,
            cardPublisherCode: cardPublisherCode,
            cardPublisherName: cardPublisherName,
            cardQuota: cardQuota,
            cardNumber: cardNumber,
            cardType: cardType,
            vbankCode: vbankCode,
            vbankName: vbankName,
            vbankNum: vbankNum,
            vbankHolder: vbankHolder,
            vbankDate: vbankDate,
            vbankIssuedAt: vbankIssuedAt,
            name: name,
            amount: amount,
            currency: currency,
            buyerName: buyerName,
            buyerEmail: buyerEmail,
            buyerTel: buyerTel,
            buyerAddr: buyerAddr,
            buyerPostcode: buyerPostcode,
            customData: customData,
            userAgent: userAgent,
            status: status,
            startedAt: PresentationMapper.formatISO8601ToDate(startedAt),
            paidAt: PresentationMapper.formatISO8601ToDate(paidAt),
            receiptUrl: receiptUrl,
            createdAt: PresentationMapper.formatISO8601ToDate(createdAt),
            updatedAt: PresentationMapper.formatISO8601ToDate(updatedAt)
        )
    }
}
