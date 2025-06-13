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
    var isInteractive: Bool
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
    
    
    // 클러스터링 관련 프로퍼티 추가 (기존 Coordinator 클래스에 추가)
    private var onClusterTap: ((ClusterInfo) -> Void)?
    private var onPOITap: ((String) -> Void)?
    private var onPOIGroupTap: (([String]) -> Void)?
    private var clusters: [String: ClusterInfo] = [:]  // clusterID -> ClusterInfo
    
    // 줌 레벨별 클러스터링 반경 설정
    private let clusterRadiusByZoomLevel: [Int: Double] = [
        6: 640000, 7: 320000, 8: 160000, 9: 80000, 10: 40000,
        11: 20000, 12: 10000, 13: 5000, 14: 2500
    ]
    
    
    init(
        centerCoordinate: CLLocationCoordinate2D,
        isInteractive: Bool,
        onMapReady: ((Double) -> Void)? = nil,
        onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)? = nil
    ) {
        self.longitude = centerCoordinate.longitude
        self.latitude = centerCoordinate.latitude
        self.onMapReady = onMapReady
        self.onMapChanged = onMapChanged
        self.isInteractive = isInteractive
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
            mapView.setScaleBarPosition(origin: GuiAlignment(vAlign: .bottom, hAlign: .right), position: CGPoint(x: 10.0, y: 10.0))
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
        guard isInteractive else { return }
        
        // 현재 줌 레벨과 좌표 정보 출력
        let currentZoomLevel = kakaoMap.zoomLevel
        //print("\n📏 현재 줌 레벨: \(currentZoomLevel)")
        
        // 뷰의 좌상단과 우상단 좌표 계산
        let topLeftPoint = kakaoMap.getPosition(CGPoint(x: 0, y: 0))
        let topRightPoint = kakaoMap.getPosition(CGPoint(x: kakaoMap.viewRect.width, y: 0))
        
        // print("📍 좌상단 좌표: lat: \(topLeftPoint.wgsCoord.latitude), lon: \(topLeftPoint.wgsCoord.longitude)")
        // print("📍 우상단 좌표: lat: \(topRightPoint.wgsCoord.latitude), lon: \(topRightPoint.wgsCoord.longitude)")
        
        // 좌상단과 우상단 사이의 실제 거리 계산 (미터)
        let topLeftLocation = CLLocation(latitude: topLeftPoint.wgsCoord.latitude, longitude: topLeftPoint.wgsCoord.longitude)
        let topRightLocation = CLLocation(latitude: topRightPoint.wgsCoord.latitude, longitude: topRightPoint.wgsCoord.longitude)
        let distanceInMeters = topLeftLocation.distance(from: topRightLocation)
        metersPerPt = distanceInMeters / Double(kakaoMap.viewRect.width)
        // print("📏 화면 가로 실제 거리: \(String(format: "%.2f", distanceInMeters))m")
        // print("📱 화면 가로 픽셀: \(kakaoMap.viewRect.width)pt")
        // print("🔍 1픽셀당 실제 거리: \(String(format: "%.2f", distanceInMeters/Double(kakaoMap.viewRect.width)))m")
        
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
    
    
    private func setupDefaultPOIStyle(_ manager: LabelManager) {
        let textLineStyles = [
            PoiTextLineStyle(textStyle: TextStyle(
                fontSize: 12,
                fontColor: UIColor.white,
                strokeThickness: 1,
                strokeColor: UIColor.black
            ))
        ]
        
        let defaultImage = UIImage(systemName: "mappin") ?? UIImage()
        var styles: [PerLevelPoiStyle] = []
        
        for level in 0...20 {
            let iconStyle = PoiIconStyle(
                symbol: defaultImage,
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            )
            
            let textStyle = PoiTextStyle(textLineStyles: textLineStyles)
            textStyle.textLayouts = [.bottom]
            
            styles.append(PerLevelPoiStyle(
                iconStyle: iconStyle,
                textStyle: textStyle,
                padding: -2.0,
                level: level
            ))
        }
        
        let poiStyle = PoiStyle(styleID: defaultStyleID, styles: styles)
        manager.addPoiStyle(poiStyle)
    }
    
    // MARK: - POI Style 생성 메서드 (디버깅 버전)
    @MainActor
    private func createPOIStyle(for pinInfo: PinInfo, with image: UIImage, index: Int) -> String {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            // print("❌ [Style-\(index)] KakaoMap 가져오기 실패")
            return ""
        }
        let manager = kakaoMap.getLabelManager()
        
        let styleID = "style_\(pinInfo.estateId)_\(index)_\(Int(Date().timeIntervalSince1970))"
        
        
        // 이미지 크기 검증
        guard image.size.width > 0 && image.size.height > 0 else {
            // print("❌ [Style-\(index)] 이미지 크기가 0 - 스타일 생성 실패")
            return ""
        }
        
        // CGImage 검증
        guard image.cgImage != nil else {
            // print("❌ [Style-\(index)] CGImage가 nil - 스타일 생성 실패")
            return ""
        }
        
        // 이미지가 너무 큰 경우 리사이징 (카카오맵 제한 고려)
        let maxSize: CGFloat = 64.0  // 카카오맵 권장 최대 크기
        let resizedImage: UIImage
        
        if max(image.size.width, image.size.height) > maxSize {
            let scale = maxSize / max(image.size.width, image.size.height)
            let newSize = CGSize(
                width: image.size.width * scale,
                height: image.size.height * scale
            )
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
            
            print("🔄 [Style-\(index)] 이미지 리사이징: \(image.size) -> \(newSize)")
        } else {
            resizedImage = image
        }
        
        // POI 아이콘 스타일 생성 (앵커 포인트 조정)
        let iconStyle = PoiIconStyle(
            symbol: resizedImage,
            anchorPoint: CGPoint(x: 0.5, y: 0.5)  // 중심점으로 변경
        )
        
        print("🎯 [Style-\(index)] 아이콘 스타일 생성 - 앵커: (0.5, 0.5)")
        
        // 텍스트 스타일 (더 명확하게)
        let textLineStyles = [
            PoiTextLineStyle(textStyle: TextStyle(
                fontSize: 14,           // 폰트 크기 증가
                fontColor: UIColor.black,  // 검은색으로 변경
                strokeThickness: 2,     // 외곽선 두께 증가
                strokeColor: UIColor.white  // 흰색 외곽선
            ))
        ]
        
        let textStyle = PoiTextStyle(textLineStyles: textLineStyles)
        textStyle.textLayouts = [.bottom]  // 텍스트를 아이콘 아래에 배치
        
        // print("📝 [Style-\(index)] 텍스트 스타일 생성 - 위치: bottom")
        
        // 레벨별 스타일 생성 (여러 줌 레벨에서 보이도록)
        let perLevelStyles = [
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: textStyle, level: 0),
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: textStyle, level: 1),
            PerLevelPoiStyle(iconStyle: iconStyle, textStyle: textStyle, level: 2)
        ]
        
        let poiStyle = PoiStyle(styleID: styleID, styles: perLevelStyles)
        
        // 스타일 등록 전후 시간 측정
        let beforeAddStyle = CFAbsoluteTimeGetCurrent()
        let addResult = manager.addPoiStyle(poiStyle)
        let afterAddStyle = CFAbsoluteTimeGetCurrent()
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let addStyleTime = afterAddStyle - beforeAddStyle
        
        return styleID
    }
    
    // MARK: - UIImage 생성 메서드 (Step 1)
    private func createUIImages(from pinInfos: [PinInfo]) async -> [(pinInfo: PinInfo, image: UIImage, index: Int)] {
        let imageLoadStartTime = CFAbsoluteTimeGetCurrent()
        
        
        var poiDataArray: [(pinInfo: PinInfo, image: UIImage, index: Int)] = []
        
        for (index, pinInfo) in pinInfos.enumerated() {
            let imageStartTime = CFAbsoluteTimeGetCurrent()
            
            
            let finalImage: UIImage
            
            if let imagePath = pinInfo.image {
                
                if let cachedImage = ImageCache.shared.image(forKey: imagePath) {
                    
                    finalImage = cachedImage
                } else if let downloadedImage = await ImageDownsampler.downloadAndDownsample(
                    imagePath: imagePath,
                    to: poiImageSize
                ) {
                    ImageCache.shared.setImage(downloadedImage, forKey: imagePath)
                    finalImage = downloadedImage
                } else {
                    
                    finalImage = await MainActor.run {
                        return UIImage(systemName: "mappin") ?? UIImage()
                    }
                }
            } else {
                
                finalImage = await MainActor.run {
                    return UIImage(systemName: "mappin") ?? UIImage()
                }
            }
            
            let imageTime = CFAbsoluteTimeGetCurrent() - imageStartTime
            
            
            poiDataArray.append((pinInfo: pinInfo, image: finalImage, index: index))
        }
        
        let imageLoadTime = CFAbsoluteTimeGetCurrent() - imageLoadStartTime
        
        
        return poiDataArray
    }
    
    // MARK: - POI 옵션 생성 메서드 (Step 2) - 렌더링 타이밍 최적화
    @MainActor
    private func createPoiOptions(from poiDataArray: [(pinInfo: PinInfo, image: UIImage, index: Int)]) -> [(poiData: (pinInfo: PinInfo, image: UIImage, index: Int), styleID: String, poiOption: PoiOptions)] {
        let optionStartTime = CFAbsoluteTimeGetCurrent()
        
        
        var poiOptionsArray: [(poiData: (pinInfo: PinInfo, image: UIImage, index: Int), styleID: String, poiOption: PoiOptions)] = []
        
        var styleInfos: [(poiData: (pinInfo: PinInfo, image: UIImage, index: Int), styleID: String)] = []
        
        for poiData in poiDataArray {
            
            // 이미지 유효성 검증
            guard poiData.image.size.width > 0 && poiData.image.size.height > 0 else {
                print("❌ [Step 2-1-\(poiData.index)] 유효하지 않은 이미지 크기 - 건너뜀")
                continue
            }
            
            // 스타일 생성 및 등록
            let styleID = createPOIStyle(
                for: poiData.pinInfo,
                with: poiData.image,
                index: poiData.index
            )
            
            guard !styleID.isEmpty else {
                print("❌ [Step 2-1-\(poiData.index)] 스타일 생성 실패 - 건너뜀")
                continue
            }
            
            styleInfos.append((poiData: poiData, styleID: styleID))
            
        }
        
        // 2단계: 스타일 적용 대기 시간
        let waitTime: UInt64 = 50_000_000 // 0.05초 나노초
        
        // 동기적 대기 (Task.sleep 대신)
        Thread.sleep(forTimeInterval: 0.05)
        
        // 3단계: POI 옵션 생성
        
        for styleInfo in styleInfos {
            let poiData = styleInfo.poiData
            let styleID = styleInfo.styleID
            
            // POI 옵션 생성
            let poiOption = PoiOptions(styleID: styleID)
            poiOption.rank = poiData.index
            poiOption.clickable = true
            
            // 텍스트가 있는 경우에만 추가
            if !poiData.pinInfo.title.isEmpty {
                poiOption.addText(PoiText(text: poiData.pinInfo.title, styleIndex: 0))
                print("📝 [Step 2-3-\(poiData.index)] 텍스트 추가: '\(poiData.pinInfo.title)'")
            }
            
            poiOptionsArray.append((poiData: poiData, styleID: styleID, poiOption: poiOption))
            
        }
        
        let optionTime = CFAbsoluteTimeGetCurrent() - optionStartTime
        
        
        return poiOptionsArray
    }
    
    // MARK: - POI 표시 메서드 (Step 3)
    @MainActor
    private func showPOIs(_ poiOptionsArray: [(poiData: (pinInfo: PinInfo, image: UIImage, index: Int), styleID: String, poiOption: PoiOptions)], layer: LabelLayer) {
        let showStartTime = CFAbsoluteTimeGetCurrent()
        
        var successCount = 0
        var failCount = 0
        var createdPOIs: [Poi] = []
        
        for poiOptionData in poiOptionsArray {
            let singleShowStartTime = CFAbsoluteTimeGetCurrent()
            let poiData = poiOptionData.poiData
            let poiOption = poiOptionData.poiOption
            
            // POI 추가
            let beforeAddPoi = CFAbsoluteTimeGetCurrent()
            let poi = layer.addPoi(
                option: poiOption,
                at: MapPoint(longitude: poiData.pinInfo.longitude, latitude: poiData.pinInfo.latitude),
                callback: { result in
                    
                }
            )
            let afterAddPoi = CFAbsoluteTimeGetCurrent()
            
            if let poi = poi {
                
                poi.show()
                
                createdPOIs.append(poi)
                
                let singleShowTime = CFAbsoluteTimeGetCurrent() - singleShowStartTime
                let addPoiTime = afterAddPoi - beforeAddPoi
                
                successCount += 1
            } else {
                
                failCount += 1
            }
        }
        
        let showTime = CFAbsoluteTimeGetCurrent() - showStartTime
        
    }
    
    func clearAllPOIs() {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID) else { return }
        layer.clearAllItems()
        currentPOIs.removeAll()
        clusters.removeAll()
    }
    
}

