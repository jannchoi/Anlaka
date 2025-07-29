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
        context.coordinator.updatePOIs(pinInfoList)
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
    
    private func calculateMaxDistance(mapView: KakaoMap) -> Double {
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
    func updatePOIs(_ pinInfos: [PinInfo]) {
        let overallStartTime = CFAbsoluteTimeGetCurrent()

        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap else {
            print("❌ KakaoMap 가져오기 실패")
            return
        }
        let manager = kakaoMap.getLabelManager()
        guard let layer = manager.getLabelLayer(layerID: layerID) else {
            print("❌ 레이어 가져오기 실패 - layerID: \(layerID)")
            return
        }
        
        // 기존 POI들 제거
        print("🧹 기존 POI 제거 중...")
        layer.clearAllItems()
        
        Task {
            // Step 1: 이미지 생성 (비동기)
            let poiDataArray = await createUIImages(from: pinInfos)
            
            // Step 2 & 3: 메인 스레드에서 순차 실행
            await MainActor.run {
                // Step 2: POI 옵션 생성 (메인 스레드)
                let poiOptionsArray = createPoiOptions(from: poiDataArray)
                
                // Step 3: POI 표시 (메인 스레드)
                showPOIs(poiOptionsArray, layer: layer)
                
                let totalTime = CFAbsoluteTimeGetCurrent() - overallStartTime
                print("🎉 updatePOIs 완료! - 전체 시간: \(String(format: "%.3f", totalTime * 1000))ms")
                
                // 최종 확인: 실제로 표시된 POI 개수
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let allPois = layer.getAllPois()
                    print("🔍 최종 확인 - 레이어의 실제 POI 개수: \(allPois?.count ?? 0)")
                }
            }
        }
    }
    
    func clearAllPOIs() {
        guard let kakaoMap = controller?.getView("mapview") as? KakaoMap,
              let layer = kakaoMap.getLabelManager().getLodLabelLayer(layerID: layerID) else { return }
        layer.clearAllItems()
    }
}
