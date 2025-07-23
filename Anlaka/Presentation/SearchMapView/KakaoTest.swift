////
////  KakaoTest.swift
////  Anlaka
////
////  Created by 최정안 on 5/22/25.
////
//
//import SwiftUI
//import CoreLocation
//import KakaoMapsSDK
//
//
//// MARK: - 최적화된 KakaoMapCoordinator
//class OptimizedKakaoMapCoordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {
//    
//    // 기본 속성들
//    var longitude: Double
//    var latitude: Double
//    var controller: KMController?
//    var container: KMViewContainer?
//    var first: Bool
//    var auth: Bool
//    var onCenterChanged: (CLLocationCoordinate2D) -> Void
//    var onMapReady: ((Double) -> Void)?
//    var onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)?
//    var isInteractive: Bool
//    
//    // 최적화 관련
//    private let geolocationLayerID = "geolocation_layer"
//    private var isViewAdded = false
//    private var lastCenter: CLLocationCoordinate2D?
//    private var lastZoomLevel: Int?
//    private var radius: Float = 20.0
//    
//    // 차분 업데이트 + 캐시 관리자
//    private let dataManager = OptimizedDataManager()
//    
//    // 디바운스 관련
//    private var pendingDataRequest: DispatchWorkItem?
//    private let requestDebounceTime: TimeInterval = 0.3
//    
//    init(
//        onCenterChanged: @escaping (CLLocationCoordinate2D) -> Void,
//        centerCoordinate: CLLocationCoordinate2D,
//        isInteractive: Bool,
//        onMapReady: ((Double) -> Void)? = nil,
//        onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)? = nil
//    ) {
//        self.longitude = centerCoordinate.longitude.isFinite ? centerCoordinate.longitude : 126.9780
//        self.latitude = centerCoordinate.latitude.isFinite ? centerCoordinate.latitude : 37.5665
//        self.first = true
//        self.auth = false
//        self.onCenterChanged = onCenterChanged
//        self.onMapReady = onMapReady
//        self.onMapChanged = onMapChanged
//        self.isInteractive = isInteractive
//        super.init()
//    }
//    
//    // MARK: - 차분 업데이트 메인 메서드
//    func updatePinInfosWithDifferentialUpdate(_ newPinInfos: [PinInfo]) {
//        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        
//        dataManager.processDifferentialUpdate(
//            newData: newPinInfos,
//            center: center
//        ) { [weak self] itemsToRemove, itemsToAdd, itemsToUpdate in
//            DispatchQueue.main.async {
//                self?.performDifferentialPOIUpdate(
//                    toRemove: itemsToRemove,
//                    toAdd: itemsToAdd,
//                    toUpdate: itemsToUpdate
//                )
//            }
//        }
//    }
//    
//    // POI 차분 업데이트 실행
//    private func performDifferentialPOIUpdate(toRemove: [String], toAdd: [PinInfo], toUpdate: [PinInfo]) {
//        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
//        let manager = kakaoMap.getLabelManager()
//        guard let layer = manager.getLodLabelLayer(layerID: geolocationLayerID) else { return }
//        
//        // 1. POI 제거
//        for pinInfoId in toRemove {
//            if let poiId = dataManager.getPOIId(for: pinInfoId) {
//                layer.removeLodPoi(poiID: poiId)
//                dataManager.removePOIMapping(pinInfoId)
//                print("🗑️ POI 제거: \(pinInfoId)")
//            }
//        }
//        
//        // 2. POI 추가
//        if !toAdd.isEmpty {
//            let (poiOptions, positions) = createPOIOptionsAndPositions(from: toAdd)
//            layer.addLodPois(options: poiOptions, at: positions)
//            
//            // 매핑 정보 업데이트
//            for (index, pinInfo) in toAdd.enumerated() {
//                dataManager.updatePOIMapping(pinInfo.estateId, poiId: poiOptions[index].itemID!)
//            }
//            print("➕ POI 추가: \(toAdd.count)개")
//        }
//        
//        // 3. POI 업데이트 (제거 후 재추가)
//        for pinInfo in toUpdate {
//            if let poiId = dataManager.getPOIId(for: pinInfo.estateId) {
//                layer.removeLodPoi(poiID: poiId)
//                
//                let (poiOptions, positions) = createPOIOptionsAndPositions(from: [pinInfo])
//                layer.addLodPois(options: poiOptions, at: positions)
//                
//                dataManager.updatePOIMapping(pinInfo.estateId, poiId: poiOptions[0].itemID!)
//                print("🔄 POI 업데이트: \(pinInfo.estateId)")
//            }
//        }
//        
//        layer.showAllLodPois()
//    }
//    
//    // MARK: - 캐시 우선 데이터 처리
//    func handleMapChangeWithCache(center: CLLocationCoordinate2D, radius: Double) -> Bool {
//        // 캐시된 데이터 먼저 확인
//        if let cachedData = dataManager.getCachedDataForRegion(center: center, radius: radius) {
//            print("✅ 캐시 데이터 사용: \(cachedData.count)개")
//            updatePinInfosWithDifferentialUpdate(cachedData)
//            return true // 캐시 데이터 사용됨
//        } else {
//            print("🌐 새로운 데이터 요청 필요")
//            return false // 새로운 데이터 요청 필요
//        }
//    }
//    
//    // MARK: - 기존 메서드들 (수정됨)
//    
//    func updateCenterCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
//        let newLongitude = newCoordinate.longitude.isFinite ? newCoordinate.longitude : 126.9780
//        let newLatitude = newCoordinate.latitude.isFinite ? newCoordinate.latitude : 37.5665
//        
//        if abs(longitude - newLongitude) > 0.0001 || abs(latitude - newLatitude) > 0.0001 {
//            longitude = newLongitude
//            latitude = newLatitude
//            
//            guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
//            
//            let cameraUpdate = CameraUpdate.make(
//                target: MapPoint(longitude: longitude, latitude: latitude),
//                zoomLevel: 15,
//                rotation: 0,
//                tilt: 0,
//                mapView: kakaoMap
//            )
//            kakaoMap.moveCamera(cameraUpdate)
//            
//            print("🗺️ 지도 중심 좌표 업데이트: \(longitude), \(latitude)")
//        }
//    }
//    
//    func cameraDidStopped(kakaoMap: KakaoMap, by: MoveBy) {
//        guard isInteractive else {
//            print("🗺️ 지도 상호작용 비활성화됨, 스킵")
//            return
//        }
//        
//        // 기존 펜딩 요청 취소 (디바운스)
//        pendingDataRequest?.cancel()
//        
//        // 새로운 요청 스케줄링
//        pendingDataRequest = DispatchWorkItem { [weak self] in
//            self?.handleCameraStopWithOptimization(kakaoMap: kakaoMap, by: by)
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + requestDebounceTime, execute: pendingDataRequest!)
//    }
//    
//    private func handleCameraStopWithOptimization(kakaoMap: KakaoMap, by: MoveBy) {
//        let viewSize = kakaoMap.viewRect.size
//        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
//        let cameraPosition = kakaoMap.getPosition(centerPoint)
//        let currentZoomLevel = kakaoMap.zoomLevel
//        
//        let center = CLLocationCoordinate2D(
//            latitude: cameraPosition.wgsCoord.latitude.isFinite ? cameraPosition.wgsCoord.latitude : 37.5665,
//            longitude: cameraPosition.wgsCoord.longitude.isFinite ? cameraPosition.wgsCoord.longitude : 126.9780
//        )
//        
//        let centerChanged = lastCenter == nil ||
//        abs(lastCenter!.latitude - center.latitude) > 0.0001 ||
//        abs(lastCenter!.longitude - center.longitude) > 0.0001
//        let zoomChanged = lastZoomLevel == nil || lastZoomLevel != currentZoomLevel
//        
//        if centerChanged || zoomChanged {
//            print("🗺️ 지도 변화 감지됨 - 중심좌표: \(centerChanged), 줌레벨: \(zoomChanged)")
//            
//            let maxDistance = calculateMaxDistanceFromCenter(mapView: kakaoMap, center: center)
//            
//            lastCenter = center
//            lastZoomLevel = currentZoomLevel
//            longitude = center.longitude
//            latitude = center.latitude
//            
//            onCenterChanged(center)
//            onMapChanged?(center, maxDistance)
//            
//            // 캐시 우선 데이터 처리 - 캐시 데이터가 없을 때만 새로운 데이터 요청
//            let usedCache = handleMapChangeWithCache(center: center, radius: maxDistance)
//            if !usedCache {
//                // 여기서 새로운 데이터 요청을 위한 콜백을 호출할 수 있음
//                // 예: onMapChanged에서 새로운 데이터를 가져온 후 updatePinInfosWithDifferentialUpdate 호출
//            }
//        }
//    }
//    
//    // MARK: - 헬퍼 메서드들
//    
//    private func createPOIOptionsAndPositions(from pinInfos: [PinInfo]) -> ([PoiOptions], [MapPoint]) {
//        var poiOptions: [PoiOptions] = []
//        var positions: [MapPoint] = []
//        
//        for (index, pinInfo) in pinInfos.enumerated() {
//            let styleId = "geolocation_style_\(pinInfo.estateId)"
//            let poiOption = PoiOptions(
//                styleID: styleId,
//                poiID: "poi_\(pinInfo.estateId)_\(UUID().uuidString)"
//            )
//            poiOption.rank = index
//            poiOption.clickable = true
//            poiOption.addText(PoiText(text: pinInfo.title, styleIndex: 0))
//            
//            poiOptions.append(poiOption)
//            positions.append(MapPoint(longitude: pinInfo.longitude, latitude: pinInfo.latitude))
//        }
//        
//        return (poiOptions, positions)
//    }
//    
//    // MARK: - 기존 설정 메서드들
//    
//    func createController(_ view: KMViewContainer) {
//        container = view
//        controller = KMController(viewContainer: view)
//        controller?.delegate = self
//    }
//    
//    func addViews() {
//        guard !isViewAdded else {
//            print("🗺️ addViews 이미 호출됨, 스킵")
//            return
//        }
//        print("🗺️ addViews 호출됨")
//        let defaultPosition = MapPoint(longitude: longitude, latitude: latitude)
//        let mapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition)
//        controller?.addView(mapviewInfo)
//        isViewAdded = true
//    }
//    
//    func resetViewAdded() {
//        isViewAdded = false
//        dataManager.clearAll() // 이 줄 추가
//        print("🗺️ isViewAdded 리셋 및 데이터 매니저 초기화")
//    }
//    
//    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
//        print("🗺️ addViewSucceeded: \(viewName)")
//        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
//        mapView.viewRect = container!.bounds
//        mapView.cameraAnimationEnabled = true
//        mapView.eventDelegate = self
//        
//        let cameraUpdate = CameraUpdate.make(
//            target: MapPoint(longitude: longitude, latitude: latitude),
//            zoomLevel: mapView.zoomLevel,
//            rotation: 0,
//            tilt: 0,
//            mapView: mapView
//        )
//        mapView.moveCamera(cameraUpdate)
//        
//        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//        let maxDistance = calculateMaxDistanceFromCenter(mapView: mapView, center: center)
//        onMapReady?(maxDistance)
//    }
//    
//    func containerDidResized(_ size: CGSize) {
//        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
//        mapView.viewRect = CGRect(origin: .zero, size: size)
//        if first {
//            let cameraUpdate = CameraUpdate.make(
//                target: MapPoint(longitude: longitude, latitude: latitude),
//                zoomLevel: mapView.zoomLevel,
//                rotation: 0,
//                tilt: 0,
//                mapView: mapView
//            )
//            mapView.moveCamera(cameraUpdate)
//            first = false
//        }
//        mapView.eventDelegate = self
//    }
//    
//    func authenticationSucceeded() {
//        print("🗺️ 인증 성공")
//        auth = true
//        addViews()
//    }
//    
//    func calculateMaxDistanceFromCenter(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
//        let viewSize = mapView.viewRect.size
//        guard viewSize.width > 0, viewSize.height > 0 else {
//            return 5000.0 // 기본값
//        }
//        
//        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
//        let corners = [
//            CGPoint(x: 0, y: 0),
//            CGPoint(x: viewSize.width, y: 0),
//            CGPoint(x: 0, y: viewSize.height),
//            CGPoint(x: viewSize.width, y: viewSize.height)
//        ]
//        
//        let maxPixelDistance = corners
//            .map { hypot(centerPoint.x - $0.x, centerPoint.y - $0.y) }
//            .max() ?? 0
//        
//        let resolution = estimateMapResolution(mapView: mapView, center: center)
//        let maxDistance = maxPixelDistance * resolution
//        
//        return maxDistance.isFinite && maxDistance > 0 ? maxDistance : 5000.0
//    }
//    
//    func estimateMapResolution(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
//        let zoomLevel = mapView.zoomLevel
//        let minLevel = mapView.minLevel
//        let maxLevel = mapView.maxLevel
//        let clampedZoomLevel = max(minLevel, min(maxLevel, zoomLevel))
//        let latitude = center.latitude.isFinite ? center.latitude : 37.5665
//        let latitudeRadians = latitude * .pi / 180
//        
//        guard clampedZoomLevel >= minLevel, clampedZoomLevel <= maxLevel, latitude >= -90, latitude <= 90 else {
//            return 10.0
//        }
//        
//        let denominator = pow(2.0, Double(clampedZoomLevel))
//        guard denominator > 0, denominator.isFinite else {
//            return 10.0
//        }
//        
//        let resolution = max(156543.03 * cos(latitudeRadians) / denominator, 0.1)
//        return resolution.isFinite && !resolution.isNaN ? resolution : 10.0
//    }
//    
//    // MARK: - 공개 메서드들
//    
//    func addGeolocationPOIs(_ pinInfos: [PinInfo]) async {
//        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
//            print("KakaoMap을 찾을 수 없습니다.")
//            return
//        }
//        let manager = kakaoMap.getLabelManager()
//        
//        // 각 POI별로 스타일 설정
//        for pinInfo in pinInfos {
//            await setupPOIStyle(manager: manager, for: pinInfo)
//        }
//        
//        setupGeolocationLodLayer(manager: manager)
//        clearExistingPOIs(manager: manager)
//        
//        // POI 추가 로직
//        guard let layer = manager.getLodLabelLayer(layerID: geolocationLayerID) else { return }
//        
//        var poiOptions: [PoiOptions] = []
//        var positions: [MapPoint] = []
//        
//        for (index, pinInfo) in pinInfos.enumerated() {
//            let styleId = "geolocation_style_\(pinInfo.estateId)"
//            let poiOption = PoiOptions(
//                styleID: styleId,
//                poiID: "poi_\(pinInfo.estateId)_\(UUID().uuidString)"
//            )
//            poiOption.rank = index
//            poiOption.clickable = true
//            poiOption.addText(PoiText(text: pinInfo.title, styleIndex: 0))
//            
//            poiOptions.append(poiOption)
//            positions.append(MapPoint(longitude: pinInfo.longitude, latitude: pinInfo.latitude))
//            
//            // POI ID 매핑 정보 저장
//            dataManager.updatePOIMapping(pinInfo.estateId, poiId: poiOption.itemID!)
//        }
//        
//        // 대량 POI 추가
//        layer.addLodPois(options: poiOptions, at: positions)
//        layer.showAllLodPois()
//        
//        print("🗺️ \(pinInfos.count)개의 LodPOI 추가 완료")
//    }
//    
//    func clearAllGeolocationPOIs() {
//        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
//        let manager = kakaoMap.getLabelManager()
//        guard let layer = manager.getLodLabelLayer(layerID: geolocationLayerID) else { return }
//        layer.clearAllItems()
//        dataManager.clearAll()
//        print("🗑️ 모든 POI 및 매핑 정보 삭제")
//    }
//    
//    func toggleGeolocationPOIsVisibility(show: Bool) {
//        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
//        let manager = kakaoMap.getLabelManager()
//        guard let layer = manager.getLodLabelLayer(layerID: geolocationLayerID) else { return }
//        if show {
//            layer.showAllLodPois()
//        } else {
//            layer.hideAllLodPois()
//        }
//    }
//}
//
//// MARK: - 최적화된 KakaoMapView
//struct OptimizedKakaoMapView: UIViewRepresentable {
//    @Binding var draw: Bool
//    var centerCoordinate: CLLocationCoordinate2D
//    var isInteractive: Bool
//    var pinInfoList: [PinInfo]
//    var onCenterChanged: (CLLocationCoordinate2D) -> Void
//    var onMapReady: ((Double) -> Void)?
//    var onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)?
//    
//    func makeUIView(context: Context) -> KMViewContainer {
//        let view = KMViewContainer(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
//        context.coordinator.createController(view)
//        return view
//    }
//    
//    func updateUIView(_ uiView: KMViewContainer, context: Context) async {
//        guard draw else {
//            context.coordinator.controller?.pauseEngine()
//            context.coordinator.controller?.resetEngine()
//            context.coordinator.clearAllGeolocationPOIs()
//            context.coordinator.resetViewAdded()
//            return
//        }
//        
//        if context.coordinator.controller?.isEnginePrepared == false {
//            context.coordinator.controller?.prepareEngine()
//        }
//        
//        if context.coordinator.controller?.isEngineActive == false {
//            context.coordinator.controller?.activateEngine()
//        }
//        
//        // 중심 좌표 업데이트
//        context.coordinator.updateCenterCoordinate(centerCoordinate)
//        
//        // 차분 업데이트로 POI 처리
//        if !pinInfoList.isEmpty {
//            context.coordinator.addGeolocationPOIs(pinInfoList)
//        }
//    }
//    
//    func makeCoordinator() -> OptimizedKakaoMapCoordinator {
//        return OptimizedKakaoMapCoordinator(
//            onCenterChanged: onCenterChanged,
//            centerCoordinate: centerCoordinate,
//            isInteractive: isInteractive,
//            onMapReady: onMapReady,
//            onMapChanged: onMapChanged
//        )
//    }
//}
