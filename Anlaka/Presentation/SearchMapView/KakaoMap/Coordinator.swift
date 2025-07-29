//
//  Coordinator.swift
//  Anlaka
//
//  Created by 최정안 on 5/31/25.
//

import Foundation
import UIKit
import KakaoMapsSDK
import CoreLocation
import os.log

// MARK: - 이미지 처리 오류 정의
enum ImageError: Error, LocalizedError {
    case invalidImageFormat(String)
    case missingAsset(String)
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidImageFormat(let message):
            return "이미지 포맷 오류: \(message)"
        case .missingAsset(let message):
            return "에셋 누락: \(message)"
        case .processingFailed(let message):
            return "이미지 처리 실패: \(message)"
        }
    }
}

// MARK: - Coordinator 클래스
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
        self.longitude = centerCoordinate.longitude
        self.latitude = centerCoordinate.latitude
        self.onMapReady = onMapReady
        self.onMapChanged = onMapChanged
        super.init()
    }
    
    func createController(_ view: KMViewContainer) {
        container = view
        controller = KMController(viewContainer: view)
        controller?.delegate = self
    }
    
    func addViews() {
        guard !isViewAdded else { return }
        let defaultPosition = MapPoint(longitude: longitude, latitude: latitude)
        let mapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition)
        controller?.addView(mapviewInfo)
        
        // 스케일바 추가
        if let mapView = controller?.getView("mapview") as? KakaoMap {
            mapView.setScaleBarPosition(origin: GuiAlignment(vAlign: .middle, hAlign: .center), position: CGPoint(x: 10.0, y: 10.0))
            mapView.showScaleBar()
        }
        
        isViewAdded = true
    }
    
    func authenticationSucceeded() {
        addViews()
    }
    
    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
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
        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
        mapView.viewRect = CGRect(origin: .zero, size: size)
        mapView.eventDelegate = self
    }
    
    func updateCenterCoordinate(_ newCoordinate: CLLocationCoordinate2D) {
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
        // 현재 줌 레벨과 좌표 정보 출력
        let currentZoomLevel = kakaoMap.zoomLevel
        //print(currentZoomLevel)
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
    
    /// 클러스터 정보를 기반으로 최대 거리를 계산합니다.
    /// 
    /// - Parameter clusterInfos: 클러스터 정보 배열
    /// - Returns: 클러스터들의 최대 반지름을 기반으로 한 최대 거리
    /// - Note: 클러스터의 maxRadius 중 최대값을 반환합니다
    private func calculateMaxDistance(clusterInfos: [ClusterInfo]) -> Double {
        guard !clusterInfos.isEmpty else { return 300.0 } // 기본값
        
        let maxRadius = clusterInfos.map { $0.maxRadius }.max() ?? 300.0
        return maxRadius
    }
    
    private func estimateMapResolution(mapView: KakaoMap) -> Double {
        let zoomLevel = mapView.zoomLevel
        let latitudeRadians = latitude * .pi / 180
        return 156543.03 * cos(latitudeRadians) / pow(2.0, Double(zoomLevel))
    }
    
    
    private func setupPOILayer(_ mapView: KakaoMap) {
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
            // POI 제거 완료
        }
    }
    
    /// POI들을 추가하는 메서드
    private func addPOIs(_ poiOptionsArray: [(poiData: (pinInfo: PinInfo, image: UIImage, index: Int), styleID: String, poiOption: PoiOptions)], to layer: LabelLayer) {
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
            // POI 추가 완료
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
        if zoomLevel >= 6 && zoomLevel <= 14 {
            return .zoomLevel6to14
        } else {
            return .zoomLevel15Plus
        }
    }
    
    // MARK: - 클러스터링 메인 메서드
    private func performClustering(_ pinInfos: [PinInfo], zoomLevel: Int) -> ([ClusterInfo], CGFloat?) {
        let clusteringType = getClusteringType(for: zoomLevel)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return ([], 0) }
        
        switch clusteringType {
        case .zoomLevel6to14:
            // HDBSCAN 기반 최적화된 클러스터링 사용
            let clusteringHelper = ClusteringHelper()
            let zoomLevelDouble = Double(zoomLevel)
            let result = clusteringHelper.clusterOptimized(pins: pinInfos, zoomLevel: zoomLevelDouble)
            
            // 노이즈를 개별 클러스터로 변환
            var allClusters = result.clusters
            for noisePin in result.noise {
                let noiseCluster = ClusterInfo(
                    estateIds: [noisePin.estateId],
                    centerCoordinate: CLLocationCoordinate2D(latitude: noisePin.latitude, longitude: noisePin.longitude),
                    count: 1,
                    representativeImage: noisePin.image,
                    opacity: nil, // 투명도는 아래에서 계산
                    maxRadius: 25.0 // 노이즈는 최소 반지름 사용
                )
                allClusters.append(noiseCluster)
            }
            
            // 투명도 계산 (루트 보간법 적용)
            for i in 0..<allClusters.count {
                let opacity = calculateClusterOpacityWithRootInterpolation(
                    for: allClusters[i],
                    allClusters: allClusters
                )
                allClusters[i] = ClusterInfo(
                    estateIds: allClusters[i].estateIds,
                    centerCoordinate: allClusters[i].centerCoordinate,
                    count: allClusters[i].count,
                    representativeImage: allClusters[i].representativeImage,
                    opacity: opacity,
                    maxRadius: allClusters[i].maxRadius
                )
            }
            
            // 겹치지 않는 POI 크기 계산 (루트 보간법 유지)
            let totalClusters = allClusters.count // 실제 클러스터 수 사용
            let screenArea = kakaoMap.viewRect.width * kakaoMap.viewRect.height
            let availableAreaPerPOI = screenArea / CGFloat(totalClusters)
            let maxPoiSize = sqrt(availableAreaPerPOI) * 0.8 // 80%로 조정하여 여백 확보
            return (allClusters, maxPoiSize)
            
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
                representativeImage: clusterPins.first?.image,
                opacity: nil, // 투명도는 아래에서 계산
                maxRadius: 50.0 // 기본값, 나중에 업데이트
            )
            
            clusterInfos.append(cluster)
        }
        
        // 투명도 계산 (루트 보간법 적용)
        for i in 0..<clusterInfos.count {
            let opacity = calculateClusterOpacityWithRootInterpolation(
                for: clusterInfos[i],
                allClusters: clusterInfos
            )
            clusterInfos[i] = ClusterInfo(
                estateIds: clusterInfos[i].estateIds,
                centerCoordinate: clusterInfos[i].centerCoordinate,
                count: clusterInfos[i].count,
                representativeImage: clusterInfos[i].representativeImage,
                opacity: opacity,
                maxRadius: clusterInfos[i].maxRadius
            )
        }
        
        return (clusterInfos, maxPoiSize)
    }
    
    // MARK: - 원형 이미지 생성 (매물 수 표시용)
    private func createCircleImage(count: Int, poiSize: CGFloat?, cluster: ClusterInfo? = nil) -> UIImage {
        let size = CGSize(width: poiSize ?? 25, height: poiSize ?? 25)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // 투명도 계산 (클러스터 정보가 있으면 루트보간법으로 계산된 투명도, 없으면 매물 수 기반)
            let alpha: CGFloat
            if let cluster = cluster, let clusterOpacity = cluster.opacity {
                // 루트보간법으로 계산된 투명도 사용
                alpha = clusterOpacity
            } else {
                // 기존 방식: 매물 수 기반 밀도 (하위 호환성)
                let density: CGFloat
                if let cluster = cluster {
                    density = self.calculateDensity(for: cluster, poiSize: poiSize ?? 50)
                } else {
                    let baseDensity = min(1.0, CGFloat(count) / 20.0)
                    density = max(0.3, baseDensity)
                }
                alpha = max(0.2, min(1.0, density)) // 최소 0.2, 최대 1.0으로 제한하여 차이를 더 명확하게
            }
            
            // OliveMist 색상으로 원형 배경 그리기
            let oliveMistColor = UIColor(named: "OliveMist") ?? UIColor(red: 0.6, green: 0.7, blue: 0.5, alpha: 1.0)
            
            // 투명도가 적용된 OliveMist 색상
            let alphaColor = oliveMistColor.withAlphaComponent(alpha)
            
            // 원형 배경 그리기
            context.cgContext.setFillColor(alphaColor.cgColor)
            context.cgContext.fillEllipse(in: rect)

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
        
        return image
    }
    
    // MARK: - 밀도 계산 함수
    /// 클러스터의 밀도를 계산합니다.
    /// 밀도는 최대 반지름 대비 매물 수로 계산됩니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    ///   - poiSize: 마커 크기
    /// - Returns: 0.0 ~ 1.0 사이의 밀도 값
    private func calculateDensity(for cluster: ClusterInfo, poiSize: CGFloat) -> CGFloat {
        // 매물 수 기반 밀도 계산 - 더 넓은 범위로 설정
        let baseDensity = min(1.0, CGFloat(cluster.count) / 15.0) // 20에서 15로 변경하여 더 민감하게
        return max(0.3, baseDensity) // 최소값을 0.7에서 0.3으로 낮춰서 차이를 더 명확하게
    }
    
    // MARK: - 동적 마커 크기 계산 함수
    /// 매물 수에 비례한 마커 크기를 계산합니다.
    /// 
    /// - Parameters:
    ///   - count: 클러스터 내 매물 수
    ///   - baseSize: 기본 마커 크기
    ///   - maxPoiSize: 최대 마커 크기 제한
    /// - Returns: 매물 수에 비례한 마커 크기
    private func calculateDynamicSize(for count: Int, baseSize: CGFloat, maxPoiSize: CGFloat?) -> CGFloat {
        // 기본 크기 범위 설정
        let minSize: CGFloat = 30
        let maxSize: CGFloat = maxPoiSize ?? 80
        
        // 매물 수에 따른 크기 계산 (로그 스케일 사용)
        let logCount = log10(Double(max(1, count)))
        let maxLogCount = log10(50.0) // 50개를 최대 기준으로 설정
        
        let sizeRatio = min(1.0, logCount / maxLogCount)
        let dynamicSize = minSize + (maxSize - minSize) * sizeRatio
        
        return dynamicSize
    }
    


    
    // MARK: - POI 배지 추가 (zoomLevel 17용)
    @MainActor
    private func addBadgeToPOI(_ poi: Poi, count: Int) {
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
        
        return image
    }
    
        private func convertToPNGRGBA(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else {
            
            return UIImage(systemName: "mappin") ?? UIImage() // 기본 이미지 반환
        }
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return image
        }
    
    let width = cgImage.width
    let height = cgImage.height
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return image
    }
    
    let rect = CGRect(x: 0, y: 0, width: width, height: height)
    context.draw(cgImage, in: rect)
    
    guard let newCGImage = context.makeImage() else {
        return image
    }
    
    let safeImage = UIImage(cgImage: newCGImage, scale: image.scale, orientation: image.imageOrientation)
    guard let pngData = safeImage.pngData() else {
        return image
    }
    
    guard let finalImage = UIImage(data: pngData) else {
        return image
    }
    
    guard ImageValidationHelper.validateUIImage(finalImage) else {
        return image
    }

    return finalImage
}
}

