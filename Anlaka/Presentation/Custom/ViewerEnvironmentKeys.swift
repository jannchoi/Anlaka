import SwiftUI

// MARK: - Viewer Environment Keys
struct ShowPDFViewerKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

struct ShowImageViewerKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

struct ShowGIFViewerKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

struct ShowVideoPlayerKey: EnvironmentKey {
    static let defaultValue: (String) -> Void = { _ in }
}

extension EnvironmentValues {
    var showPDFViewer: (String) -> Void {
        get { self[ShowPDFViewerKey.self] }
        set { self[ShowPDFViewerKey.self] = newValue }
    }
    
    var showImageViewer: (String) -> Void {
        get { self[ShowImageViewerKey.self] }
        set { self[ShowImageViewerKey.self] = newValue }
    }
    
    var showGIFViewer: (String) -> Void {
        get { self[ShowGIFViewerKey.self] }
        set { self[ShowGIFViewerKey.self] = newValue }
    }
    
    var showVideoPlayer: (String) -> Void {
        get { self[ShowVideoPlayerKey.self] }
        set { self[ShowVideoPlayerKey.self] = newValue }
    }
} 