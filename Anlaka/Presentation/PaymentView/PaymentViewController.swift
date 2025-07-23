import SwiftUI
import UIKit
import WebKit
import iamport_ios

class PaymentViewController: UIViewController, WKNavigationDelegate {
    var container: PaymentContainer?
    private var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PaymentView viewDidLoad")
        view.backgroundColor = UIColor.white
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView?.navigationDelegate = self
        webView?.backgroundColor = .white
        
        if let webView = webView {
            view.addSubview(webView)
            webView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("PaymentView viewWillAppear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("PaymentView viewDidAppear")
        requestPayment()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("PaymentView viewWillDisappear")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("PaymentView viewDidDisappear")
    }
    
    // 아임포트 SDK 결제 요청
    func requestPayment() {
        guard let container = container,
              let paymentData = container.model.paymentData else {
            print("container 또는 paymentData가 존재하지 않습니다.")
            return
        }
        
        // WebViewController 용 닫기버튼 생성
        Iamport.shared.useNavigationButton(enable: true)
        
        Iamport.shared.paymentWebView(
            webViewMode: webView ?? WKWebView(),
            userCode: container.model.userCode,
            payment: paymentData
        ) { response in
            container.handle(.setResponse(response))
        }
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView 로딩 시작")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView 로딩 완료")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView 로딩 실패: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView 프로비저널 로딩 실패: \(error.localizedDescription)")
    }
}
