//
//  SearchMapContainer.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI
import CoreLocation
import Foundation

struct SearchMapModel {
    var errorMessage: String? = nil
    var addressQuery: String = ""
    var currentLocation: CLLocationCoordinate2D?
    var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: DefaultValues.Geolocation.latitude.value,
        longitude: DefaultValues.Geolocation.longitude.value
    )
    var maxDistance: Double = DefaultValues.Geolocation.maxDistanse.value
    var estates: [EstateSummaryEntity] = []
    var isLocationPermissionGranted: Bool = false
    var isLoading: Bool = false
    var shouldDrawMap: Bool = false
}

enum SearchMapIntent {
    case loadDefaultLocation
    case queryIsAddress(query: String)
    case requestLocationPermission
    case updateCurrentLocation(CLLocationCoordinate2D)
    case updateCenterCoordinate(CLLocationCoordinate2D)
    case updateMaxDistance(Double)
    case mapDidStopMoving(center: CLLocationCoordinate2D, maxDistance: Double)
    case searchBarTextChanged(String)
    case startMapEngine
}

@MainActor
final class SearchMapContainer: NSObject, ObservableObject {
    @Published var model = SearchMapModel()
    private let repository: NetworkRepository
    private let locationManager = CLLocationManager()
    private var searchDebounceTimer: Timer?
    
    init(repository: NetworkRepository) {
        self.repository = repository
        super.init()
        setupLocationManager()
    }
    
    func handle(_ intent: SearchMapIntent) {
        switch intent {
        case .loadDefaultLocation:
            let defaultLon = DefaultValues.Geolocation.longitude.value
            let defaultLat = DefaultValues.Geolocation.latitude.value
            let defaultMaxD = DefaultValues.Geolocation.maxDistanse.value
            
            model.centerCoordinate = CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLon)
            model.maxDistance = defaultMaxD
            model.shouldDrawMap = true
            
            Task { await getGeoEstates(lon: defaultLon, lat: defaultLat, maxD: defaultMaxD) }
            
        case .queryIsAddress(let query):
            model.addressQuery = query
            Task {
                await getGeoFromAddressQuery(query)
            }
            
        case .requestLocationPermission:
            requestLocationPermission()
            
        case .updateCurrentLocation(let location):
            model.currentLocation = location
            
        case .updateCenterCoordinate(let coordinate):
            model.centerCoordinate = coordinate
            
        case .updateMaxDistance(let distance):
            model.maxDistance = distance
            
        case .mapDidStopMoving(let center, let maxDistance):
            model.centerCoordinate = center
            model.maxDistance = maxDistance
            Task {
                await getGeoEstates(lon: center.longitude, lat: center.latitude, maxD: maxDistance)
            }
            
        case .searchBarTextChanged(let text):
            model.addressQuery = text
            // Debounce search to avoid too many API calls
            searchDebounceTimer?.invalidate()
            if !text.isEmpty {
                searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    Task { @MainActor in
                        await self.getGeoFromAddressQuery(text)
                    }
                }
            }
            
        case .startMapEngine:
            model.shouldDrawMap = true
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            model.isLocationPermissionGranted = false
            handle(.loadDefaultLocation)
        case .authorizedWhenInUse, .authorizedAlways:
            model.isLocationPermissionGranted = true
            locationManager.requestLocation()
        @unknown default:
            model.isLocationPermissionGranted = false
            handle(.loadDefaultLocation)
        }
    }
    
    private func getGeoFromAddressQuery(_ query: String) async {
        guard !query.isEmpty else { return }
        
        model.isLoading = true
        do {
            let response = try await repository.getGeofromAddressQuery(query)
            let coordinate = CLLocationCoordinate2D(
                latitude: response.latitude,
                longitude: response.longitude
            )
            
            model.centerCoordinate = coordinate
            model.errorMessage = nil
            
            // Get estates for the new location
            await getGeoEstates(lon: response.longitude, lat: response.latitude, maxD: model.maxDistance)
            
        } catch {
            if let error = error as? NetworkError {
                model.errorMessage = error.errorDescription
            } else {
                model.errorMessage = "알 수 없는 에러: \(error.localizedDescription)"
            }
        }
        model.isLoading = false
    }
    
    private func getGeoEstates(category: CategoryType? = nil, lon: Double, lat: Double, maxD: Double) async {
        model.isLoading = true
        do {
            let response = try await repository.getGeoEstate(category: category, lon: lon, lat: lat, maxD: maxD)
            model.estates = response.data
            model.errorMessage = nil
            
            // 여기서 클러스터링 로직이 추가될 예정
            // TODO: Implement clustering logic here
            print("받아온 매물 데이터: \(response.data.count)개")
            
        } catch {
            if let error = error as? NetworkError {
                model.errorMessage = error.errorDescription
            } else {
                model.errorMessage = "알 수 없는 에러: \(error.localizedDescription)"
            }
        }
        model.isLoading = false
    }
}

// MARK: - CLLocationManagerDelegate
extension SearchMapContainer: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        
        handle(.updateCurrentLocation(coordinate))
        handle(.updateCenterCoordinate(coordinate))
        handle(.startMapEngine)
        
        Task {
            await getGeoEstates(lon: coordinate.longitude, lat: coordinate.latitude, maxD: model.maxDistance)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        model.errorMessage = "위치 정보를 가져올 수 없습니다: \(error.localizedDescription)"
        handle(.loadDefaultLocation)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            model.isLocationPermissionGranted = true
            manager.requestLocation()
        case .denied, .restricted:
            model.isLocationPermissionGranted = false
            handle(.loadDefaultLocation)
        case .notDetermined:
            break
        @unknown default:
            model.isLocationPermissionGranted = false
            handle(.loadDefaultLocation)
        }
    }
}
