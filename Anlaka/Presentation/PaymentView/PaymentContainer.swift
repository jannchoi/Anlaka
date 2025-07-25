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
}

enum PaymentIntent {
    case createPayment
    case setResponse(IamportResponse?)
    case setLoading(Bool)
    case setError(Error?)
    case setPaymentCompleted(Bool)
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
            
        case .setLoading(let isLoading):
            model.isLoading = isLoading
            print("로딩 상태 변경: \(isLoading)")
            
        case .setError(let error):
            model.error = error
            print("에러 발생: \(String(describing: error))")
            
        case .setPaymentCompleted(let isCompleted):
            print("결제 완료 상태 변경 시작: \(isCompleted)")
            model.isPaymentCompleted = isCompleted
            if isCompleted {
                print("결제 완료됨, onPaymentCompleted 클로저 실행 예정")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    print("onPaymentCompleted 클로저 실행")
                    self.onPaymentCompleted?()
                }
            }
            
        case .resetPayment:
            print("결제 상태 초기화")
            model.response = nil
            model.paymentData = nil
            model.error = nil
            model.isPaymentCompleted = false
        }
    }

    private func createPayment() {
        print("결제 생성 시작")
        guard let iamportPayment = model.iamportPayment else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제 정보가 없습니다."])
            return
        }
        
        // 결제 전 유효성 검사
        guard !iamportPayment.amount.isEmpty,
              !iamportPayment.orderCode.isEmpty,
              !iamportPayment.title.isEmpty else {
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제 정보가 올바르지 않습니다."])
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
            return
        }
        
        if let imp_uid = response.imp_uid, !imp_uid.isEmpty {
            do {
                let result = try await repository.validatePayment(payment: ReceiptPaymentRequestDTO(impUid: imp_uid))
                print("영수증 검증 완료: ",result)
                handle(.setPaymentCompleted(true))
            } catch {
                print("영수증 검증 실패: \(error)")
                model.error = error
            }
        } else {
            print("결제 취소됨")
            model.error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "결제가 취소되었습니다."])
        }
    }
}
