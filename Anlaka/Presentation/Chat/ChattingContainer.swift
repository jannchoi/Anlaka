import Foundation

struct ChattingModel {
    var roomId: String
}

enum ChattingIntent {
    case fetchChats
}

@MainActor
final class ChattingContainer: ObservableObject {
    @Published var model: ChattingModel
    private let repository: NetworkRepository
    init(repository: NetworkRepository, roomId: String) {
        self.repository = repository
        self.model = ChattingModel(roomId: roomId)
    }

    func handle(_ intent: ChattingIntent) {
        switch intent {
        case .fetchChats:
            Task {
                await fetchChats()
            }
        }
    }
    private func fetchChats() async {
        Task {
            do {
                let chats = try await repository.getChatList(roomId: model.roomId, from: //)
                print(chats)
            } catch {
                print(error)
            }
        }
    }
}   