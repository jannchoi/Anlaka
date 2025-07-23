//
//  Coordinator.swift
//  Anlaka
//
//  Created by 최정안 on 5/31/25.
//

import SwiftUI
import KakaoMapsSDK
import CoreLocation


class Coordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {
    var controller: KMController?
    var container: KMViewContainer?
    var isViewAdded = false
    var onMapReady: ((Double) -> Void)?
    var onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)?
    var longitude: Double
    var latitude: Double
    
    // debounce를 위한 타이머 추가
    private var debounceTimer: Timer?
    
    private let layerID = "poi_layer"
    private let defaultStyleID = "default_style"
    private let poiImageSize = CGSize(width: 40, height: 40)
    
    // 추가 프로퍼티들
    private var currentPOIs: [String: Poi] = [:]  // estateId -> POI 매핑
    private var currentPinInfos: [String: PinInfo] = [:]  // estateId -> PinInfo 매핑
    private var currentStyleIds: [String: String] = [:]  // estateId -> styleId 매핑
    private var lastMaxDistance: Double = 0
    private var lastCenter: CLLocationCoordinate2D?
    private var metersPerPt: Double = 0
    private var lastZoomLevel: Int = 0  // 마지막 줌 레벨 저장
    
    // 이전 모서리 좌표 저장
    private var previousTopLeft: CLLocationCoordinate2D?
    private var previousBottomRight: CLLocationCoordinate2D?
    
    // 클러스터링 관련 프로퍼티 추가 (기존 Coordinator 클래스에 추가)
    private var onClusterTap: ((ClusterInfo) -> Void)?
    private var onPOITap: ((String) -> Void)?
    private var onPOIGroupTap: (([String]) -> Void)?
    private var clusters: [String: ClusterInfo] = [:]  // clusterID -> ClusterInfo
    
    
    init(
        centerCoordinate: CLLocationCoordinate2D,
        onMapReady: ((Double) -> Void)? = nil,
        onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)? = nil
    ) {
        //print(#function)
        self.longitude = centerCoordinate.longitude
        self.latitude = centerCoordinate.latitude
        self.onMapReady = onMapReady
        self.onMapChanged = onMapChanged
        super.init()
    }
    
    func createController(_ view: KMViewContainer) {
        //print(#function)
        container = view
        controller = KMController(viewContainer: view)
        controller?.delegate = self
    }
    
    func addViews() {
        //print(#function)
        guard !isViewAdded else { return }
        let defaultPosition = MapPoint(longitude: longitude, latitude: latitude)
        let mapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition)
        controller?.addView(mapviewInfo)
        
        // 스케일바 추가
        if let mapView = controller?.getView("mapview") as? KakaoMap {
            mapView.setScaleBarPosition(origin: GuiAlignment(vAlign: .bottom, hAlign: .right), position: CGPoint(x: 10.0, y: 10.0))
            mapView.showScaleBar()
        }
        
        isViewAdded = true
    }
    
    func authenticationSucceeded() {
        //print(#function)
        addViews()
    }
    
    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
        //print(#function)
        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
        mapView.viewRect = container!.bounds
        mapView.setScaleBarPosition(origin: GuiAlignment(vAlign: .bottom, hAlign: .right), position: CGPoint(x: 10.0, y: 10.0))
        mapView.showScaleBar()
        mapView.eventDelegate = self
        setupPOILayer(mapView)
        
        let cameraUpdate = CameraUpdate.make(
            target: MapPoint(longitude: longitude, latitude: latitude),
            zoomLevel: 14,
            rotation: 0,
            tilt: 0,
            mapView: mapView
        )
        mapView.moveCamera(cameraUpdate)
        
        let maxDistance = calculateMaxDistance(mapView: mapView)
        onMapReady?(maxDistance)
        
        
    }
    
    func containerDidResized(_ size: CGSize) {
        //print(#function)
        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
        mapView.viewRect = CGRect(origin: .zero, size: size)
        mapView.eventDelegate = self
    }
    
    func updateCenterCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
        //print(#function)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return }
        
        // 현재 카메라 위치와 새로운 좌표의 차이가 유의미한 경우에만 이동
        let currentCenter = kakaoMap.getPosition(CGPoint(x: kakaoMap.viewRect.width / 2, y: kakaoMap.viewRect.height / 2))
        let currentLat = currentCenter.wgsCoord.latitude
        let currentLon = currentCenter.wgsCoord.longitude
        
        // 좌표 차이가 일정 값(0.0001) 이상일 때만 카메라 이동
        if abs(currentLat - newCoordinate.latitude) > 0.0001 ||
            abs(currentLon - newCoordinate.longitude) > 0.0001 {
            longitude = newCoordinate.longitude
            latitude = newCoordinate.latitude
            
            let cameraUpdate = CameraUpdate.make(
                target: MapPoint(longitude: longitude, latitude: latitude),
                zoomLevel: kakaoMap.zoomLevel,
                rotation: 0,
                tilt: 0,
                mapView: kakaoMap
            )
            kakaoMap.moveCamera(cameraUpdate)
        }
    }
    
    func cameraDidStopped(kakaoMap: KakaoMap, by: MoveBy) {
        //print(#function)
        // 현재 줌 레벨과 좌표 정보 출력
        let currentZoomLevel = kakaoMap.zoomLevel

        // 뷰의 좌상단과 우상단 좌표 계산
        let topLeftPoint = kakaoMap.getPosition(CGPoint(x: 0, y: 0))
        let topRightPoint = kakaoMap.getPosition(CGPoint(x: kakaoMap.viewRect.width, y: 0))

        // 좌상단과 우상단 사이의 실제 거리 계산 (미터)
        let topLeftLocation = CLLocation(latitude: topLeftPoint.wgsCoord.latitude, longitude: topLeftPoint.wgsCoord.longitude)
        let topRightLocation = CLLocation(latitude: topRightPoint.wgsCoord.latitude, longitude: topRightPoint.wgsCoord.longitude)
        let distanceInMeters = topLeftLocation.distance(from: topRightLocation)
        metersPerPt = distanceInMeters / Double(kakaoMap.viewRect.width)

        // 이전 타이머가 있다면 취소
        debounceTimer?.invalidate()
        
        // 새로운 타이머 생성 (1초 후에 실행)
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            let centerPoint = CGPoint(x: kakaoMap.viewRect.width / 2, y: kakaoMap.viewRect.height / 2)
            let position = kakaoMap.getPosition(centerPoint)
            let center = CLLocationCoordinate2D(
                latitude: position.wgsCoord.latitude,
                longitude: position.wgsCoord.longitude
            )
            
            self.longitude = center.longitude
            self.latitude = center.latitude
            
            let maxDistance = self.calculateMaxDistance(mapView: kakaoMap)
            self.onMapChanged?(center, maxDistance)
        }
    }
    
    func calculateMaxDistance(mapView: KakaoMap) -> Double {
        //print(#function)
        let viewSize = mapView.viewRect.size
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
        
        let resolution = estimateMapResolution(mapView: mapView)
        return maxPixelDistance * resolution
    }
    
    private func estimateMapResolution(mapView: KakaoMap) -> Double {
        //print(#function)
        let zoomLevel = mapView.zoomLevel
        let latitudeRadians = latitude * .pi / 180
        return 156543.03 * cos(latitudeRadians) / pow(2.0, Double(zoomLevel))
    }
    
    
    private func setupPOILayer(_ mapView: KakaoMap) {
        //print(#function)
        let manager = mapView.getLabelManager()
        
        // SimplePOI 예제와 동일한 레이어 옵션 사용
        let layerOption = LabelLayerOptions(
            layerID: layerID,
            competitionType: .none,  // SimplePOI와 동일하게 .none 사용
            competitionUnit: .poi,   // SimplePOI와 동일하게 .poi 사용
            orderType: .rank,
            zOrder: 10001
        )
        manager.addLabelLayer(option: layerOption)
    }

    func clearAllPOIs() {
        //print(#function)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID) else { return }
        layer.clearAllItems()
        clusters.removeAll()

    }
    
}