// MARK: - 클러스터링 기반 POI 업데이트 메서드 (기존 updatePOIsEfficiently 대체)
extension Coordinator {
    
    @MainActor func updatePOIsWithClustering(_ pinInfos: [PinInfo], currentCenter: CLLocationCoordinate2D, maxDistance: Double, forceUpdate: Bool = false) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            return
        }
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
            return
        }
        // 변화가 있을 경우에만 이전 좌표 업데이트
        previousTopLeft = topLeftLocation.coordinate
        previousBottomRight = bottomRightLocation.coordinate

        // currentPinInfos 업데이트
        currentPinInfos.removeAll()
        for pinInfo in pinInfos {
            currentPinInfos[pinInfo.estateId] = pinInfo
        }
        // 기존 POI 모두 제거
        clearAllPOIs()
        currentPOIs.removeAll()
        // 클러스터링 수행
        let (clusterInfos, maxPoiSize) = performClustering(pinInfos, zoomLevel: currentZoomLevel)
        let clusteringType = getClusteringType(for: currentZoomLevel)
        // zoomLevel에 따라 다른 처리
        switch clusteringType {
        case .zoomLevel6to14:
            createClusterPOIsForLowZoom(clusterInfos, maxPoiSize: maxPoiSize)
        case .zoomLevel15Plus:
            createClusterPOIsForHighZoom(clusterInfos, zoomLevel: currentZoomLevel)
        }
    }
    
    @MainActor
    private func createClusterPOIsForLowZoom(_ clusterInfos: [ClusterInfo], maxPoiSize: CGFloat?) {

        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID) else {
            return
        }
        clearAllPOIs()
        
        guard !clusterInfos.isEmpty else {
            return
        }
        
        // 내접원 기반으로 POI 위치와 크기 조정
        let adjustedClusters = adjustClusterPositionsToPreventOverlap(clusterInfos, kakaoMap: kakaoMap)
        
        for (index, adjustedCluster) in adjustedClusters.enumerated() {
            let cluster = adjustedCluster.cluster
            let center = adjustedCluster.center
            let baseSize = adjustedCluster.size
            
            // maxRadius 기반 마커 크기 계산
            let sizeRange = calculatePOISizeRangeBasedOnMaxRadius(clusterInfos, kakaoMap: kakaoMap)
            let dynamicSize = calculateClusterPOISizeWithMaxRadius(
                for: cluster,
                sizeRange: sizeRange,
                allClusters: clusterInfos,
                kakaoMap: kakaoMap
            )
            
            // 스타일 생성 (동적 크기 사용)
            let styleID = createCircleStyle(for: cluster, index: index, poiSize: dynamicSize)
            
            // POI 옵션 설정
            let poiOption = PoiOptions(styleID: styleID)
            poiOption.rank = index
            poiOption.clickable = true
            
            let clusterID = "cluster_\(index)"
            clusters[clusterID] = cluster
            
            let poi = layer.addPoi(
                option: poiOption,
                at: center, // 내접원 중심점 사용
                callback: { result in }
            )
            
            if let poi = poi {
                poi.userObject = clusterID as NSString
                poi.show()
                currentPOIs[clusterID] = poi
            } else {
                // POI 생성 실패
            }
        }
    }


    @MainActor
    private func createClusterPOIsForHighZoom(_ clusterInfos: [ClusterInfo], zoomLevel: Int) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID) else {
            os_log(.error, "Failed to get map or layer")
            return
        }
        
        clearAllPOIs()
        
        guard !clusterInfos.isEmpty else {
            os_log(.error, "Empty cluster list")
            return
        }
        
        Task.detached(priority: .userInitiated) {
            let processedImages = await withTaskGroup(of: (Int, UIImage?).self) { group in
                for (index, cluster) in clusterInfos.enumerated() {
                    group.addTask {
                        if let firstPinInfo = cluster.estateIds.first.flatMap({ self.currentPinInfos[$0] }) {
                            let image = await self.processEstateImage(for: firstPinInfo)
                            os_log(.debug, "Processed image for cluster %d: size=%@", index, "\(image.size)")
                            return (index, ImageValidationHelper.validateUIImage(image) ? image : nil)
                        }
                        os_log(.error, "No pin info for cluster %d", index)
                        return (index, nil)
                    }
                }
                
                var results: [(Int, UIImage?)] = []
                for await result in group {
                    results.append(result)
                }
                return results.sorted(by: { $0.0 < $1.0 })
            }
            
            await MainActor.run {
                for (index, image) in processedImages {
                    guard let image = image else {
                        os_log(.error, "Image processing failed for cluster %d", index)
                        continue
                    }
                    
                    let cluster = clusterInfos[index]
                    let styleID = self.createImageStyle(with: image, for: cluster, index: index)
                    
                    let poiOption = PoiOptions(styleID: styleID)
                    poiOption.rank = index
                    poiOption.clickable = true
                    
                    let clusterID = "cluster_\(index)"
                    self.clusters[clusterID] = cluster
                    
                    // 클러스터 크기에 따라 위치 결정
                    let poiPosition: MapPoint
                    if cluster.count == 1 {
                        // 개별 매물인 경우 원래 매물 위치 사용
                        if let firstEstateId = cluster.estateIds.first,
                           let pinInfo = self.currentPinInfos[firstEstateId] {
                            poiPosition = MapPoint(longitude: pinInfo.longitude, latitude: pinInfo.latitude)
                        } else {
                            // fallback: 클러스터 중심 위치 사용
                            poiPosition = MapPoint(longitude: cluster.centerCoordinate.longitude, latitude: cluster.centerCoordinate.latitude)
                        }
                    } else {
                        // 여러 매물인 경우 클러스터 중심 위치 사용
                        poiPosition = MapPoint(longitude: cluster.centerCoordinate.longitude, latitude: cluster.centerCoordinate.latitude)
                    }
                    
                    if let poi = layer.addPoi(
                        option: poiOption,
                        at: poiPosition
                    ) {
                        poi.userObject = clusterID as NSString
                        self.addBadgeToPOI(poi, count: cluster.count)
                        self.currentPOIs[clusterID] = poi // 먼저 저장
                        poi.show()
                        os_log(.debug, "POI added for cluster %@: itemID=%@, size=%@", clusterID, poi.itemID, "\(image.size)")
                    } else {
                        os_log(.error, "Failed to create POI for cluster %@", clusterID)
                    }
                }
                os_log(.debug, "POI update completed: currentPOIs count=%d, clusters count=%d", self.currentPOIs.count, self.clusters.count)
            }
        }
    }

    // 원형 스타일 생성 (zoomLevel 14 이하)
    private func createCircleStyle(for cluster: ClusterInfo, index: Int, poiSize: CGFloat?) -> String {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return "" }
        let manager = kakaoMap.getLabelManager()
        
        let styleID = "circle_style_\(index)_\(Int(Date().timeIntervalSince1970))"
        let circleImage = createCircleImage(count: cluster.count, poiSize: poiSize, cluster: cluster)
        let iconStyle = PoiIconStyle(symbol: circleImage, anchorPoint: CGPoint(x: 0.5, y: 0.0))
        
        let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, level: 0)
        let poiStyle = PoiStyle(styleID: styleID, styles: [perLevelStyle])
        manager.addPoiStyle(poiStyle)
        
        return styleID
    }
    
