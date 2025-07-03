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
            
            // 스크롤 가능한 텍스트 영역
            ScrollView {
                VStack(spacing: 16) {
                    // 닉네임
                    Text(nick)
                        .font(.soyoHeadline)
                        .foregroundColor(.MainTextColor)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 30)
                        .multilineTextAlignment(.center)
                    
                    // 자기소개
                    Text(introduction.isEmpty ? "자기소개가 없습니다." : introduction)
                        .font(.pretendardBody)
                        .foregroundColor(.SubText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .frame(maxHeight: 180) // 스크롤 영역의 최대 높이 제한
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

            if !newValue {
                withAnimation(.easeInOut(duration: 0.3)) {

                }
            }
        }
    }
}
