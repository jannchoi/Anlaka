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
    var currentLocation: CLLocationCoordinate2D?
    var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: DefaultValues.Geolocation.latitude.value,
        longitude: DefaultValues.Geolocation.longitude.value
    )
    var maxDistance: Double = DefaultValues.Geolocation.maxDistanse.value
    var pinInfoList: [PinInfo] = []
    var isLocationPermissionGranted: Bool = false
    var isLoading: Bool = false
    var shouldDrawMap: Bool = false
    var addressQuery: String = ""
    var errorMessage: String?
    var backToLogin: Bool = false
    var searchedData: SearchListData?
}

enum SearchMapIntent {
    case loadDefaultLocation
    case requestLocationPermission
    case updateMaxDistance(Double)
    case mapDidStopMoving(CLLocationCoordinate2D, Double)
    case searchBarSubmitted(SearchListData)
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
    }
    
    func handle(_ intent: SearchMapIntent) {
        switch intent {
        case .loadDefaultLocation:
            let defaultLon = DefaultValues.Geolocation.longitude.value
            let defaultLat = DefaultValues.Geolocation.latitude.value
            model.centerCoordinate = CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLon)
            model.shouldDrawMap = true
            
        case .requestLocationPermission:
            requestLocationPermission()
            
        case .updateMaxDistance(let distance):

            model.maxDistance = distance
            guard let searchedData = model.searchedData else {return}
            Task {
                await getGeoEstates(lon: searchedData.longitude, lat: searchedData.latitude, maxD: model.maxDistance)
            }
            
        case .mapDidStopMoving(let center, let maxDistance):
            model.centerCoordinate = center
            model.maxDistance = maxDistance
            debounceGeoEstates(lon: center.longitude, lat: center.latitude, maxD: maxDistance)
            
        case .searchBarSubmitted(let searchedData):

            model.centerCoordinate = CLLocationCoordinate2D(latitude: searchedData.latitude, longitude: searchedData.longitude)
            model.searchedData = searchedData
            
        case .startMapEngine:
            model.shouldDrawMap = true
        }
    }
    
    private func debounceGeoEstates(lon: Double, lat: Double, maxD: Double) {
        guard lon.isFinite, lat.isFinite, maxD > 0 else { return }
        
        geoEstatesDebounceTimer?.invalidate()
        geoEstatesDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                if self.lastGeoEstatesCoordinate == nil ||
                    abs(self.lastGeoEstatesCoordinate!.latitude - lat) > 0.0001 ||
                    abs(self.lastGeoEstatesCoordinate!.longitude - lon) > 0.0001 {
                    await self.getGeoEstates(lon: lon, lat: lat, maxD: maxD)
                    self.lastGeoEstatesCoordinate = coordinate
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

    private func getGeoEstates(lon: Double, lat: Double, maxD: Double) async {
        model.isLoading = true
        
        do {
            let estates = try await repository.getGeoEstate(category: nil, lon: lon, lat: lat, maxD: maxD)
            print(estates.data.count)
            model.pinInfoList = estates.toPinInfoList()
        } catch {
            handleError(error)
        }
        
        model.isLoading = false
    }
    
    private func handleError(_ error: Error) {
        model.pinInfoList = []
        if let netError = error as? NetworkError, netError == .expiredRefreshToken {
            model.backToLogin = true
        } else {
            model.errorMessage = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
        }
    }
}

extension SearchMapContainer: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            model.isLocationPermissionGranted = true
            locationManager.requestLocation()
        case .denied, .restricted:
            model.isLocationPermissionGranted = false
            handle(.loadDefaultLocation)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        model.currentLocation = location.coordinate
        model.centerCoordinate = location.coordinate
        model.shouldDrawMap = true
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error.localizedDescription)")
        handle(.loadDefaultLocation)
    }
}
