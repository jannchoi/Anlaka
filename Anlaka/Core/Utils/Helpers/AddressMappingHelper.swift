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
        // 주소 매핑 실패 시 기본값 제공 (뷰에서 옵셔널 처리 안하기)
        await mapPostSummariesWithAddressWithDefault(summaries)
    }
    
    static func mapPostSummariesWithAddressWithDefault(
        _ summaries: [PostSummaryResponseEntity]
    ) async -> AddressMappingResult<PostSummaryResponseEntity> {
        // 원본 순서를 유지하기 위해 인덱스와 함께 처리
        await withTaskGroup(of: (Int, Result<PostSummaryResponseEntity?, Error>).self) { group in
            for (index, summary) in summaries.enumerated() {
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
                        return (index, .success(updatedSummary))
                    } catch {
                        // 주소 매핑 실패 시 기본값 제공
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
                            address: "알 수 없음"
                        )
                        return (index, .success(updatedSummary)) 
                    }
                }
            }

            var indexedResults: [(Int, PostSummaryResponseEntity?)] = []
            var errors: [Error] = []

            for await (index, result) in group {
                switch result {
                case .success(let post):
                    indexedResults.append((index, post))
                case .failure(let error):
                    errors.append(error)
                }
            }

            // 원본 순서대로 정렬
            indexedResults.sort { $0.0 < $1.0 }
            let posts = indexedResults.compactMap { $0.1 }

            return AddressMappingResult(estates: posts, errors: errors)
        }
    }
    
    static func mapPostSummariesWithAddressExcludeFailed(
        _ summaries: [PostSummaryResponseEntity]
    ) async -> AddressMappingResult<PostSummaryResponseEntity> {
        // 주소 매핑 실패 시 데이터 제외
        await withTaskGroup(of: (Int, Result<PostSummaryResponseEntity?, Error>).self) { group in
            for (index, summary) in summaries.enumerated() {
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
                        return (index, .success(updatedSummary))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }

            var indexedResults: [(Int, PostSummaryResponseEntity?)] = []
            var errors: [Error] = []

            for await (index, result) in group {
                switch result {
                case .success(let post):
                    indexedResults.append((index, post))
                case .failure(let error):
                    errors.append(error)
                }
            }

            // 원본 순서대로 정렬
            indexedResults.sort { $0.0 < $1.0 }
            let posts = indexedResults.compactMap { $0.1 }

            return AddressMappingResult(estates: posts, errors: errors)
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
    
    static func mapPostWithAddress(_ post: PostResponseEntity) async -> PostResponseEntity {
        let geo = post.geolocation
        
        do {
            let address = try await addressRepository.getAddressFromGeo(geo).toShortAddress()
            // PostResponseEntity에 address 필드 추가
            return PostResponseEntity(
                postId: post.postId,
                category: post.category,
                title: post.title,
                content: post.content,
                geolocation: post.geolocation,
                creator: post.creator,
                files: post.files,
                comments: post.comments,
                createdAt: post.createdAt,
                updatedAt: post.updatedAt,
                isLike: post.isLike,
                likeCount: post.likeCount,
                address: address
            )
        } catch {
            // 에러가 발생해도 기본 주소 제공
            return PostResponseEntity(
                postId: post.postId,
                category: post.category,
                title: post.title,
                content: post.content,
                geolocation: post.geolocation,
                creator: post.creator,
                files: post.files,
                comments: post.comments,
                createdAt: post.createdAt,
                updatedAt: post.updatedAt,
                isLike: post.isLike,
                likeCount: post.likeCount,
                address: "알 수 없음"
            )
        }
    }
}