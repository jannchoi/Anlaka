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
    var pinInfoList: [PinInfo] = [] // Added to store pin info
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
    case searchBarSubmitted(String)
    case startMapEngine
}

@MainActor
final class SearchMapContainer: NSObject, ObservableObject {
    @Published var model = SearchMapModel()
    private let repository: NetworkRepository
    private let locationManager = CLLocationManager()
    private var geoEstatesDebounceTimer: Timer?
    private var lastGeoEstatesCoordinate: CLLocationCoordinate2D?
    
    init(repository: NetworkRepository) {
        self.repository = repository
        super.init()
        setupLocationManager()
        model.maxDistance = DefaultValues.Geolocation.maxDistanse.value
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
            debounceGeoEstates(lon: defaultLon, lat: defaultLat, maxD: defaultMaxD)
            
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
            model.maxDistance = distance > 0 ? distance : DefaultValues.Geolocation.maxDistanse.value
            
        case .mapDidStopMoving(let center, let maxDistance):
            model.centerCoordinate = center
            model.maxDistance = maxDistance > 0 ? maxDistance : DefaultValues.Geolocation.maxDistanse.value
            debounceGeoEstates(lon: center.longitude, lat: center.latitude, maxD: model.maxDistance)
            
        case .searchBarSubmitted(let text):
            model.addressQuery = text
            if !text.isEmpty {
                Task {
                    await getGeoFromAddressQuery(text)
                }
            }
            
        case .startMapEngine:
            model.shouldDrawMap = true
        }
    }
    
    private func debounceGeoEstates(lon: Double, lat: Double, maxD: Double) {
        guard lon.isFinite, lat.isFinite, maxD > 0 else {
            print("Invalid coordinates or maxD, skipping getGeoEstates: lon=\(lon), lat=\(lat), maxD=\(maxD)")
            return
        }
        geoEstatesDebounceTimer?.invalidate()
        geoEstatesDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
            Task { @MainActor in
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                if self.lastGeoEstatesCoordinate == nil ||
                   abs(self.lastGeoEstatesCoordinate!.latitude - lat) > 0.0001 ||
                   abs(self.lastGeoEstatesCoordinate!.longitude - lon) > 0.0001 {
                    print("getGeoEstates 호출: lon=\(lon), lat=\(lat), maxD=\(maxD)")
                    await self.getGeoEstates(lon: lon, lat: lat, maxD: maxD)
                    self.lastGeoEstatesCoordinate = coordinate
                } else {
                    print("중복 좌표로 getGeoEstates 호출 스킵: lon=\(lon), lat=\(lat)")
                }
            }
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
            print("검색어 위치: \(coordinate.longitude) \(coordinate.latitude)" )
            model.errorMessage = nil
            await getGeoEstates(lon: response.longitude, lat: response.latitude, maxD: model.maxDistance)
        } catch {
            model.errorMessage = error.localizedDescription
            model.pinInfoList = []
        }
        model.isLoading = false
    }
    
    private func getGeoEstates(category: CategoryType? = nil, lon: Double, lat: Double, maxD: Double) async {
        print("getGeoEstates 호출: lon=\(lon), lat=\(lat), maxD=\(maxD)")
        model.isLoading = true
        do {
            let response = try await repository.getGeoEstate(category: category, lon: lon, lat: lat, maxD: maxD)
            model.estates = response.data
            model.pinInfoList = response.toPinInfoList()
            model.errorMessage = nil
            print("받아온 매물 데이터: \(response.data.count)개, 핀 데이터: \(model.pinInfoList.count)개")
        } catch {
            model.errorMessage = "getGeoEstates 에러: \(error.localizedDescription)"
            model.pinInfoList = []
            print("getGeoEstates 에러: \(error.localizedDescription)")
        }
        model.isLoading = false
    }
}

extension SearchMapContainer: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        if lastGeoEstatesCoordinate == nil ||
           abs(lastGeoEstatesCoordinate!.latitude - coordinate.latitude) > 0.0001 ||
           abs(lastGeoEstatesCoordinate!.longitude - coordinate.longitude) > 0.0001 {
            handle(.updateCurrentLocation(coordinate))
            handle(.updateCenterCoordinate(coordinate))
            handle(.startMapEngine)
            debounceGeoEstates(lon: coordinate.longitude, lat: coordinate.latitude, maxD: model.maxDistance)
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
