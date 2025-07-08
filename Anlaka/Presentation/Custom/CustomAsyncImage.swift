//
//  CustomAsyncImage.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI

// 이미지 로딩 상태를 구분하는 enum
enum ImageLoadingState {
    case loading
    case loaded(UIImage)
    case error(String) // 에러 메시지 포함
    case notFound
}

struct CustomAsyncImage: View {
    let imagePath: String?  // 예: "/data/estates/xxx.png"

    
    @State private var loadingState: ImageLoadingState = .loading
    @State private var hasStartedLoading = false // 중복 로딩 방지
    
    var body: some View {
        Group {
            switch loadingState {
            case .loading:
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .overlay(ProgressView())
            case .loaded(let uiImage):
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

            case .error, .notFound:
                // 에러나 이미지 없음 상태에서는 모두 defaultImage 표시
                defaultImageView
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
            loadingState = .loading
            if let path = newPath {
                hasStartedLoading = true
                loadImage()
            }
        }
    }
    
    // 기본 이미지 뷰 (에러나 이미지 없음 시 표시)
    private var defaultImageView: some View {
        ZStack {
            // 배경 이미지 영역 (탭 시 지정된 액션 실행)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                        Text("이미지")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
            
            // 재시도 버튼 (에러 상태에서만 표시)
            if case .error = loadingState {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            hasStartedLoading = false
                            loadImage()
                        }) {
                            Text("재시도")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.trailing, 8)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
    }
    
    private func loadImage() {
        guard let imagePath = imagePath else {
            self.loadingState = .notFound
            return
        }
        
        // 캐시에서 이미지 확인
        if let cachedImage = ImageCache.shared.image(forKey: imagePath) {
            DispatchQueue.main.async {
                self.loadingState = .loaded(cachedImage)
            }
            return
        }
        
        guard let url = URL(string: FormatManager.formatImageURL(imagePath)) else {
            self.loadingState = .notFound
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue(AppConfig.apiKey, forHTTPHeaderField: "SeSACKey")
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) else {
            self.loadingState = .notFound
            return
        }
        request.addValue(accessToken, forHTTPHeaderField: "Authorization")
        
        // 타임아웃 설정 (10초)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // 네트워크 에러 처리
                if let error = error {
                    print("❌ ImageCache ERROR: \(imagePath) - \(error.localizedDescription)")
                    // 타임아웃이나 네트워크 오류 시 defaultImage로 전환
                    self.loadingState = .notFound
                    return
                }
                
                // HTTP 상태 코드 확인
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200...299:
                        // 성공적인 응답
                        if let data = data, let image = UIImage(data: data) {
                            print("✅ ImageCache SAVED: \(imagePath)")
                            self.loadingState = .loaded(image)
                            // 이미지를 캐시에 저장
                            ImageCache.shared.setImage(image, forKey: imagePath)
                        } else {
                            print("❌ ImageCache PARSE_ERROR: \(imagePath) - 이미지 데이터 파싱 실패")
                            // 이미지 파싱 실패 시 defaultImage로 전환
                            self.loadingState = .notFound
                        }
                    case 404:
                        print("❌ ImageCache NOT_FOUND: \(imagePath)")
                        // 이미지가 존재하지 않음 - defaultImage로 전환
                        self.loadingState = .notFound
                    case 401, 403, 500...599:
                        print("❌ ImageCache HTTP_ERROR: \(imagePath) - \(httpResponse.statusCode)")
                        // 인증 오류나 서버 오류 시 defaultImage로 전환
                        self.loadingState = .notFound
                    default:
                        print("❌ ImageCache HTTP_ERROR: \(imagePath) - \(httpResponse.statusCode)")
                        // 기타 HTTP 오류 시 defaultImage로 전환
                        self.loadingState = .notFound
                    }
                } else {
                    print("❌ ImageCache INVALID_RESPONSE: \(imagePath)")
                    // HTTP 응답이 아닌 경우 defaultImage로 전환
                    self.loadingState = .notFound
                }
            }
        }.resume()
    }
}