private func createImageStyle(with image: UIImage, for cluster: ClusterInfo, index: Int) -> String {
    guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return "" }
    let manager = kakaoMap.getLabelManager()
    
    let styleID = "image_style_\(index)_\(Int(Date().timeIntervalSince1970))"
    let optimizedImage = convertToPNGRGBA(image) // PNG/RGBA로 변환
    let iconStyle = PoiIconStyle(symbol: optimizedImage, anchorPoint: CGPoint(x: 0.5, y: 0.5))
    
    let perLevelStyles = [
        PerLevelPoiStyle(iconStyle: iconStyle, level: 0),
        PerLevelPoiStyle(iconStyle: iconStyle, level: 1),
        PerLevelPoiStyle(iconStyle: iconStyle, level: 2)
    ]
    
    let poiStyle = PoiStyle(styleID: styleID, styles: perLevelStyles)
    manager.addPoiStyle(poiStyle)
    
    return styleID
}
    
    // 이미지 처리 (zoomLevel 17 이상) - ImageLoader 활용
    private func processEstateImage(for pinInfo: PinInfo) async -> UIImage {
        let size = CGSize(width: 40, height: 40)

        guard let imagePath = pinInfo.image else {
            return createDefaultEstateImage(size: size)
        }
        
        // ImageLoader를 사용하여 이미지 로드
        if let loadedImage = await ImageLoader.shared.loadPOIImage(from: imagePath) {
            do {
                let processedImage = try applyStyle(to: loadedImage, size: size)
                return processedImage
            } catch {
                return createDefaultEstateImage(size: size)
            }
        } else {
            return createDefaultEstateImage(size: size)
        }
    }


    private func applyStyle(to image: UIImage, size: CGSize) throws -> UIImage {
        guard image.size.width > 0 && image.size.height > 0 else {
            print("❌ [applyStyle] 이미지 크기가 유효하지 않음 - 크기: \(image.size)")
            throw ImageError.invalidImageFormat("이미지 크기가 유효하지 않음")
        }
        
        let safeImage = convertToPNGRGBA(image)
        
        guard let bubbleImage = UIImage(named: "MapBubbleButton") else {
            throw ImageError.missingAsset("MapBubbleButton 이미지 없음")
        }
    
    let bubbleOriginalSize = bubbleImage.size
    let bubbleAspectRatio = bubbleOriginalSize.height / bubbleOriginalSize.width
    let bubbleWidth = size.width + 8
    let bubbleHeight = bubbleWidth * bubbleAspectRatio - 10
    let finalSize = CGSize(width: bubbleWidth + 6, height: bubbleHeight + 6)
    
    let renderer = UIGraphicsImageRenderer(size: finalSize, format: {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.preferredRange = .standard
        return format
    }())
    
    let resultImage = renderer.image { context in
        let ctx = context.cgContext
        
        ctx.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.3).cgColor)
        
        let bubbleRect = CGRect(origin: CGPoint(x: 3, y: 3), size: CGSize(width: bubbleWidth, height: bubbleHeight))
        bubbleImage.draw(in: bubbleRect)
        
        ctx.setShadow(offset: .zero, blur: 0, color: nil)
        
        let imageRect = CGRect(origin: CGPoint(x: bubbleRect.origin.x + 4, y: bubbleRect.origin.y + 4), size: size)
            safeImage.draw(in: imageRect)
}

