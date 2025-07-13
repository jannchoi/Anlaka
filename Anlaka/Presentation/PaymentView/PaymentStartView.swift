import SwiftUI

struct PaymentStartView: View {
  @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
  let di: DIContainer
  @StateObject private var container: PaymentContainer
  @Binding var showPaymentStartView: Bool
  @State private var showPaymentWebView = false
  var onCancel: (() -> Void)?

  init(
    di: DIContainer, iamportPayment: IamportPaymentEntity, showPaymentStartView: Binding<Bool>,
    onCancel: (() -> Void)? = nil
  ) {
    self.di = di
    self._showPaymentStartView = showPaymentStartView
    self.onCancel = onCancel
    _container = StateObject(
        wrappedValue: di.makePaymentContainer(iamportPayment: iamportPayment))
  }

  var body: some View {
    ZStack {
      // 반투명한 배경으로 EstateDetailView를 더 흐릿하게 만듦
      Color.black.opacity(0.3)
        .contentShape(Rectangle())
        .onTapGesture {
          // 배경 터치 시 아무 동작 안함 (상호작용 차단)
        }

      // 중앙에 결제 다이얼로그 표시
      RoundedRectangle(cornerRadius: 20)
        .fill(Color.WarmLinen)
        .frame(width: 300, height: 150)
        .shadow(radius: 10)
        .overlay(
          contentView()
        )
    }
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
        } else if let error = container.model.error {
          VStack(spacing: 8) {
            if container.model.errorType == .createPayment {
              Text("결제 준비 중 오류가 발생했습니다")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.MainTextColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            } else {
              Text("결제 처리 중 오류가 발생했습니다")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Color.MainTextColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
            Text(error.localizedDescription)
              .font(.footnote)
              .foregroundColor(.red)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
          }
          .padding(.vertical, 24)
          
          Divider()
          HStack(spacing: 0) {
            if container.model.errorType == .createPayment {
              // 결제 생성 단계 오류: 다시 시도 가능
              Button("다시 시도") {
                container.handle(.createPayment)
                if container.model.paymentData != nil {
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
              
              Button("닫기") {
                onCancel?()
                showPaymentStartView = false
              }
              .font(.footnote.weight(.medium))
              .frame(maxWidth: .infinity, minHeight: 44)
              .background(Color.WarmLinen)
              .foregroundColor(Color.TomatoRed)
              .contentShape(Rectangle())
            } else {
              // 결제 검증 단계 오류: 이미 돈이 빠져나간 후
              Button("고객센터 문의") {
                // 고객센터 연락처나 문의 페이지로 이동
                onCancel?()
                showPaymentStartView = false
              }
              .font(.footnote.weight(.medium))
              .frame(maxWidth: .infinity, minHeight: 44)
              .background(Color.WarmLinen)
              .foregroundColor(Color.SteelBlue)
              .contentShape(Rectangle())
              
              Divider()
                .frame(width: 1, height: 44)
              
              Button("닫기") {
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
        } else if container.model.isPaymentCompleted {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              showPaymentStartView = false
            }
          }
        } else {
          VStack(spacing: 8) {
            Text("결제를 하시겠습니까?")
              .font(.subheadline.weight(.semibold))
              .foregroundColor(Color.MainTextColor)
              .multilineTextAlignment(.center)
              .frame(maxWidth: .infinity)
          }
          .padding(.vertical, 24)
          
          Divider()
          HStack(spacing: 0) {
            Button("결제 시작") {
              container.handle(.createPayment)
              if container.model.paymentData != nil {
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
      }
    }
    .padding(24)
  }
}