// MARK: - 차분 계산 메서드 추가
extension Coordinator {
    
    /// 새로운 PinInfo 배열과 기존 데이터를 비교하여 차분을 계산
    private func calculatePOIDiff(newPinInfos: [PinInfo]) -> POIDiff {
        let newPinInfoDict = Dictionary(uniqueKeysWithValues: newPinInfos.map { ($0.estateId, $0) })
        
        var toAdd: [PinInfo] = []
        var toRemove: [String] = []
        var toUpdate: [PinInfo] = []
        
        // 새로 추가될 POI들 찾기
        for (estateId, newPinInfo) in newPinInfoDict {
            if currentPinInfos[estateId] == nil {
                toAdd.append(newPinInfo)
            } else if let currentPinInfo = currentPinInfos[estateId],
                      !arePinInfosEqual(currentPinInfo, newPinInfo) {
                toUpdate.append(newPinInfo)
            }
        }
        
        // 제거될 POI들 찾기
        for estateId in currentPinInfos.keys {
            if newPinInfoDict[estateId] == nil {
                toRemove.append(estateId)
            }
        }
        
        return POIDiff(toAdd: toAdd, toRemove: toRemove, toUpdate: toUpdate)
    }
    
    /// PinInfo 객체들이 동일한지 비교
    private func arePinInfosEqual(_ lhs: PinInfo, _ rhs: PinInfo) -> Bool {
        return lhs.estateId == rhs.estateId &&
        lhs.title == rhs.title &&
        lhs.longitude == rhs.longitude &&
        lhs.latitude == rhs.latitude &&
        lhs.image == rhs.image
    }
    
