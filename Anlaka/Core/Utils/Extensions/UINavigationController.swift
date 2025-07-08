


import SwiftUI

// 1. NavigateAction 정의
struct NavigateAction {
    let action: () -> Void
    func callAsFunction() {
        action()
    }
}

// 2. EnvironmentKey 정의
private struct NavigateActionKey: EnvironmentKey {
    static let defaultValue: NavigateAction = NavigateAction { }
}

// 3. EnvironmentValues 확장
extension EnvironmentValues {
    var navigate: NavigateAction {
        get { self[NavigateActionKey.self] }
        set { self[NavigateActionKey.self] = newValue }
    }
}

// 4. View 확장
extension View {
    func onNavigate(_ action: @escaping () -> Void) -> some View {
        self.environment(\.navigate, NavigateAction(action: action))
    }
}

extension UINavigationController: @retroactive ObservableObject, @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isHidden = true
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

