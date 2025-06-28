import SwiftUI
import UIKit
import WebKit
import iamport_ios

struct PaymentView: UIViewControllerRepresentable {
    @ObservedObject var container: PaymentContainer
    @Binding var showPaymentView: Bool
    
    private let dismissDelay: TimeInterval = 1.0
    
    func makeUIViewController(context: Context) -> PaymentViewController {
        print("PaymentView makeUIViewController")
        let viewController = PaymentViewController()
        viewController.container = container
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: PaymentViewController, context: Context) {
        print("PaymentView updateUIViewController")
        if container.model.isPaymentCompleted {
            print("PaymentView에서 결제 완료 감지")
            DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                print("PaymentView dismiss")
                showPaymentView = false
            }
        }
    }
}