    /// 현재 뷰포트가 이전과 비교해서 업데이트가 필요한지 확인
    private func shouldUpdatePOIs(newCenter: CLLocationCoordinate2D, newMaxDistance: Double) -> Bool {
        guard let lastCenter = lastCenter else { return true }
        
        // 중심점이 크게 이동했거나, 더 넓은 범위를 커버하게 된 경우
        let centerDistance = CLLocation(latitude: lastCenter.latitude, longitude: lastCenter.longitude)
            .distance(from: CLLocation(latitude: newCenter.latitude, longitude: newCenter.longitude))
        
        let significantMove = centerDistance > (lastMaxDistance * 0.3) // 이전 범위의 30% 이상 이동
        let zoomedOut = newMaxDistance > lastMaxDistance * 1.1 // 10% 이상 확대된 경우
        
        return significantMove || zoomedOut
    }
}

// MARK: - 효율적인 POI 업데이트 메서드 (기존 updatePOIs 대체)
extension Coordinator {
    
    // func updatePOIsEfficiently(_ pinInfos: [PinInfo], currentCenter: CLLocationCoordinate2D, maxDistance: Double) {
    //     let diff = calculatePOIDiff(newPinInfos: pinInfos)
    
    //     // 변경사항이 없으면 업데이트하지 않음
    //     if !diff.hasChanges {
    //         print("🔄 POI 업데이트 불필요 - 변경사항 없음")
    //         return
    //     }
    
