//
//  KakaoMapView.swift
//  Anlaka
//
//  Created by 최정안 on 5/22/25.


import SwiftUI
import KakaoMapsSDK
import CoreLocation


struct KakaoMapView: UIViewRepresentable {
    @Binding var draw: Bool
    var centerCoordinate: CLLocationCoordinate2D
    var isInteractive: Bool
    var pinInfoList: [PinInfo]
    var onCenterChanged: (CLLocationCoordinate2D) -> Void
    var onMapReady: ((Double) -> Void)?
    // 새로운 콜백 추가: 지도 변화 시 즉시 호출
    var onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)?
    
    func makeUIView(context: Context) -> KMViewContainer {
        let view = KMViewContainer(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        context.coordinator.createController(view)
        return view
    }
    
    func updateUIView(_ uiView: KMViewContainer, context: Context) {
        guard draw else {
            context.coordinator.controller?.pauseEngine()
            context.coordinator.controller?.resetEngine()
            context.coordinator.clearAllGeolocationPOIs()
            context.coordinator.resetViewAdded()
            return
        }
        
        if context.coordinator.controller?.isEnginePrepared == false {
            context.coordinator.controller?.prepareEngine()
        }
        if context.coordinator.controller?.isEngineActive == false {
            context.coordinator.controller?.activateEngine()
        }
        if context.coordinator.auth {
            context.coordinator.addViews()
            context.coordinator.addCenterPin()
            context.coordinator.updateCenterCoordinate(centerCoordinate)
            context.coordinator.addGeolocationPOIs(pinInfoList)
        }
    }
    
    func makeCoordinator() -> KakaoMapCoordinator {
        return KakaoMapCoordinator(
            onCenterChanged: onCenterChanged,
            centerCoordinate: centerCoordinate,
            isInteractive: isInteractive,
            onMapReady: onMapReady,
            onMapChanged: onMapChanged // 새 콜백 전달
        )
    }
    
    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: KakaoMapCoordinator) {
        coordinator.clearAllGeolocationPOIs()
        coordinator.resetViewAdded()
    }
}
class KakaoMapCoordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {
    var longitude: Double
    var latitude: Double
    var controller: KMController?
    var container: KMViewContainer?
    var first: Bool
    var auth: Bool
    var onCenterChanged: (CLLocationCoordinate2D) -> Void
    var onMapReady: ((Double) -> Void)?
    var onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)? // 새 콜백 추가
    var isInteractive: Bool
    private let geolocationLayerID = "geolocation_layer"
    private var isViewAdded = false
    private var lastCenter: CLLocationCoordinate2D?
    private var lastZoomLevel: Int? // 마지막 줌 레벨 추가
    
    init(
        onCenterChanged: @escaping (CLLocationCoordinate2D) -> Void,
        centerCoordinate: CLLocationCoordinate2D,
        isInteractive: Bool,
        onMapReady: ((Double) -> Void)? = nil,
        onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)? = nil
    ) {
        self.longitude = centerCoordinate.longitude.isFinite ? centerCoordinate.longitude : DefaultValues.Geolocation.longitude.value
        self.latitude = centerCoordinate.latitude.isFinite ? centerCoordinate.latitude : DefaultValues.Geolocation.latitude.value
        self.first = true
        self.auth = false
        self.onCenterChanged = onCenterChanged
        self.onMapReady = onMapReady
        self.onMapChanged = onMapChanged
        self.isInteractive = isInteractive
        super.init()
    }
    
    // 중심 좌표 업데이트 메서드
    func updateCenterCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
        let newLongitude = newCoordinate.longitude.isFinite ? newCoordinate.longitude : DefaultValues.Geolocation.longitude.value
        let newLatitude = newCoordinate.latitude.isFinite ? newCoordinate.latitude : DefaultValues.Geolocation.latitude.value
        
        // 좌표가 실제로 변경되었는지 확인
        if abs(longitude - newLongitude) > 0.0001 || abs(latitude - newLatitude) > 0.0001 {
            longitude = newLongitude
            latitude = newLatitude
            
            // 지도가 준비되었으면 카메라 이동
            guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
            
            let cameraUpdate = CameraUpdate.make(
                target: MapPoint(longitude: longitude, latitude: latitude),
                zoomLevel: kakaoMap.zoomLevel,
                rotation: 0,
                tilt: 0,
                mapView: kakaoMap
            )
            kakaoMap.moveCamera(cameraUpdate)
            
            print("🗺️ 지도 중심 좌표 업데이트: \(longitude), \(latitude)")
        }
    }
    
    func createController(_ view: KMViewContainer) {
        container = view
        controller = KMController(viewContainer: view)
        controller?.delegate = self
    }
    
    func addViews() {
        guard !isViewAdded else {
            print("🗺️ addViews 이미 호출됨, 스킵")
            return
        }
        print("🗺️ addViews 호출됨")
        let defaultPosition = MapPoint(longitude: longitude, latitude: latitude)
        let mapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition)
        controller?.addView(mapviewInfo)
        isViewAdded = true
    }
    
    func resetViewAdded() {
        isViewAdded = false
        print("🗺️ isViewAdded 리셋")
    }
    
    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
        print("🗺️ addViewSucceeded: \(viewName)")
        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
        mapView.viewRect = container!.bounds
        mapView.cameraAnimationEnabled = true
        print("🗺️ 지도 이벤트 델리게이트 등록")
        mapView.eventDelegate = self
        let cameraUpdate = CameraUpdate.make(
            target: MapPoint(longitude: longitude, latitude: latitude),
            zoomLevel: mapView.zoomLevel,
            rotation: 0,
            tilt: 0,
            mapView: mapView
        )
        mapView.moveCamera(cameraUpdate)
        
        // 지도가 준비되면 maxDistance 계산하여 콜백 호출
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let maxDistance = calculateMaxDistanceFromCenter(mapView: mapView, center: center)
        onMapReady?(maxDistance)
    }
    
    func containerDidResized(_ size: CGSize) {
        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
        mapView.viewRect = CGRect(origin: .zero, size: size)
        if first {
            let cameraUpdate = CameraUpdate.make(
                target: MapPoint(longitude: longitude, latitude: latitude),
                zoomLevel: mapView.zoomLevel,
                rotation: 0,
                tilt: 0,
                mapView: mapView
            )
            mapView.moveCamera(cameraUpdate)
            first = false
        }
        print("🗺️ containerDidResized에서 이벤트 델리게이트 설정")
        mapView.eventDelegate = self
    }
    
    func authenticationSucceeded() {
        print("🗺️ 인증 성공")
        auth = true
        addViews()
    }
    
    func calculateMaxDistanceFromCenter(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
        let viewSize = mapView.viewRect.size
        print("🗺️ viewSize: width=\(viewSize.width), height=\(viewSize.height)")
        guard viewSize.width > 0, viewSize.height > 0 else {
            print("🗺️ Invalid viewSize, returning default radius")
            return DefaultValues.Geolocation.maxDistanse.value
        }
        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        let corners = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: viewSize.width, y: 0),
            CGPoint(x: 0, y: viewSize.height),
            CGPoint(x: viewSize.width, y: viewSize.height)
        ]
        let maxPixelDistance = corners
            .map { hypot(centerPoint.x - $0.x, centerPoint.y - $0.y) }
            .max() ?? 0
        print("🗺️ maxPixelDistance: \(maxPixelDistance)")
        let resolution = estimateMapResolution(mapView: mapView, center: center)
        print("🗺️ resolution: \(resolution)")
        guard resolution.isFinite, !resolution.isNaN else {
            print("🗺️ Invalid resolution, returning default radius")
            return DefaultValues.Geolocation.maxDistanse.value
        }
        let maxDistance = maxPixelDistance * resolution
        print("🗺️ maxDistance: \(maxDistance)")
        return maxDistance.isFinite && maxDistance > 0 ? maxDistance : DefaultValues.Geolocation.maxDistanse.value
    }
    
    func estimateMapResolution(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
        let zoomLevel = mapView.zoomLevel
        let minLevel = mapView.minLevel ?? 0
        let maxLevel = mapView.maxLevel ?? 21
        let clampedZoomLevel = max(minLevel, min(maxLevel, zoomLevel))
        let latitude = center.latitude.isFinite ? center.latitude : DefaultValues.Geolocation.latitude.value
        let latitudeRadians = latitude * .pi / 180
        print("🗺️ zoomLevel: \(zoomLevel), clampedZoomLevel: \(clampedZoomLevel), latitude: \(latitude)")
        guard clampedZoomLevel >= minLevel, clampedZoomLevel <= maxLevel, latitude >= -90, latitude <= 90 else {
            print("🗺️ Invalid zoomLevel or latitude, returning fallback resolution")
            return 10.0
        }
        let denominator = pow(2.0, Double(clampedZoomLevel))
        guard denominator > 0, denominator.isFinite else {
            print("🗺️ Invalid denominator in resolution calculation, returning fallback")
            return 10.0
        }
        let resolution = max(156543.03 * cos(latitudeRadians) / denominator, 0.1)
        print("🗺️ Calculated resolution: \(resolution)")
        return resolution.isFinite && !resolution.isNaN ? resolution : 10.0
    }
    
    func cameraDidStopped(kakaoMap: KakaoMap, by: MoveBy) {
        guard isInteractive else {
            print("🗺️ 지도 상호작용 비활성화됨, 스킵")
            return
        }
        
        let viewSize = kakaoMap.viewRect.size
        let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        let cameraPosition = kakaoMap.getPosition(centerPoint)
        let currentZoomLevel = kakaoMap.zoomLevel
        
        let center = CLLocationCoordinate2D(
            latitude: cameraPosition.wgsCoord.latitude.isFinite ? cameraPosition.wgsCoord.latitude : DefaultValues.Geolocation.latitude.value,
            longitude: cameraPosition.wgsCoord.longitude.isFinite ? cameraPosition.wgsCoord.longitude : DefaultValues.Geolocation.longitude.value
        )
        
        // 중심 좌표 또는 줌 레벨 변화 확인
        let centerChanged = lastCenter == nil ||
            abs(lastCenter!.latitude - center.latitude) > 0.0001 ||
            abs(lastCenter!.longitude - center.longitude) > 0.0001
        let zoomChanged = lastZoomLevel == nil || lastZoomLevel != currentZoomLevel
        
        if centerChanged || zoomChanged {
            print("🗺️ 지도 변화 감지됨 - 중심좌표: \(centerChanged), 줌레벨: \(zoomChanged)")
            print("📍 새 중심 좌표: \(center), 줌 레벨: \(currentZoomLevel)")
            
            // maxDistance 재계산
            let maxDistance = calculateMaxDistanceFromCenter(mapView: kakaoMap, center: center)
            
            // 상태 업데이트
            lastCenter = center
            lastZoomLevel = currentZoomLevel
            longitude = center.longitude
            latitude = center.latitude
            
            // 중심 핀 업데이트
            addCenterPin()
            
            // 기존 콜백 호출 (호환성 유지)
            onCenterChanged(center)
            
            // 새로운 콜백 호출 - 즉시 getGeoEstates 호출을 위해
            onMapChanged?(center, maxDistance)
            
        } else {
            print("🗺️ cameraDidStopped 호출됨, 하지만 변화 없음, 스킵")
        }
    }
    
    func addCenterPin() {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            print("KakaoMap을 찾을 수 없습니다.")
            return
        }
        let manager = kakaoMap.getLabelManager()
        setupPOIStyle(manager: manager)
        setupGeolocationLayer(manager: manager)
        clearExistingPOIs(manager: manager)
        
        let poiOption = PoiOptions(
            styleID: "geolocation_style",
            poiID: "center_pin"
        )
        poiOption.rank = 0
        poiOption.clickable = true
        let poiText = PoiText(text: "Center", styleIndex: 0)
        poiOption.addText(poiText)
        let mapPoint = MapPoint(
            longitude: longitude,
            latitude: latitude
        )
        let poi = manager.getLabelLayer(layerID: geolocationLayerID)?.addPoi(option: poiOption, at: mapPoint) { poi in
            poi?.show()
        }
            print("🗺️ Center pin 추가 완료 at (\(longitude), \(latitude))")
        }
    
    func addGeolocationPOIs(_ pinInfos: [PinInfo]) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            print("KakaoMap을 찾을 수 없습니다.")
            return
        }
        let manager = kakaoMap.getLabelManager()
        setupPOIStyle(manager: manager)
        setupGeolocationLayer(manager: manager)
        clearExistingPOIs(manager: manager)
        addPOIsToLayer(manager: manager, pinInfos: pinInfos)
        print("🗺️ \(pinInfos.count)개의 POI 추가 완료")
    }
    
    private func setupPOIStyle(manager: LabelManager) {
        var styles: [PerLevelPoiStyle] = []
        let mapPinImage = createMapPinImage()
        for level in 0...20 {
            let perLevelStyle = PerLevelPoiStyle(
                iconStyle: PoiIconStyle(
                    symbol: mapPinImage,
                    anchorPoint: CGPoint(x: 0.5, y: 1.0)
                ),
                level: level
            )
            styles.append(perLevelStyle)
        }
        let poiStyle = PoiStyle(styleID: "geolocation_style", styles: styles)
        manager.addPoiStyle(poiStyle)
    }
    
    private func createMapPinImage() -> UIImage {
        guard let image = UIImage(systemName: "mappin") else {
            fatalError("map_pin.png 자산이 프로젝트에 없습니다.")
        }
        return image
    }
    
    private func setupGeolocationLayer(manager: LabelManager) {
        if manager.getLabelLayer(layerID: geolocationLayerID) == nil {
            let layerOption = LabelLayerOptions(
                layerID: geolocationLayerID,
                competitionType: .none,
                competitionUnit: .poi,
                orderType: .rank,
                zOrder: 10001
            )
            manager.addLabelLayer(option: layerOption)
        }
    }
    
    private func clearExistingPOIs(manager: LabelManager) {
        guard let layer = manager.getLabelLayer(layerID: geolocationLayerID) else { return }
        layer.clearAllItems()
    }
    
    private func addPOIsToLayer(manager: LabelManager, pinInfos: [PinInfo]) {
        guard let layer = manager.getLabelLayer(layerID: geolocationLayerID) else { return }
        for (index, pinInfo) in pinInfos.enumerated() {
            let poiOption = PoiOptions(
                styleID: "geolocation_style",
                poiID: "geolocation_\(index)"
            )
            poiOption.rank = 0
            poiOption.clickable = true
            let poiText = PoiText(text: pinInfo.title, styleIndex: 0)
            poiOption.addText(poiText)
            let mapPoint = MapPoint(
                longitude: pinInfo.longitude,
                latitude: pinInfo.latitude
            )
            let poi = layer.addPoi(option: poiOption, at: mapPoint)
            poi?.show()
        }
    }
    
    func removeGeolocationPOI(at index: Int) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
        let manager = kakaoMap.getLabelManager()
        guard let layer = manager.getLabelLayer(layerID: geolocationLayerID) else { return }
        layer.removePoi(poiID: "geolocation_\(index)")
    }
    
    func clearAllGeolocationPOIs() {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
        let manager = kakaoMap.getLabelManager()
        guard let layer = manager.getLabelLayer(layerID: geolocationLayerID) else { return }
        layer.clearAllItems()
    }
    
    func toggleGeolocationPOIsVisibility(show: Bool) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
        let manager = kakaoMap.getLabelManager()
        guard let layer = manager.getLabelLayer(layerID: geolocationLayerID) else { return }
        if show {
            layer.showAllPois()
        } else {
            layer.hideAllPois()
        }
    }
}


extension KakaoMapView {
    func addGeolocationPOIs(_ geolocations: [GeolocationEntity]) {
        // coordinator를 통해 POI 추가 메서드 호출
        // 이 메서드는 updateUIView에서 호출되거나, 별도의 바인딩을 통해 호출될 수 있습니다.
    }
    
    // 편의 메서드들
    func updateGeolocationPOIs(_ geolocations: [GeolocationEntity]) {
        // coordinator의 메서드를 호출하는 래퍼
    }
    
    func clearPOIs() {
        // POI 제거 래퍼
    }
    
    func togglePOIVisibility(show: Bool) {
        // POI 표시/숨김 래퍼
    }
}
