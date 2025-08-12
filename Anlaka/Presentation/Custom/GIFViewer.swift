import SwiftUI

struct GIFViewer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GIFViewerViewModel.shared
    @State private var isPlaying = true
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    
    var body: some View {
        ZStack {
            // 배경색
            Color.black.ignoresSafeArea()
            
            // GIF 이미지
            if let gifURL = viewModel.gifURL {
                GIFImageView(imagePath: gifURL, playMode: .controlled, isPlaying: isPlaying)
                    .ignoresSafeArea()
                    .onTapGesture {
                        toggleControls()
                    }
            }
            
            // 컨트롤 오버레이
            if showControls {
                VStack {
                    // 상단 컨트롤 (뒤로가기 버튼)
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // 중앙 재생/일시정지 버튼
                    Button(action: {
                        togglePlayPause()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                    }
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            startControlsTimer()
        }
        .onDisappear {
            stopControlsTimer()
        }
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        startControlsTimer()
    }
    
    private func togglePlayPause() {
        isPlaying.toggle()
        startControlsTimer()
    }
    
    private func startControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func stopControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
}

// MARK: - GIFViewerViewModel
class GIFViewerViewModel: ObservableObject {
    @Published var gifURL: String?
    
    // 싱글톤 인스턴스로 gifURL을 외부에서 설정할 수 있도록 함
    static let shared = GIFViewerViewModel()
    
    private init() {}
    
    func setGifURL(_ url: String) {
        self.gifURL = url
    }
}

#Preview {
    GIFViewer()
} 