    //     let overallStartTime = CFAbsoluteTimeGetCurrent()
    
    //     guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
    //         print("❌ KakaoMap 가져오기 실패")
    //         return
    //     }
    
    //     let manager = kakaoMap.getLabelManager()
    //     guard let layer = manager.getLabelLayer(layerID: layerID) else {
    //         print("❌ 레이어 가져오기 실패")
    //         return
    //     }
    
    //     print("📊 POI 차분 분석 - 추가: \(diff.toAdd.count), 제거: \(diff.toRemove.count), 업데이트: \(diff.toUpdate.count)")
    //     print("♻️ 유지되는 POI: \(currentPOIs.count - diff.toRemove.count - diff.toUpdate.count)개")
    
    //     // 1. 제거 작업만 수행
    //     removePOIs(diff.toRemove, from: layer)
    
    //     // 2. 업데이트 대상도 제거 (변경된 정보로 새로 생성하기 위해)
    //     let updateEstateIds = diff.toUpdate.map { $0.estateId }
    //     removePOIs(updateEstateIds, from: layer)
    
    //     // 3. 새로 추가할 POI들만 생성 (추가 + 업데이트)
    //     let poisToCreate = diff.toAdd + diff.toUpdate
    
    //     if !poisToCreate.isEmpty {
    //         Task {
    //             let poiDataArray = await createUIImages(from: poisToCreate)
    