// MARK: - 효율적인 POI 업데이트 메서드 (기존 updatePOIs 대체)
extension Coordinator {

    /// POI들을 제거하는 메서드
    private func removePOIs(_ estateIds: [String], from layer: LabelLayer) {
        //print(#function)
        var removedCount = 0
        
        for estateId in estateIds {
            if let poi = currentPOIs[estateId] {
                poi.hide()
                layer.removePoi(poiID: poi.itemID)
                currentPOIs.removeValue(forKey: estateId)
                currentPinInfos.removeValue(forKey: estateId)
                currentStyleIds.removeValue(forKey: estateId)
                removedCount += 1
            }
        }
        
        if removedCount > 0 {
            //print("🗑️ POI \(removedCount)개 제거 완료")
        }
    }
    
    /// POI들을 추가하는 메서드
    private func addPOIs(_ poiOptionsArray: [(poiData: (pinInfo: PinInfo, image: UIImage, index: Int), styleID: String, poiOption: PoiOptions)], to layer: LabelLayer) {
        //print(#function)
        var addedCount = 0
        
        for poiOptionData in poiOptionsArray {
            let poiData = poiOptionData.poiData
            let poiOption = poiOptionData.poiOption
            let styleID = poiOptionData.styleID
            
            let poi = layer.addPoi(
                option: poiOption,
                at: MapPoint(longitude: poiData.pinInfo.longitude, latitude: poiData.pinInfo.latitude),
                callback: { result in
                    // 콜백 처리
                }
            )
            
            if let poi = poi {
                poi.show()
                
                // 상태 저장
                currentPOIs[poiData.pinInfo.estateId] = poi
                currentPinInfos[poiData.pinInfo.estateId] = poiData.pinInfo
                currentStyleIds[poiData.pinInfo.estateId] = styleID
                
                addedCount += 1
            }
        }
        
        if addedCount > 0 {
            // print("✅ POI \(addedCount)개 추가 완료")
        }
    }

}

