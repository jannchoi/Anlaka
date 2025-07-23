import SwiftUI

// 1. Alert 스타일 정의
enum CustomAlertStyle {
    case error
    case warning
    case success
    case info
}

extension CustomAlertStyle {
    var themeColor: Color {
        switch self {
        case .error: return Color.TomatoRed
        case .warning: return Color.ToffeeWood
        case .info: return Color.SteelBlue
        case .success: return Color.OliveMist
        }
    }
    var iconFileName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

// 2. Alert 데이터 모델
struct CustomAlert: Identifiable {
    let id = UUID() // 고유 식별자 추가
    var type: CustomAlertStyle
    var title: String
    var message: String
    var primaryButtonTitle: String
    var secondaryButtonTitle: String?
    var onPrimary: (() -> Void)? = nil
    var onSecondary: (() -> Void)? = nil
}

// 3. Alert View
struct CustomAlertView: View {
    let alert: CustomAlert
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: alert.type.iconFileName)
                    .foregroundColor(alert.type.themeColor)
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.title)
                        .font(.soyoTitle3)
                        .foregroundColor(Color.MainTextColor)
                    Text(alert.message)
                        .font(.pretendardBody)
                        .foregroundColor(Color.SubText)
                }
                Spacer()
            }
            .padding(.top, 8)
            HStack(spacing: 12) {
                if let secondary = alert.secondaryButtonTitle {
                    Button(secondary) {
                        alert.onSecondary?()
                        onDismiss()
                    }
                    .font(.pretendardBody)
                    .foregroundColor(Color.Gray60)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.WarmLinen)
                    .cornerRadius(6)
                }
                Button(alert.primaryButtonTitle) {
                    alert.onPrimary?()
                    onDismiss()
                }
                .font(.pretendardBody)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(alert.type.themeColor)
                .cornerRadius(6)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 32)
    }
}

// 4. Alert Modifier
struct CustomAlertModifier: ViewModifier {
    @Binding var alert: CustomAlert?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if let alert = alert {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                VStack {
                    Spacer()
                    CustomAlertView(alert: alert) {
                        dismiss()
                    }
                    Spacer()
                }
                .transition(.scale)
            }
        }
        .animation(.easeInOut, value: alert?.id) // alert.id 사용
    }
    
    private func dismiss() {
        withAnimation {
            alert = nil
        }
    }
}

// 5. View Extension
extension View {
    func customAlertView(alert: Binding<CustomAlert?>) -> some View {
        self.modifier(CustomAlertModifier(alert: alert))
    }
} 