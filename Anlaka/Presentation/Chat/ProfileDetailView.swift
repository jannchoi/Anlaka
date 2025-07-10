import SwiftUI

struct ProfileDetailView: View {
    let profileImage: String?
    let nick: String
    let introduction: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 프로필 이미지
            CustomAsyncImage(imagePath: profileImage)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .shadow(radius: 5)
            
            // 닉네임
                            Text(nick)
                    .font(.soyoHeadline)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.MainTextColor)
            
            // 자기소개
                            Text(introduction.isEmpty ? "자기소개가 없습니다." : introduction)
                    .font(.pretendardBody)
                .font(.subheadline)
                .foregroundColor(.SubText)
                .multilineTextAlignment(.center)
                .lineLimit(5)
        }
        .frame(width: 250, height: 300)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.WarmLinen)
                .shadow(radius: 10)
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    // 스와이프로 dismiss
                    if abs(value.translation.height) > 50 || abs(value.translation.width) > 50 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
                }
        )
        .onChange(of: isPresented) { newValue in
            // 부모 뷰에서 dismiss될 때도 애니메이션 적용
            if !newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    // 추가 애니메이션 로직이 필요하면 여기에 추가
                }
            }
        }
    }
}