extension Coordinator {
    
    
    // 초기화 메서드 수정 (기존 init에 추가)
    convenience init(
        centerCoordinate: CLLocationCoordinate2D,
        onMapReady: ((Double) -> Void)? = nil,
        onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)? = nil,
        onClusterTap: ((ClusterInfo) -> Void)? = nil,
        onPOITap: ((String) -> Void)? = nil,
        onPOIGroupTap: (([String]) -> Void)? = nil
    ) {
        self.init(centerCoordinate: centerCoordinate,onMapReady: onMapReady, onMapChanged: onMapChanged)
        self.onClusterTap = onClusterTap
        self.onPOITap = onPOITap
        self.onPOIGroupTap = onPOIGroupTap
    }
    
    // MARK: - 줌 레벨에 따른 클러스터링 타입 결정
    private func getClusteringType(for zoomLevel: Int) -> ClusteringType {
        //print(#function, "🔷\(zoomLevel)")
        if zoomLevel >= 6 && zoomLevel <= 14 {
            return .zoomLevel6to14
        } else {
            return .zoomLevel15Plus
        }
    }
    
    // MARK: - 클러스터링 메인 메서드
    private func performClustering(_ pinInfos: [PinInfo], zoomLevel: Int) -> ([ClusterInfo], CGFloat?) {
        //print(#function, pinInfos.count)
        let clusteringType = getClusteringType(for: zoomLevel)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return ([], 0) }
        
        switch clusteringType {
        case .zoomLevel6to14:
            return clusterPinInfosDynamicWeighted_new(pinInfos, kakaoMap: kakaoMap)
        case .zoomLevel15Plus:
            return clusterPinInfosDynamicWeighted_new(pinInfos, kakaoMap: kakaoMap)
        }
    }
    
    func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let R = 6371000.0 // 지구 반지름 (미터)
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }
    
    func gridIndexForPin(
        pin: CLLocationCoordinate2D,
        origin: CLLocationCoordinate2D,
        gridWidth: Double,
        gridHeight: Double
    ) -> (Int, Int) {
        // origin을 기준으로 거리 측정
        let eastPoint = CLLocationCoordinate2D(latitude: origin.latitude, longitude: pin.longitude)
        let northPoint = CLLocationCoordinate2D(latitude: pin.latitude, longitude: origin.longitude)
        
        let dx = haversineDistance(from: origin, to: eastPoint)
        let dy = haversineDistance(from: origin, to: northPoint)
        
        // 방향 보정 (왼쪽/아래인 경우 음수)
        let signedDx = pin.longitude < origin.longitude ? -dx : dx
        let signedDy = pin.latitude < origin.latitude ? -dy : dy
        
        let gridX = Int(signedDx / gridWidth)
        let gridY = Int(signedDy / gridHeight)
        
        return (gridX, gridY)
    }
    
    private func coordinateForGridCenter(
        gridX: Int,
        gridY: Int,
        origin: CLLocationCoordinate2D,
        gridWidth: Double,
        gridHeight: Double
    ) -> CLLocationCoordinate2D {
        //print(#function)
        // 격자의 중심까지 위도/경도를 이동
        let centerOffsetX = Double(gridX) + 0.5
        let centerOffsetY = Double(gridY) + 0.5
        
        let metersPerDegreeLat = 111_000.0
        let metersPerDegreeLon = 111_000.0 * cos(origin.latitude * .pi / 180)
        
        let deltaLat = (gridHeight * centerOffsetY) / metersPerDegreeLat
        let deltaLon = (gridWidth * centerOffsetX) / metersPerDegreeLon
        
        return CLLocationCoordinate2D(
            latitude: origin.latitude + deltaLat,
            longitude: origin.longitude + deltaLon
        )
    }
    
    // MARK: - 좌표 기반 클러스터링 알고리즘
    func clusterPinInfosDynamicWeighted_new(
        _ pinInfos: [PinInfo],
        kakaoMap: KakaoMap
    ) -> ([ClusterInfo], CGFloat) {
        //print(#function, pinInfos.count)
        guard !pinInfos.isEmpty else { return ([], 0) }
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return ([], 0) }
        // 1. 화면 모서리 좌표
        let mapViewSize = kakaoMap.viewRect
        let topLeft = kakaoMap.getPosition(CGPoint(x: 0, y: 0)).wgsCoord.clLocationCoordinate
        let bottomRight = kakaoMap.getPosition(CGPoint(x: mapViewSize.width, y: mapViewSize.height)).wgsCoord.clLocationCoordinate
        let bottomLeft = kakaoMap.getPosition(CGPoint(x: 0, y: mapViewSize.height)).wgsCoord.clLocationCoordinate
        //let topRight = kakaoMap.getPosition(CGPoint(x: mapViewSize.width, y: 0)).wgsCoord.clLocationCoordinate
        
        // 2. 실제 거리 기반 가로/세로 계산
        let totalWidth = haversineDistance(from: bottomLeft, to: bottomRight)
        let totalHeight = haversineDistance(from: bottomLeft, to: topLeft)
        
        let gridWidth = totalWidth / 3
        let gridHeight = totalHeight / 6
        
        // 3. poiSize 계산 (gridWidth 기준)
        let maxPoiSize = kakaoMap.viewRect.width / 3 * 0.6
        
        // 4. 격자 클러스터링
        var gridClusters: [String: [PinInfo]] = [:]
        
        for pin in pinInfos {
            let pinCoord = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let (gridX, gridY) = gridIndexForPin(pin: pinCoord, origin: bottomLeft, gridWidth: gridWidth, gridHeight: gridHeight)
            
            guard gridX >= 0, gridX < 3, gridY >= 0, gridY < 6 else { continue }
            let key = "\(gridX)_\(gridY)"
            gridClusters[key, default: []].append(pin)
        }
        
        // 5. ClusterInfo 생성
        var clusterInfos: [ClusterInfo] = []
        
        for (key, clusterPins) in gridClusters {
            let count = clusterPins.count
            let estateIds = clusterPins.map { $0.estateId }
            
            // key에서 gridX, gridY 추출
            let parts = key.split(separator: "_")
            guard parts.count == 2,
                  let gridX = Int(parts[0]),
                  let gridY = Int(parts[1]) else { continue }
            
            let centerCoord = coordinateForGridCenter(
                gridX: gridX,
                gridY: gridY,
                origin: bottomLeft,
                gridWidth: gridWidth,
                gridHeight: gridHeight
            )
            
            let cluster = ClusterInfo(
                estateIds: estateIds,
                centerCoordinate: centerCoord,
                count: count,
                representativeImage: clusterPins.first?.image
            )
            
            clusterInfos.append(cluster)
        }
        //print("🔍 clusterInfos 생성 성공: \(clusterInfos.count)")
        return (clusterInfos, maxPoiSize)
    }
    
    // MARK: - 원형 이미지 생성 (매물 수 표시용)
    private func createCircleImage(count: Int, poiSize: CGFloat?) -> UIImage {
        //print("🔍 createCircleImage - 시작: count=\(count), poiSize=\(String(describing: poiSize))")
        let size = CGSize(width: poiSize ?? 50, height: poiSize ?? 50)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // Assets의 원형 배경 이미지
            if let backgroundImage = UIImage(named: "Ellipse") {
                //print("✅ Ellipse 이미지 로드 성공")
                backgroundImage.draw(in: rect)
            } else {
                print("❌ Ellipse 이미지 로드 실패")
            }

            // 텍스트
            let text = "\(count)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: count > 99 ? 10 : 12),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        //print("✅ createCircleImage - 이미지 생성 완료: size=\(image.size), scale=\(image.scale)")
        return image
    }

    
    // MARK: - POI 배지 추가 (zoomLevel 17용)
    @MainActor
    private func addBadgeToPOI(_ poi: Poi, count: Int) {
        //print(#function)
        if count > 1 {
            let badgeImage = createBadgeImage(count: count)
            let badge = PoiBadge(
                badgeID: "count_badge",
                image: badgeImage,
                offset: CGPoint(x: 0.1, y: 0.1),
                zOrder: 1
            )
            poi.addBadge(badge)
            poi.showBadge(badgeID: "count_badge")
        }
    }
    
    // MARK: - 배지 이미지 생성
    private func createBadgeImage(count: Int) -> UIImage {
        //print("🔍 createBadgeImage - 시작: count=\(count)")
        let size = CGSize(width: 13, height: 13)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cgContext = context.cgContext
            
            cgContext.setFillColor(UIColor.softSage.cgColor)
            cgContext.fillEllipse(in: rect)
            
            // 텍스트
            let text = "\(count)"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.mainText
            ]
            
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
        }
        
        //print("✅ createBadgeImage - 이미지 생성 완료: size=\(image.size), scale=\(image.scale)")
        return image
    }
}

