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
    var onMapReady: ((Double) -> Void)?
    var onMapChanged: ((CLLocationCoordinate2D, Double) -> Void)?
    
    func makeUIView(context: Context) -> KMViewContainer {
        let view = KMViewContainer()
        context.coordinator.createController(view)
        return view
    }
    
    // func updateUIView(_ uiView: KMViewContainer, context: Context) {
    //     guard draw else {
    //         context.coordinator.controller?.pauseEngine()
    //         context.coordinator.controller?.resetEngine()
    //         context.coordinator.clearAllPOIs()
    //         return
    //     }
    
    //     if context.coordinator.controller?.isEnginePrepared == false {
    //         context.coordinator.controller?.prepareEngine()
    //     }
    
    //     if context.coordinator.controller?.isEngineActive == false {
    //         context.coordinator.controller?.activateEngine()
    //     }
    
    //     context.coordinator.updateCenterCoordinate(centerCoordinate)
    //     context.coordinator.updatePOIs(pinInfoList)
    // }
    // MARK: - 기존 updateUIView 메서드 수정
    // KakaoMapView struct 내부의 updateUIView 메서드를 다음과 같이 수정:
    
    func updateUIView(_ uiView: KMViewContainer, context: Context) {
        guard draw else {
            context.coordinator.controller?.pauseEngine()
            context.coordinator.controller?.resetEngine()
            context.coordinator.clearAllPOIs()
            return
        }
        
        if context.coordinator.controller?.isEnginePrepared == false {
            context.coordinator.controller?.prepareEngine()
        }
        
        if context.coordinator.controller?.isEngineActive == false {
            context.coordinator.controller?.activateEngine()
        }
        
        context.coordinator.updateCenterCoordinate(centerCoordinate)
        
        // 기존 updatePOIs 대신 효율적인 업데이트 메서드 사용
        guard let kakaoMap = context.coordinator.controller?.getView("mapview") as? KakaoMap else { return }
        let maxDistance = context.coordinator.calculateMaxDistance(mapView: kakaoMap)
        
        context.coordinator.updatePOIsEfficiently(
            pinInfoList,
            currentCenter: centerCoordinate,
            maxDistance: maxDistance
        )
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            centerCoordinate: centerCoordinate,
            isInteractive: isInteractive,
            onMapReady: onMapReady,
            onMapChanged: onMapChanged
        )
    }
    
}

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
        isViewAdded = true
    }
    
    func authenticationSucceeded() {
        addViews()
    }
    
    func addViewSucceeded(_ viewName: String, viewInfoName: String) {
        guard let mapView = controller?.getView("mapview") as? KakaoMap else { return }
        mapView.viewRect = container!.bounds
        mapView.eventDelegate = self
        setupPOILayer(mapView)
        
        let cameraUpdate = CameraUpdate.make(
            target: MapPoint(longitude: longitude, latitude: latitude),
            zoomLevel: 15,
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
            print("❌ [Style-\(index)] KakaoMap 가져오기 실패")
            return ""
        }
        let manager = kakaoMap.getLabelManager()
        
        let styleID = "style_\(pinInfo.estateId)_\(index)_\(Int(Date().timeIntervalSince1970))"
        
        
        // 이미지 크기 검증
        guard image.size.width > 0 && image.size.height > 0 else {
            print("❌ [Style-\(index)] 이미지 크기가 0 - 스타일 생성 실패")
            return ""
        }
        
        // CGImage 검증
        guard image.cgImage != nil else {
            print("❌ [Style-\(index)] CGImage가 nil - 스타일 생성 실패")
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
        
        print("📝 [Style-\(index)] 텍스트 스타일 생성 - 위치: bottom")
        
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
    
    // MARK: - 메인 POI 업데이트 메서드 (순서 보장)
    // func updatePOIs(_ pinInfos: [PinInfo]) {
    //     let overallStartTime = CFAbsoluteTimeGetCurrent()
    
    //     guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
    //         print("❌ KakaoMap 가져오기 실패")
    //         return
    //     }
    //     let manager = kakaoMap.getLabelManager()
    //     guard let layer = manager.getLabelLayer(layerID: layerID) else {
    //         print("❌ 레이어 가져오기 실패 - layerID: \(layerID)")
    //         return
    //     }
    
    //     // 기존 POI들 제거
    //     print("🧹 기존 POI 제거 중...")
    //     layer.clearAllItems()
    
    //     Task {
    //         // Step 1: 이미지 생성 (비동기)
    //         let poiDataArray = await createUIImages(from: pinInfos)
    
    //         // Step 2 & 3: 메인 스레드에서 순차 실행
    //         await MainActor.run {
    //             // Step 2: POI 옵션 생성 (메인 스레드)
    //             let poiOptionsArray = createPoiOptions(from: poiDataArray)
    
    //             // Step 3: POI 표시 (메인 스레드)
    //             showPOIs(poiOptionsArray, layer: layer)
    
    //             let totalTime = CFAbsoluteTimeGetCurrent() - overallStartTime
    //             print("🎉 updatePOIs 완료! - 전체 시간: \(String(format: "%.3f", totalTime * 1000))ms")
    
    //             // 최종 확인: 실제로 표시된 POI 개수
    //             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    //                 let allPois = layer.getAllPois()
    //                 print("🔍 최종 확인 - 레이어의 실제 POI 개수: \(allPois?.count ?? 0)")
    //             }
    //         }
    //     }
    // }
    
    func clearAllPOIs() {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLodLabelLayer(layerID: layerID) else { return }
        layer.clearAllItems()
    }
    
}

// MARK: - POI 차분 구조체
private struct POIDiff {
    let toAdd: [PinInfo]
    let toRemove: [String]  // estateId들
    let toUpdate: [PinInfo]
    
    var hasChanges: Bool {
        return !toAdd.isEmpty || !toRemove.isEmpty || !toUpdate.isEmpty
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
    
    func updatePOIsEfficiently(_ pinInfos: [PinInfo], currentCenter: CLLocationCoordinate2D, maxDistance: Double) {
        let diff = calculatePOIDiff(newPinInfos: pinInfos)
        
        // 변경사항이 없으면 업데이트하지 않음
        if !diff.hasChanges {
            print("🔄 POI 업데이트 불필요 - 변경사항 없음")
            return
        }
        
        let overallStartTime = CFAbsoluteTimeGetCurrent()
        
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            print("❌ KakaoMap 가져오기 실패")
            return
        }
        
        let manager = kakaoMap.getLabelManager()
        guard let layer = manager.getLabelLayer(layerID: layerID) else {
            print("❌ 레이어 가져오기 실패")
            return
        }
        
        print("📊 POI 차분 분석 - 추가: \(diff.toAdd.count), 제거: \(diff.toRemove.count), 업데이트: \(diff.toUpdate.count)")
        print("♻️ 유지되는 POI: \(currentPOIs.count - diff.toRemove.count - diff.toUpdate.count)개")
        
        // 1. 제거 작업만 수행
        removePOIs(diff.toRemove, from: layer)
        
        // 2. 업데이트 대상도 제거 (변경된 정보로 새로 생성하기 위해)
        let updateEstateIds = diff.toUpdate.map { $0.estateId }
        removePOIs(updateEstateIds, from: layer)
        
        // 3. 새로 추가할 POI들만 생성 (추가 + 업데이트)
        let poisToCreate = diff.toAdd + diff.toUpdate
        
        if !poisToCreate.isEmpty {
            Task {
                let poiDataArray = await createUIImages(from: poisToCreate)
                
                await MainActor.run {
                    let poiOptionsArray = createPoiOptions(from: poiDataArray)
                    addPOIs(poiOptionsArray, to: layer)
                    
                    // 상태 업데이트
                    updateCurrentState(with: pinInfos, center: currentCenter, maxDistance: maxDistance)
                    
                    let totalTime = CFAbsoluteTimeGetCurrent() - overallStartTime
                    print("🎉 차분 업데이트 완료! - 전체 시간: \(String(format: "%.3f", totalTime * 1000))ms")
                    print("📍 현재 총 POI 개수: \(currentPOIs.count)개")
                }
            }
        } else {
            // 추가할 POI가 없는 경우에도 상태 업데이트
            updateCurrentState(with: pinInfos, center: currentCenter, maxDistance: maxDistance)
        }
    }
    
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
            print("🗑️ POI \(removedCount)개 제거 완료")
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

