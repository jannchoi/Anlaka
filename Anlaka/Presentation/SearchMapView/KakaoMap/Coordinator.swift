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
            zoomLevel: 13,
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
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { [weak self] _ in
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
        // 줌 레벨에 상관없이 항상 HDBSCAN 사용
        return .hdbscan(zoomLevel: zoomLevel)
    }
    
    // MARK: - 랜덤 오프셋 생성 (보안을 위한 위치 오프셋)
    private func generateRandomOffset() -> (latOffset: Double, lonOffset: Double) {
        // 30~80m 범위에서 랜덤 거리 생성
        let distance = Double.random(in: 30...80)
        
        // 0~360도 범위에서 랜덤 방향 생성
        let bearing = Double.random(in: 0...360)
        
        // 위도/경도 오프셋 계산 (미터를 도 단위로 변환)
        let metersPerDegreeLat = 111_000.0
        let metersPerDegreeLon = 111_000.0 * cos(latitude * .pi / 180)
        
        let latOffset = (distance * cos(bearing * .pi / 180)) / metersPerDegreeLat
        let lonOffset = (distance * sin(bearing * .pi / 180)) / metersPerDegreeLon
        
        return (latOffset: latOffset, lonOffset: lonOffset)
    }
    
    // MARK: - 클러스터링 메인 메서드
    private func performClustering(_ pinInfos: [PinInfo], zoomLevel: Int) -> ([ClusterInfo], CGFloat?) {
        let clusteringType = getClusteringType(for: zoomLevel)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return ([], 0) }
        
        switch clusteringType {
        case .hdbscan(let zoomLevel):
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
            
            // 투명도는 고정값으로 설정 (크기로 매물 수 표현)
            for i in 0..<allClusters.count {
                allClusters[i] = ClusterInfo(
                    estateIds: allClusters[i].estateIds,
                    centerCoordinate: allClusters[i].centerCoordinate,
                    count: allClusters[i].count,
                    representativeImage: allClusters[i].representativeImage,
                    opacity: 0.8, // 고정 투명도
                    maxRadius: allClusters[i].maxRadius
                )
            }
            
            // 겹치지 않는 POI 크기 계산 (루트 보간법 유지)
            let totalClusters = allClusters.count // 실제 클러스터 수 사용
            let screenArea = kakaoMap.viewRect.width * kakaoMap.viewRect.height
            let availableAreaPerPOI = screenArea / CGFloat(totalClusters)
            let maxPoiSize = sqrt(availableAreaPerPOI) * 0.8 // 80%로 조정하여 여백 확보
            return (allClusters, maxPoiSize)
            
        case .fixedGrid(let zoomLevel):
            return clusterWith100mGrid(pinInfos, kakaoMap: kakaoMap, zoomLevel: zoomLevel)
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
    
    // MARK: - 100m 격자 기반 클러스터링 알고리즘 (보안성 우선)
    func clusterWith100mGrid(
        _ pinInfos: [PinInfo],
        kakaoMap: KakaoMap,
        zoomLevel: Int
    ) -> ([ClusterInfo], CGFloat?) {
        guard !pinInfos.isEmpty else { return ([], nil) }
        
        // 1. 화면 모서리 좌표
        let mapViewSize = kakaoMap.viewRect
        let topLeft = kakaoMap.getPosition(CGPoint(x: 0, y: 0)).wgsCoord.clLocationCoordinate
        let bottomRight = kakaoMap.getPosition(CGPoint(x: mapViewSize.width, y: mapViewSize.height)).wgsCoord.clLocationCoordinate
        let bottomLeft = kakaoMap.getPosition(CGPoint(x: 0, y: mapViewSize.height)).wgsCoord.clLocationCoordinate
        
        // 2. 100m 격자 크기 설정 (보안성 우선)
        let gridSize = 100.0 // 100m 고정 격자
        
        // 3. 격자 개수 계산 (화면 크기에 따라 동적 조정)
        let totalWidth = haversineDistance(from: bottomLeft, to: bottomRight)
        let totalHeight = haversineDistance(from: bottomLeft, to: topLeft)
        
        let gridCountX = max(1, Int(ceil(totalWidth / gridSize)))
        let gridCountY = max(1, Int(ceil(totalHeight / gridSize)))
        
        // 4. 격자별 매물 그룹화
        var gridClusters: [String: [PinInfo]] = [:]
        
        for pin in pinInfos {
            let pinCoord = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            let (gridX, gridY) = gridIndexForPin(pin: pinCoord, origin: bottomLeft, gridWidth: gridSize, gridHeight: gridSize)
            
            // 격자 범위 내에 있는 경우만 처리
            guard gridX >= 0, gridX < gridCountX, gridY >= 0, gridY < gridCountY else { continue }
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
            
            // 격자 중심점 계산
            let centerCoord = coordinateForGridCenter(
                gridX: gridX,
                gridY: gridY,
                origin: bottomLeft,
                gridWidth: gridSize,
                gridHeight: gridSize
            )
            
            // 보안성을 위한 maxRadius 설정 (100m 격자의 절반)
            let maxRadius = gridSize / 2.0
            
            let cluster = ClusterInfo(
                estateIds: estateIds,
                centerCoordinate: centerCoord,
                count: count,
                representativeImage: clusterPins.first?.image,
                opacity: nil, // 투명도는 아래에서 계산
                maxRadius: maxRadius
            )
            
            clusterInfos.append(cluster)
        }
        
        // 6. 투명도 계산 (루트 보간법 적용)
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
        
        // 7. POI 크기 계산 (100m 격자에 맞게 조정)
        let maxPoiSize = min(60.0, kakaoMap.viewRect.width / CGFloat(gridCountX) * 0.8)
        
        return (clusterInfos, maxPoiSize)
    }
    

    
    // MARK: - 원형 이미지 생성 (매물 수 표시용)
    private func createCircleImage(count: Int, poiSize: CGFloat?, cluster: ClusterInfo? = nil) -> UIImage {
        let size = CGSize(width: poiSize ?? 25, height: poiSize ?? 25)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)

            // 투명도 고정값 설정 (모든 클러스터 동일)
            let alpha: CGFloat = 0.8 // 고정 투명도 80%
            
            // OliveMist 색상으로 원형 배경 그리기
            let oliveMistColor = UIColor(named: "OliveMist") ?? UIColor(red: 0.6, green: 0.7, blue: 0.5, alpha: 1.0)
            
            // 투명도가 적용된 OliveMist 색상
            let alphaColor = oliveMistColor.withAlphaComponent(alpha)
            
            // 원형 배경 그리기
            context.cgContext.setFillColor(alphaColor.cgColor)
            context.cgContext.fillEllipse(in: rect)

            // 여러 매물일 때만 텍스트 표시
            if count > 1 {
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
        // 클러스터링 수행 (줌 레벨에 상관없이 HDBSCAN 사용)
        let (clusterInfos, maxPoiSize) = performClustering(pinInfos, zoomLevel: currentZoomLevel)
        createHDBSCANClusterPOIs(clusterInfos, maxPoiSize: maxPoiSize)
    }
    
    @MainActor
    private func createHDBSCANClusterPOIs(_ clusterInfos: [ClusterInfo], maxPoiSize: CGFloat?) {

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
        
        // 개별 매물과 그룹 클러스터를 분리하여 처리
        let individualClusters = adjustedClusters.filter { $0.cluster.count == 1 }
        let groupClusters = adjustedClusters.filter { $0.cluster.count > 1 }
        
        // 먼저 그룹 클러스터들을 처리 (원형에 매물 수 표시)
        for (index, adjustedCluster) in groupClusters.enumerated() {
            let cluster = adjustedCluster.cluster
            let baseSize = adjustedCluster.size
            
            // 매물 수 기반 마커 크기 계산 (루트 보간법)
            let sizeRange = (minSize: CGFloat(25.0), maxSize: CGFloat(50.0))
            let dynamicSize = calculateClusterPOISizeByCount(
                for: cluster,
                sizeRange: sizeRange,
                allClusters: clusterInfos
            )
            
            // 스타일 생성 (원형에 매물 수 표시)
            let styleID = createCircleStyle(for: cluster, index: index, poiSize: dynamicSize)
            
            // POI 옵션 설정
            let poiOption = PoiOptions(styleID: styleID)
            poiOption.rank = index
            poiOption.clickable = true
            
            let clusterID = "cluster_\(index)"
            clusters[clusterID] = cluster
            
            let poi = layer.addPoi(
                option: poiOption,
                at: adjustedCluster.center,
                callback: { result in }
            )
            
            if let poi = poi {
                poi.userObject = clusterID as NSString
                poi.show()
                currentPOIs[clusterID] = poi
            }
        }
        
        // 개별 매물들을 비동기로 처리 (bubble + thumbnail + 가격 정보)
        Task.detached(priority: .userInitiated) {
            let processedImages = await withTaskGroup(of: (Int, UIImage?).self) { group in
                for (index, adjustedCluster) in individualClusters.enumerated() {
                    group.addTask {
                        let cluster = adjustedCluster.cluster
                        if let firstEstateId = cluster.estateIds.first,
                           let pinInfo = self.currentPinInfos[firstEstateId] {
                            let image = await self.processEstateImage(for: pinInfo)
                            return (index, ImageValidationHelper.validateUIImage(image) ? image : nil)
                        }
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
                    guard let image = image else { continue }
                    
                    let adjustedCluster = individualClusters[index]
                    let cluster = adjustedCluster.cluster
                    
                    // 개별 매물 위치에 랜덤 오프셋 적용
                    let center: MapPoint
                    if let firstEstateId = cluster.estateIds.first,
                       let pinInfo = self.currentPinInfos[firstEstateId] {
                        let offset = self.generateRandomOffset()
                        let offsetLat = pinInfo.latitude + offset.latOffset
                        let offsetLon = pinInfo.longitude + offset.lonOffset
                        center = MapPoint(longitude: offsetLon, latitude: offsetLat)
                    } else {
                        center = adjustedCluster.center
                    }
                    
                    // 개별 매물용 스타일 생성 (기존 Grid 방식과 동일)
                    let styleID = self.createImageStyle(with: image, for: cluster, index: index)
                    
                    let poiOption = PoiOptions(styleID: styleID)
                    poiOption.rank = groupClusters.count + index
                    poiOption.clickable = true
                    
                    let clusterID = "cluster_\(groupClusters.count + index)"
                    self.clusters[clusterID] = cluster
                    
                    if let poi = layer.addPoi(
                        option: poiOption,
                        at: center
                    ) {
                        poi.userObject = clusterID as NSString
                        poi.show()
                        self.currentPOIs[clusterID] = poi
                    }
                }
            }
        }
    }


    @MainActor
    private func createGridClusterPOIs(_ clusterInfos: [ClusterInfo], zoomLevel: Int) {
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
                        // 개별 매물인 경우 랜덤 오프셋 적용
                        if let firstEstateId = cluster.estateIds.first,
                           let pinInfo = self.currentPinInfos[firstEstateId] {
                            let offset = self.generateRandomOffset()
                            let offsetLat = pinInfo.latitude + offset.latOffset
                            let offsetLon = pinInfo.longitude + offset.lonOffset
                            poiPosition = MapPoint(longitude: offsetLon, latitude: offsetLat)
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

    // 원형 스타일 생성 (HDBSCAN 클러스터링용) - 여러 매물용
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
    
    // 개별 매물용 스타일 생성 (bubble + thumbnail + 가격 정보)
    private func createIndividualPOIStyle(with image: UIImage, for cluster: ClusterInfo, index: Int) -> String {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return "" }
        let manager = kakaoMap.getLabelManager()
        
        let styleID = "individual_style_\(index)_\(Int(Date().timeIntervalSince1970))"
        
        // 개별 매물의 PinInfo 가져오기
        let pinInfo: PinInfo?
        if let firstEstateId = cluster.estateIds.first {
            pinInfo = currentPinInfos[firstEstateId]
        } else {
            pinInfo = nil
        }
        
        // bubble + thumbnail + 가격 정보가 포함된 이미지 생성
        let finalImage: UIImage
        do {
            finalImage = try applyStyle(to: image, size: CGSize(width: 35, height: 35), pinInfo: pinInfo)
        } catch {
            // 에러 발생 시 기본 이미지 사용
            finalImage = convertToPNGRGBA(image)
        }
        
        let iconStyle = PoiIconStyle(symbol: finalImage, anchorPoint: CGPoint(x: 0.5, y: 0.5))
        
        let perLevelStyles = [
            PerLevelPoiStyle(iconStyle: iconStyle, level: 0),
            PerLevelPoiStyle(iconStyle: iconStyle, level: 1),
            PerLevelPoiStyle(iconStyle: iconStyle, level: 2)
        ]
        
        let poiStyle = PoiStyle(styleID: styleID, styles: perLevelStyles)
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
        let size = CGSize(width: 35, height: 35) // 썸네일 크기 30x30

        guard let imagePath = pinInfo.image else {
            return createDefaultEstateImage(size: size)
        }
        
        // ImageLoader를 사용하여 이미지 로드
        if let loadedImage = await ImageLoader.shared.loadPOIImage(from: imagePath) {
            do {
                let processedImage = try applyStyle(to: loadedImage, size: size, pinInfo: pinInfo)
                return processedImage
            } catch {
                return createDefaultEstateImage(size: size)
            }
        } else {
            return createDefaultEstateImage(size: size)
        }
    }


    private func applyStyle(to image: UIImage, size: CGSize, pinInfo: PinInfo? = nil) throws -> UIImage {
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
        
        // 가격 정보가 있는 경우 높이를 늘림
        let hasPriceInfo = pinInfo?.deposit != nil || pinInfo?.monthlyRent != nil
        let priceInfoHeight: CGFloat = hasPriceInfo ? 10 : 0 // 텍스트 높이 10
        
        // 썸네일+텍스트 영역 크기
        let contentWidth = size.width // 30
        let contentHeight = size.height + priceInfoHeight // 30 + 10 = 40
        
        // bubble 크기: 썸네일+텍스트 영역을 감싸도록 설정
        let bubbleWidth = contentWidth + 8 // 30 + 8 = 38
        let bubbleHeight = contentHeight + 10 // 40 + 10 = 50
        let finalSize = CGSize(width: bubbleWidth + 6, height: bubbleHeight + 6) // 44 x 56
    
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
            
            // 가격 정보 추가
            if let pinInfo = pinInfo, hasPriceInfo {
                let priceText = formatPriceText(deposit: pinInfo.deposit, monthlyRent: pinInfo.monthlyRent)
                let priceAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 5, weight: .medium),
                    .foregroundColor: UIColor(named: "SubText") ?? UIColor.gray
                ]
                
                let priceSize = priceText.size(withAttributes: priceAttributes)
                let priceRect = CGRect(
                    x: (finalSize.width - priceSize.width) / 2,
                    y: imageRect.maxY + 2, // 썸네일 아래, bubble 안에
                    width: priceSize.width,
                    height: priceSize.height
                )
                
                // 가격 텍스트 (배경 없이)
                priceText.draw(in: priceRect, withAttributes: priceAttributes)
            }
        }

        guard ImageValidationHelper.validateUIImage(resultImage) else {
            throw ImageError.invalidImageFormat("최종 이미지 유효성 검사 실패")
        }

        let finalImage = convertToPNGRGBA(resultImage) // 최종적으로 PNG/RGBA 보장

        return finalImage
    }
    
    // 가격 텍스트 포맷팅
    private func formatPriceText(deposit: Double?, monthlyRent: Double?) -> String {
        var priceText = ""
        
        if let deposit = deposit {
            priceText += PresentationMapper.formatToShortUnitString(deposit)
        }
        
        if let monthlyRent = monthlyRent {
            if !priceText.isEmpty {
                priceText += "/"
            }
            priceText += PresentationMapper.formatToShortUnitString(monthlyRent)
        }
        
        return priceText.isEmpty ? "가격정보없음" : priceText
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
        
        // 줌 레벨과 상관없이 개별 매물이면 EstateDetailView로, 여러 매물이면 하단 스크롤뷰
        if cluster.estateIds.count == 1 {
            // 개별 매물: EstateDetailView로 이동
            print("개별 매물 탭: \(cluster.estateIds.first!)")
            onPOITap?(cluster.estateIds.first!)
        } else {
            print("여러 매물 탭: \(cluster.estateIds.count)개, onPOIGroupTap 존재: \(onPOIGroupTap != nil)")
            // 여러 매물: 하단 스크롤뷰 표시
            onPOIGroupTap?(cluster.estateIds)
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

    

    
    /// 클러스터의 위치와 크기를 결정합니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    ///   - kakaoMap: 카카오맵 객체
    ///   - allClusters: 전체 클러스터 배열 (크기 계산용)
    /// - Returns: (center: MapPoint, size: CGFloat) - POI 중심점과 크기
    /// - Note: 매물 수 기반으로 크기를 계산합니다
    private func calculateClusterPOIPositionAndSize(
        for cluster: ClusterInfo, 
        kakaoMap: KakaoMap,
        allClusters: [ClusterInfo]
    ) -> (center: MapPoint, size: CGFloat) {
        // 클러스터의 중심점
        let center = MapPoint(longitude: cluster.centerCoordinate.longitude, latitude: cluster.centerCoordinate.latitude)
        
        // 매물 수 기반 크기 계산 (25pt ~ 50pt)
        let sizeRange = (minSize: CGFloat(25.0), maxSize: CGFloat(50.0))
        let finalSize = calculateClusterPOISizeByCount(
            for: cluster,
            sizeRange: sizeRange,
            allClusters: allClusters
        )
        
        return (center: center, size: finalSize)
    }
    
    /// 클러스터 간 겹침을 방지하면서 POI 크기와 위치를 조정합니다.
    /// 
    /// - Parameters:
    ///   - clusterInfos: 클러스터 정보 배열
    ///   - kakaoMap: 카카오맵 객체
    /// - Returns: 조정된 클러스터 정보 배열 (위치와 크기 포함)
    private func adjustClusterPositionsToPreventOverlap(_ clusterInfos: [ClusterInfo], kakaoMap: KakaoMap) -> [(cluster: ClusterInfo, center: MapPoint, size: CGFloat)] {
        var adjustedClusters: [(cluster: ClusterInfo, center: MapPoint, size: CGFloat)] = []
        
        for cluster in clusterInfos {
            let (center, size) = calculateClusterPOIPositionAndSize(
                for: cluster, 
                kakaoMap: kakaoMap,
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
                    
                    // 거리를 픽셀 단위로 변환 (고정 비율 사용)
                    let pixelDistance = CGFloat(distance / 10.0) // 10m = 1픽셀로 가정
                    
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
                
                let pixelDistance = CGFloat(distance / 10.0) // 10m = 1픽셀로 가정
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
    

    
    /// 클러스터의 매물 수에 따라 루트 보간법으로 POI 크기를 계산합니다.
    /// 
    /// - Parameters:
    ///   - cluster: 클러스터 정보
    ///   - sizeRange: (minSize: CGFloat, maxSize: CGFloat) - 크기 범위
    ///   - allClusters: 전체 클러스터 배열 (루트 보간법을 위한 정렬 기준)
    /// - Returns: POI 크기
    /// - Note: 매물 수를 기준으로 루트 보간법을 사용하여 크기를 결정합니다
    private func calculateClusterPOISizeByCount(
        for cluster: ClusterInfo,
        sizeRange: (minSize: CGFloat, maxSize: CGFloat),
        allClusters: [ClusterInfo]
    ) -> CGFloat {
        let minSize = sizeRange.minSize
        let maxSize = sizeRange.maxSize
        
        // 매물 수 기준으로 정렬
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
            // 모든 클러스터의 매물 수가 동일한 경우 중간값 반환
            return minSize 
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
    

}