// MARK: - 클러스터링 기반 POI 업데이트 메서드 (기존 updatePOIsEfficiently 대체)
extension Coordinator {
    
    @MainActor func updatePOIsWithClustering(_ pinInfos: [PinInfo], currentCenter: CLLocationCoordinate2D, maxDistance: Double, forceUpdate: Bool = false) {
        //print(#function, "pinInfos.count: \(pinInfos.count)")
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            print("🚫 KakaoMap 객체를 가져올 수 없습니다.")
            return
        }
        print("🔍 KakaoMap 객체 생성 성공")
        // 현재 카메라 상태 확인
        let currentZoomLevel = Int(kakaoMap.zoomLevel)

        let topLeftPoint = kakaoMap.getPosition(CGPoint(x: 0, y: 0))
        let bottomRightPoint = kakaoMap.getPosition(CGPoint(x: kakaoMap.viewRect.width, y: kakaoMap.viewRect.height))
        let topLeftLocation = CLLocation(latitude: topLeftPoint.wgsCoord.latitude, longitude: topLeftPoint.wgsCoord.longitude)
        let bottomRightLocation = CLLocation(latitude: bottomRightPoint.wgsCoord.latitude, longitude: bottomRightPoint.wgsCoord.longitude)
        
        // 이전 좌표가 없는 경우 초기화
        if previousTopLeft == nil {
            previousTopLeft = topLeftLocation.coordinate
        }
        if previousBottomRight == nil {
            previousBottomRight = bottomRightLocation.coordinate
        }
        
