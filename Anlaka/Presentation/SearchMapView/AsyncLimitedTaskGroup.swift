import SwiftUI

actor AsyncLimitedTaskGroup<T> {
    private let maxConcurrency: Int
    private var activeTasks = 0
    private var waitingTasks: [(priority: TaskPriority?, work: () async -> T, continuation: CheckedContinuation<T, Never>)] = []
    
    init(maxConcurrency: Int = 5) {
        self.maxConcurrency = maxConcurrency
    }
    
    func execute<U>(priority: TaskPriority? = nil, work: @escaping () async -> U) async -> U {
        return await withCheckedContinuation { continuation in
            Task {
                await self.enqueue(priority: priority, work: work, continuation: continuation)
            }
        }
    }
    
    private func enqueue<U>(priority: TaskPriority?, work: @escaping () async -> U, continuation: CheckedContinuation<U, Never>) {
        if activeTasks < maxConcurrency {
            activeTasks += 1
            Task(priority: priority) {
                let result = await work()
                continuation.resume(returning: result)
                await self.taskCompleted()
            }
        } else {
            waitingTasks.append((priority, work as! () async -> T, continuation as! CheckedContinuation<T, Never>))
        }
    }
    
    private func taskCompleted() {
        activeTasks -= 1
        if !waitingTasks.isEmpty {
            let nextTask = waitingTasks.removeFirst()
            activeTasks += 1
            Task(priority: nextTask.priority) {
                let result = await nextTask.work()
                nextTask.continuation.resume(returning: result)
                await self.taskCompleted()
            }
        }
    }
}