    //             await MainActor.run {
    //                 let poiOptionsArray = createPoiOptions(from: poiDataArray)
    //                 addPOIs(poiOptionsArray, to: layer)
    
    //                 // 상태 업데이트
    //                 updateCurrentState(with: pinInfos, center: currentCenter, maxDistance: maxDistance)
    
    //                 let totalTime = CFAbsoluteTimeGetCurrent() - overallStartTime
    //                 print("🎉 차분 업데이트 완료! - 전체 시간: \(String(format: "%.3f", totalTime * 1000))ms")
    //                 print("📍 현재 총 POI 개수: \(currentPOIs.count)개")
    //             }
    //         }
    //     } else {
    //         // 추가할 POI가 없는 경우에도 상태 업데이트
    //         updateCurrentState(with: pinInfos, center: currentCenter, maxDistance: maxDistance)
    //     }
    // }
    
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
            //print("🗑️ POI \(removedCount)개 제거 완료")
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
            print("✅ POI \(addedCount)개 추가 완료")
        }
    }
    
    /// 현재 상태를 업데이트하는 메서드
    private func updateCurrentState(with pinInfos: [PinInfo], center: CLLocationCoordinate2D, maxDistance: Double) {
        lastCenter = center
        lastMaxDistance = maxDistance
        
        // 현재 PinInfo 상태도 업데이트 (제거된 것들은 이미 위에서 제거됨)
        for pinInfo in pinInfos {
            currentPinInfos[pinInfo.estateId] = pinInfo
        }
    }
}