guard ImageValidationHelper.validateUIImage(resultImage) else {
    throw ImageError.invalidImageFormat("최종 이미지 유효성 검사 실패")
}

let finalImage = convertToPNGRGBA(resultImage) // 최종적으로 PNG/RGBA 보장

return finalImage
}

    
    // 기본 이미지 생성 (zoomLevel 17 이상)
    private func createDefaultEstateImage(size: CGSize) -> UIImage {
        guard let defaultImage = UIImage(systemName: "mappin") else { return UIImage() }
        return defaultImage
    }
}

// MARK: - POI 클릭 이벤트 처리
extension Coordinator {
    
    func poiDidTapped(kakaoMap: KakaoMap, layerID: String, poiID: String, position: MapPoint) {

        // POI 검색 시도
        if let poi = currentPOIs.values.first(where: { $0.itemID == poiID }) {
            // POI 찾음
        } else {
            // POI를 찾을 수 없음
        }
        
        guard let poi = currentPOIs.values.first(where: { $0.itemID == poiID }),
              let clusterID = poi.userObject as? String,
              let cluster = clusters[clusterID] else {
            os_log(.error, "Guard statement failed: poiID=%@, currentPOIs count=%d, clusters count=%d", poiID, currentPOIs.count, clusters.count)
            return
        }
        

        let currentZoomLevel = Int(kakaoMap.zoomLevel)
        let clusteringType = getClusteringType(for: currentZoomLevel)
        var pininfos = [PinInfo]()
        for estateid in cluster.estateIds {
            if let pininfo = currentPinInfos[estateid] {
                pininfos.append(pininfo)
            }
        }
        

        switch clusteringType {
        case .zoomLevel6to14:
            onClusterTap?(cluster)
            expandToShowAllEstates(pininfos, kakaoMap: kakaoMap)
            
        case .zoomLevel15Plus:
            if cluster.estateIds.count == 1 {

                onPOITap?(cluster.estateIds.first!)
            } else {

                onPOIGroupTap?(cluster.estateIds)
            }
        }
    }
    