        let topLeftDistance = haversineDistance(from: topLeftLocation.coordinate, to: previousTopLeft!)
        let bottomRightDistance = haversineDistance(from: bottomRightLocation.coordinate, to: previousBottomRight!)

        let isSignificantChange = topLeftDistance > 10 || bottomRightDistance > 10

        if !isSignificantChange && !forceUpdate {
            print("변화 없음")
            return
        }
        //print("🔍 변화 있음")
        // 변화가 있을 경우에만 이전 좌표 업데이트
        previousTopLeft = topLeftLocation.coordinate
        previousBottomRight = bottomRightLocation.coordinate

        // currentPinInfos 업데이트
        currentPinInfos.removeAll()
        for pinInfo in pinInfos {
            currentPinInfos[pinInfo.estateId] = pinInfo
        }
        //print("🔍 currentPinInfos 업데이트 성공")
        // 기존 POI 모두 제거
        clearAllPOIs()
        currentPOIs.removeAll()
        //clusters.removeAll()
        //print("🔍 기존 POI 모두 제거 성공")
        // 클러스터링 수행
        let (clusterInfos, maxPoiSize) = performClustering(pinInfos, zoomLevel: currentZoomLevel)
        let clusteringType = getClusteringType(for: currentZoomLevel)
        //print("🔍 clusteringType 계산 성공")
        // zoomLevel에 따라 다른 처리
        switch clusteringType {
        case .zoomLevel6to14:
            createClusterPOIsForLowZoom(clusterInfos, maxPoiSize: maxPoiSize)
        case .zoomLevel15Plus:
            createClusterPOIsForHighZoom(clusterInfos, zoomLevel: currentZoomLevel)
        }
        //print("🔍 클러스터링 수행 성공")
    }
    
    @MainActor
    private func createClusterPOIsForLowZoom(_ clusterInfos: [ClusterInfo], maxPoiSize: CGFloat?) {
        //print(#function, clusterInfos.count)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID),
              let maxPoiSize = maxPoiSize else {
            print("❌ 레이어 또는 맵 객체 생성 실패")
            return
        }
        clearAllPOIs()
        //clusters.removeAll()
        
        // 최소, 최대 count 계산
        // clusterInfos가 빈 배열일 때 counts.min()과 counts.max()가 nil이 됨
        let counts = clusterInfos.map { $0.count }
        guard !clusterInfos.isEmpty else {
            print("❌ 클러스터가 비어있음")
            return
        }
        
        // clusterInfos가 비어있지 않으면 min/max는 항상 존재
        let minCount = counts.min()!
        let maxCount = counts.max()!
        
        for (index, cluster) in clusterInfos.enumerated() {
            // poiSize 계산 (루트 보간)
            let poiSize: CGFloat
            if minCount == maxCount {
                poiSize = (30 + maxPoiSize) / 2
            } else {
                let normalized = sqrt(Double(cluster.count - minCount)) / sqrt(Double(maxCount - minCount))
                poiSize = 30 + (maxPoiSize - 30) * CGFloat(normalized)
            }
            
            // 스타일 생성
            let styleID = createCircleStyle(for: cluster, index: index, poiSize: poiSize)
            
            // POI 옵션 설정
            let poiOption = PoiOptions(styleID: styleID)
            poiOption.rank = index
            poiOption.clickable = true
            
            let clusterID = "cluster_\(index)"
            clusters[clusterID] = cluster
            
            let poi = layer.addPoi(
                option: poiOption,
                at: MapPoint(longitude: cluster.centerCoordinate.longitude, latitude: cluster.centerCoordinate.latitude),
                callback: { result in }
            )
            
            if let poi = poi {
                poi.userObject = clusterID as NSString
                poi.show()
                currentPOIs[clusterID] = poi
            } else {
                print("❌ POI 생성 실패: clusterID=\(clusterID)")
            }
        }

    }
    
    
    @MainActor
    private func createClusterPOIsForHighZoom(_ clusterInfos: [ClusterInfo], zoomLevel: Int) {
        //print(#function, clusterInfos.count)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID) else {
            print("❌ 레이어 또는 맵 객체 생성 실패")
            return
        }

        // 상태 초기화
        clearAllPOIs()
        //clusters.removeAll()

         let counts = clusterInfos.map { $0.count }
        guard !clusterInfos.isEmpty else {
            print("❌ 클러스터가 비어있음")
            return
        }
        
        Task {
            // 모든 이미지 처리를 동시에 시작
            async let processedImages = withTaskGroup(of: (Int, UIImage).self) { group in
                for (index, cluster) in clusterInfos.enumerated() {
                    group.addTask {
                        if let firstPinInfo = cluster.estateIds.first.flatMap({ id in
                            self.currentPinInfos[id]
                        }) {
                            let image = await self.processEstateImage(for: firstPinInfo)
                            return (index, image)
                        }
                        return (index, self.createDefaultEstateImage(size: CGSize(width: 40, height: 40)))
                    }
                }
                
                var results: [(Int, UIImage)] = []
                for await result in group {
                    results.append(result)
                }
                return results.sorted(by: { $0.0 < $1.0 })
            }
            
            // 이미지 처리가 완료된 후 POI 생성
            let images = await processedImages
            for (index, image) in images {
                let cluster = clusterInfos[index]
                let styleID = createImageStyle(with: image, for: cluster, index: index)
                
                let poiOption = PoiOptions(styleID: styleID)
                poiOption.rank = index
                poiOption.clickable = true
                
                let clusterID = "cluster_\(index)"
                clusters[clusterID] = cluster
                
                if let poi = layer.addPoi(
                    option: poiOption,
                    at: MapPoint(longitude: cluster.centerCoordinate.longitude, latitude: cluster.centerCoordinate.latitude)
                ) {
                    poi.userObject = clusterID as NSString
                    addBadgeToPOI(poi, count: cluster.count)
                    poi.show()
                    currentPOIs[clusterID] = poi
                }
            }
        }
    }
    
    // 원형 스타일 생성 (zoomLevel 14 이하)
    private func createCircleStyle(for cluster: ClusterInfo, index: Int, poiSize: CGFloat?) -> String {
        //print(#function)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return "" }
        let manager = kakaoMap.getLabelManager()
        
        let styleID = "circle_style_\(index)_\(Int(Date().timeIntervalSince1970))"
        let circleImage = createCircleImage(count: cluster.count, poiSize: poiSize)
        let iconStyle = PoiIconStyle(symbol: circleImage, anchorPoint: CGPoint(x: 0.5, y: 0.0))
        
        let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, level: 0)
        let poiStyle = PoiStyle(styleID: styleID, styles: [perLevelStyle])
        manager.addPoiStyle(poiStyle)
        
        return styleID
    }
    
    // 이미지 스타일 생성 (zoomLevel 17 이상)
    private func createImageStyle(with image: UIImage, for cluster: ClusterInfo, index: Int) -> String {
        //print(#function)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return "" }
        let manager = kakaoMap.getLabelManager()
        
        let styleID = "image_style_\(index)_\(Int(Date().timeIntervalSince1970))"
        let iconStyle = PoiIconStyle(symbol: image, anchorPoint: CGPoint(x: 0.5, y: 0.5))
        let perLevelStyles = [PerLevelPoiStyle(iconStyle: iconStyle, level: 0), PerLevelPoiStyle(iconStyle: iconStyle, level: 1), PerLevelPoiStyle(iconStyle: iconStyle, level: 2)]
        
        let poiStyle = PoiStyle(styleID: styleID, styles: perLevelStyles)
        manager.addPoiStyle(poiStyle)
        
        return styleID
    }
    
    // 이미지 처리 (zoomLevel 17 이상)
    private func processEstateImage(for pinInfo: PinInfo) async -> UIImage {
        let size = CGSize(width: 40, height: 40)

        if let imagePath = pinInfo.image {
            if let cachedImage = ImageCache.shared.image(forKey: imagePath) {
                do {
                    let processedImage = try applyStyle(to: cachedImage, size: size)
                    return processedImage
                } catch {
                    print("❌ 캐시 이미지 처리 실패: \(error.localizedDescription)")
                    return createDefaultEstateImage(size: size)
                }
            }
            
            do {
                if let downloadedImage = try await ImageDownsampler.downloadAndDownsample(
                    imagePath: imagePath,
                    to: size
                ) {
                    // 이미지 포맷 검증
                    guard let cgImage = downloadedImage.cgImage else {
                        print("❌ CGImage 변환 실패")
                        return createDefaultEstateImage(size: size)
                    }
                    
                    // 이미지 포맷 검사
                    let bitsPerComponent = cgImage.bitsPerComponent
                    let bitsPerPixel = cgImage.bitsPerPixel
                    
                    // 이미지 포맷이 유효한지 검사
                    guard bitsPerComponent == 8 && bitsPerPixel == 32 else {
                        print("❌ 지원하지 않는 이미지 포맷: bitsPerComponent=\(bitsPerComponent), bitsPerPixel=\(bitsPerPixel)")
                        return createDefaultEstateImage(size: size)
                    }
                    
                    ImageCache.shared.setImage(downloadedImage, forKey: imagePath)
                    let processedImage = try applyStyle(to: downloadedImage, size: size)
                    return processedImage
                } else {
                    print("❌ 이미지 다운로드 실패")
                    return createDefaultEstateImage(size: size)
                }
            } catch {
                print("❌ 이미지 처리 중 에러 발생: \(error.localizedDescription)")
                return createDefaultEstateImage(size: size)
            }
        } else {
            print("❌ 이미지 경로 없음")
            return createDefaultEstateImage(size: size)
        }
    }
    
    private func applyStyle(to image: UIImage, size: CGSize) throws -> UIImage {
        // 이미지 유효성 검사
        guard let cgImage = image.cgImage else {
            throw ImageError.invalidImageFormat("CGImage 변환 실패")
        }
        
        // 이미지 포맷 검사
        let bitsPerComponent = cgImage.bitsPerComponent
        let bitsPerPixel = cgImage.bitsPerPixel
        
        guard bitsPerComponent == 8 && bitsPerPixel == 32 else {
            throw ImageError.invalidImageFormat("지원하지 않는 이미지 포맷: bitsPerComponent=\(bitsPerComponent), bitsPerPixel=\(bitsPerPixel)")
        }
        
        // 1️⃣ 배경 이미지 로드
        guard let bubbleImage = UIImage(named: "MapBubbleButton") else {
            throw ImageError.missingAsset("MapBubbleButton 이미지 없음")
        }

        // 2️⃣ MapBubbleButton의 원본 비율 계산
        let bubbleOriginalSize = bubbleImage.size
        let bubbleAspectRatio = bubbleOriginalSize.height / bubbleOriginalSize.width

        // 3️⃣ 내부 이미지 사이즈 (정사각형 가정)
        let imageSize = image.size.width

        // 4️⃣ 전체 배경 사이즈 계산
        let bubbleWidth = imageSize + 8
        let bubbleHeight = bubbleWidth * bubbleAspectRatio - 10
        let finalSize = CGSize(width: bubbleWidth + 6, height: bubbleHeight + 6)

        // 5️⃣ 렌더링 시작
        let renderer = UIGraphicsImageRenderer(size: finalSize)
        let resultImage = renderer.image { context in
            let ctx = context.cgContext

            // 6️⃣ 그림자 설정
            ctx.setShadow(offset: CGSize(width: 0, height: 2),
                          blur: 4,
                          color: UIColor.black.withAlphaComponent(0.3).cgColor)

            let bubbleRect = CGRect(origin: CGPoint(x: 3, y: 3),
                                    size: CGSize(width: bubbleWidth, height: bubbleHeight))

            // 7️⃣ 그림자와 함께 bubbleImage 그리기
            bubbleImage.draw(in: bubbleRect)

            // 8️⃣ 그림자 제거
            ctx.setShadow(offset: .zero, blur: 0, color: nil)

            // 9️⃣ 내부 이미지 위치 설정
            let imageRect = CGRect(
                origin: CGPoint(x: bubbleRect.origin.x + 4, y: bubbleRect.origin.y + 4),
                size: size
            )

            // 🔟 내부 이미지 그리기
            image.draw(in: imageRect)
        }
        
        return resultImage
    }

    
    // 기본 이미지 생성 (zoomLevel 17 이상)
    private func createDefaultEstateImage(size: CGSize) -> UIImage {
        //print(#function)
        guard let defaultImage =  UIImage(systemName: "mappin") else {return UIImage()}
        return defaultImage
    }
}