extension Coordinator {
    
    
    // 초기화 메서드 수정 (기존 init에 추가)
    convenience init(
        centerCoordinate: CLLocationCoordinate2D,
        isInteractive: Bool,
        onMapReady: ((Double) -> Void)? = nil,
        onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)? = nil,
        onClusterTap: ((ClusterInfo) -> Void)? = nil,
        onPOITap: ((String) -> Void)? = nil,
        onPOIGroupTap: (([String]) -> Void)? = nil
    ) {
        self.init(centerCoordinate: centerCoordinate, isInteractive: isInteractive, onMapReady: onMapReady, onMapChanged: onMapChanged)
        self.onClusterTap = onClusterTap
        self.onPOITap = onPOITap
        self.onPOIGroupTap = onPOIGroupTap
    }
    
    // MARK: - 줌 레벨에 따른 클러스터링 타입 결정
    private func getClusteringType(for zoomLevel: Int) -> ClusteringType {
        if zoomLevel >= 6 && zoomLevel <= 16 {
            return .zoomLevel6to16
        } else {
            return .zoomLevel17Plus
        }
    }
    
    // MARK: - 클러스터링 메인 메서드
    private func performClustering(_ pinInfos: [PinInfo], zoomLevel: Int) -> ([ClusterInfo], CGFloat?) {
        let clusteringType = getClusteringType(for: zoomLevel)
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return ([], 0) }
        
        switch clusteringType {
        case .zoomLevel6to16:
            return clusterPinInfosDynamicWeighted_new(pinInfos, kakaoMap: kakaoMap)
        case .zoomLevel17Plus:
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
        let poiSize = kakaoMap.viewRect.width / 3 * 0.6
        //let poiSize = calculatePoiSize(forGridSize: gridWidth)
        
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
        
        return (clusterInfos, poiSize)
    }

    // MARK: - 원형 이미지 생성 (매물 수 표시용)
    private func createCircleImage(count: Int, poiSize: CGFloat?) -> UIImage {
        let size = CGSize(width: poiSize ?? 50, height: poiSize ?? 50)
        
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cgContext = context.cgContext
            
            // 원형 배경
            cgContext.setFillColor(UIColor.oliveMist.cgColor)
            cgContext.fillEllipse(in: rect)
            
            // 테두리
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineWidth(2.0)
            cgContext.strokeEllipse(in: rect)
            
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
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let cgContext = context.cgContext
            
            // 빨간 원형 배경
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
    }
}

// MARK: - 클러스터링 기반 POI 업데이트 메서드 (기존 updatePOIsEfficiently 대체)
extension Coordinator {
    
    @MainActor func updatePOIsWithClustering(_ pinInfos: [PinInfo], currentCenter: CLLocationCoordinate2D, maxDistance: Double) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            print("🚫 KakaoMap 객체를 가져올 수 없습니다.")
            return
        }
        
        let currentZoomLevel = Int(kakaoMap.zoomLevel)
        
