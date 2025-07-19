import SwiftUI
import UIKit
import WebKit
import iamport_ios

struct PaymentView: UIViewControllerRepresentable {
    @ObservedObject var container: PaymentContainer
    @Binding var showPaymentView: Bool
    
    private let dismissDelay: TimeInterval = 1.0
    
    func makeUIViewController(context: Context) -> UINavigationController {
        let viewController = PaymentViewController()
        viewController.container = container
        
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .fullScreen
        return navigationController
    }
    
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if container.model.isPaymentCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
                showPaymentView = false
            }
        }
    }
}
