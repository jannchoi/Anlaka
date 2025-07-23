import Foundation
import CoreLocation

protocol LocationServiceDelegate: AnyObject {
    /// 위치 업데이트 시 호출
    func locationService(didUpdateLocation coordinate: CLLocationCoordinate2D)
    /// 위치 요청 실패 시 호출
    func locationService(didFailWithError error: Error)
    /// 권한 상태 변경 시 호출
    func locationService(didChangeAuthorization status: CLAuthorizationStatus)
}

final class LocationService: NSObject, CLLocationManagerDelegate {
    // static let shared = LocationService() // 싱글턴 제거
    private let locationManager = CLLocationManager()
    weak var delegate: LocationServiceDelegate?
    
    /// 앱에서 사용할 기본 좌표 (예: 서울)
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.6522582058481, longitude: 127.045432300312)
    
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    
    var authorizationStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    fileprivate override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        print(" LocationService: 위치 요청 시작")
        self.requestLocationPermission()
    }
    
    // MARK: - 권한 상태 확인 및 요청
    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            delegate?.locationService(didChangeAuthorization: locationManager.authorizationStatus)
        case .denied, .restricted:
            delegate?.locationService(didChangeAuthorization: locationManager.authorizationStatus)
        @unknown default:
            break
        }
    }
    
    // MARK: - 현재 위치 요청 (async/await)
    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            
            switch locationManager.authorizationStatus {
            case .notDetermined:
                // 권한 요청 후 delegate에서 처리
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                // 즉시 위치 요청
                locationManager.requestLocation()
            case .denied, .restricted:
                // 권한 거부 시 기본 좌표 반환
                continuation.resume(returning: Self.defaultCoordinate)
            @unknown default:
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else { 
            // 위치 정보가 없으면 기본 좌표 반환
            locationContinuation?.resume(returning: Self.defaultCoordinate)
            locationContinuation = nil
            return 
        }
        
        delegate?.locationService(didUpdateLocation: coordinate)
        locationContinuation?.resume(returning: coordinate)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationService(didFailWithError: error)
        locationContinuation?.resume(returning: Self.defaultCoordinate)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.locationService(didChangeAuthorization: status)
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한 승인 후 위치 요청
            locationManager.requestLocation()
        case .denied, .restricted:
            // 권한 거부 시 기본 좌표 반환
            locationContinuation?.resume(returning: Self.defaultCoordinate)
            locationContinuation = nil
        case .notDetermined:
            // 권한 요청 중이므로 대기
            break
        @unknown default:
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }
}

// Factory
enum LocationServiceFactory {
    static func create() -> LocationService {
        return LocationService()
    }
} 
