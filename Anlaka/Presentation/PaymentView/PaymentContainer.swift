import Foundation
import iamport_ios

struct PaymentModel {
    var userCode: String = AppConfig.userCode
    var iamportPayment: IamportPaymentEntity?
    var paymentData: IamportPayment?
    var response: IamportResponse?
    var isLoading: Bool = false
    var error: Error?
    var isPaymentCompleted: Bool = false
    var errorType: PaymentErrorType = .none
}

enum PaymentErrorType {
    case none
    case createPayment // 결제 생성 단계 오류 (다시 시도 가능)
    case validatePayment // 결제 검증 단계 오류 (이미 돈이 빠져나간 후)
}

enum PaymentIntent {
    case createPayment
    case setResponse(IamportResponse?)
    case resetPayment
}

@MainActor
class PaymentContainer: ObservableObject {
    private let repository: NetworkRepository
    @Published var model = PaymentModel()
    var onPaymentCompleted: (() -> Void)?

    init(repository: NetworkRepository, iamportPayment: IamportPaymentEntity) {
        self.repository = repository
        self.model.iamportPayment = iamportPayment
    }

    func handle(_ intent: PaymentIntent) {
        switch intent {
        case .createPayment:
            createPayment()

        case .setResponse(let response):
            model.response = response
            Task {
                await validatePayment()
            }
            
        case .resetPayment:
            resetPayment()
        }
    }

    private func resetPayment() {
        model.response = nil
        model.paymentData = nil
        model.error = nil
        model.isPaymentCompleted = false
        model.errorType = .none
    }

    private func createPayment() {
        resetPayment()
        guard let iamportPayment = model.iamportPayment else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제 정보가 없습니다."])
            model.errorType = .createPayment
            return
        }
        
        guard !iamportPayment.amount.isEmpty,
              !iamportPayment.orderCode.isEmpty,
              !iamportPayment.title.isEmpty else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제 정보가 올바르지 않습니다."])
            model.errorType = .createPayment
            return
        }
        
        model.isLoading = true
        
        let payment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: iamportPayment.orderCode,
            amount: iamportPayment.amount
        ).then {
            $0.pay_method = PayMethod.card.rawValue
            $0.name = iamportPayment.title
            $0.buyer_name = iamportPayment.buyerName
            $0.app_scheme = "sesac"
        }
        
        model.paymentData = payment
        model.isLoading = false
    }

    private func validatePayment() async {
        guard let response = model.response else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제 응답이 없습니다."])
            model.errorType = .validatePayment
            return
        }
        
        if let imp_uid = response.imp_uid, !imp_uid.isEmpty {
            do {
                let result = try await repository.validatePayment(payment: ReceiptPaymentRequestDTO(impUid: imp_uid))
                
                model.isPaymentCompleted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.onPaymentCompleted?()
                }
            } catch {
                model.error = error
                model.errorType = .validatePayment
            }
        } else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제가 취소되었거나 실패했습니다."])
            model.errorType = .validatePayment
        }
    }
}
