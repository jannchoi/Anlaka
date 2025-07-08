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
        var onClusterTap: ((ClusterInfo) -> Void)?
    var onPOITap: ((String) -> Void)?  // estate_id 전달
    var onPOIGroupTap: (([String]) -> Void)?  // 클러스터 매물들의 estate_id 배열
    
    func makeUIView(context: Context) -> KMViewContainer {
        let view = KMViewContainer()
        context.coordinator.createController(view)
        return view
    }

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
        
        context.coordinator.updatePOIsWithClustering(  
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
            onMapChanged: onMapChanged,
            onClusterTap: onClusterTap,
            onPOITap: onPOITap,
            onPOIGroupTap: onPOIGroupTap
        )
    }
    
}