    private func expandToShowAllEstates(_ pinInfos: [PinInfo], kakaoMap: KakaoMap) {
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
            
            // 카메라 이동 완료 후 줌레벨 확인 및 조정
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let currentZoomLevel = Int(kakaoMap.zoomLevel)
                let targetZoomLevel = currentZoomLevel + 1
                
                // 현재 줌레벨이 14 미만이고, 확대 후에도 같은 줌레벨이면 한 단계 높이기
                if currentZoomLevel < 14 && targetZoomLevel <= 15 {
                    let newCameraUpdate = CameraUpdate.make(area: areaRect, levelLimit: targetZoomLevel)
                    kakaoMap.moveCamera(newCameraUpdate)
                }
            }
        }
    }
}


extension CLLocation {
    func coordinate(with distanceMeters: Double, bearing: Double) -> CLLocationCoordinate2D {
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
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }
}

// MARK: - AreaRect 내접원 계산 유틸리티
extension Coordinator {

    
    /// AreaRect에 내접하는 원의 중심점과 반지름을 계산합니다 (Haversine 거리 사용).
    /// 
    /// - Parameters:
    ///   - areaRect: 내접원을 구할 AreaRect
    /// - Returns: (center: MapPoint, radius: Double) - 원의 중심점과 반지름(미터)
    /// - Note: 정확한 Haversine 거리를 사용하여 반지름을 계산합니다
    private func calculateInscribedCircleAccurate(for areaRect: AreaRect) -> (center: MapPoint, radius: Double) {
        // AreaRect의 중심점
        let center = areaRect.center()
        
        // AreaRect의 모서리들
        let southWest = areaRect.southWest
        let northEast = areaRect.northEast
        
        // 중심점에서 각 모서리까지의 거리 계산
        let centerCoord = CLLocationCoordinate2D(latitude: center.wgsCoord.latitude, longitude: center.wgsCoord.longitude)
        
        let distances = [
            haversineDistance(from: centerCoord, to: CLLocationCoordinate2D(latitude: southWest.wgsCoord.latitude, longitude: southWest.wgsCoord.longitude)),
            haversineDistance(from: centerCoord, to: CLLocationCoordinate2D(latitude: northEast.wgsCoord.latitude, longitude: northEast.wgsCoord.longitude)),
            haversineDistance(from: centerCoord, to: CLLocationCoordinate2D(latitude: southWest.wgsCoord.latitude, longitude: northEast.wgsCoord.longitude)),
            haversineDistance(from: centerCoord, to: CLLocationCoordinate2D(latitude: northEast.wgsCoord.latitude, longitude: southWest.wgsCoord.longitude))
        ]
        
        // 가장 작은 거리가 내접원의 반지름
        let radius = distances.min() ?? 0
        
        return (center: center, radius: radius)
    }
    
    /// 클러스터의 매물들을 포함하는 AreaRect를 생성하고, 그에 내접하는 원을 계산합니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    /// - Returns: (center: MapPoint, radius: Double) - 내접원의 중심점과 반지름(미터)
    /// - Note: 클러스터의 모든 매물을 포함하는 최소 영역에 내접하는 원을 계산합니다
    private func calculateClusterInscribedCircle(for cluster: ClusterInfo) -> (center: MapPoint, radius: Double) {
        // 클러스터 내 모든 매물의 좌표를 MapPoint로 변환
        let mapPoints: [MapPoint] = cluster.estateIds.compactMap { estateId in
            guard let pinInfo = currentPinInfos[estateId] else { return nil }
            return MapPoint(longitude: pinInfo.longitude, latitude: pinInfo.latitude)
        }
        
        guard !mapPoints.isEmpty else {
            // 매물이 없으면 기본값 반환
            return (center: MapPoint(longitude: 0, latitude: 0), radius: 0)
        }
        
        // 모든 매물을 포함하는 AreaRect 생성
        let areaRect = AreaRect(points: mapPoints)
        
        // AreaRect에 내접하는 원 계산
        return calculateInscribedCircleAccurate(for: areaRect)
    }
    