// MARK: - POI 클릭 이벤트 처리
extension Coordinator {
    
    func poiDidTapped(kakaoMap: KakaoMap, layerID: String, poiID: String, position: MapPoint) {
//        print("📍poi tapped")
//        print("🔍 Debug Info:")
//        print("- poiID: \(poiID)")
//        print("- currentPOIs count: \(currentPOIs.count)")
//        print("- currentPOIs keys: \(currentPOIs.keys)")
//        
        // POI 검색 시도
        if let poi = currentPOIs.values.first(where: { $0.itemID == poiID }) {
            //print("✅ Found POI with itemID: \(poi.itemID)")
            if let userObject = poi.userObject {
                //print("✅ userObject type: \(type(of: userObject))")
                //print("✅ userObject value: \(userObject)")
            } else {
                //print("❌ userObject is nil")
            }
        } else {
            //print("❌ No POI found with itemID: \(poiID)")
            // 모든 POI의 itemID 출력
            //print("Available POI itemIDs:")
            currentPOIs.values.forEach { poi in
                //print("- \(poi.itemID)")
            }
        }
        
        guard let poi = currentPOIs.values.first(where: { $0.itemID == poiID }),
              let clusterID = poi.userObject as? String,
              let cluster = clusters[clusterID] else {
            print("❌ Guard statement failed")
            return
        }
        
        //print("📍📍poi tapped")
        let currentZoomLevel = Int(kakaoMap.zoomLevel)
        let clusteringType = getClusteringType(for: currentZoomLevel)
        var pininfos = [PinInfo]()
        for estateid in cluster.estateIds {
            if let pininfo = currentPinInfos[estateid] {
                pininfos.append(pininfo)
            }
        }
        
        //print("🪣 \(clusteringType)")
        switch clusteringType {
        case .zoomLevel6to14:
            onClusterTap?(cluster)
            expandToShowAllEstates(pininfos, kakaoMap: kakaoMap)
            
        case .zoomLevel15Plus:
            if cluster.estateIds.count == 1 {
                //print("🧤 \(cluster.estateIds.count)")
                onPOITap?(cluster.estateIds.first!)
            } else {
                //print("🧤🧤🧤 \(cluster.estateIds.count)")
                onPOIGroupTap?(cluster.estateIds)
            }
        }
    }
    
