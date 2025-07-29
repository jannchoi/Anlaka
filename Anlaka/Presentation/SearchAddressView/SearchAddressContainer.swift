//
//  SearchAddressContainer.swift
//  Anlaka
//
//  Created by 최정안 on 6/3/25.
//

import Foundation

struct SearchAddressModel {
    var errorMessage: String?
    var query: String = ""
    var addressQueryIsEnd = false
    var addressCurPage = 1
    var keywordQueryIsEnd = false
    var keywordCurPage = 1
    var addressQueryData: [SearchListData] = []
    var keywordQueryData: [SearchListData] = []
    var isLoading = false // 추가
}

enum SearchAddressIntent {
    case searchBarSubmitted(String)
    case loadMoreIfNeeded // 추가
    case selectAddress(SearchListData) // 추가
}

class SearchAddressContainer: ObservableObject {
    @Published var model = SearchAddressModel()
    private let repository: AddressNetworkRepository
    
    // 선택된 주소를 전달하기 위한 클로저 추가
    var onAddressSelected: ((SearchListData) -> Void)?
    
    init(repository: AddressNetworkRepository) {
        self.repository = repository
    }
    
    func handle(_ intent: SearchAddressIntent) {
        switch intent {
        case .searchBarSubmitted(let query):
            
            model.query = query
            model.addressCurPage = 1
            model.keywordCurPage = 1
            model.addressQueryData = []
            model.keywordQueryData = []
            model.addressQueryIsEnd = false
            model.keywordQueryIsEnd = false

            Task {
                await MainActor.run { model.isLoading = true }
                
                async let addressTask: () = getGeoFromAddressQuery(query)
                async let keywordTask: () = getGeoFormKeywordQuery(query)
                
                await addressTask
                await keywordTask
                
                await MainActor.run { model.isLoading = false }
            }
            
        case .loadMoreIfNeeded:
            guard !model.isLoading else { return }
            
            let shouldLoadAddress = !model.addressQueryIsEnd
            let shouldLoadKeyword = !model.keywordQueryIsEnd
            
            if shouldLoadAddress || shouldLoadKeyword {
                Task {
                    await MainActor.run { model.isLoading = true }
                    
                    if shouldLoadAddress && shouldLoadKeyword {
                        async let addressTask: () = getGeoFromAddressQuery(model.query)
                        async let keywordTask: () = getGeoFormKeywordQuery(model.query)
                        
                        await addressTask
                        await keywordTask
                    } else if shouldLoadAddress {
                        await getGeoFromAddressQuery(model.query)
                    } else if shouldLoadKeyword {
                        await getGeoFormKeywordQuery(model.query)
                    }
                    
                    await MainActor.run { model.isLoading = false }
                }
            }
            
        case .selectAddress(let selectedData):
            onAddressSelected?(selectedData)
        }
    }
    
    private func getGeoFromAddressQuery(_ query: String) async {
        
        guard !query.isEmpty else { return }
        do {
            let response = try await repository.getGeofromAddressQuery(query, page: model.addressCurPage)

            await MainActor.run {
                model.addressCurPage += 1
                model.addressQueryIsEnd = response.meta.isEnd
                model.addressQueryData.append(contentsOf: response.documents.compactMap { $0.toSearchListData() })
                model.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
    }
    
    private func getGeoFormKeywordQuery(_ query: String) async {
        do {
            let response = try await repository.getGeoFromKeywordQuery(query, page: model.keywordCurPage)
            await MainActor.run {
                model.keywordCurPage += 1
                model.keywordQueryIsEnd = response.meta.isEnd
                model.keywordQueryData.append(contentsOf: response.places.compactMap { $0.toSearchListData() })
                model.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                handleError(error)
            }
        }
    }
    
    private func handleError(_ error: Error) {
        if let netError = error as? CustomError {
            model.errorMessage = netError.errorDescription
        } else {
            model.errorMessage = error.localizedDescription
        }
    }
}
