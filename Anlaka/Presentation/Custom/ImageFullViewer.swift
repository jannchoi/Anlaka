import SwiftUI

struct ImageFullViewer: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ImageFullViewerViewModel.shared
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // 배경색
            Color.black.ignoresSafeArea()
            
            // 이미지
            if let imagePath = viewModel.imagePath {
                CustomAsyncImage.detail(imagePath: imagePath)
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        // 확대/축소 제스처
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = min(max(scale * delta, 0.5), 5.0) // 0.5x ~ 5.0x 범위
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                // 최소 크기보다 작으면 원래 크기로 복원
                                if scale < 1.0 {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        scale = 1.0
                                        offset = .zero
                                    }
                                }
                            }
                    )
                    .gesture(
                        // 드래그 제스처 (확대된 상태에서만)
                        DragGesture()
                            .onChanged { value in
                                if scale > 1.0 {
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                            }
                            .onEnded { _ in
                                lastOffset = offset
                            }
                    )
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
                        
                        // 확대/축소 리셋 버튼 (확대된 상태에서만 표시)
                        if scale > 1.0 || offset != .zero {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    scale = 1.0
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
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

// MARK: - ImageFullViewerViewModel
class ImageFullViewerViewModel: ObservableObject {
    @Published var imagePath: String?
    
    // 싱글톤 인스턴스로 imagePath를 외부에서 설정할 수 있도록 함
    static let shared = ImageFullViewerViewModel()
    
    private init() {}
    
    func setImagePath(_ path: String) {
        
        self.imagePath = path
        
    }
}
