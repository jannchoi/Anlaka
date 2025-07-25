
// MARK: - 안전한 캐싱 로직

//
//  CustomAsyncImage.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI

struct CustomAsyncImage: View {
    let imagePath: String?  // 예: "/data/estates/xxx.png"
    
    @State private var uiImage: UIImage?
    @State private var isLoading = true
    @State private var hasStartedLoading = false // 중복 로딩 방지
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(ProgressView())
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text("이미지")
                    .font(.pretendardCaption)
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            if !hasStartedLoading {
                hasStartedLoading = true
                loadImage()
            }
        }
        .onChange(of: imagePath) { newPath in
            // 이미지 경로가 변경되면 다시 로딩
            hasStartedLoading = false
            isLoading = true
            uiImage = nil
            if let path = newPath {
                hasStartedLoading = true
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let imagePath = imagePath else {
            self.uiImage = nil
            self.isLoading = false
            return
        }
        
        // 캐시에서 이미지 확인
        if let cachedImage = ImageCache.shared.image(forKey: imagePath) {
            DispatchQueue.main.async {
                self.uiImage = cachedImage
                self.isLoading = false
            }
            return
        }
        
        guard let url = URL(string: FormatManager.formatImageURL(imagePath)) else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) else {
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return
        }
        request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = data, let image = UIImage(data: data) {
                    self.uiImage = image
                    // 이미지를 캐시에 저장
                    ImageCache.shared.setImage(image, forKey: imagePath)
                }
            }
        }.resume()
    }
}