    /// 클러스터의 Delaunay 삼각분할 기반 최대 반지름을 사용하여 POI 크기와 위치를 결정합니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    ///   - kakaoMap: 카카오맵 객체
    ///   - sizeRange: (minSize: CGFloat, maxSize: CGFloat) - 크기 범위 (선택적)
    ///   - allClusters: 전체 클러스터 배열 (루트 보간법을 위한 정렬 기준, 선택적)
    /// - Returns: (center: MapPoint, size: CGFloat) - POI 중심점과 크기
    /// - Note: maxRadius를 기반으로 정확한 위치와 크기를 계산합니다
    private func calculateClusterPOIPositionAndSize(
        for cluster: ClusterInfo, 
        kakaoMap: KakaoMap,
        sizeRange: (minSize: CGFloat, maxSize: CGFloat)? = nil,
        allClusters: [ClusterInfo]? = nil
    ) -> (center: MapPoint, size: CGFloat) {
        // 클러스터의 중심점
        let center = MapPoint(longitude: cluster.centerCoordinate.longitude, latitude: cluster.centerCoordinate.latitude)
        
        // 크기 계산 - maxRadius 기반
        if let sizeRange = sizeRange, let allClusters = allClusters {
            // maxRadius와 매물 수를 고려한 크기 계산
            let finalSize = calculateClusterPOISizeWithMaxRadius(
                for: cluster,
                sizeRange: sizeRange,
                allClusters: allClusters,
                kakaoMap: kakaoMap
            )
            return (center: center, size: finalSize)
        } else {
            // 기존 방식 (하위 호환성)
            let inscribedCircle = calculateClusterInscribedCircle(for: cluster)
            let radiusInPixels = CGFloat(inscribedCircle.radius / calculateMetersPerPixel(kakaoMap: kakaoMap))
            let baseSize = radiusInPixels * 2.0
            let minSize: CGFloat = 30
            let maxSize: CGFloat = 80
            let clampedSize = max(minSize, min(maxSize, baseSize))
            let sizeMultiplier = min(1.5, 1.0 + CGFloat(cluster.count - 1) * 0.1)
            let finalSize = clampedSize * sizeMultiplier
            
            return (center: center, size: finalSize)
        }
    }
    
    /// 클러스터 간 겹침을 방지하면서 POI 크기와 위치를 조정합니다.
    /// 
    /// - Parameters:
    ///   - clusterInfos: 클러스터 정보 배열
    ///   - kakaoMap: 카카오맵 객체
    /// - Returns: 조정된 클러스터 정보 배열 (위치와 크기 포함)
    private func adjustClusterPositionsToPreventOverlap(_ clusterInfos: [ClusterInfo], kakaoMap: KakaoMap) -> [(cluster: ClusterInfo, center: MapPoint, size: CGFloat)] {
        var adjustedClusters: [(cluster: ClusterInfo, center: MapPoint, size: CGFloat)] = []
        
        // maxRadius 기반으로 크기 범위 계산
        let sizeRange = calculatePOISizeRangeBasedOnMaxRadius(clusterInfos, kakaoMap: kakaoMap)
        
        for cluster in clusterInfos {
            let (center, size) = calculateClusterPOIPositionAndSize(
                for: cluster, 
                kakaoMap: kakaoMap,
                sizeRange: sizeRange,
                allClusters: clusterInfos
            )
            adjustedClusters.append((cluster: cluster, center: center, size: size))
        }
        
        // 클러스터 간 겹침 검사 및 조정 (개선된 알고리즘)
        let maxIterations = 3 // 최대 반복 횟수 제한
        var iteration = 0
        
        while iteration < maxIterations {
            var hasOverlap = false
            
            for i in 0..<adjustedClusters.count {
                for j in (i+1)..<adjustedClusters.count {
                    let cluster1 = adjustedClusters[i]
                    let cluster2 = adjustedClusters[j]
                    
                    // 두 클러스터 중심점 간의 거리 계산
                    let distance = haversineDistance(
                        from: CLLocationCoordinate2D(latitude: cluster1.center.wgsCoord.latitude, longitude: cluster1.center.wgsCoord.longitude),
                        to: CLLocationCoordinate2D(latitude: cluster2.center.wgsCoord.latitude, longitude: cluster2.center.wgsCoord.longitude)
                    )
                    
                    // 거리를 픽셀 단위로 변환
                    let metersPerPixel = calculateMetersPerPixel(kakaoMap: kakaoMap)
                    let pixelDistance = CGFloat(distance / metersPerPixel)
                    
                    // 겹침 여부 확인 (두 POI의 반지름 합이 중심점 간 거리보다 크면 겹침)
                    let combinedRadius = cluster1.size / 2 + cluster2.size / 2
                    let safetyMargin: CGFloat = 2.0 // 안전 마진 추가
                    
                    if pixelDistance < (combinedRadius + safetyMargin) {
                        hasOverlap = true
                        
                        // 겹침 정도에 따른 조정 전략
                        let overlapRatio = pixelDistance / combinedRadius
                        
                        if overlapRatio < 0.3 {
                            // 심각한 겹침: 크기를 크게 줄임
                            let reductionFactor = max(0.3, overlapRatio * 0.5)
                            adjustedClusters[i].size *= reductionFactor
                            adjustedClusters[j].size *= reductionFactor
                        } else if overlapRatio < 0.7 {
                            // 중간 겹침: 크기를 적당히 줄임
                            let reductionFactor = max(0.5, overlapRatio * 0.8)
                            adjustedClusters[i].size *= reductionFactor
                            adjustedClusters[j].size *= reductionFactor
                        } else {
                            // 약간의 겹침: 크기를 조금만 줄임
                            let reductionFactor = max(0.7, overlapRatio * 0.9)
                            adjustedClusters[i].size *= reductionFactor
                            adjustedClusters[j].size *= reductionFactor
                        }
                        
                        // 최소 크기 보장
                        adjustedClusters[i].size = max(30, adjustedClusters[i].size)
                        adjustedClusters[j].size = max(30, adjustedClusters[j].size)
                    }
                }
            }
            
            // 겹침이 없으면 반복 종료
            if !hasOverlap {
                break
            }
            
            iteration += 1
        }
        
        // 최종 검증: 여전히 겹침이 있는 경우 추가 조정
        for i in 0..<adjustedClusters.count {
            for j in (i+1)..<adjustedClusters.count {
                let cluster1 = adjustedClusters[i]
                let cluster2 = adjustedClusters[j]
                
                let distance = haversineDistance(
                    from: CLLocationCoordinate2D(latitude: cluster1.center.wgsCoord.latitude, longitude: cluster1.center.wgsCoord.longitude),
                    to: CLLocationCoordinate2D(latitude: cluster2.center.wgsCoord.latitude, longitude: cluster2.center.wgsCoord.longitude)
                )
                
                let metersPerPixel = calculateMetersPerPixel(kakaoMap: kakaoMap)
                let pixelDistance = CGFloat(distance / metersPerPixel)
                let combinedRadius = cluster1.size / 2 + cluster2.size / 2
                
                if pixelDistance < combinedRadius {
                    // 최후의 수단: 더 작은 클러스터를 숨김
                    if cluster1.cluster.count < cluster2.cluster.count {
                        adjustedClusters[i].size = 0 // 숨김 처리
                    } else {
                        adjustedClusters[j].size = 0 // 숨김 처리
                    }
                }
            }
        }
        
        // 크기가 0인 클러스터 제거
        adjustedClusters = adjustedClusters.filter { $0.size > 0 }
        
        return adjustedClusters
    }
    
