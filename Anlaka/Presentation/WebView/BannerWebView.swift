//
//  BannerWebView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI
import WebKit

// MARK: - BannerWebView
struct BannerWebView: UIViewControllerRepresentable {
    let url: URL
    let onAttendanceComplete: (Int) -> Void
    let onError: (String) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> BannerWebViewController {
        let webVC = BannerWebViewController()
        webVC.setupBridge(onAttendanceComplete: onAttendanceComplete, onError: onError, onDismiss: onDismiss)
        return webVC
    }
    
    func updateUIViewController(_ uiViewController: BannerWebViewController, context: Context) {
        // 업데이트 불필요
    }
}

// MARK: - BannerWebViewController
class BannerWebViewController: UIViewController, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var onAttendanceComplete: ((Int) -> Void)?
    private var onError: ((String) -> Void)?
    private var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        // webView 초기화 완료 후 URL 로드
        DispatchQueue.main.async { [weak self] in
            self?.loadEventApplicationURL()
        }
    }
    
    // MARK: - WebView Setup
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        
        // 메시지 핸들러 등록
        userContentController.add(self, name: "click_attendance_button")
        userContentController.add(self, name: "complete_attendance")
        
        configuration.userContentController = userContentController
        
        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Bridge Setup
    func setupBridge(onAttendanceComplete: @escaping (Int) -> Void, onError: @escaping (String) -> Void, onDismiss: @escaping () -> Void) {
        self.onAttendanceComplete = onAttendanceComplete
        self.onError = onError
        self.onDismiss = onDismiss
    }
    
    // MARK: - URL Loading
    func loadURL(_ url: URL) {
        var request = URLRequest(url: url)
        
        // 헤더에 SeSACKey 포함
        request.setValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        
        // 액세스 토큰이 있다면 Authorization 헤더 추가
        if let accessToken = KeychainManager.shared.getString(forKey: .accessToken) {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
        }
        
        webView.load(request)
    }
    
    // MARK: - Event Application URL Loading
    private func loadEventApplicationURL() {
        // BaseURL.baseURL을 사용하여 올바른 URL 구성
        let baseURLString = BaseURL.baseURL
        let eventApplicationPath = "/event-application"
        
        guard let fullURL = URL(string: baseURLString + eventApplicationPath) else {
            onError?("잘못된 URL입니다.")
            return
        }
        
        loadURL(fullURL)
    }
    
    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "click_attendance_button":
            handleAttendanceButtonClick()
            
        case "complete_attendance":
            handleAttendanceComplete(message.body)
            
        default:
            print("Unknown message: \(message.name)")
        }
    }
    
    // MARK: - Message Handlers
    private func handleAttendanceButtonClick() {
        guard let accessToken = KeychainManager.shared.getString(forKey: .accessToken) else {
            onError?("액세스 토큰을 찾을 수 없습니다.")
            return
        }
        
        // JavaScript 함수 호출로 토큰 전송
        let script = "requestAttendance('\(accessToken)')"
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("JavaScript 실행 오류: \(error)")
                self.onError?("출석 처리 중 오류가 발생했습니다.")
            }
        }
    }
    
    private func handleAttendanceComplete(_ body: Any) {
        if let attendanceCount = body as? Int {
            // 출석 완료 처리
            DispatchQueue.main.async {
                self.onAttendanceComplete?(attendanceCount)
                // WebView 닫기
                self.onDismiss?()
            }
        } else if let attendanceCountString = body as? String, let count = Int(attendanceCountString) {
            // 문자열로 전달된 경우
            DispatchQueue.main.async {
                self.onAttendanceComplete?(count)
                // WebView 닫기
                self.onDismiss?()
            }
        } else {
            // 출석 횟수를 알 수 없는 경우 기본값 사용
            DispatchQueue.main.async {
                self.onAttendanceComplete?(1)
                // WebView 닫기
                self.onDismiss?()
            }
        }
    }
}

// MARK: - WKNavigationDelegate
extension BannerWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // 로딩 시작
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // 로딩 완료
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // 로딩 실패
        onError?("웹페이지 로딩에 실패했습니다: \(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // 초기 로딩 실패
        onError?("웹페이지 로딩에 실패했습니다: \(error.localizedDescription)")
    }
} 