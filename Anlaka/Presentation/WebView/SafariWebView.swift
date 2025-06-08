//
//  SafariWebView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI
import SafariServices

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = true

        let safariVC = SFSafariViewController(url: url, configuration: config)
        safariVC.preferredControlTintColor = .systemBlue // 선택 사항
        return safariVC
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // 업데이트 불필요
    }
}
