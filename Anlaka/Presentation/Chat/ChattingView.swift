import SwiftUI


// MARK: - Placeholder Views (실제 구현에서는 제거)
struct ChattingView: View {
    let di: DIContainer
     @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
     @StateObject private var container: ChattingContainer

     init(roomId: String, di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeChattingContainer(roomId: roomId))
     }
    var body: some View {
        Text("Chatting View - Room")
            .navigationTitle("채팅")
    }
}