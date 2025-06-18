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
    var onCenterChanged: (CLLocationCoordinate2D) -> Void
    var onRadiusChanged: (CLLocationDistance) -> Void
    
    func makeUIView(context: Self.Context) -> KMViewContainer {
        let view: KMViewContainer = KMViewContainer(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        
        context.coordinator.createController(view)
        
        return view
    }
    
    func updateUIView(_ uiView: KMViewContainer, context: Self.Context) {
        if draw {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if context.coordinator.controller?.isEnginePrepared == false {
                    context.coordinator.controller?.prepareEngine()
                }
                
                if context.coordinator.controller?.isEngineActive == false {
                    context.coordinator.controller?.activateEngine()
                }
                
                // 추가: 엔진이 활성화된 후 뷰 추가
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if context.coordinator.auth {
                        context.coordinator.addViews()
                    }
                }
            }
        }
        else {
            context.coordinator.controller?.pauseEngine()
            context.coordinator.controller?.resetEngine()
        }
    }
    
    func makeCoordinator() -> KakaoMapCoordinator {
        return KakaoMapCoordinator(onCenterChanged: onCenterChanged,
                                   onRadiusChanged: onRadiusChanged,
                                   centerCoordinate: centerCoordinate)
    }
    
    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: KakaoMapCoordinator) {
        
    }
    
    
    class KakaoMapCoordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {
        var longitude: Double
        var latitude: Double
        
        var controller: KMController?
        var container: KMViewContainer?
        var first: Bool
        var auth: Bool
        var onCenterChanged: (CLLocationCoordinate2D) -> Void
        var onRadiusChanged: (CLLocationDistance) -> Void
        
        init(
            onCenterChanged: @escaping (CLLocationCoordinate2D) -> Void,
            onRadiusChanged: @escaping (CLLocationDistance) -> Void,
            centerCoordinate: CLLocationCoordinate2D
        ) {
            self.longitude = centerCoordinate.longitude
            self.latitude = centerCoordinate.latitude
            self.first = true
            self.auth = false
            self.onCenterChanged = onCenterChanged
            self.onRadiusChanged = onRadiusChanged
            super.init()
        }
        
        func createController(_ view: KMViewContainer) {
            container = view
            controller = KMController(viewContainer: view)
            controller?.delegate = self
        }
        
        func addViews() {
            print("🗺️ addViews 호출됨")
            let defaultPosition: MapPoint = MapPoint(longitude: longitude, latitude: latitude)
            let mapviewInfo: MapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition)
            
            controller?.addView(mapviewInfo)
        }
        
        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
            print("🗺️ addViewSucceeded: \(viewName)")
            let view = controller?.getView("mapview")
            view?.viewRect = container!.bounds
            
            // 지도 뷰에 이벤트 리스너 등록
            if let mapView = view as? KakaoMap {
                print("🗺️ 지도 이벤트 리스너 등록")
                // 카메라 이동 완료 이벤트 등록 (KakaoMap SDK 방식에 따라 조정 필요)
                mapView.eventDelegate = self
            }
        }
        
        func containerDidResized(_ size: CGSize) {
            let mapView: KakaoMap? = controller?.getView("mapview") as? KakaoMap
            mapView?.viewRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size)
            if first {
                let cameraUpdate: CameraUpdate = CameraUpdate.make(target: MapPoint(longitude: longitude, latitude: latitude), mapView: mapView!)
                mapView?.moveCamera(cameraUpdate)
                first = false
            }
            
            // 여기서도 이벤트 델리게이트 설정 시도
            if let mapView = mapView {
                print("🗺️ containerDidResized에서 이벤트 델리게이트 설정")
                mapView.eventDelegate = self
            }
        }
        
        func authenticationSucceeded() {
            print("🗺️ 인증 성공")
            auth = true
            // 인증 성공 후 바로 뷰 추가 시도
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.addViews()
            }
        }
        
        func calculateMaxDistanceFromCenter(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
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
            
            let resolution = estimateMapResolution(mapView: mapView, center: center)
            return maxPixelDistance * resolution
        }
        
        /// 현재 줌 레벨과 중심 위도를 기반으로 해상도(m/pt) 추정
        func estimateMapResolution(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
            let zoomLevel = mapView.zoomLevel
            let latitudeRadians = center.latitude * .pi / 180
            return 156543.03 * cos(latitudeRadians) / pow(2.0, Double(zoomLevel))
        }
        
        // ✅ 사용자가 지도를 움직이고 손을 뗐을 때 호출됨
        func cameraMoveEnded(_ mapView: KakaoMap, cameraPosition: CameraPosition) {
            print("🗺️ cameraMoveEnded 호출됨")
            let centerCoord = cameraPosition.targetPoint.wgsCoord
            let center = CLLocationCoordinate2D(latitude: centerCoord.latitude,
                                                longitude: centerCoord.longitude)
            
            let maxDistance = calculateMaxDistanceFromCenter(mapView: mapView, center: center)
            print("📍 지도 중심 좌표 변경됨:", center)
            print("📏 중심~모서리 거리:", Int(maxDistance), "m")
            
            // 클로저 호출
            onCenterChanged(center)
            onRadiusChanged(maxDistance)
        }
    }
}
