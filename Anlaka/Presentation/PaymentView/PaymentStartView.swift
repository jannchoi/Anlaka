import SwiftUI

struct PaymentStartView: View {
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    let di: DIContainer
    @StateObject private var container: PaymentContainer
    @Binding var showPaymentStartView: Bool
    @State private var showPaymentWebView = false
    var onCancel: (() -> Void)?
    
    init(di: DIContainer, iamportPayment: IamportPaymentEntity, showPaymentStartView: Binding<Bool>, onCancel: (() -> Void)? = nil) {
        self.di = di
        self._showPaymentStartView = showPaymentStartView
        self.onCancel = onCancel
        _container = StateObject(wrappedValue: PaymentContainer(repository: di.networkRepository, iamportPayment: iamportPayment))
        print("PaymentStartView 초기화됨")
    }
    
    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.WarmLinen)
                .frame(width: 300, height: 150)
                .shadow(radius: 10)
                .overlay(
                    contentView()
                )
        }
        .background(.ultraThinMaterial)
        .fullScreenCover(isPresented: $showPaymentWebView) {
            PaymentView(container: container, showPaymentView: $showPaymentWebView)
        }
    }
    
    @ViewBuilder
    private func contentView() -> some View {
        VStack(spacing: 0) {
            Group {
                if container.model.isLoading {
                    ProgressView("결제 처리 중...")
                        .font(.headline)
                        .foregroundColor(Color.MainTextColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                }
                else if let error = container.model.error {
                    VStack(spacing: 8) {
                        Text("결제 중 오류가 발생했습니다")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.MainTextColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Text(error.localizedDescription)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 24)
                }
                else if container.model.isPaymentCompleted {
                    VStack(spacing: 8) {
                        Text("결제가 완료되었습니다")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.MainTextColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        Text("잠시 후 이전 화면으로 이동합니다")
                            .font(.footnote)
                            .foregroundColor(Color.MainTextColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 24)
                    .onAppear {
                        print("결제 완료 화면 표시됨")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showPaymentStartView = false
                        }
                    }
                }
                else {
                    VStack(spacing: 8) {
                        Text("결제를 하시겠습니까?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.MainTextColor)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 24)
                }
            }
            Divider()
            HStack(spacing: 0) {
                Button("결제 시작") {
                    print("결제 시작 버튼 클릭")
                    container.handle(.createPayment)
                    if container.model.paymentData != nil {
                        print("결제 데이터 생성됨, PaymentView로 이동")
                        showPaymentWebView = true
                    }
                }
                .font(.footnote.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.WarmLinen)
                .foregroundColor(Color.SteelBlue)
                .contentShape(Rectangle())
                Divider()
                    .frame(width: 1, height: 44)
                Button("취소") {
                    onCancel?()
                    showPaymentStartView = false
                }
                .font(.footnote.weight(.medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.WarmLinen)
                .foregroundColor(Color.TomatoRed)
                .contentShape(Rectangle())
            }
        }
        .padding(24)
    }
}
