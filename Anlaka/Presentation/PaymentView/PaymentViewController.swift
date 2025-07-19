import SwiftUI
import UIKit
import WebKit
import iamport_ios

class PaymentViewController: UIViewController, WKNavigationDelegate {
    var container: PaymentContainer?
    private var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupNavigationBar()
        setupWebView()
    }
    
    private func setupNavigationBar() {
        // NavigationBar 설정
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.backgroundColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor(Color.MainTextColor)
        
        // 뒤로가기 버튼 추가
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        
        // 타이틀 설정
        navigationItem.title = "결제"
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestPayment()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // 아임포트 SDK 결제 요청
    func requestPayment() {
        guard let container = container,
              let paymentData = container.model.paymentData else {
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
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    }
}
