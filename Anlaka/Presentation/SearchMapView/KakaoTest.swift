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
//struct KakaoMapView: UIViewRepresentable {
//    @Binding var draw: Bool
//    var centerCoordinate: CLLocationCoordinate2D
//    var onCenterChanged: (CLLocationCoordinate2D) -> Void
//    var onRadiusChanged: (CLLocationDistance) -> Void
//    
//    func makeCoordinator() -> KakaoMapCoordinator {
//        return KakaoMapCoordinator(onCenterChanged: onCenterChanged,
//                                   onRadiusChanged: onRadiusChanged)
//    }
//    
//    func makeUIView(context: Context) -> KMViewContainer {
//        let view: KMViewContainer = KMViewContainer()
//        context.coordinator.createController(view)
//        context.coordinator.controller?.prepareEngine()
//        return view
//    }
//    
//    func updateUIView(_ uiView: KMViewContainer, context: Self.Context) {
//        if draw {
//            Task {
//                try? await Task.sleep(for: .seconds(0.5))
//                guard let controller = context.coordinator.controller else { return }
//                if controller.isEnginePrepared == false {
//                    controller.prepareEngine()
//                }
//                if controller.isEngineActive == false {
//                    controller.activateEngine()
//                }
//            }
//        } else {
//            context.coordinator.controller?.pauseEngine()
//            context.coordinator.controller?.resetEngine()
//        }
//
//    }
//    
//    static func dismantleUIView(_ uiView: KMViewContainer, coordinator: KakaoMapCoordinator) {}
//    
//    class KakaoMapCoordinator: NSObject, MapControllerDelegate, KakaoMapEventDelegate {
//        
//        var controller: KMController?
//        var container: KMViewContainer?
//        var first = true
//        var auth = false
//        var longitude = DefaultValues.Geolocation.longitude.value
//        var latitude = DefaultValues.Geolocation.latitude.value
//        var onCenterChanged: (CLLocationCoordinate2D) -> Void
//        var onRadiusChanged: (CLLocationDistance) -> Void
//        
//        init(onCenterChanged: @escaping (CLLocationCoordinate2D) -> Void,
//             onRadiusChanged: @escaping (CLLocationDistance) -> Void) {
//            self.onCenterChanged = onCenterChanged
//            self.onRadiusChanged = onRadiusChanged
//        }
//        func addViews() {
//            let defaultPosition: MapPoint = MapPoint(longitude: longitude, latitude: latitude)
//            let mapviewInfo: MapviewInfo = MapviewInfo(viewName: "mapview", viewInfoName: "map", defaultPosition: defaultPosition)
//
//            guard let controller else {
//                print("Controller is nil at this point")
//                return
//            }
//
//            controller.addView(mapviewInfo)
//        }
////        func createController(_ view: KMViewContainer, initialCenter: CLLocationCoordinate2D) {
////            container = view
////            controller = KMController(viewContainer: view)
////            controller?.delegate = self
////            
////            let defaultPosition = MapPoint(longitude: initialCenter.longitude,
////                                           latitude: initialCenter.latitude)
////            let mapviewInfo = MapviewInfo(viewName: "mapview",
////                                          viewInfoName: "map",
////                                          defaultPosition: defaultPosition)
////            guard let controller = controller else {
////                assertionFailure("Controller is nil at this point")
////                return
////            }
////            controller.addView(mapviewInfo)
////        }
//        func createController(_ view: KMViewContainer) {
//            controller = KMController(viewContainer: view)
//            controller?.delegate = self
//        }
//        
//        func addViewSucceeded(_ viewName: String, viewInfoName: String) {
//            guard let view = controller?.getView("mapview") as? KakaoMap else { return }
//            view.viewRect = container?.bounds ?? .zero
//            view.eventDelegate = self
//            
//        }
//        
//        func containerDidResized(_ size: CGSize) {
//            let mapView: KakaoMap? = controller?.getView("mapview") as? KakaoMap
//            mapView?.viewRect = CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: size)
//            if first {
//                let cameraUpdate: CameraUpdate = CameraUpdate.make(target: MapPoint(longitude: longitude, latitude: latitude), mapView: mapView!)
//                mapView?.moveCamera(cameraUpdate)
//                first = false
//            }
//        }
//        
//        func authenticationSucceeded() {
//            auth = true
//        }
//        func calculateMaxDistanceFromCenter(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
//            let viewSize = mapView.viewRect.size
//            let centerPoint = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
//
//            let corners = [
//                CGPoint(x: 0, y: 0),
//                CGPoint(x: viewSize.width, y: 0),
//                CGPoint(x: 0, y: viewSize.height),
//                CGPoint(x: viewSize.width, y: viewSize.height)
//            ]
//
//            let maxPixelDistance = corners
//                .map { hypot(centerPoint.x - $0.x, centerPoint.y - $0.y) }
//                .max() ?? 0
//
//            let resolution = estimateMapResolution(mapView: mapView, center: center)
//            return maxPixelDistance * resolution
//        }
//
//        /// 현재 줌 레벨과 중심 위도를 기반으로 해상도(m/pt) 추정
//        func estimateMapResolution(mapView: KakaoMap, center: CLLocationCoordinate2D) -> Double {
//            let zoomLevel = mapView.zoomLevel
//            let latitudeRadians = center.latitude * .pi / 180
//            return 156543.03 * cos(latitudeRadians) / pow(2.0, Double(zoomLevel))
//        }
//
//        // ✅ 사용자가 지도를 움직이고 손을 뗐을 때 호출됨
//        func cameraMoveEnded(_ mapView: KakaoMap, cameraPosition: CameraPosition) {
//            let centerCoord = cameraPosition.targetPoint.wgsCoord
//            let center = CLLocationCoordinate2D(latitude: centerCoord.latitude,
//                                                longitude: centerCoord.longitude)
//            
//            let maxDistance = calculateMaxDistanceFromCenter(mapView: mapView, center: center)
//            print("📍 지도 중심 좌표 변경됨:", center)
//            print("📏 중심~모서리 거리:", Int(maxDistance), "m")
//            
//            // 클로저 호출
//            onCenterChanged(center)
//            onRadiusChanged(maxDistance)
//        }
//    }
//    
//}
//
