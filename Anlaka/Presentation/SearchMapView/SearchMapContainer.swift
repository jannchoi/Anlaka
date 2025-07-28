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
    var detailEstateList: [DetailEstateEntity] = []
    
    // 필터 최대 범위 상수 정의
    static let maxAreaRange: ClosedRange<Double> = 0...200
    static let maxMonthlyRentRange: ClosedRange<Double> = 0...5000
    static let maxDepositRange: ClosedRange<Double> = 0...50000
    
    var selectedFilterIndex: Int? = nil // 0: 카테고리, 1: 평수, 2: 월세, 3: 보증금
    var selectedCategory: String? = nil // 단일 카테고리 선택으로 변경
    var selectedAreaRange: ClosedRange<Double> = SearchMapModel.maxAreaRange
    var selectedMonthlyRentRange: ClosedRange<Double> = SearchMapModel.maxMonthlyRentRange
    var selectedDepositRange: ClosedRange<Double> = SearchMapModel.maxDepositRange
    var selectedEstateIds: [String] = [] // onPOIGroupTap에서 받은 estate_id들
    var filteredEstates: [DetailEstatePresentation] = []
    var showEstateScroll: Bool = false
    
    // DetailView로 이동하기 위한 상태 추가
    var selectedEstate: DetailEstateEntity? = nil
    var selectedEstateId: IdentifiableString? = nil
    
    var curEstatesData: GeoEstateEntity? = nil
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
    case selectCategory(String?) // 단일 카테고리 선택으로 변경
    case updateAreaRange(ClosedRange<Double>)
    case updateMonthlyRentRange(ClosedRange<Double>)
    case updateDepositRange(ClosedRange<Double>)
    case poiGroupSelected([String]) // onPOIGroupTap
    case poiSelected(String) // onPOITap
    case hideEstateScroll
    case estateCardSelected(String)
}

@MainActor
final class SearchMapContainer: NSObject, ObservableObject, LocationServiceDelegate {
    @Published var model = SearchMapModel()
    @Published var forceUpdate = false
    private let repository: NetworkRepository
    private let locationService: LocationService // DI로 받음
    private var geoEstatesDebounceTimer: Timer?
    private var filterDebounceTimer: Timer?
    private var lastGeoEstatesCoordinate: CLLocationCoordinate2D?
    var isFilterUpdate = false
    
    init(repository: NetworkRepository, locationService: LocationService) {
        self.repository = repository
        self.locationService = locationService // DI로 받음
        super.init()
        locationService.delegate = self
    }
    