//        // 줌 레벨 17 이상 제한
//        if currentZoomLevel > 17 {
//            print("⚠️ 줌 레벨이 17을 초과하여 17로 제한합니다.")
//            let cameraUpdate = CameraUpdate.make(
//                target: MapPoint(longitude: currentCenter.longitude, latitude: currentCenter.latitude),
//                zoomLevel: 17,
//                rotation: 0,
//                tilt: 0,
//                mapView: kakaoMap
//            )
//            kakaoMap.moveCamera(cameraUpdate)
//            return
//        }

        // currentPinInfos 업데이트
        currentPinInfos.removeAll()
        for pinInfo in pinInfos {
            currentPinInfos[pinInfo.estateId] = pinInfo
        }
        
        // 기존 POI 모두 제거
        //print("🗑️ 기존 POI 제거 시작")
        clearAllPOIs()
        //print("✅ 기존 POI 제거 완료")
        
        // 클러스터링 수행
        //print("\n🔄 클러스터링 시작 - 매물 수: \(pinInfos.count)개")
        let (clusterInfos, poiSize) = performClustering(pinInfos, zoomLevel: currentZoomLevel)
        //print("✅ 클러스터링 완료 - 클러스터 수: \(clusterInfos.count)개")
        
        // zoomLevel에 따라 다른 처리
        Task {
            if currentZoomLevel <= 14 {
                //print("\n🎨 저줌 레벨 POI 생성 시작 (원형 클러스터)")
                await createClusterPOIsForLowZoom(clusterInfos, poiSize: poiSize)
                
            } else {
                //print("\n🎨 고줌 레벨 POI 생성 시작 (이미지 기반)")
                await createClusterPOIsForHighZoom(clusterInfos, zoomLevel: currentZoomLevel)
            }
        }
    }
    
    @MainActor
    private func createClusterPOIsForLowZoom(_ clusterInfos: [ClusterInfo], poiSize: CGFloat?) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID) else {
            print("❌ 레이어 또는 맵 객체 생성 실패")
            return
        }
        
        //print("🔄 저줌 레벨 POI 생성 중...")
        clusters.removeAll()
        
        for (index, cluster) in clusterInfos.enumerated() {
            //print("\n📌 클러스터 #\(index) 처리 중")
            //print("- 포함된 매물 수: \(cluster.count)")
            //print("- 중심 좌표: lat: \(cluster.centerCoordinate.latitude), lon: \(cluster.centerCoordinate.longitude)")
            
            let styleID = createCircleStyle(for: cluster, index: index, poiSize: poiSize)
            //print("- 생성된 스타일 ID: \(styleID)")
            
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
                //print("✅ POI 생성 및 표시 완료")
            } else {
                print("❌ POI 생성 실패")
            }
        }
        
        print("\n📊 최종 결과:")
        print("- 생성된 총 POI 수: \(currentPOIs.count)")
        print("- 등록된 클러스터 수: \(clusters.count)")
    }
    
    @MainActor
    private func createClusterPOIsForHighZoom(_ clusterInfos: [ClusterInfo], zoomLevel: Int) {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLabelLayer(layerID: layerID) else {
            print("❌ 레이어 또는 맵 객체 생성 실패")
            return
        }
        
        //print("🔄 고줌 레벨 POI 생성 중... (줌 레벨: \(zoomLevel))")
        
        // 상태 초기화
        clearAllPOIs()

        Task {
            // 모든 이미지 처리를 동시에 시작
            async let processedImages = withTaskGroup(of: (Int, UIImage).self) { group in
                for (index, cluster) in clusterInfos.enumerated() {
                    group.addTask {
                        print(cluster.estateIds.first)
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
                    addBadgeToPOI(poi, count: clusterInfos.count)
                    poi.show()
                    currentPOIs[clusterID] = poi
                }
            }
        }
    }
    
    // 원형 스타일 생성 (zoomLevel 14 이하)
    private func createCircleStyle(for cluster: ClusterInfo, index: Int, poiSize: CGFloat?) -> String {
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
        let padding: CGFloat = 4
        let cornerRadius: CGFloat = 12
        let borderWidth: CGFloat = 2
        let borderColor: UIColor = .white
        if let imagePath = pinInfo.image {
            print("⛑️ imagePath: \(imagePath)")
            if let cachedImage = ImageCache.shared.image(forKey: imagePath) {
                return applyStyle(to: cachedImage, size: size, padding: padding, cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor)
            }
            
            if let downloadedImage = await ImageDownsampler.downloadAndDownsample(
                imagePath: imagePath,
                to: size
            ) {
                let processedImage = applyStyle(to: downloadedImage, size: size, padding: padding, cornerRadius: cornerRadius, borderWidth: borderWidth, borderColor: borderColor)
                ImageCache.shared.setImage(processedImage, forKey: imagePath)
                return processedImage
            }
        }
        
        return createDefaultEstateImage(size: size)
    }
    
    // 이미지 스타일 적용
    private func applyStyle(to image: UIImage, size: CGSize, padding: CGFloat, cornerRadius: CGFloat, borderWidth: CGFloat, borderColor: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 배경 패스 (테두리와 코너 라운딩을 위한)
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            
            // 테두리 그리기
            borderColor.setStroke()
            context.cgContext.setLineWidth(borderWidth)
            path.stroke()
            
            // 이미지를 패딩을 고려하여 그리기
            let imageRect = rect.insetBy(dx: padding, dy: padding)
            context.cgContext.saveGState()
            path.addClip()
            image.draw(in: imageRect)
            context.cgContext.restoreGState()
        }
    }
    
    // 기본 이미지 생성 (zoomLevel 17 이상)
    private func createDefaultEstateImage(size: CGSize) -> UIImage {
        guard let defaultImage =  UIImage(systemName: "mappin") else {return UIImage()}
        return defaultImage
    }
}

