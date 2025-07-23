//
//  FileDownloadRepository.swift
//  Anlaka
//
//  Created by 최정안 on 6/10/25.
//

import Foundation
import UIKit
import Combine

// MARK: - File Download Repository Protocol
protocol FileDownloadRepository {
    func downloadFile(from serverPath: String) async throws -> ServerFileEntity
    func downloadFiles(from serverPaths: [String]) async throws -> [ServerFileEntity]
    
    // 백그라운드 다운로드 (진행률 추적)
    func downloadFileInBackground(from serverPath: String) -> AnyPublisher<FileDownloadProgress, Never>
    func downloadFilesInBackground(from serverPaths: [String]) -> AnyPublisher<[String: FileDownloadProgress], Never>
    
    // 캐시 관리
    func clearDownloadCache() throws
    func getDownloadedFileSize() -> Int64
    func isFileDownloaded(serverPath: String) -> Bool
    func getDownloadedFile(serverPath: String) -> ServerFileEntity?
}

// MARK: - File Download Progress
struct FileDownloadProgress {
    let serverPath: String
    let progress: Double // 0.0 ~ 1.0
    let state: DownloadState
    let downloadedFile: ServerFileEntity?
    let error: Error?
    
    enum DownloadState {
        case notStarted
        case downloading
        case downloaded
        case failed
    }
}

// MARK: - File Download Repository Implementation
final class FileDownloadRepositoryImp: FileDownloadRepository {
    private let networkManager: NetworkManager
    private let baseURL: String
    private let headers: [String: String]
    
    // 다운로드된 파일 캐시
    private var downloadedFiles: [String: ServerFileEntity] = [:]
    private let cacheQueue = DispatchQueue(label: "fileDownloadCache", attributes: .concurrent)
    
    init(networkManager: NetworkManager, baseURL: String, headers: [String: String] = [:]) {
        self.networkManager = networkManager
        self.baseURL = baseURL
        self.headers = headers
    }
    
    // MARK: - Synchronous Download Methods
    func downloadFile(from serverPath: String) async throws -> ServerFileEntity {
        // 캐시 확인
        if let cachedFile = getDownloadedFile(serverPath: serverPath) {
            return cachedFile
        }
        
        let result = try await networkManager.downloadFile(from: serverPath)
        var file = ServerFileEntity(serverPath: serverPath)
        file.setDownloaded(localPath: result.localPath, image: result.image)
        
        // 캐시에 저장
        cacheQueue.async(flags: .barrier) {
            self.downloadedFiles[serverPath] = file
        }
        
        return file
    }
    
    func downloadFiles(from serverPaths: [String]) async throws -> [ServerFileEntity] {
        let results = try await networkManager.downloadFiles(from: serverPaths)
        
        return serverPaths.map { serverPath in
            var file = ServerFileEntity(serverPath: serverPath)
            if let result = results[serverPath] {
                file.setDownloaded(localPath: result.localPath, image: result.image)
                
                // 캐시에 저장
                cacheQueue.async(flags: .barrier) {
                    self.downloadedFiles[serverPath] = file
                }
            }
            return file
        }
    }
    
    // MARK: - Background Download Methods
    func downloadFileInBackground(from serverPath: String) -> AnyPublisher<FileDownloadProgress, Never> {
        return Future<FileDownloadProgress, Never> { promise in
            Task {
                // 초기 상태 발행
                promise(.success(FileDownloadProgress(
                    serverPath: serverPath,
                    progress: 0.0,
                    state: .notStarted,
                    downloadedFile: nil,
                    error: nil
                )))
                
                // 다운로드 시작 상태 발행
                promise(.success(FileDownloadProgress(
                    serverPath: serverPath,
                    progress: 0.0,
                    state: .downloading,
                    downloadedFile: nil,
                    error: nil
                )))
                
                do {
                    let file = try await self.downloadFile(from: serverPath)
                    
                    // 다운로드 완료 상태 발행
                    promise(.success(FileDownloadProgress(
                        serverPath: serverPath,
                        progress: 1.0,
                        state: .downloaded,
                        downloadedFile: file,
                        error: nil
                    )))
                } catch {
                    // 에러 상태 발행
                    promise(.success(FileDownloadProgress(
                        serverPath: serverPath,
                        progress: 0.0,
                        state: .failed,
                        downloadedFile: nil,
                        error: error
                    )))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func downloadFilesInBackground(from serverPaths: [String]) -> AnyPublisher<[String: FileDownloadProgress], Never> {
        let publishers = serverPaths.map { serverPath in
            downloadFileInBackground(from: serverPath)
                .map { progress in (serverPath, progress) }
        }
        
        return Publishers.MergeMany(publishers)
            .scan([String: FileDownloadProgress]()) { result, tuple in
                var newResult = result
                newResult[tuple.0] = tuple.1
                return newResult
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Cache Management
    func clearDownloadCache() throws {
        cacheQueue.sync(flags: .barrier) {
            downloadedFiles.removeAll()
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("Downloads")
        
        if FileManager.default.fileExists(atPath: downloadsPath.path) {
            try FileManager.default.removeItem(at: downloadsPath)
        }
    }
    
    func getDownloadedFileSize() -> Int64 {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("Downloads")
        
        guard FileManager.default.fileExists(atPath: downloadsPath.path) else { return 0 }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: downloadsPath, includingPropertiesForKeys: [.fileSizeKey])
            return contents.reduce(0) { total, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return total + Int64(size)
            }
        } catch {
            return 0
        }
    }
    
    func isFileDownloaded(serverPath: String) -> Bool {
        return cacheQueue.sync {
            return downloadedFiles[serverPath] != nil
        }
    }
    
    func getDownloadedFile(serverPath: String) -> ServerFileEntity? {
        return cacheQueue.sync {
            return downloadedFiles[serverPath]
        }
    }
}

// MARK: - File Download Repository Factory
enum FileDownloadRepositoryFactory {
    static func create() -> FileDownloadRepository {
        return FileDownloadRepositoryImp(
            networkManager: NetworkManager.shared,
            baseURL: BaseURL.baseURL,
            headers: [
                "Content-Type": "application/json"
            ]
        )
    }
    
    static func createWithAuth() -> FileDownloadRepository {
        var headers: [String: String] = [
            "Content-Type": "application/json"
        ]
        
        if let accessToken = UserDefaultsManager.shared.getString(forKey: .accessToken) as? String {
            headers["Authorization"] = "Bearer \(accessToken)"
        }
        
        return FileDownloadRepositoryImp(
            networkManager: NetworkManager.shared,
            baseURL: BaseURL.baseURL,
            headers: headers
        )
    }
} 
