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
    private static let addressRepository = AddressNetworkRepositoryFactory.create()
    
    static func mapLikeSummariesWithAddress(_ summaries: [LikeSummaryEntity]) async -> AddressMappingResult<LikeEstateWithAddress> {
        
        await withTaskGroup(of: Result<LikeEstateWithAddress?, Error>.self) { group in
            for summary in summaries {
                group.addTask {
                    let geo = summary.geolocation
                    do {
                        let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
                        return .success(LikeEstateWithAddress(summary: summary.toPresentation(), address: address))
                    } catch {
                        return .success(nil) // 앱은 돌아가게
                            .flatMapError { _ in .failure(error) }
                    }
                }
            }

            var estates: [LikeEstateWithAddress?] = []
            var errors: [Error] = []

            for await result in group {
                switch result {
                case .success(let estate):
                    estates.append(estate)
                case .failure(let error):
                    errors.append(error)
                }
            }
            
            return AddressMappingResult(estates: Array(estates.compactMap{$0}.prefix(7)), errors: errors)
        }
    }
        
    static func mapHotSummariesWithAddress(
           _ summaries: [HotSummaryEntity]
       ) async -> AddressMappingResult<HotEstateWithAddress> {

           await withTaskGroup(of: Result<HotEstateWithAddress?, Error>.self) { group in
               for summary in summaries {
                   group.addTask {
                       let geo = summary.geolocation
                       do {
                           let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
                           return .success(HotEstateWithAddress(summary: summary.toPresentation(), address: address))
                       } catch {

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
        _ summaries: [SimilarSummaryEntity]
    ) async -> AddressMappingResult<SimilarEstateWithAddress> {

        await withTaskGroup(of: Result<SimilarEstateWithAddress?, Error>.self) { group in
            for summary in summaries {
                group.addTask {
                    let geo = summary.geolocation
                    do {
                        let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
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
        _ summaries: [TodaySummaryEntity]
    ) async -> AddressMappingResult<TodayEstateWithAddress> {

        await withTaskGroup(of: Result<TodayEstateWithAddress?, Error>.self) { group in
            for summary in summaries {
                group.addTask {
                    let geo = summary.geolocation
                    do {
                        let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
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

extension AddressMappingHelper {
    static func mapDetailEstateWithAddress(
        _ detail: DetailEstateEntity
    ) async -> Result<DetailEstateWithAddrerss, Error> {
        
        guard let geo = detail.geolocation else {
            return .failure(CustomError.nilResponse)
        }
        
        do {
            let address = try await addressRepository.getAddressFromGeo(geo).roadAddressName
            let mapped = DetailEstateWithAddrerss(
                detail: detail.toPresentationModel(),
                address: address
            )
            return .success(mapped)
        } catch {
            return .failure(error)
        }
    }
}



extension AddressMappingHelper {
    static func mapPostSummariesWithAddress(
        _ summaries: [PostSummaryResponseEntity]
    ) async -> AddressMappingResult<PostSummaryResponseEntity> {
        await withTaskGroup(of: Result<PostSummaryResponseEntity?, Error>.self) { group in
            for summary in summaries {
                group.addTask {
                    let geo = summary.geolocation
                    do {
                        let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
                        // address가 이미 있는 경우 업데이트
                        let updatedSummary = PostSummaryResponseEntity(
                            postId: summary.postId,
                            category: summary.category,
                            title: summary.title,
                            content: summary.content,
                            geolocation: summary.geolocation,
                            creator: summary.creator,
                            files: summary.files,
                            isLike: summary.isLike,
                            likeCount: summary.likeCount,
                            createdAt: summary.createdAt,
                            updatedAt: summary.updatedAt,
                            address: address
                        )
                        return .success(updatedSummary)
                    } catch {
                        return .success(nil)
                            .flatMapError { _ in .failure(error) }
                    }
                }
            }

            var posts: [PostSummaryResponseEntity?] = []
            var errors: [Error] = []

            for await result in group {
                switch result {
                case .success(let post):
                    posts.append(post)
                case .failure(let error):
                    errors.append(error)
                }
            }

            return AddressMappingResult(estates: posts.compactMap{$0}, errors: errors)
        }
    }
    
    static func getSingleAddress(longitude: Double, latitude: Double) async -> String {
        let geo = GeolocationEntity(longitude: longitude, latitude: latitude)
        
        do {
            let address = try await addressRepository.getAddressFromGeo(geo).toRoadRegion2()
            return address
        } catch {
            return "알 수 없음"
        }
    }
}