// MARK: - POI 클릭 이벤트 처리
extension Coordinator {
    
    func poiDidTapped(kakaoMap: KakaoMap, layerID: String, poiID: String, position: MapPoint) {
        guard let poi = currentPOIs.values.first(where: { $0.itemID == poiID }),
              let clusterID = poi.userObject as? String,
              let cluster = clusters[clusterID] else { return }
        
        let currentZoomLevel = Int(kakaoMap.zoomLevel)
        let clusteringType = getClusteringType(for: currentZoomLevel)
        
        switch clusteringType {
        case .zoomLevel6to16:
            // 클러스터 탭 이벤트 발생
            onClusterTap?(cluster)
            // 그룹 내 모든 매물이 보이도록 줌 레벨 확장
            expandToShowAllEstates(cluster, kakaoMap: kakaoMap)
            
        case .zoomLevel17Plus:
            // SearchMapView로 전환하여 해당 범위 매물들 표시
            if cluster.estateIds.count == 1 {
                onPOITap?(cluster.estateIds.first!)
            } else {
                onPOIGroupTap?(cluster.estateIds)
            }
        }
    }
    
    private func expandToShowAllEstates(_ cluster: ClusterInfo, kakaoMap: KakaoMap) {
        // 클러스터 내 모든 매물을 포함하는 경계 계산
        guard !cluster.estateIds.isEmpty else { return }
        
        // 클러스터의 모든 매물 좌표를 포함하는 AreaRect 생성
        let points = [MapPoint(longitude: cluster.centerCoordinate.longitude, latitude: cluster.centerCoordinate.latitude)]
        let areaRect = AreaRect(points: points)
        
        // AreaRect를 기반으로 카메라 업데이트 생성
        let cameraUpdate = CameraUpdate.make(area: areaRect, levelLimit: 21)  // 최대 줌 레벨을 17로 제한
        
        kakaoMap.moveCamera(cameraUpdate)
        
        // 줌 변경 후 POI 업데이트는 cameraDidStopped에서 자동으로 처리됨
    }
}
extension Coordinator {
    private func calculatePoiSize(forGridSize gridSize: Double) -> CGFloat {
        // 메인 스레드가 아닌 경우 메인 스레드에서 실행
        if !Thread.isMainThread {
            var result: CGFloat = 0
            DispatchQueue.main.sync {
                result = calculatePoiSize(forGridSize: gridSize)
            }
            return result
        }
        
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else { return 40 }
        
        // 화면 중앙의 좌표와 gridSize 미터만큼 떨어진 좌표의 실제 거리를 계산
        let centerPoint = kakaoMap.getPosition(CGPoint(x: kakaoMap.viewRect.width / 2, y: kakaoMap.viewRect.height / 2))
        let rightPoint = kakaoMap.getPosition(CGPoint(x: kakaoMap.viewRect.width, y: kakaoMap.viewRect.height / 2))
        
        let centerLocation = CLLocation(
            latitude: centerPoint.wgsCoord.latitude,
            longitude: centerPoint.wgsCoord.longitude
        )
        let rightLocation = CLLocation(
            latitude: rightPoint.wgsCoord.latitude,
            longitude: rightPoint.wgsCoord.longitude
        )
        
        // 화면 가로의 실제 거리(미터)와 픽셀 수를 이용해 1픽셀당 실제 거리 계산
        let distanceInMeters = centerLocation.distance(from: rightLocation)
        let pixelsPerMeter = Double(kakaoMap.viewRect.width / 2) / distanceInMeters
        
        // gridSize를 픽셀로 변환
        let pixels = gridSize * pixelsPerMeter
        
        // POI 크기 계산 (최소/최대 제한 적용)
        let size = CGFloat(pixels * 0.8)
        let minSize: CGFloat = 20
        let maxSize: CGFloat = 60
        print(pixels, size)
        return min(max(size, minSize), maxSize)
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
