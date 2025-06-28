//
//  AddressMappingHelper.swift
//  Anlaka
//
//  Created by 최정안 on 5/19/25.
//

import Foundation
struct AddressMappingResult<T> {
    let estates: [T]
    let errors: [Error]  // 또는 [Error]
}

struct AddressMappingHelper {
    
    static func mapHotSummariesWithAddress(
           _ summaries: [HotSummaryEntity],
           repository: NetworkRepository
       ) async -> AddressMappingResult<HotEstateWithAddress> {

           await withTaskGroup(of: Result<HotEstateWithAddress?, Error>.self) { group in
               for summary in summaries {
                   group.addTask {
                       let geo = summary.geolocation
                       do {
                           let address = try await repository.getAddressFromGeo(geo).roadRegion3
                           return .success(HotEstateWithAddress(summary: summary.toPresentation(), address: address))
                       } catch {
                           let message = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                           return .success(nil) // 앱은 돌아가게
                               .flatMapError { _ in .failure(error) }
                       }
                   }
               }

               var estates: [HotEstateWithAddress?] = []
               var errors: [Error] = []

               for await result in group {
                   switch result {
                   case .success(let estate):
                       estates.append(estate)
                   case .failure(let error):
                       errors.append(error)
                   }
               }

               return AddressMappingResult(estates: estates.compactMap{$0}, errors: errors)
           }
       }

}
extension AddressMappingHelper {

    static func mapSimilarSummariesWithAddress(
        _ summaries: [SimilarSummaryEntity],
        repository: NetworkRepository
    ) async -> AddressMappingResult<SimilarEstateWithAddress> {

        await withTaskGroup(of: Result<SimilarEstateWithAddress?, Error>.self) { group in
            for summary in summaries {
                group.addTask {
                    let geo = summary.geolocation
                    do {
                        let address = try await repository.getAddressFromGeo(geo).roadRegion3
                        return .success(SimilarEstateWithAddress(summary: summary.toPresentation(), address: address))
                    } catch {
                        return .success(nil)
                            .flatMapError { _ in .failure(error) }
                    }
                }
            }

            var estates: [SimilarEstateWithAddress?] = []
            var errors: [Error] = []

            for await result in group {
                switch result {
                case .success(let estate):
                    estates.append(estate)
                case .failure(let error):
                    errors.append(error)
                }
            }

            return AddressMappingResult(estates: estates.compactMap{$0}, errors: errors)
        }
    }
}
extension AddressMappingHelper {

    static func mapTodaySummariesWithAddress(
        _ summaries: [TodaySummaryEntity],
        repository: NetworkRepository
    ) async -> AddressMappingResult<TodayEstateWithAddress> {

        await withTaskGroup(of: Result<TodayEstateWithAddress?, Error>.self) { group in
            for summary in summaries {
                group.addTask {
                    let geo = summary.geolocation
                    do {
                        let address = try await repository.getAddressFromGeo(geo).roadRegion3
                        return .success(TodayEstateWithAddress(summary: summary.toPresentation(), address: address))
                    } catch {
                        return .success(nil)
                            .flatMapError { _ in .failure(error) }
                    }
                }
            }

            var estates: [TodayEstateWithAddress?] = []
            var errors: [Error] = []

            for await result in group {
                switch result {
                case .success(let estate):
                    estates.append(estate)
                case .failure(let error):
                    errors.append(error)
                }
            }

            return AddressMappingResult(estates: estates.compactMap{$0}, errors: errors)
        }
    }
}
