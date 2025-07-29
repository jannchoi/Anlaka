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
    
    // 새로 추가할 필터 관련 프로퍼티들
    var selectedFilterIndex: Int? = nil // 0: 카테고리, 1: 평수, 2: 월세, 3: 보증금
    var selectedCategories: [String] = [] // 배열로 변경
    var selectedAreaRange: ClosedRange<Double> = 0...200 // 수정: 0~200평
    var selectedMonthlyRentRange: ClosedRange<Double> = 0...5000 // 수정: 0~5000만원
    var selectedDepositRange: ClosedRange<Double> = 0...50000 // 수정: 0~50000만원
    var selectedEstateIds: [String] = [] // onPOIGroupTap에서 받은 estate_id들
    var filteredEstates: [DetailEstateEntity] = []
    var showEstateScroll: Bool = false
    
    var navigationDestination: SearchMapRoute? = nil
    
}

enum SearchMapIntent {
    case loadDefaultLocation
    case requestLocationPermission
    case updateMaxDistance(Double)
    case mapDidStopMoving(CLLocationCoordinate2D, Double)
    case searchBarSubmitted(SearchListData)
    case startMapEngine
    
    // 새로 추가할 필터 관련 인텐트들
    case selectFilter(Int?) // nil이면 필터 해제
    case selectCategory(String?)
    case updateAreaRange(ClosedRange<Double>)
    case updateMonthlyRentRange(ClosedRange<Double>)
    case updateDepositRange(ClosedRange<Double>)
    case poiGroupSelected([String]) // onPOIGroupTap
    case poiSelected(String) // onPOITap
    case hideEstateScroll
}

@MainActor
final class SearchMapContainer: NSObject, ObservableObject {
    @Published var model = SearchMapModel()
    private let repository: NetworkRepository
    private let locationManager = CLLocationManager()
    private var geoEstatesDebounceTimer: Timer?
    private var filterDebounceTimer: Timer?
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
            
        case .selectFilter(let index):
            model.selectedFilterIndex = index
            
        case .selectCategory(let category):
            if let category = category {
                if model.selectedCategories.contains(category) {
                    model.selectedCategories.removeAll { $0 == category }
                } else {
                    model.selectedCategories.append(category)
                }
            } else {
                model.selectedCategories.removeAll()
            }
            debounceFilterUpdate()
            
        case .updateAreaRange(let range):
            model.selectedAreaRange = range
            debounceFilterUpdate()
            
        case .updateMonthlyRentRange(let range): //만원
            model.selectedMonthlyRentRange = scaleRange(range, by: 10000) //원
            debounceFilterUpdate()
            
        case .updateDepositRange(let range): //만원
            model.selectedDepositRange = scaleRange(range, by: 10000) //원
            debounceFilterUpdate()
            
        case .poiGroupSelected(let estateIds):
            model.selectedEstateIds = estateIds
            loadEstatesForScroll(estateIds: estateIds)
            
        case .poiSelected(let estateId):
            model.navigationDestination = .detail(estateId: estateId)

