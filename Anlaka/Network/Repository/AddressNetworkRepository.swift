import Foundation

protocol AddressNetworkRepository {
    func getAddressFromGeo(_ geo: GeolocationEntity) async throws -> AddressResponseEntity
    func getRoad3FromGeo(_ geo: GeolocationEntity) async throws -> RoadRegion3Entity
    func getGeofromAddressQuery(_ query: String, page: Int) async throws -> KakaoGeolocationEntity
    func getGeoFromKeywordQuery(_ query: String, page: Int) async throws -> KakaoGeoKeywordEntity
}

// MARK: - AddressNetworkRepository Factory
internal enum AddressNetworkRepositoryFactory {
    static func create() -> AddressNetworkRepository {
        return AddressNetworkRepositoryImp()
    }
}

// MARK: - AddressNetworkRepository Implementation
internal final class AddressNetworkRepositoryImp: AddressNetworkRepository {
    
    func getGeoFromKeywordQuery(_ query: String, page: Int) async throws -> KakaoGeoKeywordEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getGeoByKeyword(query: query, page: page), model: KakaoGeoKeywordDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getGeofromAddressQuery(_ query: String, page: Int) async throws -> KakaoGeolocationEntity {
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getGeolocation(query: query, page: page), model: KakaoGeolocationDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
    
    func getRoad3FromGeo(_ geo: GeolocationEntity) async throws -> RoadRegion3Entity {
        let (x,y) = (geo.longitude, geo.latitude)
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getAddress(lon: x, lat: y), model: AddressResponseDTO.self)
            return response.toRoadRegion3Entity()
        } catch {
            throw error
        }
    }
    
    func getAddressFromGeo(_ geo: GeolocationEntity) async throws -> AddressResponseEntity {
        let (x,y) = (geo.longitude, geo.latitude)
        do {
            let response = try await NetworkManager.shared.callRequest(target: GeoRouter.getAddress(lon: x, lat: y), model: AddressResponseDTO.self)
            return response.toEntity()
        } catch {
            throw error
        }
    }
} 