    /// 클러스터들의 지리적 범위(실제 반지름)를 기반으로 POI 크기 범위를 계산합니다.
    /// 
    /// - Parameters:
    ///   - clusterInfos: 클러스터 정보 배열
    ///   - kakaoMap: 카카오맵 객체
    /// - Returns: (minSize: CGFloat, maxSize: CGFloat) - 최소/최대 POI 크기
    /// - Note: 매물 수는 고려하지 않고 순수하게 클러스터의 지리적 범위만을 기준으로 합니다
    private func calculatePOISizeRangeBasedOnMaxRadius(_ clusterInfos: [ClusterInfo], kakaoMap: KakaoMap) -> (minSize: CGFloat, maxSize: CGFloat) {
        guard !clusterInfos.isEmpty else { return (minSize: 25, maxSize: 150) }
        
        // 지리적 범위를 고려한 크기 범위 설정 (POI 간 겹침 방지)
        let maxDistance = calculateMaxDistance(clusterInfos: clusterInfos)
        let minPoiSize: CGFloat = 25.0 // 하한선
        
        // maxDistance를 픽셀로 변환하여 POI 간 겹침 방지
        let metersPerPixel = calculateMetersPerPixel(kakaoMap: kakaoMap)
        let maxDistanceInPixels = CGFloat(maxDistance / metersPerPixel)
        
        // POI 크기가 클러스터 간 거리의 절반을 넘지 않도록 제한 (겹침 방지)
        let maxPoiSizeForNoOverlap = maxDistanceInPixels * 0.4 // 클러스터 간 거리의 40%로 제한
        let maxPoiSize: CGFloat = max(minPoiSize + 25.0, min(150.0, maxPoiSizeForNoOverlap))
        
//        print("🔍 POI 크기 범위 설정 (겹침 방지):")
//        print("   - maxDistance: \(maxDistance)m")
//        print("   - maxDistanceInPixels: \(maxDistanceInPixels)픽셀")
//        print("   - 겹침 방지 상한선: \(maxPoiSizeForNoOverlap)픽셀")
//        print("   - 최종 상한선 (maxPoiSize): \(maxPoiSize)픽셀")
//        print("   - 하한선 (minPoiSize): \(minPoiSize)픽셀")
        
        return (minSize: minPoiSize, maxSize: maxPoiSize)
    }

    /// 클러스터의 지리적 범위(실제 반지름)를 기준으로 루트 보간법을 사용하여 POI 크기를 계산합니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    ///   - sizeRange: (minSize: CGFloat, maxSize: CGFloat) - 크기 범위
    ///   - allClusters: 전체 클러스터 배열
    ///   - kakaoMap: 카카오맵 객체 (maxRadius를 픽셀로 변환하기 위해 사용)
    /// - Returns: POI 크기
    /// - Note: 매물 수는 고려하지 않고 순수하게 클러스터의 지리적 범위만을 기준으로 루트 보간법을 적용합니다
    private func calculateClusterPOISizeWithMaxRadius(
        for cluster: ClusterInfo,
        sizeRange: (minSize: CGFloat, maxSize: CGFloat),
        allClusters: [ClusterInfo],
        kakaoMap: KakaoMap
    ) -> CGFloat {
        let minSize = sizeRange.minSize
        let maxSize = sizeRange.maxSize
        
        // 매물이 1개인 클러스터(노이즈)는 무조건 최솟값 반환
        if cluster.count == 1 {
            //print("🎯 POI 크기 결과: Cluster \(cluster.count)개 - 노이즈이므로 최솟값 적용, finalSize=\(minSize)")
            return minSize
        }
        
        // 실제 클러스터들만 필터링 (매물수 2개 이상)
        let actualClusters = allClusters.filter { $0.count > 1 }
        
        // 실제 클러스터가 없으면 최솟값 반환
        guard !actualClusters.isEmpty else {
            //print("🎯 POI 크기 결과: Cluster \(cluster.count)개 - 실제 클러스터 없음, finalSize=\(minSize)")
            return minSize
        }
        
        // 실제 클러스터의 반지름 기준으로 정렬
        let sortedClusters = actualClusters.sorted { $0.maxRadius < $1.maxRadius }
        
        // 현재 클러스터의 순위 찾기
        guard let currentIndex = sortedClusters.firstIndex(where: { 
            $0.estateIds == cluster.estateIds && 
            $0.centerCoordinate.latitude == cluster.centerCoordinate.latitude &&
            $0.centerCoordinate.longitude == cluster.centerCoordinate.longitude
        }) else {
            return minSize
        }
        
        let minRadius = sortedClusters.first?.maxRadius ?? cluster.maxRadius
        let maxRadius = sortedClusters.last?.maxRadius ?? cluster.maxRadius
        
//        print("🔧 지리적 범위 기반 크기 계산:")
//        print("   - 현재 클러스터 지리적 범위: \(cluster.maxRadius)m")
//        print("   - 최소 지리적 범위: \(minRadius)m")
//        print("   - 최대 지리적 범위: \(maxRadius)m")
        
        // 루트 보간법 적용 (지리적 범위 기준)
        if minRadius == maxRadius {
            let finalSize = (minSize + maxSize) / 2
            //print("🎯 POI 크기 결과: Cluster \(cluster.count)개 - 지리적 범위 동일, finalSize=\(finalSize)")
            return finalSize
        } else {
            let normalized = sqrt(Double(cluster.maxRadius - minRadius)) / sqrt(Double(maxRadius - minRadius))
            let finalSize = minSize + (maxSize - minSize) * CGFloat(normalized)
            
            //print("🎯 POI 크기 결과: Cluster \(cluster.count)개 - 지리적범위=\(cluster.maxRadius)m, normalized=\(normalized), finalSize=\(finalSize)")
            
            return finalSize
        }
    }
    
