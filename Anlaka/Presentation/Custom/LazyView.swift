

import SwiftUI

struct LazyView<Content: View>: View {
    private let content: () -> Content
    var body: some View {
        content()
    }

    init(content: @autoclosure @escaping () -> Content) {
        self.content = content
        
    }
}
