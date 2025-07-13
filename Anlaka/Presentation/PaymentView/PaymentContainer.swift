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
        print("PaymentContainer 초기화됨")
    }

    func handle(_ intent: PaymentIntent) {
        print("PaymentContainer handle 호출됨: \(intent)")
        switch intent {
        case .createPayment:
            createPayment()

        case .setResponse(let response):
            model.response = response
            Task {
                await validatePayment()
            }
            print("결제 응답 저장됨: \(String(describing: response))")
            

            
        case .resetPayment:
            resetPayment()
        }

    }
private func resetPayment() {
    print("결제 상태 초기화")
    model.response = nil
    model.paymentData = nil
    model.error = nil
    model.isPaymentCompleted = false
    model.errorType = .none
}
    private func createPayment() {
        resetPayment()
        print("결제 생성 시작")
        guard let iamportPayment = model.iamportPayment else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제 정보가 없습니다."])
            model.errorType = .createPayment
            return
        }
        
        // 결제 전 유효성 검사
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
        print("결제 생성 완료")
    }

    private func validatePayment() async {
        print("결제 검증 시작")
        guard let response = model.response else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제 응답이 없습니다."])
            model.errorType = .validatePayment
            return
        }
        
        if let imp_uid = response.imp_uid, !imp_uid.isEmpty {
            do {
                let result = try await repository.validatePayment(payment: ReceiptPaymentRequestDTO(impUid: imp_uid))
                print("영수증 검증 완료: ",result)
                
                // 결제 완료 상태 직접 설정
                print("결제 완료 상태 변경 시작: true")
                model.isPaymentCompleted = true
                print("결제 완료됨, onPaymentCompleted 클로저 실행 예정")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("onPaymentCompleted 클로저 실행")
                    self.onPaymentCompleted?()
                }
            } catch {
                print("영수증 검증 실패: \(error)")
                model.error = error
                model.errorType = .validatePayment
            }
        } else {
            print("결제가 취소되었거나 실패했습니다")
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제가 취소되었거나 실패했습니다."])
            model.errorType = .validatePayment
        }
    }
}