    func handle(_ intent: SearchMapIntent) {
        switch intent {
        case .loadDefaultLocation:
            let defaultLon = DefaultValues.Geolocation.longitude.value
            let defaultLat = DefaultValues.Geolocation.latitude.value
            model.centerCoordinate = CLLocationCoordinate2D(latitude: defaultLat, longitude: defaultLon)
            model.shouldDrawMap = true
        case .requestLocationPermission:
            Task {
                // 위치 권한 요청과 현재 위치 요청을 한 번에 처리
                if let coordinate = await locationService.requestCurrentLocation() {
                    model.currentLocation = coordinate
                    model.centerCoordinate = coordinate
                    model.shouldDrawMap = true
                } else {
                    model.currentLocation = LocationService.defaultCoordinate
                    model.centerCoordinate = LocationService.defaultCoordinate
                    model.shouldDrawMap = true
                }
            }
            
        case .updateMaxDistance(let distance):
            
            model.maxDistance = distance
            guard let searchedData = model.searchedData else {return}
            Task {
                await getGeoEstates(lon: searchedData.longitude, lat: searchedData.latitude, maxD: model.maxDistance, category: model.selectedCategory)
            }
            
        case .mapDidStopMoving(let center, let maxDistance):
            model.centerCoordinate = center
            model.maxDistance = maxDistance
            debounceGeoEstates(lon: center.longitude, lat: center.latitude, maxD: maxDistance)
            
        case .searchBarSubmitted(let searchedData):
            model.centerCoordinate = CLLocationCoordinate2D(latitude: searchedData.latitude, longitude: searchedData.longitude)
            model.searchedData = searchedData
            Task {
                await getGeoEstates(lon: searchedData.longitude, lat: searchedData.latitude, maxD: model.maxDistance, category: model.selectedCategory, forceUpdate: true)
            }
            
        case .startMapEngine:
            model.shouldDrawMap = true
            
        case .selectFilter(let index):
            model.selectedFilterIndex = index
            
        case .selectCategory(let category):
            if model.selectedCategory == category {
                model.selectedCategory = nil
            } else {
                model.selectedCategory = category
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

            model.selectedEstateId = IdentifiableString(id: estateId)
            model.selectedEstate = nil

        case .hideEstateScroll:
            model.showEstateScroll = false
            model.filteredEstates = []
        
        case .estateCardSelected(let estateId):

            if let estate = model.detailEstateList.first(where: { $0.estateId == estateId }) {
                model.selectedEstate = estate
                model.selectedEstateId = nil
            }

        }
    }
    private func scaleRange(_ range: ClosedRange<Double>, by factor: Double) -> ClosedRange<Double> {
        return (range.lowerBound * factor)...(range.upperBound * factor)
    }
    private func applyFiltersAndUpdateMap() {
        isFilterUpdate = true
        // 현재 로드된 데이터가 있다면 필터를 적용하여 맵 업데이트
        if let geoEstates = model.curEstatesData {
            let data = estateDataFiltering(geoEstates)
            let newPinInfoList = data.toPinInfoList()
            
            // 데이터가 변경된 경우에만 pinInfoList 업데이트
            if newPinInfoList != model.pinInfoList {
                model.pinInfoList = newPinInfoList
                // forceUpdate를 true로 설정하고 다음 프레임에서 false로 설정
                DispatchQueue.main.async {
                    self.forceUpdate = true
                    DispatchQueue.main.async {
                        self.forceUpdate = false
                        self.isFilterUpdate = false
                    }
                }
            } else {
                isFilterUpdate = false
            }
        } else {
            model.pinInfoList = []
            isFilterUpdate = false
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
            model.detailEstateList = estates
            model.filteredEstates = estates.map{$0.toPresentationModel()}

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
        var filteredData = estates.data.compactMap { $0 }

        // 필터가 선택되지 않았으면 원본 데이터 반환
        if model.selectedFilterIndex == nil {
            return estates
        }

        // 카테고리 필터
        if let selectedCategory = model.selectedCategory {
            filteredData = filteredData.filter { estate in
                estate.category == selectedCategory
            }
        }

        // 평수 필터
        if model.selectedFilterIndex == 1 {
            filteredData = applyRangeFilter(
                data: filteredData,
                valueProvider: { $0.area },
                selectedRange: model.selectedAreaRange,
                fullRange: SearchMapModel.maxAreaRange
            )
        }

        // 월세 필터
        if model.selectedFilterIndex == 2 {
            filteredData = applyRangeFilter(
                data: filteredData,
                valueProvider: { $0.monthlyRent },
                selectedRange: model.selectedMonthlyRentRange,
                fullRange: SearchMapModel.maxMonthlyRentRange
            )
        }

        // 보증금 필터
        if model.selectedFilterIndex == 3 {
            filteredData = applyRangeFilter(
                data: filteredData,
                valueProvider: { $0.deposit },
                selectedRange: model.selectedDepositRange,
                fullRange: SearchMapModel.maxDepositRange
            )
        }

        return GeoEstateEntity(data: filteredData)
    }
    
    private func applyRangeFilter<T: BinaryFloatingPoint>(
        data: [EstateSummaryEntity],
        valueProvider: (EstateSummaryEntity) -> T?,
        selectedRange: ClosedRange<T>,
        fullRange: ClosedRange<T>
    ) -> [EstateSummaryEntity] {
        // 왼쪽 knob이 최소값(0)에 있고, 오른쪽 knob이 최대값에 있으면 필터링하지 않음
        if selectedRange.lowerBound <= fullRange.lowerBound && selectedRange.upperBound >= fullRange.upperBound {
            return data
        }
        
        return data.filter { estate in
            guard let value = valueProvider(estate) else { return false }
            
            // 왼쪽 knob이 최소값(0)에 있으면 오른쪽 값까지만 체크
            if selectedRange.lowerBound <= fullRange.lowerBound {
                return value <= selectedRange.upperBound
            }
            
            // 오른쪽 knob이 최대값에 있으면 왼쪽 값부터 체크
            if selectedRange.upperBound >= fullRange.upperBound {
                return value >= selectedRange.lowerBound
            }
            
            // 일반적인 경우
            return selectedRange.contains(value)
        }
    }

    private func getGeoEstates(lon: Double, lat: Double, maxD: Double, category: String? = nil, forceUpdate: Bool = false) async {
        model.isLoading = true
        do {
            let estates = try await repository.getGeoEstate(category: category, lon: lon, lat: lat, maxD: maxD)

            model.curEstatesData = estateDataFiltering(estates)

            if let geoEstates = model.curEstatesData {

                model.pinInfoList = geoEstates.toPinInfoList()

            } else {
                model.pinInfoList = []
            }
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
                    await self.getGeoEstates(lon: lon, lat: lat, maxD: maxD, category: self.model.selectedCategory)
                    self.lastGeoEstatesCoordinate = coordinate
                }
            }
        }
    }
    
    private func debounceFilterUpdate() {
        filterDebounceTimer?.invalidate()
        filterDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.applyFiltersAndUpdateMap()
        }
    }
    
    // 기존 locationManager 관련 메서드/Delegate 완전 제거
    // setupLocationManager, requestLocationPermission 등 제거
    // 위치 업데이트는 LocationServiceDelegate에서 처리
    
    // MARK: - LocationServiceDelegate
    func locationService(didUpdateLocation coordinate: CLLocationCoordinate2D) {
        model.currentLocation = coordinate
        model.centerCoordinate = coordinate
        model.shouldDrawMap = true
    }
    func locationService(didFailWithError error: Error) {
        model.currentLocation = LocationService.defaultCoordinate
        model.centerCoordinate = LocationService.defaultCoordinate
        model.shouldDrawMap = true
    }
    func locationService(didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Task {
                if let coordinate = await locationService.requestCurrentLocation() {
                    model.currentLocation = coordinate
                    model.centerCoordinate = coordinate
                    model.shouldDrawMap = true
                }
            }
        case .denied, .restricted:
            model.currentLocation = LocationService.defaultCoordinate
            model.centerCoordinate = LocationService.defaultCoordinate
            model.shouldDrawMap = true
        case .notDetermined:
            // 권한 요청 중이므로 대기
            break
        @unknown default:
            model.currentLocation = LocationService.defaultCoordinate
            model.centerCoordinate = LocationService.defaultCoordinate
            model.shouldDrawMap = true
        }
    }
    
    private func handleError(_ error: Error) {
        model.pinInfoList = []
        if let netError = error as? CustomError, netError == .expiredRefreshToken {
            model.backToLogin = true
        } else {
            model.errorMessage = (error as? CustomError)?.errorDescription ?? error.localizedDescription
        }
    }
}