        case .hideEstateScroll:
            model.showEstateScroll = false
            model.filteredEstates = []
            
        }
    }
    private func scaleRange(_ range: ClosedRange<Double>, by factor: Double) -> ClosedRange<Double> {
        return (range.lowerBound * factor)...(range.upperBound * factor)
    }
    private func applyFiltersAndUpdateMap() {
        // 현재 로드된 데이터가 있다면 필터를 적용하여 맵 업데이트
        Task {
            await getGeoEstates(
                lon: model.centerCoordinate.longitude,
                lat: model.centerCoordinate.latitude,
                maxD: model.maxDistance
            )
        }
    }

    private func loadEstatesForScroll(estateIds: [String]) {
        Task {
            let estates = await withTaskGroup(of: DetailEstateEntity?.self) { group in
                // 각 estateId에 대해 병렬로 작업 추가
                for estateId in estateIds {
                    group.addTask {
                        do {
                            return try await self.getDetailEstate(estateId)
                        } catch {
                            print("Failed to load estate \(estateId): \(error)")
                            return nil
                        }
                    }
                }
                
                // 성공한 결과만 수집
                var results: [DetailEstateEntity] = []
                for await estate in group {
                    if let estate = estate {
                        results.append(estate)
                    }
                }
                return results
            }
            
            model.filteredEstates = estates
            model.showEstateScroll = true
        }
    }
    private func getDetailEstate(_ estateId: String) async throws -> DetailEstateEntity {
        
        do {
            let response = try await repository.getDetailEstate(estateId)
            return response
        } catch {
            throw error
        }
    }
    private func estateDataFiltering(_ estates: GeoEstateEntity) -> GeoEstateEntity {
        var filteredData = estates.data
        
        // 카테고리 필터
        if !model.selectedCategories.isEmpty {
            filteredData = filteredData.filter { model.selectedCategories.contains($0.category) }
        }
        
        // 평수 필터 - 슬라이더 범위 기반 처리
        let sliderAreaRange = 0.0...200.0   // 슬라이더 범위 수정
        let fullAreaRange = 0.0...200.0     // 전체 데이터 범위
        
        if model.selectedAreaRange != fullAreaRange {
            if model.selectedAreaRange.lowerBound <= sliderAreaRange.lowerBound &&
               model.selectedAreaRange.upperBound >= sliderAreaRange.upperBound {
                // 슬라이더 전체 범위인 경우 필터링 안함
            } else if model.selectedAreaRange.lowerBound <= sliderAreaRange.lowerBound {
                // 하한선 없음 (상한선만 적용)
                filteredData = filteredData.filter { $0.area <= model.selectedAreaRange.upperBound }
            } else if model.selectedAreaRange.upperBound >= sliderAreaRange.upperBound {
                // 상한선 없음 (하한선만 적용)
                filteredData = filteredData.filter { $0.area >= model.selectedAreaRange.lowerBound }
            } else {
                // 일반 범위 필터링
                filteredData = filteredData.filter { model.selectedAreaRange.contains($0.area) }
            }
        }
        
        // 월세 필터 - 슬라이더 범위 기반 처리
        let sliderMonthlyRentRange = 0.0...5000.0   // 슬라이더 범위 수정
        let fullMonthlyRentRange = 0.0...5000.0
        
        if model.selectedMonthlyRentRange != fullMonthlyRentRange {
            if model.selectedMonthlyRentRange.lowerBound <= sliderMonthlyRentRange.lowerBound &&
               model.selectedMonthlyRentRange.upperBound >= sliderMonthlyRentRange.upperBound {
                // 슬라이더 전체 범위인 경우 필터링 안함
            } else if model.selectedMonthlyRentRange.lowerBound <= sliderMonthlyRentRange.lowerBound {
                // 하한선 없음 (상한선만 적용)
                filteredData = filteredData.filter { $0.monthlyRent <= model.selectedMonthlyRentRange.upperBound }
            } else if model.selectedMonthlyRentRange.upperBound >= sliderMonthlyRentRange.upperBound {
                // 상한선 없음 (하한선만 적용)
                filteredData = filteredData.filter { $0.monthlyRent >= model.selectedMonthlyRentRange.lowerBound }
            } else {
                // 일반 범위 필터링
                filteredData = filteredData.filter { model.selectedMonthlyRentRange.contains($0.monthlyRent) }
            }
        }
        
        // 보증금 필터 - 슬라이더 범위 기반 처리
        let sliderDepositRange = 0.0...50000.0
        let fullDepositRange = 0.0...50000.0
        
        if model.selectedDepositRange != fullDepositRange {
            if model.selectedDepositRange.lowerBound <= sliderDepositRange.lowerBound &&
               model.selectedDepositRange.upperBound >= sliderDepositRange.upperBound {
                // 슬라이더 전체 범위인 경우 필터링 안함
            } else if model.selectedDepositRange.lowerBound <= sliderDepositRange.lowerBound {
                // 하한선 없음 (상한선만 적용)
                filteredData = filteredData.filter { $0.deposit <= model.selectedDepositRange.upperBound }
            } else if model.selectedDepositRange.upperBound >= sliderDepositRange.upperBound {
                // 상한선 없음 (하한선만 적용)
                filteredData = filteredData.filter { $0.deposit >= model.selectedDepositRange.lowerBound }
            } else {
                // 일반 범위 필터링
                filteredData = filteredData.filter { model.selectedDepositRange.contains($0.deposit) }
            }
        }
        
        return GeoEstateEntity(data: filteredData)
    }
    // getGeoEstates 메서드 수정
    private func getGeoEstates(lon: Double, lat: Double, maxD: Double) async {
        model.isLoading = true
        
        do {

            let estates = try await repository.getGeoEstate(category: nil, lon: lon, lat: lat, maxD: maxD)
            print("⛑️⛑️⛑️ monthly",estates.data.map{$0.monthlyRent}.sorted())
            print("🧤🧤🧤 deposit",estates.data.map{$0.deposit}.sorted())
            print("🔷🔷🔷 area", estates.data.map{$0.area}.sorted())
            let filteredEstates = estateDataFiltering(estates) // 필터링 적용
            model.pinInfoList = filteredEstates.toPinInfoList()

        } catch {
            handleError(error)
        }
        
        model.isLoading = false
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
    
    private func debounceFilterUpdate() {
        filterDebounceTimer?.invalidate()
        filterDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.getGeoEstates(
                    lon: self.model.centerCoordinate.longitude,
                    lat: self.model.centerCoordinate.latitude,
                    maxD: self.model.maxDistance
                )
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
