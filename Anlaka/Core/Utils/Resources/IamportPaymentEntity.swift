import Foundation

struct IamportPaymentEntity: Equatable, Hashable {
    let orderCode: String
    let amount: String
    let title: String
    let buyerName: String

}