    private func expandToShowAllEstates(_ pinInfos: [PinInfo], kakaoMap: KakaoMap) {
        //print(#function)    
        // 클러스터 내 모든 매물을 포함하는 경계 계산
        guard !pinInfos.isEmpty else { return }
        
        // 클러스터의 모든 매물 좌표를 포함하는 AreaRect 생성
        let points: [MapPoint] = pinInfos.map {
            MapPoint(longitude: $0.longitude, latitude: $0.latitude)
        }

        let areaRect = AreaRect(points: points)
        let currentCenter = kakaoMap.getPosition(CGPoint(x: kakaoMap.viewRect.width / 2, y: kakaoMap.viewRect.height / 2))
        
        // 현재 중심점과 새로운 중심점의 차이가 일정 값 이상일 때만 카메라 이동
        
        if abs(currentCenter.wgsCoord.latitude - areaRect.center().wgsCoord.latitude) > 0.0001 ||
            abs(currentCenter.wgsCoord.longitude - areaRect.center().wgsCoord.longitude) > 0.0001 {
            let cameraUpdate = CameraUpdate.make(area: areaRect, levelLimit: 16)
            kakaoMap.moveCamera(cameraUpdate)
        }
    }
}


extension CLLocation {
    func coordinate(with distanceMeters: Double, bearing: Double) -> CLLocationCoordinate2D {
        //print(#function)
        let distanceRadians = distanceMeters / (6371000.0) // 지구 반경(m)
        let bearingRadians = bearing * .pi / 180 // 각도를 라디안으로 변환
        
        let lat1 = self.coordinate.latitude * .pi / 180
        let lon1 = self.coordinate.longitude * .pi / 180
        
        let lat2 = asin(
            sin(lat1) * cos(distanceRadians) +
            cos(lat1) * sin(distanceRadians) * cos(bearingRadians)
        )
        
        let lon2 = lon1 + atan2(
            sin(bearingRadians) * sin(distanceRadians) * cos(lat1),
            cos(distanceRadians) - sin(lat1) * sin(lat2)
        )
        
        return CLLocationCoordinate2D(
            latitude: lat2 * 180 / .pi,
            longitude: lon2 * 180 / .pi
        )
    }
}
extension GeoCoordinate {
    var clLocationCoordinate: CLLocationCoordinate2D {
        //print(#function)
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}

// 이미지 에러 타입 정의
enum ImageError: Error {
    case invalidImageFormat(String)
    case missingAsset(String)
    case processingError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidImageFormat(let message):
            return "이미지 포맷 오류: \(message)"
        case .missingAsset(let message):
            return "에셋 누락: \(message)"
        case .processingError(let message):
            return "이미지 처리 오류: \(message)"
        }
    }
}