    /// 클러스터 수에 따라 루트 보간법으로 POI 크기를 계산합니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    ///   - sizeRange: (minSize: CGFloat, maxSize: CGFloat) - 크기 범위
    ///   - allClusters: 전체 클러스터 배열 (루트 보간법을 위한 정렬 기준)
    /// - Returns: POI 크기
    /// - Note: 클러스터 수를 기준으로 루트 보간법을 사용하여 크기를 결정합니다
    private func calculateClusterPOISizeWithRootInterpolation(
        for cluster: ClusterInfo,
        sizeRange: (minSize: CGFloat, maxSize: CGFloat),
        allClusters: [ClusterInfo]
    ) -> CGFloat {
        let minSize = sizeRange.minSize
        let maxSize = sizeRange.maxSize
        
        // 클러스터 수 기준으로 정렬
        let sortedClusters = allClusters.sorted { $0.count < $1.count }
        
        // 현재 클러스터의 순위 찾기 (estateIds 배열을 비교하여 식별)
        guard let currentIndex = sortedClusters.firstIndex(where: { 
            $0.estateIds == cluster.estateIds && 
            $0.centerCoordinate.latitude == cluster.centerCoordinate.latitude &&
            $0.centerCoordinate.longitude == cluster.centerCoordinate.longitude
        }) else {
            return minSize
        }
        
        let minCount = sortedClusters.first?.count ?? 1
        let maxCount = sortedClusters.last?.count ?? 1
        
        // 루트 보간법 적용
        if minCount == maxCount {
            return (minSize + maxSize) / 2
        } else {
            let normalized = sqrt(Double(cluster.count - minCount)) / sqrt(Double(maxCount - minCount))
            return minSize + (maxSize - minSize) * CGFloat(normalized)
        }
    }
    
    /// 클러스터 밀도에 따라 루트 보간법으로 투명도를 계산합니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    ///   - allClusters: 전체 클러스터 배열 (루트 보간법을 위한 정렬 기준)
    /// - Returns: 투명도 값 (0.5 ~ 1.0 범위)
    /// - Note: 클러스터 수(밀도)를 기준으로 루트 보간법을 사용하여 투명도를 결정합니다. 노이즈는 제외합니다.
    private func calculateClusterOpacityWithRootInterpolation(
        for cluster: ClusterInfo,
        allClusters: [ClusterInfo]
    ) -> CGFloat {
        let minOpacity: CGFloat = 0.5
        let maxOpacity: CGFloat = 1.0
        
        // 노이즈 제외하고 실제 클러스터만 필터링 (매물수 1개는 노이즈로 간주)
        let actualClusters = allClusters.filter { $0.count > 1 }
        
        // 실제 클러스터가 없으면 기본값 반환
        guard !actualClusters.isEmpty else {
            return minOpacity
        }
        
        // 실제 클러스터 수 기준으로 정렬
        let sortedClusters = actualClusters.sorted { $0.count < $1.count }
        
        // 현재 클러스터가 실제 클러스터인지 확인
        let isActualCluster = cluster.count > 1
        
        // 현재 클러스터의 순위 찾기
        guard let currentIndex = sortedClusters.firstIndex(where: { 
            $0.estateIds == cluster.estateIds && 
            $0.centerCoordinate.latitude == cluster.centerCoordinate.latitude &&
            $0.centerCoordinate.longitude == cluster.centerCoordinate.longitude
        }) else {
            // 노이즈인 경우 최소 투명도 반환
            return minOpacity
        }
        
        let minCount = sortedClusters.first?.count ?? 1
        let maxCount = sortedClusters.last?.count ?? 1
        
         
        

        
        // 루트 보간법 적용
        if minCount == maxCount {
            let result = (minOpacity + maxOpacity) / 2
            
            return result
        } else {
            let normalized = sqrt(Double(cluster.count - minCount)) / sqrt(Double(maxCount - minCount))
            let opacity = minOpacity + (maxOpacity - minOpacity) * CGFloat(normalized)
            let finalOpacity = max(minOpacity, min(maxOpacity, opacity))
            
            
            
            // 최소/최대 투명도 확인
            if cluster.count == minCount {
            
            } else if cluster.count == maxCount {
             
            }
            
            return finalOpacity
        }
    }
    
    /// 픽셀당 미터 비율을 계산합니다.
    /// 
    /// - Parameters:
    ///   - kakaoMap: 카카오맵 객체
    /// - Returns: 픽셀당 미터 비율
    private func calculateMetersPerPixel(kakaoMap: KakaoMap) -> Double {
        return calculateMaxDistance(mapView: kakaoMap) / sqrt(pow(kakaoMap.viewRect.width, 2) + pow(kakaoMap.viewRect.height, 2))
    }
}

