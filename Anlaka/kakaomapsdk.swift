//import Foundation
//import KakaoMapsSDK.ApiEnums
//import KakaoMapsSDK.ApiStructs
//import KakaoMapsSDK.KMController
//import KakaoMapsSDK.KMViewContainer
//import KakaoMapsSDK.NativeEventDelegate
//import KakaoMapsSDK.Swift
//import UIKit
//import _Concurrency
//import _StringProcessing
//import _SwiftConcurrencyShims
//
////! Project version number for VectorMapAPI_swift.
//public var KakaoMapsSDKAPIVersionNumber: Double
//
////! Project version string for VectorMapAPI_swift.
//public let KakaoMapsSDKAPIVersionString: <<error type>>
//
///// AnimationEffect중 Animation 시간동안 지정된 Keyframe 에 따라 회전 변환을 수행하는 애니메이션 효과.
/////
///// Poi에 적용할 수 있다.
//@objc public class AlphaAnimationEffect : KakaoMapsSDK.KeyFrameAnimationEffect {
//
//    /// Initializer
//    @objc dynamic public init()
//
//    /// 애니메이션 키프레임을 추가한다.
//    ///
//    ///  - parameter frame: 추가할 키프레임.
//    @objc public func addKeyframe(_ frame: KakaoMapsSDK.AlphaAnimationKeyFrame)
//}
//
///// AlphaAnimation 을 구성하기 위해 하나의 keyframe을 구성하기 위한 클래스
//@objc public class AlphaAnimationKeyFrame : KakaoMapsSDK.AnimationKeyFrame {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - alpha: 투명도 값. 0.0~1.0
//    ///     - interpolation: 프레임 시간, 보간 방법.
//    @objc public init(alpha: Float, interpolation: AnimationInterpolation)
//
//    /// 투명도 값. 0.0~1.0
//    @objc public var alpha: Float
//}
//
///// 키프레임 애니메이션을 구성하기 위한 keyframe 
//@objc public class AnimationKeyFrame : NSObject {
//
//    /// 애니메이션 지속 시간, 프레임 보간방법 지정
//    @objc public var interpolation: AnimationInterpolation
//}
//
/////Animator protocol
//@objc public protocol Animator {
//
//    /// 애니메이션 시작
//    @objc func start()
//
//    /// 애니메이션 정지
//    @objc func stop()
//
//    /// 애니메이션 정지 콜백 지정
//    @objc func setStopCallback(_ callback: (((any KakaoMapsSDK.Animator)?) -> Void)?)
//
//    /// 애니메이터 ID
//    @objc var animatorID: String { get }
//
//    /// 애니메이션 시작 여부
//    @objc var isStart: Bool { get }
//}
//
///// 지도상의 사각형 범위를 나타내는 클래스. 서남쪽, 북동쪽 좌표를 각각 좌하단, 우상단으로 하는 정방형 범위를 의미한다.
//@objc open class AreaRect : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameter southWest: 서남쪽 MapPoint
//    /// - parameter northEast: 동북쪽 MapPoint
//    @objc public init(southWest: KakaoMapsSDK.MapPoint, northEast: KakaoMapsSDK.MapPoint)
//
//    /// Initializer
//    ///
//    /// - parameter points: AreaRect의 범위에 포함되어야 할 MapPoint들
//    @objc public init(points: [KakaoMapsSDK.MapPoint])
//
//    /// 두 AreaRect의 범위를 합친 AreaRect를 구한다.
//    ///
//    /// - parameter rect1: 첫 번째 AreaRect
//    /// - parameter rect2: 두 번째 AreaRect
//    /// - returns: 두 AreaRect의 범위를 합친 새 AreaRect
//    @objc public static func union(_ rect1: KakaoMapsSDK.AreaRect, _ rect2: KakaoMapsSDK.AreaRect) -> KakaoMapsSDK.AreaRect
//
//    /// AreaRect의 중심점
//    /// - returns: AreaRect의 중심점
//    @objc public func center() -> KakaoMapsSDK.MapPoint
//
//    /// AreaRect의 서남쪽 포인트
//    @objc open var southWest: KakaoMapsSDK.MapPoint
//
//    /// AreaRect의 동북쪽 포인트
//    @objc open var northEast: KakaoMapsSDK.MapPoint
//}
//
///// 카메라 액션 이벤트 파라미터 구조체.
//public struct CameraActionEventParam {
//
//    /// 카메라가 속한 View
//    public let view: KakaoMapsSDK.ViewBase
//
//    /// 액션 발생 소스
//    public let by: MoveBy
//}
//
///// 카메라 위치를 지정하기 위한 클래스. 사용편의를 위해 카메라의 좌표가 아니라 카메라 시야범위의 중심점 위치 및 각도로 표현한다.
//@objc open class CameraPosition : NSObject, NSCopying {
//
//    /// Initializer
//    ///
//    /// - parameter target: 카메라가 바라보는 지점의 MapPoint
//    /// - parameter height: 카메라 높이(m)
//    /// - parameter rotation: 카메라 회전각 (radian, 정북기준 시계방향)
//    /// - parameter tilt: 카메라 기울임각 (radian, 수직방향 기준)
//    @objc public init(target: KakaoMapsSDK.MapPoint, height: Double, rotation: Double, tilt: Double)
//
//    /// Initializer
//    ///
//    /// - parameter target: 카메라가 바라보는 지점의 MapPoint
//    /// - parameter zoomLevel: 줌레벨
//    /// - parameter rotation: 카메라 회전각 (radian, 정북기준 시계방향)
//    /// - parameter tilt: 카메라 기울임각 (radian, 수직방향 기준)
//    @objc required public init(target: KakaoMapsSDK.MapPoint, zoomLevel: Int, rotation: Double, tilt: Double)
//
//    /// 객체 복사를 위한 함수
//    ///
//    /// - parameter zone: zone
//    /// - returns: new copied object
//    open func copy(with zone: NSZone?) -> Any
//
//    /// 카메라가 바라보는 지점에 대한 MapPoint
//    @objc open var targetPoint: KakaoMapsSDK.MapPoint
//
//    /// 카메라 높이(m)
//    @objc open var height: Double
//
//    /// 카메라 회전각(radian, 정북기준 시계방향)
//    @objc open var rotation: Double
//
//    /// 카메라 기울임각(radian, 수직방향 기준)
//    @objc open var tilt: Double
//
//    /// 줌 레벨
//    @objc public var zoomLevel: Int
//
//    /// 카메라 레벨 우선 지정. True일 경우 지정된 줌 레벨로 카메라 높이 결정. False일 경우 지정된 높이값으로 카메라 높이 결정. True/False에 따라 zoomLevel/height 값이 지정되어야 함.
//    @objc public var byLevel: Bool
//}
//
///// 카메라의 위치 및 각도 변화량을 지정하는 클래스. 카메라가 이동할 위치나 각도를 지정하는 것이 아니라, 얼마나 이동할지(ex. 10도씩 시계방향으로 회전)를 지정하고자 할 때 사용한다.
//@objc open class CameraTransform : NSObject, NSCopying {
//
//    /// Initializer
//    override dynamic public init()
//
//    /// Initializer.
//    ///
//    /// - parameter deltaPos: 카메라가 바라보는 위치 변화량
//    /// - parameter deltaHeight: 카메라 높이 변화량
//    /// - parameter deltaRotation: 카메라 회전각 변화량
//    /// - parameter deltaTilt: 카메라 기울임각 변화량
//    @objc required public init(deltaPos: CameraTransformDelta, deltaHeight: Double, deltaRotation: Double, deltaTilt: Double)
//
//    /// 객체 복사를 위한 함수.
//    ///
//    /// - parameter zone: zone
//    /// - returns: new copied object
//    open func copy(with zone: NSZone?) -> Any
//
//    /// 카메라가 바라보는 위치 변화량.
//    @objc open var deltaPos: CameraTransformDelta
//
//    /// 카메라 높이 변화량
//    @objc open var deltaHeight: Double
//
//    /// 카메라의 회전각 변화량
//    @objc open var deltaRotation: Double
//
//    /// 카메라 기울임각 변화량을 지정
//    @objc open var deltaTilt: Double
//}
//
///// 카메라의 위치 및 각도를 조작하기 위한 클래스.
//@objc open class CameraUpdate : NSObject {
//
//    /// KakaoMap의 현재 카메라 위치 및 각도로 CameraUpdate를 생성한다.
//    ///
//    /// - parameter mapView: KakaoMap객체
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(mapView: KakaoMapsSDK.KakaoMap) -> KakaoMapsSDK.CameraUpdate
//
//    /// CameraPosition으로 지정된 위치로 이동하는 CameraUpdate를 생성한다.
//    ///
//    /// - parameter cameraPosition: 카메라 위치 및 각도를 지정한 CameraPosition
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(cameraPosition: KakaoMapsSDK.CameraPosition) -> KakaoMapsSDK.CameraUpdate
//
//    /// AreaRect로 지정된 범위가 화면에 최대한 가득 차게 보이도록 이동하는 CameraUpdate를 생성한다.
//    ///
//    /// - parameter area: 화면에 보일 범위를 지정하는 AreaRect
//    /// - parameter levelLimit: 레벨을 지정하면 카메라가 지정한 레벨까지만 확대되도록 제한함. -1 일 경우 제한하지 않음. 기본값 -1.
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(area: KakaoMapsSDK.AreaRect, levelLimit: Int = -1) -> KakaoMapsSDK.CameraUpdate
//
//    /// Target위치를 바라보도록 이동하는 CameraUpdate를 생성한다.
//    ///
//    /// - parameter target: 카메라가 바라볼 위치
//    /// - parameter mapView: 이동할 카메라가 속한 KakaoMap
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(target: KakaoMapsSDK.MapPoint, mapView: KakaoMapsSDK.KakaoMap) -> KakaoMapsSDK.CameraUpdate
//
//    /// 카메라 방향을 지정한 각도 및 기울기로 움직이는 CameraUpdate를 생성한다.
//    ///
//    /// - parameter rotation: 카메라 회전각
//    /// - parameter tilt: 카메라 기울임각
//    /// - retunrs: 생성된 CameraUpdate
//    @objc public static func make(rotation: Double, tilt: Double, mapView: KakaoMapsSDK.KakaoMap) -> KakaoMapsSDK.CameraUpdate
//
//    /// target위치를 지정된 줌 레벨에서 바라보도록 이동하는 CameraUpdate를 생성한다.
//    ///
//    /// - parameter target: 카메라가 바라볼 위치
//    /// - parameter zoomLevel: 줌 레벨
//    /// - parameter mapView: 이동할 카메라가 속한 KakaoMap
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(target: KakaoMapsSDK.MapPoint, zoomLevel: Int, mapView: KakaoMapsSDK.KakaoMap) -> KakaoMapsSDK.CameraUpdate
//
//    /// target위치를 지정된 줌 레벨에서 rotation만큼 회전 및 tilt만큼 기울어진 상태로 바라보도록 이동하는 CameraUpdate를 생성한다.
//    ///
//    /// - parameter target: 카메라가 바라볼 위치
//    /// - parameter zoomLevel: 줌 레벨
//    /// - parameter rotation: 카메라의 회전 각도
//    /// - parameter tilt: 카메라의 기울어짐 각도
//    /// - parameter mapView: 카메라가 속한 KakaoMap
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(target: KakaoMapsSDK.MapPoint, zoomLevel: Int, rotation: Double, tilt: Double, mapView: KakaoMapsSDK.KakaoMap) -> KakaoMapsSDK.CameraUpdate
//
//    /// 지정된 줌 레벨로 이동하는 CameraUpdate를 생성한다.
//    ///
//    /// - paramter zoomLevel: 줌 레벨
//    /// - parameter mapView: 카메라가 속한 KakaoMap
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(zoomLevel: Int, mapView: KakaoMapsSDK.KakaoMap) -> KakaoMapsSDK.CameraUpdate
//
//    /// 카메라를 현재 위치로부터 transform으로 지정된 만큼 이동하는 CameraUpdate를 생성한다.
//    /// 
//    /// - parameter transform: 카메라의 이동량
//    /// - returns: 생성된 CameraUpdate
//    @objc public static func make(transform: KakaoMapsSDK.CameraTransform) -> KakaoMapsSDK.CameraUpdate
//
//    /// CameraUpdate의 종류.
//    @objc open var type: CameraUpdateType { get }
//
//    /// 지정된 CameraPosition.  CameraPosition을 이용해 생성되었을 경우에만 유효하다.
//    @objc open var cameraPosition: KakaoMapsSDK.CameraPosition? { get }
//
//    /// 지정된 CameraTransform. CameraTransfrom을 이용해 생성되었을 경우에만 유효하다.
//    @objc open var cameraTransform: KakaoMapsSDK.CameraTransform? { get }
//
//    /// 지정된 AreaRect. AreaRect를 이용해 생성되었을 경우에만 유효하다.
//    @objc open var area: KakaoMapsSDK.AreaRect? { get }
//
//    /// 지정된 확대레벨 제한값
//    @objc open var levelLimit: Int { get }
//}
//
///// 지도 뷰 전체를 어둡게 가리는 DimScreen 클래스.
/////
///// KakaoMap에 종속되어 있으며 사용자가 별도로 생성할 수 없다. KakaoMap 인터페이스로 DimScreend의 On/Off가 가능하다.
/////
///// screen에 원하는대로 Shape를 추가하여 특정 부분만 하이라이트 효과를 줄 수 있다.
//@objc open class DimScreen : NSObject {
//
//    /// PolygonStyleSet을 추가한다.
//    ///
//    /// PolygonShape의 Polygon이 여러개인 경우, Polygon마다 다른 스타일을 설정할 수 있다. 같은 styleID로 추가하더라도 overwrite되지 않는다.
//    ///
//    /// - SeeAlso: PolygonStyleSet
//    /// - parameter styles: 추가할 PolygonStyleSet
//    @objc open func addPolygonStyleSet(_ styles: KakaoMapsSDK.PolygonStyleSet)
//
//    /// DimScreen에 MapPolygonShape를 추가한다.
//    ///
//    /// 중복ID로는 추가할 수 없으며, 기존에 같은 아이디의 Shape가 존재할 경우 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOption: 생성할 MapPolygonShape 옵션
//    ///     - callback: MapPolygonShape객체가 생성이 완료됐을 때 호출할 콜백함수(optional)
//    /// - returns: 생성된 MapPolygonShape 객체
//    @objc open func addHighlightMapPolygonShape(_ shapeOption: KakaoMapsSDK.MapPolygonShapeOptions, callback: ((KakaoMapsSDK.MapPolygonShape?) -> Void)? = nil) -> KakaoMapsSDK.MapPolygonShape?
//
//    /// DimScreen에 다수의 MapPolygonShape를 추가한다.
//    ///
//    /// 중복ID로는 추가할 수 없으며, 기존에 같은 아이디의 Shape가 존재할 경우 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 MapPolygonShape 옵션 배열
//    ///     - callback: MapPolygonShape객체가 모두 생성이 완료됐을 때 호출할 콜백함수(optional)
//    /// - returns: 생성된 MapPolygonShape 객체 배열
//    @objc open func addHighlightMapPolygonShapes(_ shapeOptions: [KakaoMapsSDK.MapPolygonShapeOptions], callback: (([KakaoMapsSDK.MapPolygonShape]?) -> Void)? = nil) -> [KakaoMapsSDK.MapPolygonShape]?
//
//    /// 현재 DimScreen에 속한 MapPolygonShape를 가져온다.
//    ///
//    /// - parameter shapeID: 가져올 MapPolygonShape ID
//    /// - returns: ID에 해당하는 MapPolygonShape 객체, 없을경우 nil.
//    @objc open func getHighlightMapPolygonShape(shapeID: String) -> KakaoMapsSDK.MapPolygonShape?
//
//    /// 현재 DimScreen에 속한 다수의 MapPolygonShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 MapPolygonShape ID 배열
//    /// - returns: ID에 해당하는 MapPolygonShape 객체 배열, 없을경우 nil.
//    @objc open func getHighlightMapPolygonShapes(shapeIDs: [String]) -> [KakaoMapsSDK.MapPolygonShape]?
//
//    /// 현재 DimScreen에 속한 모든 MapPolygonShape를 가져온다.
//    ///
//    /// - returns: 현재 DimScreen에 추가된 MapPolygonShape 배열
//    @objc open func getAllHighlightMapPolygonShapes() -> [KakaoMapsSDK.MapPolygonShape]?
//
//    /// 현재 DimScreen에서 특정 MapPolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: DimScreen에서 제거할 MapPolygonShape Id
//    ///     - callback : DimScreen에서 해당 Shape제거가 완료되었을 때, 호출할 콜백함수(optional)
//    @objc open func removeHighlightMapPolygonShape(shapeID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 DimScreen에서 다수의 MapPolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: DimScreen에서 제거할 MapPolygonShape Id 배열
//    ///     - callback: DimScreen에서 id에 해당하는 모든 shape제거가 완료되었을 때, 호출할 콜백함수(optional)
//    @objc open func removeHighlightMapPolygonShapes(shapeIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 DimScreen에 속한 특정 MapPolygonShape를 보여준다.
//    ///
//    /// - parameter shapeIDs: 보여줄 MapPolygonShape ID 배열
//    @objc open func showHighlightMapPolygonShapes(shapeIDs: [String])
//
//    /// 현재 DimScreen에 속한 특정 MapPolygonShape를 숨긴다.
//    ///
//    /// - parameter shapeIDs: 숨길 MapPolygonShape ID 배열
//    @objc open func hideHighlightMapPolygonShapes(shapeIDs: [String])
//
//    /// DimScreen에 PolygonShape를 추가한다.
//    ///
//    /// 이미 추가한 ID로 추가할 수 없으며, 이 경우 기존의 객체가 리턴된다.
//    ///
//    /// - parameters:
//    ///     - shaepOption: DimScreen에 추가할 PolygonShapeOptions
//    ///     - callback: DimScreen에 객체 추가가 완료되었을 때, 호출할 콜백함수(optional)
//    /// - returns: 추가된 PolygonShape 객체
//    @objc open func addHighlightPolygonShape(_ shapeOption: KakaoMapsSDK.PolygonShapeOptions, callback: ((KakaoMapsSDK.PolygonShape?) -> Void)? = nil) -> KakaoMapsSDK.PolygonShape?
//
//    /// DimScreen에 여러개의 PolygonShape를 추가한다.
//    ///
//    /// 이미 추가한 ID로 추가할 수 없으며, 이 경우 기존의 객체가 리턴된다.
//    ///
//    /// - parameters:
//    ///     - shaepOptions: DimScreen에 추가할 PolygonShapeOptions 배열
//    ///     - callback: DimScreen에 객체 추가가 모두 완료되었을 때, 호출할 콜백함수(optional)
//    /// - returns: 추가된 PolygonShape 객체 배열
//    @objc open func addHighlightPolygonShapes(_ shapeOptions: [KakaoMapsSDK.PolygonShapeOptions], callback: (([KakaoMapsSDK.PolygonShape]?) -> Void)? = nil) -> [KakaoMapsSDK.PolygonShape]?
//
//    /// DimScreen에 추가된 PolygonShape를 가져온다.
//    ///
//    /// - parameter shapeID: 가져올 PolygonShape ID
//    /// - returns: shapeID에 해당하는 Shape객체. 없을경우 nil 리턴
//    @objc open func getHighlightPolygonShape(shapeID: String) -> KakaoMapsSDK.PolygonShape?
//
//    /// DimScreen에 추가된 다수의 PolygonShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 PolygonShape ID 배열
//    /// - returns: shapeID에 해당하는 PolygonShape객체 배열. 없을경우 nil 리턴
//    @objc public func getHighlightPolygonShapes(shapeIDs: [String]) -> [KakaoMapsSDK.PolygonShape]?
//
//    /// DimScreen에 추가된 모든 PolygonShape를 가져온다.
//    ///
//    /// - returns: DimScreen에 추가된 모든 PolygonShape 객체 배열
//    @objc open func getAllHighlightPolygonShapes() -> [KakaoMapsSDK.PolygonShape]?
//
//    /// DimScreen에 추가된 특정 PolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: 지울 PolygonShape ID
//    ///     - callback: 제거가 완료되었을 때, 호출할 callback 함수(optional)
//    @objc open func removeHighlightPolygonShape(shapeID: String, callback: (() -> Void)? = nil)
//
//    /// DimScreen에 추가된 다수의 PolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeIDs: 지울 PolygonShape ID 배열
//    ///     - callback: 제거가 완료되었을 때, 호출할 callback 함수(optional)
//    @objc open func removeHighlightPolygonShapes(shapeIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 DimScreen에 속한 특정 PolygonShape를 보여준다.
//    ///
//    /// - parameter shapeIDs: 보여줄 PolygonShape ID 배열
//    @objc public func showHighlightPolygonShapes(shapeIDs: [String])
//
//    /// 현재 DimScreen에 속한 특정 PolygonShape를 숨긴다.
//    ///
//    /// - parameter shapeIDs: 숨길 PolygonShape ID 배열
//    @objc public func hideHighlightPolygonShapes(shapeIDs: [String])
//
//    /// DimScreen에 추가된 모든 Shape를 지운다.
//    @objc open func clearAllHighlightShapes()
//
//    /// DimScreen의 활성화 상태를 지정한다.
//    ///
//    /// `true`설정 시 DimScreen이 활성화 되어 표시된다. `false` 설정시 DimScreen이 비활성화된다.
//    @objc open var isEnabled: Bool
//
//    /// DimScreen의 컬러값
//    ///
//    /// 값을 설정하면 DimScreen의 컬러가 업데이트된다.
//    @objc open var color: UIColor
//
//    /// DimScreen이 덮을 레이어 범위
//    ///
//    /// - SeeAlso: DimScreenCover
//    @objc public var cover: DimScreenCover
//
//    /// ShapeAnimator를 추가한다.
//    ///
//    /// ShapeAnimator 객체는 사용자가 직접 생성할 수 없으며, Manager를 통해서만 생성이 가능하다. 이미 존재하는 AnimatorID로는 overwrite되지 않는다.
//    ///
//    /// - SeeAlso: AnimationInterpolation
//    /// - SeeAlso: WaveTextAnimation
//    /// - parameters:
//    ///     - animatorID: ShapeAnimator ID
//    ///     - effect:레벨별 애니메이션 효과 지정
//    /// - returns: 생성된 Animator 객체
//    @objc public func addShapeAnimator(animatorID: String, effect: any KakaoMapsSDK.ShapeAnimationEffect) -> KakaoMapsSDK.ShapeAnimator?
//
//    /// 추가한 ShapeAnimator 객체를 제거한다.
//    ///
//    /// - parameter animatorID: 제거할 animatorID
//    @objc public func removeShapeAnimator(animatorID: String)
//
//    /// 추가되어있는 모든 ShapeAnimaotr를 제거한다.
//    @objc public func clearAllShapeAnimators()
//
//    /// 추가한 ShapeAnimator 객체를 가져온다.
//    ///
//    /// - parameter animatorID: 가져올 AnimatorID
//    /// - returns: animatorID에 해당하는 ShapeAnimator 객체. 존재하지 않을 경우 nil 리턴
//    @objc public func getShapeAnimator(animatorID: String) -> KakaoMapsSDK.ShapeAnimator?
//}
//
///// 이벤트 핸들러 dispose 를 위한 프로토콜.
//public protocol DisposableEventHandler {
//
//    /// Dispose handler
//    func dispose()
//}
//
///// AnimationEffect중 Animation 시간동안 특정 pixel값만큼 위에서 아래로 떨어지는 애니메이션 효과 클래스.
/////
///// Poi와 InfoWindow Animator에 적용할 수 있다.
//@objc public class DropAnimationEffect : NSObject, KakaoMapsSDK.PoiAnimationEffect, KakaoMapsSDK.InfoWindowAnimationEffect {
//
//    /// Initializer
//    ///
//    /// - parameter pixelHeight: Drop Animation시 떨어지는 pixel Height
//    @objc public init(pixelHeight: Float)
//
//    /// Drop Animation시 떨어지는 pixel height
//    @objc public var pixelHeight: Float { get }
//
//    /// 애니메이션 지속 시간, 반복 횟수 등 세부사항 지정
//    public var interpolation: AnimationInterpolation
//
//    /// 애니메이션 종료 시 애니메이터에 속한 객체들을 숨길지에 대한 여부.
//    ///
//    /// true로 설정하면 애니메이션이 종료되면 객체들이 화면에서 자동으로 사라진다.
//    public var hideAtStop: Bool
//
//    /// 애니메이션 종료 시 애니메이터에 속한 객체들을 제거할지에 대한 여부.
//    ///
//    /// true로 설정하면 애니메이션이 종료되면 객체들이 제거된다.
//    public var removeAtStop: Bool
//
//    /// 애니메이션 재생 횟수.
//    public var playCount: UInt
//}
//
///// 포커스 변경 이벤트 파라미터 구조체.
//public struct FocusChangedEventParam {
//
//    /// 포커스가 변경된 View
//    public let view: KakaoMapsSDK.ViewBase
//
//    /// 포커스 상태.
//    public let focus: Bool
//}
//
///// gif처럼 여러장의 이미지로 구성된 애니메이션을 보여주는 component 클래스
/////
///// 애니메이션을 구성하는 이미지는 모두 같은 크기, 같은 포맷이어야 한다.
/////
///// 하나의 child component를 가질 수 있다.
//@objc open class GuiAnimatedImage : KakaoMapsSDK.GuiComponentBase {
//
//    /// initializer
//    ///
//    /// - parameter componentId: Component ID
//    @objc public init(_ componentId: String)
//
//    /// 애니메이션 이미지들을 추가한다. 각 이미지들이 animation의 keyframe image가 된다.
//    ///
//    /// - parameter images:애니메이션 이미지
//    @objc open func addImages(_ images: [UIImage])
//
//    /// GuiAnimatedImage의 child Component를 가져온다.
//    ///
//    /// child component가 GuiLayout component로 구성되어 있어도 componentId로 가져올 수 있다.
//    ///
//    /// - parameter componentId: 가져올 component의 Id
//    /// - returns: componentID에 해당하는 component. 없을경우 nil
//    override public func getChild(_ componentId: String) -> KakaoMapsSDK.GuiComponentBase?
//
//    /// AnimatedImage 컴포넌트의 애니메이션을 실행시킨다.
//    @objc public func start()
//
//    /// AnimatedImage 컴포넌트의 애니메이션을 멈춘다.
//    @objc public func stop()
//
//    /// AnimatedImage 컴포넌트의 애니메이션을 재시작시킨다.
//    @objc public func resume()
//
//    /// AnimatedImage 컴포넌트의 애니메이션을 일시정지한다..
//    @objc public func pause()
//
//    /// 애니메이션의 이미지들을 가져온다.
//    @objc open var images: [UIImage] { get }
//
//    /// 애니메이션 이미지 사이즈를 지정한다. 지정하지 않을경우 원본 크기를 사용한다.
//    @objc open var imageSize: GuiSize
//
//    /// 애니메이션 1회 재생 시간을 지정한다.
//    @objc open var duration: UInt
//
//    /// 애니메이션 반복 횟수를 지정한다.
//    ///
//    /// 애니메이션 재생을 시작하면 지정한 회수만큼 반복 재생된다.
//    ///
//    /// 너무 긴 시간동안 애니메이션을 재생하면 배터리 사용량이 크게 늘어날 수 있다.
//    ///
//    /// 무한반복 혹은 짧은 반복횟수를 여러번 반복하는것은 권장하지 않는다.
//    @objc open var playCount: UInt
//
//    /// GuiAnimatedImage Component에 추가되는 child component
//    ///
//    /// GuiLayout 컴포넌트를 넣어서 여러개의 Component를 구성할 수도 있다.
//    @objc open var child: KakaoMapsSDK.GuiComponentBase?
//}
//
///// GUI 애니메이션 이벤트 파라미터 구조체.
//public struct GuiAnimationEventParam {
//
//    /// Gui
//    public let gui: KakaoMapsSDK.GuiBase
//
//    /// 애니메이션 상태
//    public let state: AnimationState
//
//    /// 컴포넌트 이름
//    public let guiComponentName: String?
//}
//
///// Gui 베이스 클래스
/////
///// Gui는 특성상 culling 이 되지 않으므로, 지도상의 특정 위치에 그려져서 화면에 그려지는 영역 밖에 있더라도 실제로 그려진다.
/////
///// 그러므로 다수의 Gui를 추가하게 되면 엔진 부하를 야기할 수 있다.
//@objc open class GuiBase : NSObject {
//
//    /// Gui를 그린다.
//    @objc open func show()
//
//    /// Gui를 숨긴다.
//    @objc open func hide()
//
//    /// Gui가 그려지고 있던 경우 갱신하여 새로 그린다. 한번 Gui를 그린 상태에서 속성을 변경하고자 하는 경우, 이 함수를 호출해야 반영된다.
//    @objc public func updateGui()
//
//    /// childComponent를 가져온다.
//    ///
//    /// - parameter componentId: 가져올 컴포넌트의 Id
//    /// - returns: ComponentId에 해당하는 GuiComponent. 없을경우 nil
//    @objc open func getChild(_ componentId: String) -> KakaoMapsSDK.GuiComponentBase?
//
//    /// 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    open func addTapEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.GuiInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    open func addAnimationEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.GuiAnimationEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Gui 이동 정지 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    open func addMoveEndEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.GuiMoveEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Gui의 name
//    @objc open var name: String { get }
//
//    /// GuiEventDelegate를 지정한다.
//    @objc open var delegate: (any KakaoMapsSDK.GuiEventDelegate)?
//
//    /// Gui의 렌더링 우선순위를 지정한다. 값을 세팅하면, 따로 updateGui() 호출 없이도 바로 반영된다.
//    ///
//    /// zOrder는 같은 Gui타입끼리만 유효하며, zOrder 값이 클수록 더 위에 그려진다.
//    ///
//    /// 즉, zOrder가 0인 Gui는 zOrder가 1인 Gui보다 아래에 그려진다.
//    @objc open var zOrder: Int
//
//    /// Gui 표출 여부
//    @objc open var isShow: Bool { get }
//}
//
///// 버튼 Component 클래스. 사용자로부터 탭 이벤트를 받을 수 있다.
/////
///// 한 개의 child component를 가질 수 있다. Child component로 GuiLayout을 사용하면 여러 개의 child를 추가할 수 있다.
//@objc open class GuiButton : KakaoMapsSDK.GuiImage {
//
//    /// initailizer
//    ///
//    /// - parameter componentId: Component ID
//    override public init(_ componentId: String)
//
//    /// button pressed Image 지정
//    @objc open var pressedImage: UIImage?
//
//    /// button pressed Image Size 지정. 지정하지 않을경우 원본사이즈 유지
//    @objc open var pressedImageSize: GuiSize
//}
//
///// GuiComponent의 베이스 클래스
//@objc open class GuiComponentBase : NSObject {
//
//    /// Component의 childComponent를 가져온다.
//    ///
//    /// - parameter componentId: 가져오고자 하는 componentID
//    /// - returns: ID에 해당하는 child component. 없을경우 nil
//    @objc public func getChild(_ componentId: String) -> KakaoMapsSDK.GuiComponentBase?
//
//    /// Component의 padding(pixel)
//    ///
//    /// 컴포넌트 기준으로 상하좌우로 여백값을 줄 수 있으며, 컴포넌트 본래 사이즈 + padding값이 해당 컴포넌트의 최종 크기가 된다.
//    ///
//    /// padding값을 별도로 지정하지 않는 경우, 컴포넌트의 최종 크기는 본래 사이즈가 된다.
//    @objc public var padding: GuiPadding
//
//    /// component의 origin
//    ///
//    /// component 자체의 원점 위치를 조절한다. root component에만 적용된다.
//    @objc public var origin: GuiAlignment
//
//    /// component의 align
//    ///
//    /// Gui내에서 컴포넌트가 차지하는 최종 공간에서 컴포넌트의 정렬 위치.
//    @objc public var align: GuiAlignment
//
//    /// GuiComponent의 타입
//    @objc public var type: GuiComponentType { get }
//
//    /// GuiComponent의 Id
//    @objc public var componentId: String { get }
//}
//
///// 여러개의 child를 가질 수 있는 GuiComponentGroup 클래스
//@objc open class GuiComponentGroup : KakaoMapsSDK.GuiComponentBase {
//
//    /// 현재 컴포넌트에 child component를 추가한다.
//    ///
//    /// - parameter component: 추가하고자 하는 child component
//    @objc open func addChild(_ component: KakaoMapsSDK.GuiComponentBase)
//
//    /// 현재 컴포넌트의 child component를 가져온다.
//    ///
//    /// - parameter componentId: 가져오고자 하는 child component Id
//    /// - returns: componentId에 해당하는 child component, 없을경우 nil
//    override open func getChild(_ componentId: String) -> KakaoMapsSDK.GuiComponentBase?
//
//    /// 현재 컴포넌트의 child component를 지운다..
//    ///
//    /// - parameter componentId: 지우고자 하는 child component Id
//    @objc open func removeChild(_ componentId: String)
//
//    /// 현재 컴포넌트가 childComponent를 가지고 있는지 체크한다.
//    ///
//    /// - returns: 현재 컴포넌트가 child를 가지고있을경우 true, 아니면 false
//    @objc open var hasChildren: Bool { get }
//
//    /// 현재 컴포넌트가 갖는 child component Array
//    ///
//    /// - returns: child component 배열
//    @objc open var children: NSMutableArray { get }
//}
//
///// Gui에서 발생하는 이벤트에 대한 delegate.
//@objc public protocol GuiEventDelegate {
//
//    /// Component 탭 이벤트
//    ///
//    /// - parameter gui: 탭된 Gui
//    /// - parameter componentName: 탭된 GuiComponent의 이름
//    @objc optional func guiDidTapped(_ gui: KakaoMapsSDK.GuiBase, componentName: String)
//
//    /// Animation 재생상태 변경시 발생
//    ///
//    /// - parameter gui: 재생상태가 변경된 Gui
//    /// - parameter componentName: Component의 이름
//    /// - parameter state: animation state
//    @objc optional func guiAnimationStateDidChanged(_ gui: KakaoMapsSDK.GuiBase, componentName: String, state: AnimationState)
//
//    /// Gui 이동 정지 이벤트
//    ///
//    /// - parameter gui: Gui
//    /// - parameter position: 위치.
//    @objc optional func guiMoveDidStopped(_ gui: KakaoMapsSDK.GuiBase, position: KakaoMapsSDK.MapPoint)
//}
//
///// Gui에 Image를 그리기 위한 component 클래스.
/////
///// 이미지는 크기를 지정하지 않으면 원본 크기로 그려지고 지정하면 지정된 크기대로 그려진다(배경이미지로 사용되는 경우는 component의 크기로 그려짐).
/////
///// 하나의 child component를 가질 수 있다.
//@objc open class GuiImage : KakaoMapsSDK.GuiComponentBase {
//
//    /// initializer
//    ///
//    /// - parameter componentId: componentID
//    @objc public init(_ componentId: String)
//
//    /// GuiImage의 child Component를 가져온다.
//    ///
//    /// child component가 GuiLayout component로 구성되어 있어도 componentId로 가져올 수 있다.
//    ///
//    /// - parameter componentId: 가져올 component의 Id
//    /// - returns: componentID에 해당하는 component. 없을경우 nil
//    override public func getChild(_ componentId: String) -> KakaoMapsSDK.GuiComponentBase?
//
//    /// 사용될 이미지
//    @objc open var image: UIImage?
//
//    /// 사용될 이미지의 사이즈. 크기를 지정하지 않으면 원본 사이즈로 사용된다.
//    @objc open var imageSize: GuiSize
//
//    /// imageStretch를 지정하면 리사이즈될 때 나인패치 이미지 형태로 리사이즈 되어 그려진다.
//    @objc open var imageStretch: GuiEdgeInsets
//
//    /// GuiImage Component에 추가되는 child component
//    ///
//    /// GuiLayout 컴포넌트를 넣어서 여러개의 Component를 구성할 수도 있다.
//    @objc open var child: KakaoMapsSDK.GuiComponentBase?
//}
//
///// Gui 이벤트 파라미터 구조체.
//public struct GuiInteractionEventParam {
//
//    /// Gui
//    public let gui: KakaoMapsSDK.GuiBase
//
//    /// 컴포넌트 이름
//    public let guiComponentName: String?
//}
//
///// 여러개의 child component를 가지는 component 클래스.
/////
///// child component를 가로, 혹은 세로로 배치할 수 있으며, 배치 방향에 따라 추가한 순서대로 그려진다.
/////
///// GuiLayout의 크기는 배치된 총 child component의 전체 크기가 된다.
//@objc open class GuiLayout : KakaoMapsSDK.GuiComponentGroup {
//
//    /// initializer
//    ///
//    /// - parameter componentId: component ID
//    @objc public init(_ componentId: String)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - componentId: componentID
//    ///     - arrangement: child component 배치 방향
//    @objc public init(_ componentId: String, arrangement: LayoutArrangement)
//
//    /// layout에 추가한 child component의 배치 방향
//    @objc public var arrangement: LayoutArrangement
//
//    /// layout의 child component 구분선 표시 여부
//    @objc public var showSplitLine: Bool
//
//    /// layout의 child component 구분선 색깔
//    @objc public var splitLineColor: UIColor
//
//    /// layout의 child component 구분선 두께
//    @objc public var splitLineWidth: Int
//
//    /// layout의 배경 색깔
//    @objc public var bgColor: UIColor
//}
//
///// 사용자 Gui를 사용하고 관리하기 위한 클래스
/////
///// SpriteGui, InfoWIndow를 추가 및 제거 등 관리할 수 있다. InfoWindow의 경우, InfoWindow에 적용할 Animator를 추가할 수 있다.
/////
///// ViewBase에 종속적이므로 각 ViewBase가 삭제된 뒤에도 사용하지 않도록 주의하여야 한다.
//@objc open class GuiManager : NSObject {
//
//    /// InfoWindowAnimator를 추가한다.
//    ///
//    /// InfoWindowAnimator 객체는 사용자가 직접 생성할 수 없으며, GuiManager를 통해서만 생성이 가능하다. 이미 존재하는 AnimatorID로는 overwrite되지 않는다.
//    ///
//    /// - SeeAlso: InfoWindowAnimator
//    /// - SeeAlso: AnimationInterpolation
//    /// - parameters:
//    ///     - animatorID: InfoWindowAnimator ID
//    ///     - effect: 애니메이션 효과 지정
//    /// - returns: 생성된 Animator 객체
//    @objc public func addInfoWindowAnimator(animatorID: String, effect: any KakaoMapsSDK.InfoWindowAnimationEffect) -> KakaoMapsSDK.InfoWindowAnimator?
//
//    /// 추가한 InfoWindowAnimator를 제거한다.
//    ///
//    /// - parameter animatorID: 제거할 animatorID
//    @objc public func removeInfoWindowAnimator(animatorID: String)
//
//    /// 추가되어있는 모든 InfoWindowAnimator를 제거한다.
//    @objc public func clearAllInfoWindowAnimators()
//
//    /// 추가한 InfoWindowAnimator 객체를 가져온다.
//    ///
//    /// - parameter animatorID: 가져올 animatorID
//    /// - returns: animatorID에 해당하는 InfoWindowAnimator 객체. 존재하지 않을 경우 nil 리턴.
//    @objc public func getInfoWindowAnimator(animatorID: String) -> KakaoMapsSDK.InfoWindowAnimator?
//
//    /// SpriteGui Layer. SpriteGui를 추가하기 위해서는 해당 레이어에 Gui를 추가한다.
//    @objc public var spriteGuiLayer: KakaoMapsSDK.SpriteGuiLayer { get }
//
//    /// InfoWindow Layer. InfoWindow를 추가하기 위해서는 해당 레이어에 InfoWindow를 추가한다.
//    @objc public var infoWindowLayer: KakaoMapsSDK.InfoWindowLayer { get }
//}
//
///// Gui 이동 이벤트 파라미터 구조체.
//public struct GuiMoveEventParam {
//
//    /// Gui
//    public let gui: KakaoMapsSDK.GuiBase
//
//    /// 위치
//    public let position: KakaoMapsSDK.MapPoint
//}
//
///// Gui에 글자를 그리는 component class
//@objc open class GuiText : KakaoMapsSDK.GuiComponentBase {
//
//    /// initializer
//    ///
//    /// - parameter componentId: GuiText의 componentId
//    @objc public init(_ componentId: String)
//
//    /// GuiText에 텍스트를 추가한다.
//    ///
//    /// 여러 라인으로 추가할 수 있고, 각 라인별로 스타일을 지정할 수 있다.
//    ///
//    /// - parameters:
//    ///     - text: 추가하고자하는 텍스트
//    ///     - style: 추가하고자하는 텍스트에 적용할 스타일
//    @objc open func addText(text: String, style: KakaoMapsSDK.TextStyle = TextStyle())
//
//    /// Gui에 추가된 텍스트를 가져온다.
//    ///
//    /// 여러 라인으로 추가했을 경우, 추가한 인덱스로 텍스트를 가져올 수 있다.
//    ///
//    /// - parameter index: 추가한 텍스트의 인덱스
//    /// - returns: 인덱스에 해당하는 텍스트
//    @objc open func text(index: Int) -> String
//
//    /// Gui에 추가된 텍스트 스타일을 가져온다.
//    ///
//    /// 여러 라인으로 추가했을 경우, 추가한 인덱스로 텍스트 스타일을 가져올 수 있다.
//    ///
//    /// - parameter index: 추가한 텍스트의 인덱스
//    /// - returns:추가한 텍스트 인덱스의 스타일
//    @objc open func textStyle(index: Int) -> KakaoMapsSDK.TextStyle
//
//    /// Gui Text Component에 추가된 텍스트 라인 수를 가져온다
//    ///
//    /// - returns: 텍스트 라인 수
//    @objc open func textCount() -> Int
//
//    /// text의 특정 라인을 업데이트한다. 변경사항은 Gui의 updateGui를 호출해야 유효하다.
//    ///
//    /// - parameters:
//    ///     - index: 텍스트 라인 index
//    ///     - text: 업데이트 할 내용
//    ///     - style: 업데이트할 텍스트 스타일
//    @objc open func updateText(index: Int, text: String, style: KakaoMapsSDK.TextStyle? = nil)
//}
//
///// InfoWindow class
/////
///// 인포윈도우는 body, tail 두 부분으로 구성된다. body는 GuiImage로 구성되어 있으며, 이 GuiImage Component에 존재하는 기본 layout에 원하는 child 컴포넌트를 구성할 수 있다.
//@objc open class InfoWindow : KakaoMapsSDK.GuiBase {
//
//    /// initializer
//    ///
//    /// - parameter name: InfoWindow 이름
//    @objc public init(_ name: String)
//
//    /// InfoWindow의 body
//    ///
//    /// GuiImage Component이며, body에 child component를 추가할 수 있다.
//    @objc public var body: KakaoMapsSDK.GuiImage?
//
//    /// InfoWindow의 tail
//    @objc public var tail: KakaoMapsSDK.GuiImage?
//
//    /// InfoWindow의 body offset
//    /// tail의 원점(origin) 으로부터 body의 원점이 떨어진 위치.
//    /// InfoWindow의 tail은 원점이 position으로 지정된 위치에 놓이고 body는 body의 원점이 tail 원점으로부터 offset만큼 떨어진 위치에 놓이게 된다.
//    @objc public var bodyOffset: CGPoint
//
//    /// InfoWindow의 position offset
//    /// tail의 원점(origin) 이 position 으로 부터 떨어진 위치.
//    /// InfoWindow의 tail은 원점이 position으로 지정된 위치에서 position offset 만큼 떨어진 위치에 놓이고 body는 body의 원점이 tail 원점으로부터 offset만큼 떨어진 위치에 놓이게 된다.
//    @objc public var positionOffset: CGPoint
//
//    /// InfoWindow가 표시 될 위치. 값을 셋팅하면, 별도의 updateGui() 호출 없이도 바로 반영된다. 
//    @objc public var position: KakaoMapsSDK.MapPoint?
//
//    /// InfoWindow를 화면에 표시하고, InfoWinodw가 표시되는 영역으로 자동으로 이동한다.
//    ///
//    /// - parameter callback: 카메라 이동이 끝났을 때, 호출할 callback(optional)
//    @objc public func showWithAutoMove(callback: (() -> Void)? = nil)
//
//    /// infoWindow의 child Component를 가져온다.
//    ///
//    /// - parameter componentId: Child component ID
//    /// - returns: componentId에 해당하는 child Component. 없을경우 nil
//    override public func getChild(_ componentId: String) -> KakaoMapsSDK.GuiComponentBase?
//
//    /// InfoWindow를 특정 위치로 지정한 시간만큼 이동시킨다.
//    ///
//    /// - parameters:
//    ///     - position: 이동시킬 위치
//    ///     - duration: 이동시킬 시간
//    @objc public func moveAt(_ position: KakaoMapsSDK.MapPoint, duration: UInt)
//
//    /// InfoWindow rawPosition
//    @objc public func rawPosition() -> KakaoMapsSDK.MapPoint?
//}
//
///// InfoWindowAnimation을 생성할 때 Animation Effect 종류를 정의하는 프로토콜
//@objc public protocol InfoWindowAnimationEffect {
//
//    /// 애니메이션의 지속시간, 반복 회수, 프레임간의 보간 방법등을 지정
//    @objc var interpolation: AnimationInterpolation { get set }
//
//    /// 애니메이션 종료시 대상 객체를 숨길지 여부를 지정.
//    @objc var hideAtStop: Bool { get set }
//
//    /// 애니메이션 재생 횟수.
//    @objc var playCount: UInt { get set }
//}
//
///// InfoWindow에 애니메이션 효과를 주기 위한 Animator 클래스.
/////
///// Animator를 생성해서 효과를 주고자 하는 InfoWindow를 Animator에 넣어서 animator를 동작시키는 방식이다.
/////
///// Animator는 사용자가 직접 생성할 수 없으며, GuiManager를 통해서만 생성이 가능하다.
//@objc public class InfoWindowAnimator : NSObject, KakaoMapsSDK.Animator {
//
//    /// Animator를 동작시킨다.
//    ///
//    /// Animator에 추가된 InfoWindow가 없으면 start함수는 동작하지 않는다. start를 호출한 이후에는 Animator에   InfoWindow를 추가하거나 지울 수 없다. 추가하고자 하는 경우, stop을 호출하고 추가해야한다.
//    ///
//    /// start 호출 이후 애니메이션이 끝나면 Animator에 추가된 InfoWindow는 비워지므로, 다시 start를 호출하려면 InfoWindow를 추가해야한다.
//    ///
//    /// InfoWindow Interface에 있는 move등의 동작은 Animator가 start되면 멈춘다.
//    public func start()
//
//    /// Animator 의 종료 콜백을 지정한다. Start 된 애니메이션이 종료되거나 stop이 호출되면 지정한 callback 이 호출된다. nil 로 지정해서 기존에 지정했던 callback을 제거할 수 있다. 기본값 nil.
//    ///
//    /// - parameter callback: Animator에 추가할 종료 콜백.
//    public func setStopCallback(_ callback: (((any KakaoMapsSDK.Animator)?) -> Void)?)
//
//    /// Animator의 동작을 멈춘다.
//    ///
//    /// stop이 호출되면 다시 애니메이션이 끝난것으로 간주되어 Animator에 속한 InfoWindow는 모두 비워지므로, Animator를 다시 동작시키리면 다시 InfoWindow를 Animator에 추가해야한다.
//    public func stop()
//
//    /// Animator에 InfoWindow를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 InfoWindow를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 InfoWindow를 추가할 수 없다.
//    ///
//    /// - parameter infoWindow: Animator에 추가할 InfoWindow
//    @objc public func addInfoWindow(_ infoWindow: KakaoMapsSDK.InfoWindow)
//
//    /// Animator에 여러개의 InfoWindow를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 InfoWindow를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 InfoWindow를 추가할 수 없다.
//    ///
//    /// - parameter infoWindows: Animator에 추가할 InfoWindow 배열
//    @objc public func addInfoWindows(_ infoWindows: [KakaoMapsSDK.InfoWindow])
//
//    /// Animator에 추가한 InfoWindow를 모두 지운다.
//    ///
//    /// start() 호출 이후에는 동작하지 않는다.
//    @objc public func clearAllInfoWindows()
//
//    /// 추가한 animatorID
//    public var animatorID: String { get }
//
//    /// Animator 시작 여부
//    public var isStart: Bool { get }
//}
//
///// InfoWindowLayer - InfoWindow 들을 담는 layer
//@objc open class InfoWindowLayer : NSObject {
//
//    /// InfoWindowLayer의 visible 상태.
//    ///
//    /// layer의 on/off 상태를 나타내며, layer에 속한 객체의 show/hide는 별도로 동작시켜야한다.
//    ///
//    /// 즉, layer의 visible이 true여도 layer에 속한 객체의 show를 호출해야 보이고, visible이 false라면 layer에 속한 객체는 화면에 표시되지 않는다.
//    @objc public var visible: Bool
//
//    /// 추가한 모든 InfoWindow를 지운다.
//    @objc public func clear()
//
//    /// InfoWindow를 현재 레이어에 추가한다.
//    ///
//    /// InfoWindow를 레이어에 추가하기 전까지는 화면에 표시되지 않는다.
//    ///
//    /// 같은 이름으로 중복으로 추가할 수 없다.
//    ///
//    /// - parameter gui: 추가할 InfoWindow 객체
//    @objc public func addInfoWindow(_ gui: KakaoMapsSDK.InfoWindow)
//
//    /// InfoWindow를 현재 레이어에서 제거한다.
//    ///
//    /// - parameter gui: 제거할 InfoWindow 객체
//    @objc public func removeInfoWindow(_ gui: KakaoMapsSDK.InfoWindow)
//
//    /// guiName을 Key로 갖는 InfoWindow를 현재 레이어에서 제거한다.
//    ///
//    /// - parameter guiName: 제거할 InfoWindow의 guiName
//    @objc public func removeInfoWindow(guiName: String)
//
//    /// InfoWindowLayer에 추가되어있는 InfoWindow를 guiName을 Key로 가져온다.
//    ///
//    /// - parameter guiName: 가져올 InfoWindow의 guiName
//    /// - returns: 이름에 해당하는 InfoWindow. 없을 경우 nil.
//    @objc public func getInfoWindow(guiName: String) -> KakaoMapsSDK.InfoWindow?
//
//    /// InfoWindowLayer에 특정 guiName을 가진 InfoWindow가 존재하는지 체크한다.
//    ///
//    /// - parameter guiName: 추가되어있는지 확인할 InfoWindow guiName
//    /// - returns: 존재 여부. 이미 추가되어있는 guiName의 경우 true, 아니면 false를 리턴한다.
//    @objc public func isInfoWindowExist(guiName: String) -> Bool
//
//    /// InfoWindowLayer에 추가한 모든 InfoWindow를 가져온다.
//    ///
//    /// - returns: 추가된 모든 InfoWindow 객체 배열
//    @objc public func getAllInfoWindows() -> [KakaoMapsSDK.InfoWindow]?
//}
//
///// 지도 뷰를 위한 클래스
//@objc open class KakaoMap : KakaoMapsSDK.ViewBase {
//
//    /// 여백을 지정한다.
//    ///
//    /// 여백을 지정하면, 지도 중심점 계산이나 애니메이션 기능과 같이 뷰 영역 계산이 필요한 부분에 반영된다.
//    ///
//    /// 예를들어, 좌측 여백을 지정하면 화면의 중심점에 대한 위치 계산시 (좌측여백 / 2)만큼 우측으로 밀린 지점에 대한 위치로 계산한다.
//    ///
//    /// - parameter insets: 상하좌우 여백
//    @objc open func setMargins(_ insets: UIEdgeInsets)
//
//    /// 여백을 0으로 초기화한다.
//    @objc open func resetMargins()
//
//    /// 지도 Poi 표시 여부를 설정한다.
//    ///
//    /// - parameter enable: true인경우, 지도판의 Poi가 표시되고, false인 경우 지도판의 Poi가 표시되지 않는다.
//    @objc open func setPoiEnabled(_ enable: Bool)
//
//    /// 지도 기본 Poi(API를 통해 추가된 POI가 아닌 POI) 들의 클릭가능 여부
//    @objc open var poiClickable: Bool
//
//    /// 지도 최소 레벨.
//    ///
//    /// KakaoMap의 지도 구성상 최소 레벨을 가져온다.
//    @objc public var minLevel: Int { get }
//
//    /// 지도 최대 레벨.
//    ///
//    /// KakaoMap의 지도 구성상 최대 레벨을 가져온다.
//    @objc public var maxLevel: Int { get }
//
//    /// 카메라 이동 최소 레벨
//    ///
//    /// 카메라가 이동할 수 있는 최소 레벨. 새 값을 지정할 때, minLevel~maxLevel 사이의 값이 아닐 경우 무시된다. cameraMinLevel은 cameraMaxLevel 보다 같거나 작아야 한다.
//    @objc open var cameraMinLevel: Int
//
//    /// 카메라 이동 최대 레벨
//    ///
//    /// 카메라가 이동할 수 있는 최대 레벨. 새 값을 지정할 때, minLevel~maxLevel 사이의 값이 아닐 경우 무시된다. cameraMaxLevel은 cameraMinLevel보다 크거나 같아야 한다.
//    @objc open var cameraMaxLevel: Int
//
//    /// 현재 줌 레벨.
//    ///
//    /// 현재 KakaoMap의 줌 레벨을 가져온다.
//    @objc open var zoomLevel: Int { get }
//
//    /// 현재 포커스 상태
//    ///
//    /// KakaoMap의 현재 Focus 여부를 가져온다.
//    @objc open var isFocused: Bool { get }
//
//    /// 현재 지도의 상하좌우 여백 값.
//    ///
//    /// KakaoMap의 현재 상하좌우 여백값을 가져온다.
//    @objc open var margins: UIEdgeInsets { get }
//
//    /// 카메라를 cameraUpdate로 정의된 대로 즉시 이동한다.
//    ///
//    /// 진행중이던 카메라 이동 애니메이션은 모두 종료된다.
//    ///
//    /// - SeeAlso: CameraUpdate
//    /// - parameters:
//    ///     - cameraUpdate: 카메라 이동을 정의한 CameraUpdate.
//    ///     - callback: 이동 완료시 호출될 callback
//    @objc open func moveCamera(_ cameraUpdate: KakaoMapsSDK.CameraUpdate, callback: (() -> Void)? = nil)
//
//    /// 카메라를 cameraUpdate로 정의된 대로 animationOption 에 따라 이동한다.
//    ///
//    /// - SeeAlso: CameraUpdate
//    /// - SeeAlso: CameraAnimationOptions
//    /// - parameters:
//    ///     - cameraUpdate: 카메라 이동을 정의한 CameraUpdate.
//    ///     - options: 이동 애니메이션 옵션.
//    ///     - callback: 이동 애니메이션 종료시 호출될 callback
//    @objc open func animateCamera(cameraUpdate: KakaoMapsSDK.CameraUpdate, options: CameraAnimationOptions, callback: (() -> Void)? = nil)
//
//    /// 카메라의 orientation(회전, 기울임)을 0으로 초기화시킨다.
//    ///
//    /// - parameters:
//    ///     - options:  애니메이션 옵션.
//    ///     - callback: 카메라 이동 애니메이션 종료시 호출될 callback
//    @objc open func resetCameraOrientation(_ options: CameraAnimationOptions = CameraAnimationOptions(autoElevation: false, consecutive: false, durationInMillis: 0), callback: (() -> Void)? = nil)
//
//    /// CameraAnimationOptions에 autoElevation 을 true로 지정한 애니메이션 진행시, autoElevation하는 동안 정북방향으로 카메라를 회전할지 여부를 지정한다.
//    ///
//    /// - parameter enable: true면 autoElevation시 정북으로 회전한다.
//    @objc open func setBackToNorthDuringAutoElevation(_ enable: Bool)
//
//    /// level에 해당하는 카메라 높이를 가져온다.
//    ///
//    /// - parameter level: 지도 레벨
//    /// - returns: 카메라 높이(m)
//    @objc open func heightAtLevel(_ level: Int) -> Double
//
//    /// 현재 KakaoMap 영역의 viewPoint에 해당하는 실제 위치를 가져온다.
//    ///
//    /// - parameter viewPoint: KakaoMap 뷰 범위 내의 임의의 한 지점 (x, y)
//    /// - returns: viewPoint에 해당하는 실제 위치를 나타내는 MapPoint. viewPoint가 KakaoMap의 범위 밖일 경우 잘못된 MapPoint가 return 된다.
//    @objc open func getPosition(_ viewPoint: CGPoint) -> KakaoMapsSDK.MapPoint
//
//    /// 임의의 지점들이 특정레벨에서 지정된 viewRect 안에 모두 그려질 수 있는지를 확인한다.
//    ///
//    /// - parameter mapPoints: MapPoint의 배열
//    /// - parameter atLevel: 지도 레벨
//    /// - parameter rotationAngle: 카메라 회전각(radian).
//    /// - parameter weight: view bound내에 지점들이 다 들어올지 판단할 때 기준이 되는 높이의 가중치값. 기본값은 1.0이고, 1.0보다 크면 view bound내의 points를 좀 더 넉넉하게 보여질 수 있도록 level을 판단한다.
//    /// - parameter inRect: view bound내에 지점들을 그리고 싶은 sub viewRect. nil이면 전체
//    /// - returns: 가능여부
//    open func canShow(mapPoints: [KakaoMapsSDK.MapPoint], atLevel level: Int, rotationAngle: Double = 0.0, weight: Float = 1.0, inRect rect: CGRect? = nil) -> Bool
//
//    /// 카메라 애니메이션 활성화 상태를 지정한다.
//    ///
//    /// `true`로 설정하면 animateCamera 호출 시 애니메이션이 활성화 된다. `false`로 설정하면 animateCamera()를 호출해도 애니메이션 없이 즉시 이동된다.
//    @objc open var cameraAnimationEnabled: Bool
//
//    /// 현재 카메라 높이(m)를 가져온다.
//    @objc open var cameraHeight: Double { get }
//
//    /// 현재 카메라의 회전각(radian, 정북기준 반시계방향).
//    @objc open var rotationAngle: Double { get }
//
//    /// 현재 카메라의 기울임각(radian, 수직 방향 기준).
//    @objc open var tiltAngle: Double { get }
//
//    /// 지도상 표시를 지원하는 언어코드 목록을 가져온다.
//    ///
//    /// - returns:  지원하는 언어코드의 배열
//    @objc public func getSupportedLanguages() -> [String]
//
//    /// 지도상에 표시될 언어를 설정한다.
//    ///
//    /// 지원되는 언어만 선택가능하다. 미지원언어를 지정할 경우 무시된다.
//    ///
//    /// - parameter langCode: 언어 코드.(ex. ko, en, ja, zh)
//    @objc open func setLanguage(_ langCode: String)
//
//    /// 지도상에 표시될 언어를 설정한다.
//    ///
//    /// 지원되는 언어만 선택가능하다. 미지원언어를 지정할 경우 무시된다.
//    /// 
//    /// - parameter langCode: 언어 코드.
//    @available(macOS 13, iOS 16, tvOS 16, watchOS 9, *)
//    open func setLanguage(_ langCode: Locale.LanguageCode)
//
//    /// 지도에 표시될 기본 라벨의 타일별 최대 개수를 지정한다.
//    ///
//    /// - parameters:
//    ///     - category: 라벨 카테고리
//    ///     - count: 최대 개수.
//    @objc open func setMaxCountPerTile(category: LabelCategory, count: UInt)
//
//    /// 타일별 최대 개수 지정값을 초기값으로 되돌린다.
//    ///
//    /// - parameter category : 라벨 카테고리
//    @objc open func resetMaxCountPerTile(category: LabelCategory)
//
//    /// 특정 카테고리의 지도 기본 라벨의 표시 유무를 지정한다.
//    ///
//    /// - parameters:
//    ///     - category: 라벨 카테고리
//    ///     - visible: 표시여부.
//    @objc open func setLabelCategoryVisible(category: LabelCategory, visible: Bool)
//
//    /// 건물 높이 scale을 지정한다. scale값에 따라 그려지는 건물의 높이가 조절된다.
//    ///
//    /// - parameter scale: 0 ~ 1 사이의 건물 높이 scale
//    @objc open var buildingScale: Float
//
//    /// 지도상의 poi size를 조절한다. icon 크기도 함께 변한다.
//    ///
//    /// default값은 Regular
//    @objc open var poiScale: PoiScaleType
//
//    /// viewRect크기가 변할 때, 지도 각 레벨에 해당하는 카메라의 높이값이 재계산된다. 계산 후 레벨을 유지할 수 있도록 카메라를 조정할지 여부를 지정한다.
//    ///
//    /// true일 경우, 크기가 변하면 카메라 높이값이 레벨을 유지할 수 있게 재조정된다. 기본값 false.
//    @objc open var keepLevelOnResize: Bool
//
//    /// Tap인식 사이의 시간. 
//    ///
//    /// 탭이 인식되었을 때 연속된 제스쳐를 위한 인식 대기시간을 의미한다. 탭, 더블탭, 탭&드래그 제스쳐 등의 인식에 영향을 미친다. 단위 ms. 기본값 450ms
//    @objc public var tapInterval: UInt
//
//    /// 지도 위에 overlay를 표시한다.
//    ///
//    /// - parameter overlay: 지도위에 표시하고자 하는 overlay 이름
//    @objc open func showOverlay(_ overlay: String)
//
//    /// 지도 위에 overlay를 숨긴다.
//    ///
//    /// - parameter overlay: 숨길 overlay 이름
//    @objc open func hideOverlay(_ overlay: String)
//
//    /// 축척을 표시한다.
//    @objc open func showScaleBar()
//
//    /// 축척을 숨긴다.
//    @objc open func hideScaleBar()
//
//    /// 축척의 alignment와 offset을 지정한다.
//    ///
//    /// - SeeAlso: GuiAlignment
//    /// - parameter origin: 축척의 origin
//    /// - parameter position: 축척 origin으로부터의 offset(pt)
//    @objc open func setScaleBarPosition(origin: GuiAlignment, position: CGPoint)
//
//    /// 축척의 자동숨김 기능 활성화를 지정한다.
//    /// 활성화되면 축척이 보여진 뒤 일정시간 후에 자동으로 숨겨진다.
//    /// - parameter autoDisappear: 자동숨김 활성화.
//    @objc open func setScaleBarAutoDisappear(_ autoDisappear: Bool)
//
//    /// 축척의 FadeInOutOption을 지정한다.
//    ///
//    /// - parameter option: FadeInOut 옵션.
//    @objc open func setScaleBarFadeInOutOption(_ option: FadeInOutOptions)
//
//    /// 나침반을 표시한다.
//    @objc open func showCompass()
//
//    /// 나침반을 숨긴다.
//    @objc open func hideCompass()
//
//    /// 나침반의 alignment를 지정한다.
//    ///
//    /// - SeeAlso: GuiAlignment
//    /// - parameter origin: 나침반의 alignment
//    /// - parameter position : 나침반 alignmnet로부터의 offset(pt)
//    @objc open func setCompassPosition(origin: GuiAlignment, position: CGPoint)
//
//    /// 로고의 위치를 지정한다.
//    /// 로고는 SpriteGUI 와 같은 방식으로 화면상의 특정위치에 고정적으로 표시되므로, 다른 GUI 와 겹치는 현상을 피하기 위해 로고의 위치를 이동시키는 데 사용한다.
//    /// 위치 지정방식은 SpriteGUI와 동일하다.
//    ///
//    /// - parameters:
//    ///     - origin: 로고의 alignment
//    ///     - position: alignment 기준점으로부터의 offset
//    @objc public func setLogoPosition(origin: GuiAlignment, position: CGPoint)
//
//    /// 제스쳐의 동작 기준점을 뷰의 가운데로 고정시킨다. 줌/회전/틸트 관련 제스쳐에만 적용된다(그 외 제스쳐는 무시함).
//    ///
//    /// - parameter forGesture: 제스쳐 종류
//    @objc open func lockReferencePoint(forGesture gesture: GestureType)
//
//    /// 제스쳐의 동작 기준점을 뷰의 가운데 고정을 해제한다.
//    ///
//    /// - parameter forGesture: 제스쳐 종류
//    @objc open func unlockReferencePoint(forGesture gesture: GestureType)
//
//    /// 뷰를 다시 그린다.
//    @objc open func refresh()
//
//    /// 지도 뷰의 DimmingScreen 객체
//    @objc open var dimScreen: KakaoMapsSDK.DimScreen { get }
//
//    /// LabelManager
//    /// - returns : 이 KakaoMap의 LabelManager
//    @objc public func getLabelManager() -> KakaoMapsSDK.LabelManager
//
//    /// ShapeManager
//    /// - returns : 이 KakaoMap의 ShapeManager
//    @objc public func getShapeManager() -> KakaoMapsSDK.ShapeManager
//
//    /// TrackingManager
//    /// - returns : 이 KakaoMap의 TrackingManager
//    @objc public func getTrackingManager() -> KakaoMapsSDK.TrackingManager
//
//    /// RouteManager
//    /// - returns : 이 KakaoMap의 RouteManager
//    @objc public func getRouteManager() -> KakaoMapsSDK.RouteManager
//
//    /// GuiManager
//    /// - returns : 이 KakaoMap의 GuiManager
//    @objc public func getGuiManager() -> KakaoMapsSDK.GuiManager
//
//    /// ZoneManager
//    ///  - returns : 이 KakaoMap의 ZoneManager
//    @objc public func getZoneManager() -> KakaoMapsSDK.ZoneManager
//
//    /// 이벤트 delegate를 지정한다.
//    ///
//    /// - parameter delegate: event delegate
//    @objc open var eventDelegate: (any KakaoMapsSDK.KakaoMapEventDelegate)?
//
//    /// 뷰의 활성화 상태
//    ///
//    /// `true`인 경우 렌더링이 실행되며,`false`인 경우 렌더링을 하지 않는다.
//    @objc open var isEnabled: Bool
//}
//
//extension KakaoMap {
//
//    /// 뷰 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addMapTappedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.ViewInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Terrain layer 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addTerrainTappedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.TerrainInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Terrain layer 롱프레스 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addTerrainLongPressedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.TerrainInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// POI 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addPoisTappedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.PoisInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// 지도 이동 시작 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addCameraWillMovedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.CameraActionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// 지도 이동 종료 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addCameraStoppedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.CameraActionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// 뷰의 포커스 변경 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addFocusChangedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.FocusChangedEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// 리사이즈 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addViewResizedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.KakaoMap) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Margin 변경 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addMarginUpdatedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.KakaoMap) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// 나침반 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addCompassTappedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.KakaoMap) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Zone 생성 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addEnterZoneEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.ZoneEnterEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Zone 삭제 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    public func addLeaveZoneEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.ZoneLeaveEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//}
//
//extension KakaoMap {
//
//    /// ViewInfo를 변경한다.
//    ///
//    /// 지정된 이름의 Viewinfo를 서버로부터 가져와서 현재 뷰에 교체하여 적용한다.
//    ///
//    /// 결과는 event delegate 로 전달된다.
//    ///
//    /// Note: 지도용 ViewInfo만 가능.
//    ///
//    /// - parameter appName: 변경할 app 이름
//    /// - parameter viewInfoName: 변경할 viewInfo 이름
//    @objc dynamic public func changeViewInfo(appName: String, viewInfoName: String)
//}
//
///// KakaoMap의 이벤트 Delegate
//@objc public protocol KakaoMapEventDelegate {
//
//    /// 포커스가 변경되었을 때 호출.
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    /// - parameter focus: 변경된 포커스 상태
//    @objc optional func kakaoMapFocusDidChanged(kakaoMap: KakaoMapsSDK.KakaoMap, focus: Bool)
//
//    /// KakaoMap의 크기가 변경되었을 때 호출.
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    @objc optional func kakaoMapDidResized(_ kakaoMap: KakaoMapsSDK.KakaoMap)
//
//    /// KakaoMap의 Margin이 변경되었을 때 호출.
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    @objc optional func kakaoMapMarginDidUpdated(_ kakaoMap: KakaoMapsSDK.KakaoMap)
//
//    /// KakaoMap의 영역이 탭되었을 때 호출.
//    ///
//    /// - parameter kakaoMap: 탭된 kakaoMap 객체
//    /// - parameter point: 탭 위치
//    @objc optional func kakaoMapDidTapped(kakaoMap: KakaoMapsSDK.KakaoMap, point: CGPoint)
//
//    /// Terrain Layer가 탭되면 호출.
//    ///
//    /// - parameter kakaoMap: 탭된 kakaoMap 객체
//    /// - parameter position: 탭된 지점의 위치
//    @objc optional func terrainDidTapped(kakaoMap: KakaoMapsSDK.KakaoMap, position: KakaoMapsSDK.MapPoint)
//
//    /// Terrain Layer가 길게 눌리면 발생.
//    ///
//    /// - parameter kakaoMap: 눌린 kakaoMap 객체
//    /// - parameter position: 눌린 지점의 위치
//    @objc optional func terrainDidLongPressed(kakaoMap: KakaoMapsSDK.KakaoMap, position: KakaoMapsSDK.MapPoint)
//
//    /// Poi가 탭되면 호출.
//    ///
//    /// - parameter kakaoMap: Poi가 속한 KakaoMap
//    /// - parameter layerID: Poi가 속한 layerID
//    /// - parameter poiID:  Poi의 ID
//    /// - parameter position: Poi의 위치
//    @objc optional func poiDidTapped(kakaoMap: KakaoMapsSDK.KakaoMap, layerID: String, poiID: String, position: KakaoMapsSDK.MapPoint)
//
//    /// 나침반이 탭 되면 호출.
//    ///
//    /// - parameter kakaoMap: 나침반이 속한 KakaoMap
//    @objc optional func compassDidTapped(kakaoMap: KakaoMapsSDK.KakaoMap)
//
//    /// 카메라 이동이 시작될 때 호출.
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    /// - parameter by: 지도 이동을 유발한 원인(사용자 제스쳐, API 호출).
//    @objc optional func cameraWillMove(kakaoMap: KakaoMapsSDK.KakaoMap, by: MoveBy)
//
//    /// 지도 이동이 멈췄을 때 호출.
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    /// - parameter by: 지도 이동을 유발한 원인(사용자 제스쳐, API 호출).
//    @objc optional func cameraDidStopped(kakaoMap: KakaoMapsSDK.KakaoMap, by: MoveBy)
//
//    /// 지도의 viewInfo변경이 성공했을 때 호출
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    /// - parameter viewInfoName: 변경한 viewInfoName
//    @objc optional func onViewInfoChanged(kakaoMap: KakaoMapsSDK.KakaoMap, viewInfoName: String)
//
//    /// 지도의 viewInfo변경이 실패했을 때 호출
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    /// - parameter viewInfoName: 변경한 viewInfoName
//    @objc optional func onViewInfoChangeFailure(kakaoMap: KakaoMapsSDK.KakaoMap, viewInfoName: String)
//
//    /// Zone에 진입했을 때(zone이 checkRect 안에 들어왔을 때) 호출
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    /// - parameter zoneType: Zone Type (ex. indoor)
//    /// - parameter zoneId: CheckRect 안에 들어온 zone의 Id
//    /// - parameter zoneDetailId: zone의 기본 detail Id
//    /// - parameter zoneDetails: zone의 detail Id의 목록
//    /// - parameter zoneLinkInfos: zone 연결정보 dictionary. key : 현재 zoneDetail 중에서 다른 zone과 연결된 부분이 있는 detailId. value : 연결된 다른 zone-detail 리스트.
//    @objc optional func onEnterZone(kakaoMap: KakaoMapsSDK.KakaoMap, zoneType: String, zoneId: String, zoneDetailId: String, zoneDetails: [String], zoneLinkInfos: [String : [KakaoMapsSDK.ZoneLinkInfo]])
//
//    /// Zone을 나갔을 때(zone이 checkRect 밖으로 나갔을 때) 호출
//    ///
//    /// - parameter kakaoMap: KakaoMap
//    /// - parameter zoneType: Zone Type (ex. indoor)
//    /// - parameter zoneId: CheckRect 밖으로 나간 zone의 Id
//    /// - parameter zoneDetailId: zone의 기본 detail Id
//    /// - parameter zoneDetails: zone의 detail Id의 목록
//    @objc optional func onLeaveZone(kakaoMap: KakaoMapsSDK.KakaoMap, zoneType: String, zoneId: String, zoneDetailId: String, zoneDetails: [String])
//}
//
///// 키프레임으로 구성되는 애니메이션 효과
//@objc public class KeyFrameAnimationEffect : NSObject, KakaoMapsSDK.PoiAnimationEffect {
//
//    /// 애니메이션 종료 시 애니메이터에 속한 객체들을 숨길지에 대한 여부.
//    ///
//    /// true로 설정하면 애니메이션이 종료되면 객체들이 화면에서 자동으로 사라진다.
//    public var hideAtStop: Bool
//
//    /// 애니메이션 종료 시 애니메이터에 속한 객체들을 제거할지에 대한 여부.
//    ///
//    /// true로 설정하면 애니메이션이 종료되면 객체들이 제거된다.
//    public var removeAtStop: Bool
//
//    /// 애니메이션 종료 후 초기상태로 원복 여부.
//    @objc public var resetToInitialState: Bool
//}
//
///// Label protocol
//@objc public protocol Label {
//
//    /// 라벨 표출
//    @objc func show()
//
//    /// 라벨 숨김
//    @objc func hide()
//
//    /// 라벨 스타일 변경
//    @objc func changeStyle(styleID: String, enableTransition: Bool)
//
//    /// 라벨이 속한 레이어 ID
//    @objc var layerID: String { get }
//
//    /// 라벨 ID
//    @objc var itemID: String { get }
//
//    /// 라벨 표출여부
//    @objc var isShow: Bool { get }
//
//    /// 사용자 객체
//    @objc var userObject: AnyObject? { get set }
//}
//
///// Label 종류(Poi, WaveText)를 관리하는 단위인 LabelLayer 클래스.
/////
///// Poi, WaveText를 추가/삭제 등 관리할 수 있으며, 일종의 그룹처럼 관리가 가능하다.
/////
///// 사용자가 직접 객체를 생성할 수 없으며, LabelManager를 통해 객체를 간접적으로 생성할 수 있다.
//@objc open class LabelLayer : NSObject {
//
//    /// LabelLayer의 visible 상태.
//    ///
//    /// layer의 on/off 상태를 나타내며, layer에 속한 객체의 show/hide는 별도로 동작시켜야한다.
//    ///
//    /// 즉, layer의 visible이 true여도 layer에 속한 객체의 show를 호출해야 보이고, visible이 false라면 layer에 속한 객체는 화면에 표시되지 않는다.
//    @objc public var visible: Bool
//
//    /// 현재 Layer에 있는 모든 item을 일괄적으로 지운다.
//    ///
//    /// 하나의 layer안에 Poi와 WaveText가 함께 추가가 가능하므로, 이 경우 clear를 호출게 되면 모든 Poi와 WaveText가 지워진다.
//    @objc public func clearAllItems()
//
//    /// 현재 Layer에 있는  Exit Transition 속성을 가진 Poi를 지운다.
//    @objc public func clearAllExitTransitionPois()
//
//    /// 현재 레이어의 clickable 속성을 지정한다.
//    ///
//    /// - parameter clickable: 클릭 설정 여부. 해당 레이어에 속한 모든 Poi에 적용된다.
//    @objc public func setClickable(_ clickable: Bool)
//
//    /// 현재 Layer에 Poi를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할경우 nil을 리턴한다.
//    ///
//    /// - parameters:
//    ///     - option: 생성할 Poi의 옵션
//    ///     - at: 생성할 Poi의 위치
//    ///     - callback: Poi 생성이 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성된 Poi 객체
//    @objc public func addPoi(option: KakaoMapsSDK.PoiOptions, at position: KakaoMapsSDK.MapPoint, callback: ((KakaoMapsSDK.Poi?) -> Void)? = nil) -> KakaoMapsSDK.Poi?
//
//    /// 현재 Layer에 같은 옵션을 가지는 다수의 Poi를 추가한다.
//    ///
//    /// 같은 옵션을 가지지만 위치만 다른 Poi를 생성할 경우 사용한다.
//    ///
//    /// 다수 생성을 위해 PoiOptions의 poiID는 무시되고 자동 생성된다.
//    ///
//    /// - parameters:
//    ///     - option: 생성할 Poi의 옵션
//    ///     - at: 생성할 Poi의 위치 배열
//    ///     - callback: Poi 생성이 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성된 Poi 객체
//    @objc public func addPois(option: KakaoMapsSDK.PoiOptions, at positions: [KakaoMapsSDK.MapPoint], callback: (([KakaoMapsSDK.Poi]?) -> Void)? = nil) -> [KakaoMapsSDK.Poi]?
//
//    /// 현재 Layer에 다른 옵션을 가지는 다수의 Poi를 추가한다.
//    ///
//    /// Poi별로 다른 옵션을 가지는 경우 사용한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할경우 기존 객체를 리턴한다.
//    ///
//    /// - Warning: 여러개의 옵션으로 여러개의 poi를 생성하는 경우, option과 position의 pair가 일치해야한다. 즉, position하나당 option 하나의 짝을 맞추어야 한다.
//    /// - parameters:
//    ///     - options: 생성할 Poi의 옵션 배열
//    ///     - at: Poi가 표시될 위치. option과 pair를 맞추어야 한다.
//    ///     - callback: Poi 생성이 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성된 Poi 객체배열
//    @objc public func addPois(options: [KakaoMapsSDK.PoiOptions], at positions: [KakaoMapsSDK.MapPoint], callback: (([KakaoMapsSDK.Poi]?) -> Void)? = nil) -> [KakaoMapsSDK.Poi]?
//
//    /// 현재 Layer에서 특정 Poi를 지운다.
//    ///
//    /// - parameters:
//    ///     - poiID: Layer에서 제거할 Poi Id
//    ///     - callback: Poi 제거가 완료되었을 때, 호출할 callback(optional)
//    @objc public func removePoi(poiID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에서 여러개의 Poi를 지운다.
//    ///
//    /// - parameters:
//    ///     - poiIDs: Layer에서 제거할 Poi Id 배열
//    ///     - callback: Poi 제거가 완료되었을 때, 호출할 callback(optional)
//    @objc public func removePois(poiIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속해있는 Poi를 모두 보여준다.
//    @objc public func showAllPois()
//
//    /// 현재 Layer에 속해있는 Poi를 모두 숨긴다.
//    @objc public func hideAllPois()
//
//    /// 현재 Layer에 속한 특정 Poi를 보여준다.
//    ///
//    /// - parameter poiIDs: 보여줄 Poi ID 배열
//    @objc public func showPois(poiIDs: [String])
//
//    /// 현재 Layer에 속한 특정 Poi를 숨긴다.
//    ///
//    /// - parameter poiIDs: 숨길 Poi ID 배열
//    @objc public func hidePois(poiIDs: [String])
//
//    /// 현재 Layer에 속한 Poi를 가져온다.
//    ///
//    /// - parameter poiID: 가져올 Poi ID
//    /// - returns: ID에 해당하는 Poi 객체, 없을경우 ni.
//    @objc public func getPoi(poiID: String) -> KakaoMapsSDK.Poi?
//
//    /// 현재 Layer에 속한 Poi들을 가져온다.
//    ///
//    /// - parameter poiIDs: 가져올 Poi ID
//    /// - returns: ID에 해당하는 Poi 객체 배열. 없을경우 ni.
//    @objc public func getPois(poiIDs: [String]) -> [KakaoMapsSDK.Poi]?
//
//    /// 현재 Layer에 속한 모든 Poi를 가져온다.
//    /// - returns: 레이어에 속한 모든 Poi.
//    @objc public func getAllPois() -> [KakaoMapsSDK.Poi]?
//
//    /// 현재 Layer에 WaveText를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할경우 nil을 리턴한다.
//    ///
//    /// - parameters:
//    ///     - options: 생성할 WaveText의 option
//    ///     - callback: WaveText 제거가 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성한 waveText 객체
//    @objc public func addWaveText(_ options: KakaoMapsSDK.WaveTextOptions, callback: ((KakaoMapsSDK.WaveText?) -> Void)? = nil) -> KakaoMapsSDK.WaveText?
//
//    /// 현재 Layer에 속한 특정 WaveText를 지운다.
//    ///
//    /// - parameters:
//    ///     - waveTextID: 지우고자 하는 WaveText의 ID
//    ///     - callback: WaveText 제거가 완료되었을 때, 호출할 callback(optional)
//    @objc public func removeWaveText(waveTextID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속한 여러개의 특정 WaveText를 지운다.
//    ///
//    /// - parameters:
//    ///     - waveTextIDs: 지우고자 하는 WaveText의 ID 배열
//    ///     - callback: WaveText 제거가 모두 완료되었을 때, 호출할 callback(optional)
//    @objc public func removeWaveTexts(waveTextIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속한 모든 WaveText를 표시한다.
//    @objc public func showAllWaveTexts()
//
//    /// 현재 Layer에 속한 모든 WaveText를 숨긴다.
//    @objc public func hideAllWaveTexts()
//
//    /// 현재 Layer에 속한 특정 WaveText를 보여준다.
//    ///
//    /// - parameter waveTextIDs: 보여줄 WaveText ID 배열
//    @objc public func showWaveTexts(waveTextIDs: [String])
//
//    /// 현재 Layer에 속한 특정 WaveText를 숨긴다.
//    ///
//    /// - parameter waveTextIDs: 숨길 WaveText ID 배열
//    @objc public func hideWaveTexts(waveTextIDs: [String])
//
//    /// 현재 Layer에 속한 WaveText를 가져온다.
//    ///
//    /// - parameter waveTextID: 가져올 WaveText ID
//    /// - returns: ID에 해당하는 WaveText객체, 없을경우 ni.
//    @objc public func getWaveText(waveTextID: String) -> KakaoMapsSDK.WaveText?
//
//    /// 현재 Layer에 속한 여러개의 WaveText를 가져온다.
//    ///
//    /// - parameter waveTextIDs: 가져올 WaveText ID배열
//    /// - returns: ID에 해당하는 WaveText객체 배열, 없을경우 ni.
//    @objc public func getWaveTexts(waveTextIDs: [String]) -> [KakaoMapsSDK.WaveText]?
//
//    /// 현재 Layer에 속한 모든 waveText를 가져온다.
//    @objc public func getAllWaveTexts() -> [KakaoMapsSDK.WaveText]?
//
//    /// layer의 ID
//    @objc public var layerID: String { get }
//
//    /// layer에 속한 Poi가 경쟁하는 방법을 지정한다.
//    ///
//    /// Layer의 우선순위(zOrder)에 따라 Poi끼리 겹쳐졌을 때, Poi가 표시될 정책을 지정한다.
//    ///
//    /// - SeeAlso: CompetitionType
//    @objc public var competitionType: CompetitionType { get }
//
//    /// Poi가 경쟁할 때, 경쟁을 하는 단위를 선택한다.
//    ///
//    /// - SeeAlso: CompetitionUnit
//    @objc public var competitionUnit: CompetitionUnit { get }
//
//    /// competitionType이 same일 경우, 경쟁을 하는 기준이 된다.
//    ///
//    /// - SeeAlso: OrderingType
//    @objc public var orderType: OrderingType { get }
//
//    /// layer의 렌더링 우선순위
//    ///
//    /// zOrder는 같은 LabelLayer타입끼리만 유효하며, 기본적으로 zOrder 값이 클수록 더 높은 우선권을 가진다.
//    @objc public var zOrder: Int
//}
//
///// LabelLayer 생성 옵션
//@objc open class LabelLayerOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - layerID: layer ID
//    ///     - competitionType: 다른 poi와 경쟁하는 방법
//    ///     - competitionUnit: 경쟁을 하는 단위
//    ///     - orderType:competitionType이 same일 때, 경쟁하는 기준
//    ///     - zOrder: layer의 zOrder. 값이 클수록 위에 그려진다.
//    @objc public init(layerID: String, competitionType: CompetitionType, competitionUnit: CompetitionUnit, orderType: OrderingType, zOrder: Int)
//
//    /// layerID
//    @objc public var layerID: String
//
//    /// 다른 poi와 경쟁하는 방법을 지정한다. 해당 레이어에 속한 poi는 모두 해당 방법으로 경쟁한다.
//    @objc public var competitionType: CompetitionType
//
//    /// 경쟁할 때 단위를 지정한다. 해당 레이어에 속한 poi는 모두 해당 방법으로 경쟁한다.
//    @objc public var competitionUnit: CompetitionUnit
//
//    /// competitionType이 same일 때 경쟁하는 기준을 설정한다.
//    @objc public var orderType: OrderingType
//
//    /// layer의 zOrder
//    ///
//    /// zOrder는 같은 LabelLayer타입끼리만 유효하며, zOrder 값이 클수록 더 위에 그려진다
//    ///
//    /// 즉, zOrder가 0인 LabelLayer는에 속한 Label은 zOrder가 1인 LabelLayer에 속한 Label보다 아래에 그려진다.
//    @objc public var zOrder: Int
//}
//
///// KakaoMap에서 사용자 Poi, LodPoi, WaveText등 Label종류를 사용하고 관리하기 위한 클래스
/////
///// 각 Object의 레이어 관리, 스타일추가와 Poi의 Animator 추가등이 가능하다.
/////
///// KakaoMap에 종속적이므로 KakaoMap이 삭제된 뒤에도 사용하지 않도록 주의하여야 한다.
//@objc public class LabelManager : NSObject {
//
//    /// PoiStyle을 추가한다.
//    ///
//    /// 레벨별로 다른 스타일을 갖는 PoiStyle을 추가한다. 이미 추가된 styleID와 중복된 styleID로 추가할 수 없으며, overwrite되지 않는다.
//    ///
//    /// - SeeAlso: PoiStyle
//    /// - parameter style: 추가할 PoiStyle
//    @objc open func addPoiStyle(_ style: KakaoMapsSDK.PoiStyle)
//
//    /// PoiStyle을 삭제한다.
//    ///
//    /// - parameter styleID: 삭제할 PoiStyle ID
//    @objc open func removePoiStyle(_ styleID: String)
//
//    /// WaveTextStyle을 추가한다.
//    ///
//    /// 레벨별로 다른 스타일을 갖는 WaveTextStyle을 추가한다. 이미 추가된 styleID와 중복된 styleID로 추가할 수 없으며, overwrite되지 않는다.
//    ///
//    /// WaveText에는 TextStyle중 charSpace, lineSpace, aspectRatio 는 적용되지 않는다.
//    ///
//    /// - SeeAlso: WaveTextStyle
//    /// - parameter style: 추가할 WaveTextStyle
//    @objc open func addWaveTextStyle(_ style: KakaoMapsSDK.WaveTextStyle)
//
//    /// LabelLayer를 추가한다.
//    ///
//    /// LabelLayer는 LOD가 적용되지 않는 Label인 Poi와 WaveText를 관리하는 단위. 사용자가 LabelLayer 객체를 직접 생성할 수 없으며, LabelManager를 통해 LayerOptions으로 생성할 수 있다. 생성한 레이어에 Poi 및 WaveText를 추가&삭제할 수 있다.
//    ///
//    /// LabelLayer, LodLabelLayer를 통합으로 관리하므로 중복 ID로 추가할 수 없으며, overwrite되지 않고 기존 Layer가 유지된다.
//    ///
//    /// - SeeAlso: LabelLayer
//    /// - SeeAlso: LabelLayerOptions
//    /// - parameter option: 추가할 LabelLayer Option
//    /// - returns: add 성공시 add된 layer. 같은 ID의 layer가 이미 있을 경우 기존 레이어 타입이 LabelLayer 이면 해당 layer, 아니면 nil
//    @objc open func addLabelLayer(option: KakaoMapsSDK.LabelLayerOptions) -> KakaoMapsSDK.LabelLayer?
//
//    /// LabelLayer를 삭제한다.
//    ///
//    /// LayerID로 Layer를 삭제한다. Layer 삭제와 동시에 Layer에 추가되어있던 Poi,WaveText도 모두 삭제된다.
//    ///
//    /// - parameter layerID: 삭제할 LabelLayer의 ID
//    @objc open func removeLabelLayer(layerID: String)
//
//    /// LabelLayer를 모두 삭제한다.
//    ///
//    /// KakaoMap에 등록된 모든 LabelLayer를 삭제한다. Layer 삭제와 동시에 Layer에 추가되어있던 Poi,WaveText도 모두 삭제된다.
//    @objc public func clearAllLabelLayers()
//
//    /// 추가한 LabelLayer를 가져온다.
//    ///
//    /// - parameter layerID: 가져올 LabelLayer ID
//    /// - returns: LabelLayer
//    @objc public func getLabelLayer(layerID: String) -> KakaoMapsSDK.LabelLayer?
//
//    /// LodLabelLayer를 추가한다.
//    ///
//    /// LodLabelLayer는 LOD가 적용되는 LodPoi를 관리하는 단위이다. 사용자가 LodLabelLayer 객체를 직접 생성할 수 없으며, LabelManager를 통해 LodLayerOptions으로 생성할 수 있다. 생성한 레이어에 LodPoi를 추가&삭제할 수 있다.
//    ///
//    /// LabelLayer, LodLabelLayer를 통합으로 관리하므로 중복 ID로 추가할 수 없으며, overwrite되지 않고 기존 Layer가 유지된다.
//    ///
//    /// - SeeAlso: LodLabelLayer
//    /// - SeeAlso: LodLabelLayerOptions
//    /// - parameter option: 추가할 LodLabelLayerOptions
//    /// - returns: add 성공시 add된 layer. 같은 ID의 layer가 이미 있을 경우 기존 레이어 타입이 LodLabelLayer 이면 해당 layer, 아니면 nil
//    @objc open func addLodLabelLayer(option: KakaoMapsSDK.LodLabelLayerOptions) -> KakaoMapsSDK.LodLabelLayer?
//
//    /// LodLabelLayer를 삭제한다.
//    ///
//    /// LayerID로 LodLabelLayer를 삭제한다. Layer 삭제와 동시에 Layer에 추가되어있던 LodPoi도 모두 삭제된다.
//    ///
//    /// - parameter layerID: 삭제할 LodLabelLayer의 ID
//    @objc open func removeLodLabelLayer(layerID: String)
//
//    /// LodLabelLayer를 모두 삭제한다.
//    ///
//    /// KakaoMap에 등록된 모든 LodLabelLayer를 삭제한다. Layer 삭제와 동시에 Layer에 추가되어있던 LodPoi도 모두 삭제된다.
//    @objc public func clearAllLodLabelLayers()
//
//    /// 추가한 LodLabelLayer를 가져온다.
//    ///
//    /// - parameter layerID: 가져올 LodLabelLayer ID
//    /// - returns: LodLabelLayer
//    @objc public func getLodLabelLayer(layerID: String) -> KakaoMapsSDK.LodLabelLayer?
//
//    /// PoiAnimator를 추가한다.
//    ///
//    /// PoiAnimator 객체는 사용자가 직접 생성할 수 없으며, Manager를 통해서만 생성 가능하다.
//    ///
//    /// - SeeAlso: PoiAnimator
//    /// - SeeAlso: AnimationInterpolation
//    /// - parameters:
//    ///     - animatorID: 추가할 animatorID
//    ///     - effect: 애니메이션 효과 지정
//    /// - returns: 생성된 PoiAnimator
//    @objc public func addPoiAnimator(animatorID: String, effect: any KakaoMapsSDK.PoiAnimationEffect) -> KakaoMapsSDK.PoiAnimator?
//
//    /// 추가한 PoiAnimator를 삭제한다.
//    ///
//    /// - parameter animatorID: 삭제할 PoiAnimator ID
//    @objc public func removePoiAnimator(animatorID: String)
//
//    /// 추가한 모든 PoiAnimator를 제거한다.
//    @objc public func clearAllPoiAnimators()
//
//    /// 추가한 Animator를 가져온다.
//    ///
//    /// - parameter animatorID: animatorID
//    /// - returns: PoiAnimator
//    @objc public func getPoiAnimator(animatorID: String) -> KakaoMapsSDK.PoiAnimator?
//}
//
///// 대량의 Poi( ex. 즐겨찾기 )를 관리하는 단위인 LodLabelLayer 클래스
/////
///// 대량의 Poi를 추가할땐 LabelLayer가 아닌 LodLabelLayer를 이용하여 경쟁처리를 하면 빠르게 Poi를 보여줄 수 있다.
/////
///// LodLabelLayer에 추가된 LodPoi는 일반 Poi객체와는 다르게 이동/회전에 대한 인터페이스가 존재하지 않는다.
/////
///// 사용자가 직접 객체를 생성할 수 없으며, LabelManager를 통해 객체를 간접적으로 생성할 수 있다.
//@objc open class LodLabelLayer : NSObject {
//
//    /// LodLabelLayer의 visible 상태.
//    ///
//    /// layer의 on/off 상태를 나타내며, layer에 속한 객체의 show/hide는 별도로 동작시켜야한다.
//    ///
//    /// 즉, layer의 visible이 true여도 layer에 속한 객체의 show를 호출해야 보이고, visible이 false라면 layer에 속한 객체는 화면에 표시되지 않는다.
//    @objc public var visible: Bool
//
//    /// 현재 Layer에 있는 모든 item을 일괄적으로 지운다.
//    @objc public func clearAllItems()
//
//    /// 현재 Layer에 있는  Exit Transition 속성을 가진 LodPoi를 지운다.
//    @objc public func clearAllExitTransitionLodPois()
//
//    /// 현재 레이어의 clickable 속성을 지정한다.
//    ///
//    /// - parameter clickable: 클릭 설정 여부. 해당 레이어에 속한 모든 Poi에 적용된다.
//    @objc public func setClickable(_ clickable: Bool)
//
//    /// 현재 Layer에 LodPoi를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 nil을 리턴한다.
//    ///
//    /// - parameters:
//    ///     - option: 생성할 LodPoi의 옵션
//    ///     - at: 생성할 LodPoi의 위치
//    ///     - callback: LodPoi 생성이 완료되고나면 호출할 callback(optional)
//    /// - returns: 생성된 LodPoi 객체
//    @objc public func addLodPoi(option: KakaoMapsSDK.PoiOptions, at position: KakaoMapsSDK.MapPoint, callback: ((KakaoMapsSDK.LodPoi?) -> Void)? = nil) -> KakaoMapsSDK.LodPoi?
//
//    /// 현재 Layer에 같은 옵션을 가지는 다수의 LodPoi를 추가한다.
//    ///
//    /// 같은 옵션을 가지지만 위치만 다른 LodPoi를 생성할 경우 사용한다.
//    ///
//    /// 다수 생성을 위해 PoiOptions의 poiID는 무시되고 자동 생성된다.
//    ///
//    /// - parameters:
//    ///     - option: 생성할 LodPoi의 옵션
//    ///     - at: 생성할 LodPoi의 위치 배열
//    ///     - callback: LodPoi 생성이 모두 완료되고나면 호출할 callback (optional)
//    /// - returns: 생성된 LodPoi 객체
//    @objc public func addLodPois(option: KakaoMapsSDK.PoiOptions, at positions: [KakaoMapsSDK.MapPoint], callback: (([KakaoMapsSDK.LodPoi]?) -> Void)? = nil) -> [KakaoMapsSDK.LodPoi]?
//
//    /// 현재 Layer에 다른 옵션을 가지는 다수의 LodPoi를 추가한다.
//    ///
//    /// LodPoi별로 다른 옵션을 가지는 경우 사용한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할경우 기존 객체를 리턴한다.
//    ///
//    /// - Warning: 여러개의 옵션으로 여러개의 poi를 생성하는 경우, option과 position의 pair가 일치해야한다. 즉, position하나당 option 하나의 짝을 맞추어야 한다.
//    /// - parameters:
//    ///     - options: 생성할 LodPoi의 옵션 배열
//    ///     - at: 생성할 LodPoi 위치
//    ///     - callback: LodPoi 생성이 모두 완료되고나면 호출할 callback (optional)
//    /// - returns: 생성된 LodPoi 객체배열
//    @objc public func addLodPois(options: [KakaoMapsSDK.PoiOptions], at positions: [KakaoMapsSDK.MapPoint], callback: (([KakaoMapsSDK.LodPoi]?) -> Void)? = nil) -> [KakaoMapsSDK.LodPoi]?
//
//    /// 현재 Layer에서 특정  LodPoi를 지운다.
//    ///
//    /// - parameters:
//    ///     - poiID: LodLabelLayer에서 제거할 LodPoi Id
//    ///     - callback: 해당 LodPoi 제거가 완료되면 호출할 callback(optional)
//    @objc public func removeLodPoi(poiID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에서 여러개의 LodPoi를 지운다.
//    ///
//    /// - parameters:
//    ///     - poiIDs: LodLabelLayer에서 제거할 LodPoi Id 배열
//    ///     - callback: 해당 LodPoi 제거가 모두 완료되면 호출할 callback(optional)
//    @objc public func removeLodPois(poiIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속해있는 LodPoi를 모두 보여준다.
//    @objc public func showAllLodPois()
//
//    /// 현재 Layer에 속해있는 모든 LodPoi를 숨긴다.
//    @objc public func hideAllLodPois()
//
//    /// 현재 Layer에 속한 특정 LodPoi를 보여준다.
//    ///
//    /// - parameter poiIDs: 보여줄 LodPoi ID 배열
//    @objc public func showLodPois(poiIDs: [String])
//
//    /// 현재 Layer에 속한 특정 LodPoi를 숨긴다.
//    ///
//    /// - parameter poiIDs: 숨길 LodPoi ID 배열
//    @objc public func hideLodPois(poiIDs: [String])
//
//    /// 현재 Layer에 속한 LodPoi를 가져온다.
//    ///
//    /// - parameter poiID: 가져올 LodPoi ID
//    /// - returns: ID에 해당하는 LodPoi 객체, 없을경우 ni.
//    @objc public func getLodPoi(poiID: String) -> KakaoMapsSDK.LodPoi?
//
//    /// 현재 Layer에 속한 여러개의 LodPoi를 가져온다.
//    ///
//    /// - parameter poiIDs: 가져올 LodPoi ID 배열
//    /// - returns: ID에 해당하는 LodPoi 객체 배열, 없을경우 ni.
//    @objc public func getLodPois(poiIDs: [String]) -> [KakaoMapsSDK.LodPoi]?
//
//    /// 현재 Layer에 속한 모든 LodPoi를 가져온다.
//    /// - returns: 현재 Layer에 속한 모든 LodPod.
//    @objc public func getAllLodPois() -> [KakaoMapsSDK.LodPoi]?
//
//    /// layer의 ID
//    @objc public var layerID: String { get }
//
//    /// layer에 속한 Poi가 경쟁하는 방법을 지정한다.
//    ///
//    /// Layer의 우선순위(zOrder)에 따라 Poi끼리 겹쳐졌을 때, Poi가 표시될 정책을 지정한다.
//    ///
//    /// - SeeAlso: CompetitionType
//    @objc public var competitionType: CompetitionType { get }
//
//    /// Poi가 경쟁할 때, 경쟁을 하는 단위를 선택한다.
//    ///
//    /// - SeeAlso: CompetitionUnit
//    @objc public var competitionUnit: CompetitionUnit { get }
//
//    /// competitionType이 same일 경우, 경쟁을 하는 기준이 된다.
//    ///
//    /// - SeeAlso: OrderingType
//    @objc public var orderType: OrderingType { get }
//
//    /// layer의 렌더링 우선순위
//    ///
//    /// zOrder는 같은 LabelLayer타입끼리만 유효하며, 기본적으로 zOrder 값이 클수록 더 높은 우선권을 가진다.
//    @objc public var zOrder: Int
//}
//
///// LodLabelLayer 생성 옵션
//@objc open class LodLabelLayerOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - layerID: layer ID
//    ///     - competitionType: 다른 poi와 경쟁하는 방법
//    ///     - competitionUnit: 경쟁을 하는 단위
//    ///     - orderType:competitionType이 same일 때, 경쟁하는 기준
//    ///     - zOrder: layer의 zOrder. 값이 클수록 위에 그려진다.
//    ///     - radius: LOD를 계산할 때 사용하는 반경 원의 반지름
//    @objc public init(layerID: String, competitionType: CompetitionType, competitionUnit: CompetitionUnit, orderType: OrderingType, zOrder: Int, radius: Float)
//
//    /// layerID
//    @objc public var layerID: String
//
//    /// 다른 poi와 경쟁하는 방법을 지정한다. 해당 레이어에 속한 poi는 모두 해당 방법으로 경쟁한다.
//    @objc public var competitionType: CompetitionType
//
//    /// 경쟁할 때 단위를 지정한다. 해당 레이어에 속한 poi는 모두 해당 방법으로 경쟁한다.
//    @objc public var competitionUnit: CompetitionUnit
//
//    /// competitionType이 same일 때 경쟁하는 기준을 설정한다.
//    @objc public var orderType: OrderingType
//
//    /// layer의 zOrder
//    ///
//    /// zOrder는 같은 LodLabelLayer타입끼리만 유효하며, zOrder 값이 클수록 더 위에 그려진다
//    ///
//    /// 즉, zOrder가 0인 LodLabelLayer는에 속한 Label은 zOrder가 1인 LodLabelLayer에 속한 Label보다 아래에 그려진다.
//    @objc public var zOrder: Int
//
//    /// Lod 처리시 계산하는 반경
//    @objc public var radius: Float
//}
//
///// 지도상에 대량의 Poi를 그리기 위한 클래스
/////
///// Lod 처리를 통해 성능저하를 줄이면서 대량의 Poi를 표시하고자 할 때 사용한다.
/////
///// LodPoi를 추가하기 위해서는 먼저 KakaoMap에 LodLabelLayer를 추가한 뒤, 해당 Layer에 LodPoi를 추가할 수 있다.
/////
///// show, hide, style 변경이 가능하며, Poi마다 개별 badge를 추가할 수 있다.
/////
///// 레벨별로 충돌검사를 하는 LOD 처리가 들어가므로, 이동 및 회전에 대한 interface는 존재하지 않는다.
/////
///// LodPoi는 사용자가 직접 생성할 수 없으며, PoiOptions class를 이용하여 LodLabelLayer에 추가하면 해당 Object를 얻을 수 있다.
//@objc open class LodPoi : NSObject, KakaoMapsSDK.Label {
//
//    /// LodPoi를 보여준다.
//    public func show()
//
//    /// LodPoi를 표시하고, 해당 위치로 이동한다.
//    ///
//    /// - parameter callback: LodPoi위치로 카메라 이동이 끝났을 때, 호출할 callback ( optional)
//    @objc public func showWithAutoMove(callback: (() -> Void)? = nil)
//
//    /// LodPoi를 숨긴다.
//    public func hide()
//
//    /// LodPoi의 Style을 바꾼다.
//    ///
//    /// LabelManager에 등록한 PoiStyle의 키를 이용하여 Style을 변경한다.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 Style의 ID
//    ///     - enableTransition: 변경시 trasition 효과 적용 여부
//    public func changeStyle(styleID: String, enableTransition: Bool = false)
//
//    /// LodPoi의 text와 style을 변경한다.
//    ///
//    /// LodPoi의 text와 style을 바꿀 때 사용한다.
//    ///
//    /// - parameters:
//    ///     - texts: 바꾸고자 하는 LodPoi의 text
//    ///     - styleID: 변경할 styleID.
//    ///     - enableTransition: Style 변경시 trasition 효과 적용 여부
//    @objc public func changeTextAndStyle(texts: [KakaoMapsSDK.PoiText], styleID: String, enableTransition: Bool = false)
//
//    /// 개별 Poi에 Badge를 추가한다.
//    ///
//    /// 같은 id의 badge가 이미 있는 경우 추가되거나 override 되지 않는다.
//    ///
//    /// - SeeAlso: PoiBadge
//    /// - parameter badge: 추가할 Poi Badge
//    @objc public func addBadge(_ badge: KakaoMapsSDK.PoiBadge)
//
//    /// 개별 Poi에 여러개의 Badge를 추가한다.
//    ///
//    /// 같은 id의 badge가 이미 있는 경우 추가되거나 override 되지 않는다.
//    ///
//    /// - SeeAlso: PoiBadge
//    /// - parameter badges: 추가할 Poi Badge 배열
//    @objc public func addBadges(_ badges: [KakaoMapsSDK.PoiBadge])
//
//    /// Poi에 추가된 뱃지를 지운다.
//    ///
//    /// Poi에 등록된 Badge ID를 이용하여 지운다.
//    ///
//    /// - Note: PoiStyle에 추가되어있는 In-Style Badge는 스타일에 종속되므로, 해당 함수로 지울 수 없다.
//    /// - parameter badgeID: 지우고자하는 badge의 ID
//    @objc public func removeBadge(badgeID: String)
//
//    /// Poi에 등록된 Badge를 일괄 지운다.
//    ///
//    /// - Note: PoiStyle에 추가되어있는 In-Style Badge는 스타일에 종속되므로, 해당 함수를 호출해도 지워지지 않는다.
//    @objc public func removeAllBadge()
//
//    /// Poi에 등록되어있는 Badge를 보여준다.
//    ///
//    /// - parameter badgeID: 보여주고자 하는 badge의 ID
//    @objc public func showBadge(badgeID: String)
//
//    /// Poi에 등록되어있는 Badge들을 보여준다.
//    ///
//    /// - parameter badgeIDs: 보여주고자 하는 badge의 ID 배열
//    @objc public func showBadges(badgeIDs: [String])
//
//    /// Poi에 등록되어있는 Badge를 숨긴다.
//    ///
//    /// - parameter badgeID: 숨기고자 하는 badge의 ID
//    @objc public func hideBadge(badgeID: String)
//
//    /// Poi에 등록되어있는 Badge들을 숨긴다.
//    ///
//    /// - parameter badgeIDs: 숨기고자 하는 badge의 ID 배열
//    @objc public func hideBadges(badgeIDs: [String])
//
//    /// Poi의 In-Style badge를 보여준다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 badge를 보여준다.
//    ///
//    /// - parameter badgeID: 보여주고자 하는 In-Style badge의 ID
//    @objc public func showStyleBadge(badgeID: String)
//
//    /// Poi의 In-Style badge를 모두 보여준다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 모든 badge를 보여준다.
//    @objc public func showAllStyleBadges()
//
//    /// Poi의 In-Style badge를 숨긴다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 badge를 숨긴다.
//    ///
//    /// - parameter badgeID: 숨기고자 하는 In-Style badge의 ID
//    @objc public func hideStyleBadge(badgeID: String)
//
//    /// Poi의 In-Style badge를 모두 숨긴다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 모든 badge를 숨긴다.
//    @objc public func hideAllStyleBadges()
//
//    /// Poi 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameters:
//    ///     - target: 이벤트를 수신할 target Object
//    ///     - handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러
//    open func addPoiTappedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.PoiInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Poi가 속한 LayerID
//    public var layerID: String { get }
//
//    /// Poi의 ID
//    public var itemID: String { get }
//
//    /// LodPoi의 렌더링 우선순위
//    ///
//    /// 새로운 rank로 값을 assign 하면, 해당 LodPoi의 rank가 업데이트된다.
//    @objc public var rank: Int
//
//    /// LodPoi의 Clickable 여부
//    ///
//    /// clickable 여부를 새로 assign하면, LodPoi의 click여부가 업데이트된다.
//    @objc public var clickable: Bool
//
//    /// LodPoi가 현재 뷰에 보여지고 있는지 여부
//    public var isShow: Bool { get }
//
//    /// 사용자 객체
//    public var userObject: AnyObject?
//}
//
///// 좌표계 및 좌표계 변환을 담당하는 클래스
///// 지원하는 좌표계 : WTM(5181), WCONG, WGS84(4326), Kakao(3857)
//@objc open class MapCoordConverter : NSObject {
//
//    /// WCong 좌표를 WGS84 좌표로 변환한다.
//    /// - parameter wcong : 변환할 WCong 좌표를 나타내는 평면좌표 값
//    /// - returns : WGS84 경위도 좌표
//    @objc public static func fromWCongToWGS84(wcong: CartesianCoordinate) -> GeoCoordinate
//
//    /// WCong 좌표를 Kakao 좌표로 변환한다.
//    /// - parameter wcong : 변환할 wcong 좌표를 나타내는 평면좌표 값
//    /// - returns : Kakao  좌표
//    @objc public static func fromWCongToKakao(wcong: CartesianCoordinate) -> CartesianCoordinate
//
//    /// WCong 좌표를 WTM 좌표로 변환한다.
//    /// - parameter wcong : 변환할 wcong 좌표를 나타내는 평면좌표 값
//    /// - returns : WTM  좌표
//    @objc public static func fromWCongToWTM(wcong: CartesianCoordinate) -> CartesianCoordinate
//
//    /// WTM 좌표를 WCong 좌표로 변환한다.
//    /// - parameter wtm : 변환할 WTM 좌표를 나타내는 평면좌표 값
//    /// - returns : WCong  좌표
//    @objc public static func fromWTMToWCong(wtm: CartesianCoordinate) -> CartesianCoordinate
//
//    /// WTM 좌표를 WGS84 좌표로 변환한다.
//    /// - parameter wtm : 변환할 WTM 좌표를 나타내는 평면좌표 값
//    /// - returns : WGS84 경위도  좌표
//    @objc public static func fromWTMToWGS84(wtm: CartesianCoordinate) -> GeoCoordinate
//
//    /// WTM 좌표를 Kakao 좌표로 변환한다.
//    /// - parameter wtm : 변환할 WTM 좌표를 나타내는 평면좌표 값
//    /// - returns : Kakao  좌표
//    @objc public static func fromWTMToKakao(wtm: CartesianCoordinate) -> CartesianCoordinate
//
//    /// WGS84 좌표를 WCong 좌표로 변환한다.
//    /// - parameter wgs : 변환할 WGS84 좌표를 나타내는 경위도좌표 값
//    /// - returns : WCong  좌표
//    @objc public static func fromWGS84ToWCong(wgs: GeoCoordinate) -> CartesianCoordinate
//
//    /// WGS84 좌표를 WTM 좌표로 변환한다.
//    /// - parameter wgs : 변환할 WGS84 좌표를 나타내는 경위도좌표 값
//    /// - returns : WTM  좌표
//    @objc public static func fromWGS84ToWTM(wgs: GeoCoordinate) -> CartesianCoordinate
//
//    /// WGS84 좌표를 Kakao 좌표로 변환한다.
//    /// - parameter wgs : 변환할 WGS84 좌표를 나타내는 경위도좌표 값
//    /// - returns : Kakao  좌표
//    @objc public static func fromWGS84ToKakao(wgs: GeoCoordinate) -> CartesianCoordinate
//
//    /// Kakao 좌표를 WGS84 좌표로 변환한다.
//    /// - parameter kakao : 변환할 Kakao 좌표를 나타내는 평면좌표 값
//    /// - returns : WGS84  좌표
//    @objc public static func fromKakaoToWGS84(kakao: CartesianCoordinate) -> GeoCoordinate
//
//    /// Kakao 좌표를 WTM 좌표로 변환한다.
//    /// - parameter kakao : 변환할 Kakao 좌표를 나타내는 평면좌표 값
//    /// - returns : WTM  좌표
//    @objc public static func fromKakaoToWTM(kakao: CartesianCoordinate) -> CartesianCoordinate
//
//    /// Kakao 좌표를 WCong 좌표로 변환한다.
//    /// - parameter kakao : 변환할 Kakao 좌표를 나타내는 평면좌표 값
//    /// - returns : WCong  좌표
//    @objc public static func fromKakaoToWCong(kakao: CartesianCoordinate) -> CartesianCoordinate
//}
//
///// 지도상의 위치를 나타내기 위한 클래스. WGS84(4326) 좌표계를 지원한다.
//@objc open class MapPoint : NSObject {
//
//    /// Initializer
//    /// 
//    /// WGS84 경위도좌표계 좌표값으로 MapPoint를 생성한다.
//    ///
//    /// - parameter longitude: 경도값
//    /// - parameter latitude: 위도값
//    @objc public convenience init(longitude: Double, latitude: Double)
//
//    /// Initializer
//    ///
//    /// 다른 MapPoint 객체로부터 복사한 값으로 새로운 MapPoint 객체를 생성한다.
//    ///
//    /// - parameter from: 값을 가져올 MapPoint
//    @objc public convenience init(from: KakaoMapsSDK.MapPoint)
//
//    /// WGS84 좌표값
//    @objc public var wgsCoord: GeoCoordinate { get }
//}
//
///// MapPolygonShape를 구성할 때 사용하는 MapPolygon 클래스.
/////
///// 폴리곤은 단독으로 Map에 추가할 수 없으며, Shape에 종속되는 객체이다.
/////
///// 하나의 외곽선과 hole을 넣어서 구성할 수 있다. 외곽선 point인 exterior ring과 폴리곤 내부 홀을 표시하는 holes로 구성된다.
/////
///// exteriorRing, 즉 외곽선은 시계방향으로 MapPoint를 넣어야 하고, hole은 시계반대방향으로 MapPoint를 넣어야한다.
/////
///// MapPolygon의 Point는 지도좌표계(ex. 3857)타입의 MapPoint로만 구성한다.
//@objc open class MapPolygon : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - exteriorRing: MapPolygon의 외곽선
//    ///     - holes: MapPolygon의 hole 배열. hole이 없을경우 nil로 지정
//    ///     - styleIndex: PolygonStyleSet에서 사용할 PolygonStyle 인덱스
//    @objc required public init(exteriorRing: [KakaoMapsSDK.MapPoint], holes: [[KakaoMapsSDK.MapPoint]]? = nil, styleIndex: UInt)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - exteriorRing: Polygon의 외곽선
//    ///     - hole: Polygon의 하나의 hole. hole이 없을경우 nil로 지정
//    ///     - styleIndex: PolygonStyleSet에서 사용할 PolygonStyle 인덱스
//    @objc public convenience init(exteriorRing: [KakaoMapsSDK.MapPoint], hole: [KakaoMapsSDK.MapPoint]? = nil, styleIndex: UInt)
//
//    /// Polygon의 외곽선.
//    ///
//    /// 시계방향의 MapPoint 배열로 구성한다.
//    @objc public var exteriorRing: [KakaoMapsSDK.MapPoint] { get }
//
//    /// MapPolygon의 holes
//    ///
//    /// 0개 이상으로 구성되며, 반시계방향의 MapPoint 배열로 구성한다.
//    @objc public var holes: [[KakaoMapsSDK.MapPoint]]? { get }
//
//    /// PolygonStyleSet에서 사용할 표출 스타일 인덱스를 지정한다.
//    @objc public var styleIndex: UInt { get }
//}
//
///// 지도상에 특정 영역을 2d Polygon으로 표시하는 MapPolygonShape 클래스.
/////
///// 지도 위 특정 위치에 의미있는 면형을 표시하기 위해 사용된다.
/////
///// 따라서 PolygonShape와는 다르게, basePosition 없이  좌표계( ex. 3857 )로 구성되어있는 정점으로만 구성한다.
/////
///// MapPolygonShape를 추가하기 위해서는 먼저 KakaoMap에 ShapeLayer를 추가한 뒤, 해당 Layer에 MapPolygonShape를 추가할 수 있다.
/////
///// show, hide, style변경 및 이동/회전이 가능하다.
/////
///// MapPolygonShape는 사용자가 직접 생성할 수 없으며, MapPolygonShapeOptions class를 이용하여 Layer에 추가하면 해당 object를 얻을 수 있다.
//@objc open class MapPolygonShape : NSObject, KakaoMapsSDK.Shape {
//
//    /// MapPolygonShape를 보여준다.
//    public func show()
//
//    /// MapPolygonShape를 숨긴다.
//    public func hide()
//
//    /// MapPolygonShape의 style과 Data를 변경한다.
//    ///
//    /// MapPolygonShape의 Style과 MapPolygonShape가 표시하는 polgyon Data를 변경하고자 할 때 사용한다. 단, polygon Data를 바꿀때는 해당 MapPolygonShape 객체가 가리키는 본질이 변하지 않을때만 사용한다. 즉 전혀 다른 MapPolygonShape 객체일때는 MapPolygonShape를 하나 더 만드는것을 권장한다.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 styleID
//    ///     - polygons: 업데이트 할 폴리곤 데이터.
//    @objc public func changeStyleAndData(styleID: String, polygons: [KakaoMapsSDK.MapPolygon])
//
//    /// shape가 속한 layerID
//    public var layerID: String? { get }
//
//    /// ShapeID.
//    public var shapeID: String { get }
//
//    /// PolygonShape의 현재 orientation값
//    ///
//    /// 새로운 orientation값으로 assign할 경우, PolygonShape의 orientation이 변경된다.
//    public var orientation: Double
//
//    /// PolygonShape가 현재 지도에 표시되는지 여부
//    public var isShow: Bool { get }
//
//    /// 사용자 객체
//    public var userObject: AnyObject?
//}
//
///// MapPolygonShape생성 옵션 클래스.
/////
///// MapPolygonShape는 지도상의 특정 위치에 의미있는 면형을 표시하기 위해 사용한다.
/////
///// PolygonShape와는 다르게, basePosition없이 지도 좌표계로 구성되어있는 점으로만 폴리곤을 구성한다.
/////
///// MapPolygonShape는 1개 이상의 MapPolygon으로 구성된다. MapPolygon은 지도 좌표계(ex. 3857)로 구성할 수 있다.
/////
///// StyleSetPolygonShape에 속한 Polygon마다 StyleSet을 이용하여 다르게 표출할 수도 있다.
//@objc open class MapPolygonShapeOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 값이 클수록 위에 그려진다.
//    @objc public init(styleID: String, zOrder: Int)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - shapeID: Shape의 ID
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 값이 클수록 위에 그려진다.
//    @objc public init(shapeID: String, styleID: String, zOrder: Int)
//
//    /// Shape의 ID
//    @objc public var shapeID: String? { get }
//
//    /// Shape가 표출될 StyleID
//    @objc public var styleID: String { get }
//
//    /// Shape의 렌더링 우선순위
//    ///
//    /// 높을수록 더 위에 그려지며, Shape type끼리만 유효하다.
//    ///
//    /// 즉, zOrder = 0 인 Shape는 zOrder = 1 인 shape보다 아래에 그려진다.
//    @objc public var zOrder: Int { get }
//
//    /// Shape에 속한 폴리곤.
//    ///
//    /// 1개 이상의 폴리곤으로 구성된다.
//    ///
//    /// - SeeAlso: MapPolygon
//    @objc public var polygons: [KakaoMapsSDK.MapPolygon]
//}
//
///// MapPolylineShape를 구성할 때 사용하는 Polyline 클래스
/////
///// 폴리라인은 단독으로 Map에 추가할 수 없으며, Shape에 종속되는 객체이다.
/////
///// 2개 이상의 MapPoint로 만들어진 라인으로 구성된다. 폴리라인의 캡 스타일도 지정할 수 있다.
//@objc open class MapPolyline : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - line: MapPolyline을 구성하는 MapPoint 배열
//    ///     - styleIndex: MapPolyline에 적용할 PolylineStyleSet에 속한 PolylineStyle의 index
//    @objc required public init(line: [KakaoMapsSDK.MapPoint], styleIndex: UInt)
//
//    /// 라인. 2개 이상의 MapPoint로 구성된다.
//    @objc public var line: [KakaoMapsSDK.MapPoint] { get }
//
//    /// ShapeStyleSet에서 사용할 표출 인덱스
//    @objc public var styleIndex: UInt { get }
//}
//
///// 지도상에 특정 선형을 2d Polyline으로 표시하는  PolylineShape 클래스.
/////
///// 지도 위 특정 위치에 의미있는 선형을 표시하기 위해 사용된다.
/////
///// 따라서 PolylineShape와는 다르게, basePosition 없이  좌표계( ex. 3857 )로 구성되어있는 정점으로만 구성한다.
/////
///// MapPolylineShape를 추가하기 위해서는 먼저 KakaoMap에 ShapeLayer를 추가한 뒤, 해당 Layer에 MapPolylineShape를 추가할 수 있다.
/////
///// show, hide, style변경 및 이동/회전이 가능하다.
/////
///// MapPolylineShape는 사용자가 직접 생성할 수 없으며, MapPolylineShapeOptions class를 이용하여 Layer에 추가하면 해당 Object를 얻을 수 있다.
//@objc open class MapPolylineShape : NSObject, KakaoMapsSDK.Shape {
//
//    /// MapPolylineShape를 보여준다.
//    public func show()
//
//    /// MapPolylineShape를 숨긴다.
//    public func hide()
//
//    /// MapPolylineShape의 style과 Data를 변경한다.
//    ///
//    /// MapPolylineShape의 style과 표시하는 MapPolyline Data를 변경하고자 할 때 사용한다.
//    ///
//    /// 단, MapPolyline Data를 바꿀때는 해당 MapPolylineShape 객체가 가리키는 본질이 변하지 않을때만 사용한다.
//    ///
//    /// 즉 전혀 다른 MapPolylineShape 객체일때는 MapPolylineShape를 하나 더 만드는것을 권장한다.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 styleID
//    ///     - lines: 업데이트 할 폴리라인 데이터.
//    @objc public func changeStyleAndData(styleID: String, lines: [KakaoMapsSDK.MapPolyline])
//
//    /// Shape가 속한 layerID
//    public var layerID: String? { get }
//
//    /// Shape의 ID
//    public var shapeID: String { get }
//
//    /// MapPolylineShape의 Orientation (radian)
//    ///
//    /// 새로운 orientation값을 assign하면, PolylineShape의 orientation 값이 업데이트된다.
//    public var orientation: Double
//
//    /// MapPolylineShape가 현재 지도에 표시되는지 여부
//    public var isShow: Bool { get }
//
//    /// 사용자 객체
//    public var userObject: AnyObject?
//}
//
///// MapPolylineShape 생성 옵션 클래스.
/////
///// MapPolylineShape는 지도상의 특정 위치에 의미있는 선형을 표시하기 위해 사용한다.
/////
///// PolylineShape와는 다르게, basePosition 없이 지도 좌표계로 구성되어있는 점으로만 폴리라인을 구성한다.
/////
///// MapPolylineShape는 1개 이상의 MapPolyline으로 구성된다. MapPolyline은 지도 좌표계(ex. 3857)로 구성할 수 있다.
/////
///// Style은 PolylineShape에 속한 Polyline마다 StyleSet을 이용하여 다르게 적용할 수 있다.
/////
///// PolylineShape의 id를 별도로 지정하지 않는 경우, 내부적으로 자동으로 부여한다.
//@objc open class MapPolylineShapeOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 값이 높을수록 위에 그려진다.
//    @objc public init(styleID: String, zOrder: Int)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - shapeID: Shape의 ID
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 값이 높을수록 위에 그려진다.
//    @objc required public init(shapeID: String, styleID: String, zOrder: Int)
//
//    /// Shape의 ID
//    @objc public var shapeID: String? { get }
//
//    /// Shape가 표출될 StyleID
//    @objc public var styleID: String { get }
//
//    /// Shape의 렌더링 우선순위
//    ///
//    /// 높을수록 더 위에 그려지며, Shape type끼리만 유효하다.
//    ///
//    /// 즉, zOrder = 0 인 Shape는 zOrder = 1 인 shape보다 아래에 그려진다.
//    @objc public var zOrder: Int { get }
//
//    /// Shape에 속한 MapPolyline 배열
//    ///
//    /// 1개 이상의 폴리라인으로 구성된다.
//    ///
//    /// - SeeAlso: MapPolyline
//    @objc public var polylines: [KakaoMapsSDK.MapPolyline]
//}
//
///// 지도 ViewInfo. KakaoMap으로 view가 생성된다.
//@objc public class MapviewInfo : KakaoMapsSDK.ViewInfo {
//
//    /// 초기 위치
//    @objc public var defaultPosition: KakaoMapsSDK.MapPoint { get }
//
//    /// 초기 레벨
//    @objc public var defaultLevel: Int { get }
//}
//
//extension MapviewInfo {
//
//    /// Initializer
//    ///
//    /// - parameter viewName: view의 이름
//    /// - parameter appName: Cocoa에 등록된 app 이름. 따로 등록된 내용이 없을 경우 "openmap" 사용.
//    /// - parameter viewInfo: viewInfo의 이름. 
//    /// - parameter defaultPosition: 초기 위치(MapView인 경우). 기본값은 서울시청.
//    /// - parameter defaultLevel: 초기 레벨(MapView인 경우). 기본값은 17.
//    /// - parameter enabled: 초기 활성화 여부. 기본값은 true.
//    @objc dynamic public convenience init(viewName: String, appName: String = "openmap", viewInfoName: String = "map", defaultPosition: KakaoMapsSDK.MapPoint?, defaultLevel: Int = 17, enabled: Bool = true)
//}
//
///// PanoramaView에 표시할 Marker 클래스.
//@objc open class PanoramaMarker : NSObject {
//
//    /// Initializer
//    /// position 타입의 PanoramaMarker를 생성.
//    /// - parameters:
//    ///     - position: marker가 표시될 MapPoint.
//    public init(position: KakaoMapsSDK.MapPoint)
//
//    /// Initializer
//    /// direction 타입의 PanoramaMarker를 생성.
//    /// - parameters:
//    ///     - pan: PanoramaMarker가 표시될 pan값. 정북기준 시계방향. 단위 radian.
//    ///     - tilt: PanoramaMarker가 표시될 tilt값. 0이 수평. 양수값이 지면방향. 단위 radian.
//    public init(pan: Double, tilt: Double)
//
//    /// PanoramaMarker의 타입
//    ///
//    /// - SeeAlso: PanoramaMarkerType
//    @objc open var markerType: PanoramaMarkerType { get }
//
//    /// PanoramaMarker가 표시될 방향의 pan 값
//    @objc open var pan: Double { get }
//
//    /// PanoramaMarker가 표시될 방향의 tilt 값
//    @objc open var tilt: Double { get }
//
//    /// PanoramaMarker가 표시될 위치
//    @objc open var position: KakaoMapsSDK.MapPoint? { get }
//
//    /// 마커 심볼 이미지
//    @objc open var symbol: UIImage?
//}
//
///// 특정레벨에 적용될 라벨스타일을 지정하는 클래스.
/////
///// PoiStyle을 하나 이상의 PerLevelPoiStyle로 구성할 수 있다.
/////
///// PerLevelPoiStyle에 지정된 레벨에서부터 하위의 PerLevelStyle이 지정된 레벨이 되기전까지 적용된다.
//@objc public class PerLevelPoiStyle : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - iconStyle: Poi의 IconStyle.
//    ///     - padding: padding
//    ///     - level: 해당 Style이 표출되기 시작할 레벨. 특정 레벨에서 해당 표출 레벨의 iconStyle, 혹은 textStyle이 추가되지 않은 경우, Poi 심볼이나 텍스트가 표시되지 않는다.
//    @objc public init(iconStyle: KakaoMapsSDK.PoiIconStyle, padding: Float = 0.0, level: Int = 0)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - textStyle: Poi의 TextStyle
//    ///     - padding: padding
//    ///     - level: 해당 Style이 표출되기 시작할 레벨. 특정 레벨에서 해당 표출 레벨의 iconStyle, 혹은 textStyle이 추가되지 않은 경우, Poi 심볼이나 텍스트가 표시되지 않는다.
//    @objc public init(textStyle: KakaoMapsSDK.PoiTextStyle, padding: Float = 0.0, level: Int = 0)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - iconStyle: Poi의 IconStyle.
//    ///     - textStyle: Poi의 TextStyle
//    ///     - padding: padding
//    ///     - level: 해당 Style이 표출되기 시작할 레벨. 특정 레벨에서 해당 표출 레벨의 iconStyle, 혹은 textStyle이 추가되지 않은 경우, Poi 심볼이나 텍스트가 표시되지 않는다.
//    @objc public init(iconStyle: KakaoMapsSDK.PoiIconStyle, textStyle: KakaoMapsSDK.PoiTextStyle, padding: Float = 0.0, level: Int = 0)
//
//    /// Poi의 IconStyle
//    ///
//    /// - SeeAlso: PoiIconStyle
//    @objc public var iconStyle: KakaoMapsSDK.PoiIconStyle? { get }
//
//    /// Poi의 TextStyle
//    ///
//    /// - SeeAlso: PoiTextStyle
//    @objc public var textStyle: KakaoMapsSDK.PoiTextStyle? { get }
//
//    /// padding
//    @objc public var padding: Float { get }
//
//    /// Style이 표출되기 시작할 레벨
//    @objc public var level: Int { get }
//}
//
///// PolygonStyle Unit 클래스.
/////
///// Level별 PolygonStyle을 구성할 때 사용한다.
//@objc open class PerLevelPolygonStyle : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - color: PolygonShape의 색깔
//    ///     - storkeWidth: PolygonShape의 외곽선 두께
//    ///     - storkeColor: PolygonShape의 외곽선 색깔
//    ///     - level: 해당 단위 스타일이 표출 될 레벨
//    @objc public init(color: UIColor, strokeWidth: UInt, strokeColor: UIColor, level: Int)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - color: PolygonShape의 색깔
//    ///     - level: 해당 단위 스타일이 표출 될 레벨
//    @objc public convenience init(color: UIColor, level: Int)
//
//    /// Shape의 색깔.
//    @objc public var color: UIColor { get }
//
//    /// Shape의 외곽선 두께. 지정하지 않을 경우 0
//    @objc public var strokeWidth: UInt { get }
//
//    /// Shape의 외곽선 색깔. 지정하지 않을 경우 투명.
//    @objc public var strokeColor: UIColor { get }
//
//    /// 해당 스타일이 표출될 레벨 . 
//    @objc public var level: Int { get }
//}
//
///// PerLevelPolylineStyle의 단위 클래스
/////
///// level별 PolylineStyle을 구성할 때 사용한다.
//@objc open class PerLevelPolylineStyle : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - bodyColor: Polyline의 body 색상
//    ///     - bodyWidth: Polyline의 body 두께
//    ///     - strokeColor: Polyline의 외곽선 색깔
//    ///     - storkeWidth: Polyline의 외곽선 두께
//    ///     - level: 해당 단위스타일이 표출될 레벨
//    @objc public init(bodyColor: UIColor, bodyWidth: UInt, strokeColor: UIColor, strokeWidth: UInt, level: Int)
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - bodyColor: Polyline의 body 색상
//    ///     - bodyWidth: Polyline의 body 두께
//    ///     - level: 해당 단위스타일이 표출될 레벨
//    @objc public convenience init(bodyColor: UIColor, bodyWidth: UInt, level: Int)
//
//    /// Polyline의 Body 색깔.
//    @objc public var bodyColor: UIColor { get }
//
//    /// Polyline의 Body 두께
//    @objc public var bodyWidth: UInt { get }
//
//    /// Polyline의 외곽선 색깔
//    @objc public var strokeColor: UIColor { get }
//
//    /// Polyline의 외곽선 두께
//    @objc public var strokeWidth: UInt { get }
//
//    /// 해당 단위 스타일이 표출될 레벨
//    @objc public var level: Int { get }
//}
//
///// PerLevelRouteStyle 단위 클래스.
/////
///// Level별 Route Style을 구성할 때 사용한다.
//@objc open class PerLevelRouteStyle : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - width: Route Width
//    ///     - color: rotue Color
//    ///     - strokeWidth: Route의 외곽선 두께
//    ///     - strokeColor: Route의 외곽선 색깔
//    ///     - level: 해당 단위 스타일이 표출될 레벨
//    ///     - patternIndex: 추가한 패턴의 인덱스
//    @objc public init(width: UInt, color: UIColor, strokeWidth: UInt, strokeColor: UIColor, level: Int, patternIndex: Int = -1)
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - width: Route Width
//    ///     - color: rotue Color
//    ///     - level: 해당 단위 스타일이 표출될 레벨
//    ///     - patternIndex: 추가한 패턴의 인덱스
//    @objc public convenience init(width: UInt, color: UIColor, level: Int, patternIndex: Int = -1)
//
//    /// Route의 두께.
//    @objc public var width: UInt { get }
//
//    /// Route의 색깔
//    @objc public var color: UIColor { get }
//
//    /// Route의 외곽선 두께
//    @objc public var strokeWidth: UInt { get }
//
//    /// Route의 외곽선 색깔
//    @objc public var strokeColor: UIColor { get }
//
//    /// 스타일이 표출될 레벨
//    @objc public var level: Int { get }
//
//    /// 추가한 패턴의 인덱스
//    @objc public var patternIndex: Int { get }
//}
//
///// PerLevelWaveTextStyle을 표시하기 위한 클래스
/////
///// 하나의 WaveTextStyle을 하나 이상의 PerLevelWaveTextStyle로 구성할 수 있다.
/////
///// PerLevelWaveTextStyle에 지정된 레벨에서부터 하위의 PerLevelWaveTextStyle이 지정된 레벨이 되기전까지 적용된다.
//@objc open class PerLevelWaveTextStyle : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - textStyle : WaveText의 TextStyle
//    ///     - level: 해당 스타일이 표시될 레벨
//    @objc required public init(textStyle: KakaoMapsSDK.TextStyle, level: Int)
//
//    /// WaveText의 TextStyle
//    ///
//    /// - SeeAlso: TextStyle
//    @objc public var textStyle: KakaoMapsSDK.TextStyle { get }
//
//    /// Style이 표출될 level
//    ///
//    /// PerLevelWaveTextStyle 단독으로는 사용되지 않으며, WaveTextStyle을 생성할 때 사용된다.
//    ///
//    /// - SeeAlso: WaveTextStyle
//    @objc public var level: Int { get }
//}
//
///// 지도상에 Poi를 그리기 위한 클래스
/////
///// Poi를 추가하기 위해서는 먼저 KakaoMap에 LabelLayer를 추가한 뒤, 해당 Layer에 Poi를 추가할 수 있다.
/////
///// show, hide, style 변경이 가능하며, Poi마다 개별 badge를 추가할 수 있다.
/////
///// 이동, 또는 회전을 하는 애니메이션이 가능하다. 이동 애니메이션중에 다른 애니메이션 동작을 할 경우 기존 이동 애니메이션이 멈춘다. 회전 애니메이션 중에 다른 회전 애니메이션을 할 경우 기존 애니메이션이 멈춘다.
/////
///// Poi는 사용자가 직접 생성할 수 없으며, PoiOptions class를 이용하여 Layer에 추가하면 해당 Object를 얻을 수 있다.
//@objc open class Poi : NSObject, KakaoMapsSDK.Label {
//
//    /// Poi를 보여준다.
//    public func show()
//
//    /// Poi를 표시하고, 해당 위치로 이동한다.
//    ///
//    /// - parameter callback: Poi위치로 카메라 이동이 끝났을 때, 호출할 callback ( optional)
//    @objc public func showWithAutoMove(callback: (() -> Void)? = nil)
//
//    /// Poi를 숨긴다.
//    public func hide()
//
//    /// Poi의 Style을 변경한다.
//    ///
//    /// LabelManager에 등록한 PoiStyle의 키를 이용하여 Style을 변경한다.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 Style의 ID
//    ///     - enableTransition: Style 변경시 trasition 효과 적용 여부
//    public func changeStyle(styleID: String, enableTransition: Bool = false)
//
//    /// Poi의 text와 style을 변경한다.
//    ///
//    /// Poi의 text와 style을 바꿀 때 사용한다.
//    ///
//    /// - parameters:
//    ///     - texts: 바꾸고자 하는 PoiText
//    ///     - styleID: 변경할 styleID.
//    ///     - enableTransition: 변경시 trasition 효과 적용 여부
//    @objc public func changeTextAndStyle(texts: [KakaoMapsSDK.PoiText], styleID: String, enableTransition: Bool = false)
//
//    /// 개별 Poi에 Badge를 추가한다.
//    ///
//    /// 같은 id의 badge가 이미 있는 경우 추가되거나 override 되지 않는다.
//    ///
//    /// - SeeAlso: PoiBadge
//    /// - parameter badge: 추가할 Poi Badge
//    @objc public func addBadge(_ badge: KakaoMapsSDK.PoiBadge)
//
//    /// 개별 Poi에 여러개의 Badge를 추가한다.
//    ///
//    /// 같은 id의 badge가 이미 있는 경우 추가되거나 override 되지 않는다.
//    /// 
//    /// - SeeAlso: PoiBadge
//    /// - parameter badges: 추가할 Poi Badge 배열
//    @objc public func addBadges(_ badges: [KakaoMapsSDK.PoiBadge])
//
//    /// Poi에 추가된 뱃지를 지운다.
//    ///
//    /// Poi에 등록된 Badge ID를 이용하여 지운다.
//    ///
//    /// - Note: PoiStyle에 추가되어있는 In-Style Badge는 스타일에 종속되므로, 해당 함수로 지울 수 없다.
//    /// - parameter badgeID: 지우고자하는 badge의 ID
//    @objc public func removeBadge(badgeID: String)
//
//    /// Poi에 등록된 Badge를 일괄 지운다.
//    ///
//    /// - Note: PoiStyle에 추가되어있는 In-Style Badge는 스타일에 종속되므로, 해당 함수를 호출해도 지워지지 않는다.
//    @objc public func removeAllBadge()
//
//    /// Poi에 등록되어있는 Badge를 보여준다.
//    ///
//    /// - parameter badgeID: 보여주고자 하는 badge의 ID
//    @objc public func showBadge(badgeID: String)
//
//    /// Poi에 등록되어있는 Badge들을 보여준다.
//    ///
//    /// - parameter badgeIDs: 보여주고자 하는 badge의 ID 배열
//    @objc public func showBadges(badgeIDs: [String])
//
//    /// Poi에 등록되어있는 Badge를 숨긴다.
//    ///
//    /// - parameter badgeID: 숨기고자 하는 badge의 ID
//    @objc public func hideBadge(badgeID: String)
//
//    /// Poi에 등록되어있는 Badge들을 숨긴다.
//    ///
//    /// - parameter badgeIDs: 숨기고자 하는 badge의 ID 배열
//    @objc public func hideBadges(badgeIDs: [String])
//
//    /// Poi의 In-Style badge를 보여준다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 badge를 보여준다.
//    ///
//    /// - parameter badgeID: 보여주고자 하는 In-Style badge의 ID
//    @objc public func showStyleBadge(badgeID: String)
//
//    /// Poi의 In-Style badge를 모두 보여준다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 모든 badge를 보여준다.
//    @objc public func showAllStyleBadges()
//
//    /// Poi의 In-Style badge를 숨긴다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 badge를 숨긴다.
//    ///
//    /// - parameter badgeID: 숨기고자 하는 In-Style badge의 ID
//    @objc public func hideStyleBadge(badgeID: String)
//
//    /// Poi의 In-Style badge를 모두 숨긴다.
//    ///
//    /// LabelManager를 통해 등록된 PoiStyle에 종속되는 모든 badge를 숨긴다.
//    @objc public func hideAllStyleBadges()
//
//    /// Poi를 지정한 위치로 옮긴다
//    ///
//    /// Poi를 지정한 위치로 지정한 시간동안 이동시킨다.
//    ///
//    /// - parameters:
//    ///     - position: 이동시킬 위치
//    ///     - duration: 애니메이션 시간
//    @objc public func moveAt(_ position: KakaoMapsSDK.MapPoint, duration: UInt)
//
//    /// Poi를 지정한 각도로 회전시킨다.
//    ///
//    /// Poi를 지정한 각도로 지정한 시간동안 회전시킨다. 현재 방향을 기준으로 회전하는것이 아니라, 절대회전방위로 이동한다.
//    /// 회전중에 setOrientation()이 호출되면, 멈춘다.
//    ///
//    /// - parameters:
//    ///     - roll: 회전시킬 각도
//    ///     - duration: 애니메이션 시간
//    @objc public func rotateAt(_ roll: Double, duration: UInt)
//
//    /// Poi가 특정지점들을 따라서 움직이게 한다.
//    ///
//    /// Path를 지정해서 Poi가 해당 path를 따라 움직이게 한다. 단, Poi의 각도는 변하지 않고 지정한 Path를 따라 움직이기만 한다.
//    /// 이동중에 setPosition / moveAt이 호출되면 멈춘다.
//    ///
//    /// - parameters:
//    ///     - points: Poi가 따라서 움직일 각도
//    ///     - duration: 애니메이션 시간
//    ///     - cornerRadius: Path중 코너를 통과할 때 부드러운 이동 효과를 주기 위한 곡선으로 처리하는 길이
//    ///     - jumpTreshold: 해당 함수 실행중에 새로운 경로가 들어왔을때 현재위치~새 경로 시작점간에 거리에서 점프를 할지에 대한 임계값.
//    @objc public func moveOnPath(_ points: [KakaoMapsSDK.MapPoint], duration: UInt, cornerRadius: Float, jumpThreshold: Float)
//
//    /// Poi가 특정지점들을 따라서 회전하면서 움직이게 한다.
//    ///
//    /// Path를 지정해서 Poi가 해당 path를 따라 회전하면서 움직이게 한다. path의 각도에 따라 Poi도 같이 회전한다.
//    ///
//    /// - parameters:
//    ///     - points: Poi가 따라서 움직일 path
//    ///     - baseRadian: path가 1개뿐이거나, 진행방향의 역방향으로 path가 들어와 방향을 알 수 없을 때 가이드가 될 radian 값. 
//    ///     - duration: 애니메이션 시간
//    ///     - cornerRadius: Path중 코너를 통과할 때 부드러운 이동 효과를 주기 위한 곡선으로 처리하는 길이
//    ///     - jumpTreshold: 해당 함수 실행중에 새로운 경로가 들어왔을때 현재위치~새 경로 시작점간에 거리에서 점프를 할지에 대한 임계값.
//    @objc public func moveAndRotateOnPath(_ points: [KakaoMapsSDK.MapPoint], baseRadian: Float, duration: UInt, cornerRadius: Float, jumpThreshold: Float)
//
//    /// 현재 Poi의 position을 공유할 Poi를 추가한다/
//    ///
//    /// 파라미터의 Poi가 현재 Poi의 위치만을 따라간다.
//    ///
//    /// - parameter poi: 현재 poi의 position을 공유할 poi
//    @objc public func sharePositionWithPoi(_ poi: KakaoMapsSDK.Poi)
//
//    /// 현재 Poi와 지정된 poi간에 더이상 position을 공유하지 않게한다.
//    ///
//    /// - parameter poi: position공유를 하지 않을 poi
//    @objc public func removeSharePositionWithPoi(_ poi: KakaoMapsSDK.Poi)
//
//    /// 현재 Poi의 transform을 공유할 Poi를 추가한다.
//    ///
//    /// 파라미터의 Poi가 현재 객체 Poi의 transform을 따라간다.
//    ///
//    /// - parameter poi: 현재 poi의 transform을 공유할 poi
//    @objc public func shareTransformWithPoi(_ poi: KakaoMapsSDK.Poi)
//
//    /// 현재 Poi와 지정된 poi간에 더이상 transform을 공유하지 않게한다.
//    ///
//    /// - parameter poi: transform공유를 하지 않을 poi
//    @objc public func removeShareTransformWithPoi(_ poi: KakaoMapsSDK.Poi)
//
//    /// 현재 Poi의 transform을 공유할 Shape를 추가한다.
//    ///
//    /// 파라미터의 Shape가 현재 객체 Poi의 transform을 따라간다.
//    ///
//    /// - parameter shape: 현재 poi의 transform을 공유할 shape
//    @objc public func shareTransformWithShape(_ shape: any KakaoMapsSDK.Shape)
//
//    /// 현재 Poi와 지정된 shape간에 더이상 transform을 공유하지 않게한다.
//    ///
//    /// - parameter shape: transform공유를 하지 않을 shape
//    @objc public func removeShareTransformWithShape(_ shape: any KakaoMapsSDK.Shape)
//
//    /// Poi 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameters:
//    ///     - target: 이벤트를 수신할 target Object
//    ///     - handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러
//    open func addPoiTappedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.PoiInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// Poi가 속한 LayerID
//    public var layerID: String { get }
//
//    /// Poi의 ID
//    public var itemID: String { get }
//
//    /// Poi의 렌더링 우선순위
//    ///
//    /// rank값을 새로 assign하면, Poi의 rank가 업데이트 된다.
//    @objc public var rank: Int
//
//    /// Poi의 clickable 여부. 생성 옵션에서 따로 지정하지 않는 경우, default는 false로 설정된다.
//    ///
//    /// 새로운 값을 assign하여 clickable 여부를 바꿀 수 있다.
//    @objc public var clickable: Bool
//
//    /// Poi의 위치
//    ///
//    /// 새로운 position값으로 assign하면, Poi의 position값이 변경된다.
//    @objc public var position: KakaoMapsSDK.MapPoint
//
//    /// Poi의 Orientation(radian)
//    ///
//    /// 새로운 orientation값으로 assign하면, Poi의 Orientation값이 변경된다.
//    @objc public var orientation: Double
//
//    /// Poi가 현재 뷰에 보여지고 있는지 여부
//    public var isShow: Bool { get }
//
//    /// Poi가 그려진 위치로부터 pixelOffset을 적용한다.
//    ///
//    /// left/top 방향은 -, right/bottom 방향은 +로 offset을 지정할 수 있다.
//    @objc public var pixelOffset: CGPoint
//
//    /// 사용자 객체
//    public var userObject: AnyObject?
//}
//
///// Poi 의 애니메이션 효과 지정 인터페이스
//@objc public protocol PoiAnimationEffect {
//
//    /// 애니메이션 종료시 해당 poi를 숨길지 여부
//    @objc var hideAtStop: Bool { get set }
//
//    /// 애니메이션 종료시 해당 poi를 제거할지 여부
//    @objc var removeAtStop: Bool { get set }
//}
//
///// Poi에 Animation 효과를 주는 클래스.
/////
///// Animator를 생성해서 Animator에 효과를 주고자 하는 poi를 넣고, animator를 동작시키는 방식이다.
/////
///// Animator는 사용자가 직접 생성할 수 없으며, LabelManager를 통해서만 생성한 객체를 받아서 사용할 수 있다.
//@objc public class PoiAnimator : NSObject, KakaoMapsSDK.Animator {
//
//    /// Animator를 동작시킨다.
//    ///
//    /// Animator에 추가된 Poi가 하나도 없을 경우, 동작하지 않는다. start를 호출한 이후에는 Animator에 Poi를 추가하거나 지울 수 없다. 추가하고자 하는 경우, stop을 호출하고 추가해야한다.
//    ///
//    /// start 호출 이후 애니메이션이 끝나면 Animator에 추가된 Poi는 비워지므로, 다시 start를 호출하려면 Poi를 추가해야한다.
//    ///
//    /// Poi Interface에 있는 애니메이션은 animator가 start되면 모두 멈춘다.
//    public func start()
//
//    /// Animator 동작을 멈춘다.
//    ///
//    /// stop이 호출되면 애니메이션이 끝난것으로 간주되어 Animator에 속한 Poi는 모두 비워지므로, Animator를 다시 동작시키려면 다시 Poi를 Animator에 추가해야한다.
//    public func stop()
//
//    /// Animator 의 종료 콜백을 지정한다. Start 된 애니메이션이 종료되거나 stop이 호출되면 지정한 callback 이 호출된다. nil 로 지정해서 기존에 지정했던 callback을 제거할 수 있다. 기본값 nil.
//    ///
//    /// - parameter callback: Animator에 추가할 종료 콜백.
//    public func setStopCallback(_ callback: (((any KakaoMapsSDK.Animator)?) -> Void)?)
//
//    /// Animator에 Poi를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 Poi를 추가한다. start() 를 호출한 이후에는 애니메이션이 끝나기 전까지 poi를 추가할 수 없다.
//    ///
//    /// - parameter poi: Animator에 추가할 poi
//    @objc public func addPoi(_ poi: KakaoMapsSDK.Poi)
//
//    /// Animator에 여러개의 Poi를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 Poi를 추가한다. start() 를 호출한 이후에는 애니메이션이 끝나기 전까지 poi를 추가할 수 없다.
//    ///
//    /// - parameter pois: Animator에 추가할 poi 배열
//    @objc public func addPois(_ pois: [KakaoMapsSDK.Poi])
//
//    /// Animator에 추가한 poi를 모두 지운다.
//    ///
//    /// start() 호출 이후에는 동작하지 않는다.
//    @objc public func clearAllPois()
//
//    /// 추가한 animatorID
//    public var animatorID: String { get }
//
//    /// Animator 시작 여부
//    public var isStart: Bool { get }
//}
//
///// PoiBadge 클래스
///// Poi에 Poi icon 심볼이미지외에 추가 이미지를 표시하고자 할 경우 사용할 수 있다.
///// Poi에 개별로 지정하거나 PoiIconStyle에 지정할 수 있다.
//@objc open class PoiBadge : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///  - badgeID: 추가할 badge의 ID
//    ///  - image: badge의 image
//    ///  - offset: Badge가 위치할 offset
//    ///  - zOrder: Badge의 zOrder. 뱃지의 배치 순서를 결정한다. 값이 클수록 더 위에 그려진다.
//    @objc public init(badgeID: String, image: UIImage?, offset: CGPoint, zOrder: Int)
//
//    /// badge의 ID
//    @objc public var badgeID: String { get }
//
//    /// 추가한 badge의 offset
//    @objc public var offset: CGPoint { get }
//
//    /// badge의 Image
//    @objc public var image: UIImage? { get }
//
//    /// badge의 zOrder. 해당 값으로 badge의 배치 순서를 바꿀 수 있다.
//    ///
//    /// 값이 큰 Badge가 더 위에 그려진다.
//    @objc public var zOrder: Int { get }
//}
//
///// PoiIconStyle Class.
/////
///// Poi의 Icon Style을 정의한다.
/////
///// Poi의 심 볼이미지, AnchorPoint등을 정의한다.
/////
///// Poi가 나타나거나 사라질 때, Icon의 애니메이션 효과인 transition type을 정의할 수 있다.
/////
///// 또한 Icon에 종속되는 Badge를 Style로 정의할 수 있다.
//@objc open class PoiIconStyle : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - symbol: Poi의 심볼이미지
//    ///     - anchorPoint: Symbol Image의 AnchorPoint. default값은 (0.5, 0.5)
//    ///     - transition: Poi가 show/hide 할 때 애니메이션 효과 타입
//    ///     - enableEntranceTransition: 레벨변경시 스타일이 변할 때, 지정한 transition효과 적용여부. show()/hide()는 해당 값과 관계없이 transition 효과가 적용된다.
//    ///     - enableExitTransition: 레벨변경시 스타일이 변할 때, 지정한 transition 효과 적용 여부. show()/hide()는 해당 값과 관계없이 transition 효과가 적용된다.
//    ///     - badges: IconStyle에 종속되는 Badge. 여러개의 Poi에 badge가 포함된 똑같은 스타일을 사용하면 일괄적으로 뱃지가 표시된다.
//    @objc public init(symbol: UIImage?, anchorPoint: CGPoint = CGPoint(x: 0.5, y: 0.5), transition: PoiTransition = PoiTransition(entrance: .none, exit: .none), enableEntranceTransition: Bool = true, enableExitTransition: Bool = true, badges: [KakaoMapsSDK.PoiBadge]? = nil)
//
//    /// Poi의 심볼이미지
//    @objc public var symbol: UIImage? { get }
//
//    /// AnchorPoint
//    @objc public var anchorPoint: CGPoint { get }
//
//    /// Poi가 show/hide하거나, 레벨변경에 의해 스타일이 변할 때 심볼에 적용되는 애니메이션 효과 정의
//    @objc public var transition: PoiTransition { get }
//
//    /// 레벨변경에 의해 스타일이 변할 때, transition 효과 적용 여부. false로 설정할 경우 설정한 transition이 적용되지 않는다.
//    ///
//    /// 해당 값과 관계없이 Poi가 show()로 화면에 표시될 때는 기존에 설정한 transition대로 동작한다.
//    ///
//    /// 기본값은 true.
//    @objc public var enableEntranceTransiion: Bool { get }
//
//    /// 레벨변경에 의해 스타일이 변할 때, transition 효과 적용 여부. false로 설정할 경우 설정한 transition이 적용되지 않는다.
//    ///
//    /// 해당 값과 관계없이 Poi가 hide()로 화면에서 사라질 때는 기존에 설정한 transition대로 동작한다.
//    ///
//    /// 기본값은 true.
//    @objc public var enableExitTransition: Bool { get }
//
//    /// Poi IconStyle에 종속되는 뱃지
//    ///
//    /// 여러개의 Poi에 badge가 포함된 똑같은 스타일을 사용하면 일괄적으로 뱃지가 표시된다.
//    @objc public var badges: [KakaoMapsSDK.PoiBadge]? { get }
//}
//
///// 개별 POI 이벤트 파라미터 구조체.
//public struct PoiInteractionEventParam {
//
//    /// POI가 속한 KakaoMap
//    public let kakaoMap: KakaoMapsSDK.KakaoMap
//
//    /// POI
//    public let poiItem: any KakaoMapsSDK.Label
//}
//
///// Poi 생성 옵션 클래스
//@objc public class PoiOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///  - styleID: 사용할 PoiStyle ID
//    @objc required public init(styleID: String)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///  - styleID: 사용할 PoiStyle ID
//    ///  - poiID: poi 고유 ID
//    @objc public convenience init(styleID: String, poiID: String)
//
//    /// PoiID. 지정하지 않을 경우 자동으로 부여된다.
//    @objc public var itemID: String? { get }
//
//    /// Poi의 styleID
//    @objc public var styleID: String
//
//    /// Poi의 렌더링 우선순위
//    @objc public var rank: Int
//
//    /// Poi의 클릭가능 여부
//    @objc public var clickable: Bool
//
//    /// Poi의 transformType. 총 4가지 타입이 존재한다.
//    /// - SeeAlso: PoiTransformType
//    @objc public var transformType: PoiTransformType
//
//    /// Poi에 추가할 텍스트를 지정한다.
//    ///
//    /// - SeeAlso: PoiText
//    /// - parameter text: Poi에 표시될 text
//    @objc public func addText(_ text: KakaoMapsSDK.PoiText)
//
//    /// Poi에 추가할 텍스트 목록
//    ///
//    /// - returns: Poi에 표시될 text
//    @objc public func texts() -> [KakaoMapsSDK.PoiText]
//}
//
///// PoiStyle을 지정하는 클래스.
/////
///// 1개 이상의 PerLevelPoiStyle로 구성된다.
/////
///// LabelManager를 통해 Style을 등록한다. 등록된 style의 ID를 Poi에 지정해주면, Poi가 해당 스타일로 생성된다.
/////
///// 혹은 등록된 styleID로 Poi의 스타일을 변경할 수 있다.
//@objc public class PoiStyle : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters
//    ///     - styleID: PoiStyle의 ID
//    ///     - styles: PoiStyle을 구성할 단위레벨별 PerLevelPoiStyle 배열
//    @objc public init(styleID: String, styles: [KakaoMapsSDK.PerLevelPoiStyle])
//
//    /// 추가된 PerLevelPoiStyle 배열
//    @objc public var styles: [KakaoMapsSDK.PerLevelPoiStyle] { get }
//
//    /// PoiStyleID.
//    @objc public var styleID: String { get }
//}
//
///// Poi에 표시할 PoiText Class
/////
///// Poi에 표시될 하나의 라인을 정의한다.
//@objc open class PoiText : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - text: Poi에 표시할 text
//    ///     - styleIndex: 적용한 PoiTextStyle내에서 TextLine의 인덱스. 인덱스가 생성해둔 PoiTextStyle의 크기를 넘어갈 경우, 가장 마지막에 추가한 styleIndex로 표시된다.
//    @objc public init(text: String, styleIndex: UInt)
//
//    /// Poi에 표시될 Text
//    @objc public var text: String { get }
//
//    /// 적용한 PoiTextStyle내에서 TextLine의 인덱스
//    @objc public var styleIndex: UInt { get }
//}
//
///// PoiTextLineStyle 클래스
/////
///// PoiText 하나마다 PoiTextLineStyle을 지정할 수 있다.
/////
///// 예를 들어, Poi에 PoiText를 2개 이상 넣고자 하는 경우, 각 PoiText마다 PoiTextStyle에 생성한 PoiTextLineStyle의 인덱스를 지정하여 특정 텍스트 스타일로 표시할 수 있다.
//@objc public class PoiTextLineStyle : NSObject {
//
//    /// initializer
//    ///
//    /// default TextStyle과 center Layout 으로 지정된다.
//    override dynamic public init()
//
//    /// initializer
//    ///
//    /// - SeeAlso: TextStyle
//    /// - parameters:
//    ///     - textStyle: textStyle
//    public init(textStyle: KakaoMapsSDK.TextStyle)
//
//    /// TextStyle
//    @objc public var textStyle: KakaoMapsSDK.TextStyle
//}
//
///// PoiTextStyle class.
/////
///// Poi에 Text를 넣을 경우, 이 Text의 Style을 정의하는 클래스.
/////
///// 한개 이상의 PoiTextLineStyle로 구성된다. 하나의 Poi에 여러라인의 텍스트를 넣고 각 텍스트 라인마다 스타일을 다르게 주고자 하는 경우 두개 이상의 PoiTextLineStyle을 생성하여 PoiTextStyle을 구성할 수 있다.
/////
///// Poi가 나타나거나 사라질 때, transition Type을 지정할 수 있다.
//@objc open class PoiTextStyle : NSObject {
//
//    /// Initailizer
//    ///
//    /// - parameters:
//    ///     - transition: Poi가 show/hide 할 때 애니메이션 효과
//    ///     - enableEntranceTransition: 레벨변경시 스타일이 변할 때, 지정한 transition효과 적용여부. show()/hide()는 해당 값과 관계없이 transition 효과가 적용된다.
//    ///     - enableExitTransition: 레벨변경시 스타일이 변할 때, 지정한 transition 효과 적용 여부. show()/hide()는 해당 값과 관계없이 transition 효과가 적용된다.
//    ///     - textLineStyles: Poi의 Text Line별 스타일
//    @objc public init(transition: PoiTransition = PoiTransition(entrance: .none, exit: .none), enableEntranceTransition: Bool = true, enableExitTransition: Bool = true, textLineStyles: [KakaoMapsSDK.PoiTextLineStyle])
//
//    /// Poi가 show/hide하거나, 레벨변경에 의해 스타일이 변할 때 텍스트에 적용되는 애니메이션 효과 정의
//    ///
//    /// - SeeAlso: PoiTransition
//    @objc public var transition: PoiTransition { get }
//
//    /// 레벨변경에 의해 스타일이 변할 때, transition 효과 적용 여부. false로 설정할 경우 설정한 transition이 적용되지 않는다.
//    ///
//    /// 해당 값과 관계없이 Poi가 show()로 화면에 표시될 때는 기존에 설정한 transition대로 동작한다.
//    ///
//    /// 기본값은 true.
//    @objc public var enableEntranceTransiion: Bool { get }
//
//    /// 레벨변경에 의해 스타일이 변할 때, transition 효과 적용 여부. false로 설정할 경우 설정한 transition이 적용되지 않는다.
//    ///
//    ///  해당 값과 관계없이 Poi가 hide()로 화면에서 사라질 때는 기존에 설정한 transition대로 동작한다.
//    ///
//    /// 기본값은 true.
//    @objc public var enableExitTransition: Bool { get }
//
//    /// Poi의 라인별 텍스트 스타일.
//    ///
//    /// Poi에 멀티 라인의 텍스트를 넣을 경우, TextLine마다 TextLineStyle을 인덱스로 지정할 수 있다.
//    ///
//    /// Poi에 두개 이상의 PoiText를 넣고, 각 PoiText에 생성한 PoiTextLineStyle의의 index를 지정한다.
//    @objc public var textLineStyles: [KakaoMapsSDK.PoiTextLineStyle] { get }
//
//    /// text layouts
//    public var textLayouts: [PoiTextLayout]
//
//    /// text layouts(for obj-c)
//    @objc(textLayouts) public func objc_textLayout() -> [Int]
//
//    /// set text layouts(for obj-c)
//    @objc(setTextLayouts:) public func objc_setTextLayout(_ layouts: [Int])
//}
//
///// POI 이벤트 파라미터 구조체.
//public struct PoisInteractionEventParam {
//
//    /// POI가 속한 KakaoMap
//    public let kakaoMap: KakaoMapsSDK.KakaoMap
//
//    /// POI ID
//    public let poiID: String
//
//    /// Layer ID
//    public let layerID: String
//
//    /// 객체 위치
//    public let position: KakaoMapsSDK.MapPoint
//}
//
///// PolygonShape를 구성할 때 사용하는 Polygon 클래스.
/////
///// 폴리곤은 단독으로 Map에 추가할 수 없으며, Shape에 종속되는 객체이다.
/////
///// 하나의 외곽선과 hole을 넣어서 구성할 수 있다. 외곽선 point인 exterior ring과 폴리곤 내부 홀을 표시하는 holes로 구성된다.
/////
///// exteriorRing, 즉 외곽선은 시계방향으로 CGPoint를 넣어야 하고, hole은 시계반대방향으로 CGPoint를 넣어야한다.
/////
///// Polygon의 Point는 basePosition을 기준으로 한 실수 타입의  CGPoint 정점으로 구성한다.
//@objc open class Polygon : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - exteriorRing: Polygon의 외곽선
//    ///     - holes: Polygon의 hole 배열. hole이 없을경우 nil로 지정
//    ///     - styleIndex: PolygonStyleSet에서 사용할 PolygonStyle 인덱스
//    @objc required public init(exteriorRing: [CGPoint], holes: [[CGPoint]]? = nil, styleIndex: UInt)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - exteriorRing: Polygon의 외곽선
//    ///     - hole: Polygon의 하나의 hole. hole이 없을경우 nil로 지정
//    ///     - styleIndex: PolygonStyleSet에서 사용할 PolygonStyle 인덱스
//    @objc public convenience init(exteriorRing: [CGPoint], hole: [CGPoint]? = nil, styleIndex: UInt)
//
//    /// Polygon의 외곽선.
//    ///
//    /// 시계방향의 CGPoint 배열로 구성한다.
//    @objc public var exteriorRing: [CGPoint] { get }
//
//    /// Polygon의 holes
//    ///
//    /// 0개 이상으로 구성되며, 반시계방향의 CGPoint 배열로 구성한다.
//    @objc public var holes: [[CGPoint]]? { get }
//
//    /// PolygonStyleSet에서 사용할 표출 스타일 인덱스를 지정한다.
//    @objc public var styleIndex: UInt { get }
//}
//
///// 지도상에 특정 영역을 2d Polygon으로 표시하는 PolygonShape 클래스.
/////
///// basePosition을 기준으로 정점을 구성한다.
/////
///// PolygonShape를 추가하기 위해서는 먼저 KakaoMap에 ShapeLayer를 추가한 뒤, 해당 Layer에 PolygonShape를 추가할 수 있다.
/////
///// show, hide, style변경 및 이동/회전이 가능하다.
/////
///// PolygonShape는 사용자가 직접 생성할 수 없으며, PolygonShapeOptions class를 이용하여 Layer에 추가하면 해당 object를 얻을 수 있다.
//@objc open class PolygonShape : NSObject, KakaoMapsSDK.Shape {
//
//    /// PolygonShape를 보여준다.
//    public func show()
//
//    /// PolygonShape를 숨긴다.
//    public func hide()
//
//    /// PolygonShape의 style과 Data를 변경한다.
//    ///
//    /// PolygonShape의 Style과 PolygonShape가 표시하는 polgyon Data를 변경하고자 할 때 사용한다.
//    ///
//    /// 단, polygon Data를 바꿀때는 해당 PolygonShape 객체가 가리키는 본질이 변하지 않을때만 사용한다.
//    ///
//    /// 즉 전혀 다른 PolygonShape 객체일때는 PolygonShape를 하나 더 만드는것을 권장한다.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 styleID
//    ///     - polygons: 업데이트 할 폴리곤 데이터.
//    @objc public func changeStyleAndData(styleID: String, polygons: [KakaoMapsSDK.Polygon])
//
//    /// shape가 속한 layerID
//    public var layerID: String? { get }
//
//    /// ShapeID.
//    public var shapeID: String { get }
//
//    /// Shape의 base Position
//    @objc public var basePosition: KakaoMapsSDK.MapPoint { get }
//
//    /// PolygonShape의 position
//    ///
//    /// 새로운 position값으로 assign 할 경우, PolygonShape의 position값이 update된다.
//    @objc public var position: KakaoMapsSDK.MapPoint
//
//    /// PolygonShape의 현재 orientation값
//    ///
//    /// 새로운 orientation값으로 assign할 경우, PolygonShape의 orientation이 변경된다.
//    public var orientation: Double
//
//    /// PolygonShape가 현재 지도에 표시되는지 여부
//    public var isShow: Bool { get }
//
//    /// 사용자 객체
//    public var userObject: AnyObject?
//}
//
///// PolygonShape생성 옵션 클래스.
/////
///// PolygonShape는 지도상의 특정 2d polygon을 표시할 때 사용한다. basePosition을 기준점으로 오프셋 좌표인 CGPoint 로 이루어진 하나 이상의 폴리곤으로 구성된다.
/////
///// CGPoint로 이루어진 폴리곤을 받아 위경도 좌표계에 폴리곤을 표시한다.
/////
///// PolygonShape에 속한 Polygon마다 StyleSet을 이용하여 다르게 표출할 수도 있다.
/////
///// PolylineShape의 id를 별도로 지정하지 않는 경우, 내부적으로 자동으로 부여한다.
//@objc open class PolygonShapeOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 값이 클수록 더 위에 그려진다.
//    @objc public init(styleID: String, zOrder: Int)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - shapeID: Shape의 ID
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 값이 클수록 더 위에 그려진다.
//    @objc public init(shapeID: String, styleID: String, zOrder: Int)
//
//    /// Shape의 ID
//    @objc public var shapeID: String? { get }
//
//    /// Shape가 표출될 StyleID
//    @objc public var styleID: String { get }
//
//    /// Shape의 렌더링 우선순위.
//    ///
//    /// 높을수록 더 위에 그려지며, Shape type끼리만 유효하다.
//    ///
//    /// 즉, zOrder = 0 인 Shape는 zOrder = 1 인 shape보다 아래에 그려진다.
//    @objc public var zOrder: Int { get }
//
//    /// shape의 base position.
//    @objc public var basePosition: KakaoMapsSDK.MapPoint
//
//    /// Shape에 속한 폴리곤.
//    ///
//    /// 1개 이상의 폴리곤으로 구성된다.
//    ///
//    /// - SeeAlso: Polygon
//    @objc public var polygons: [KakaoMapsSDK.Polygon]
//}
//
///// PolygonStyle 클래스.
/////
///// PolygonShape의 스타일을 지정하기 위해 사용한다. 한 개 이상의 PerLevelPolygonStyle로 구성된다.
/////
///// PerLevelPolygonStyle Unit 클래스를 추가하여 레벨별로 표출할 스타일을 지정할 수 있다.
//@objc open class PolygonStyle : NSObject {
//
//    /// initializer
//    ///
//    /// - parameter styles: PolygonStyle을 구성할 단위레벨별 PerLevelPolygonStyle 배열
//    @objc public init(styles: [KakaoMapsSDK.PerLevelPolygonStyle])
//
//    /// 추가한 ShapeStyle 배열
//    @objc public var styles: [KakaoMapsSDK.PerLevelPolygonStyle] { get }
//}
//
///// PolygonStyleSet 클래스
/////
///// Shape내부에 여러개의 폴리곤이 있을 때, PolygonStyle은 하나의 스타일을 적용하게 되면 여러개의 폴리곤에 일괄적으로 똑같은 스타일이 적용된다.
/////
///// 반면 PolygonStyleSet은 PolygonShape 내부에 여러개의 폴리곤이 있을때, 각 폴리곤마다 다른 스타일을 적용할 수 있다.
/////
///// 즉, 하나의 스타일을 추가하더라도 폴리곤마다 다르게 표출될 수 있게 정의할 수 있다.
//@objc open class PolygonStyleSet : NSObject {
//
//    /// initializer
//    ///
//    /// - parameter styleSetID: StyleSet ID
//    @objc public init(styleSetID: String)
//
//    /// initializer
//    ///
//    /// - parameters
//    ///     - styleSetID: StyleSet ID
//    ///     - styles: PolygonStyleSet을 구성할 PolygonStyle 배열
//    @objc public convenience init(styleSetID: String, styles: [KakaoMapsSDK.PolygonStyle])
//
//    /// styleSet에 추가 될 LevelStyle을 추가한다.
//    ///
//    /// - parameter style: 추가할 ShapeLevelStyle
//    @objc public func addStyle(_ style: KakaoMapsSDK.PolygonStyle)
//
//    /// styleSet ID
//    @objc public var styleSetID: String { get }
//
//    /// 추가할 ShapeStyles
//    @objc public var styles: [KakaoMapsSDK.PolygonStyle] { get }
//}
//
///// PolylineShape를 구성할 때 사용하는 Polyline 클래스
/////
///// 폴리라인은 단독으로 Map에 추가할 수 없으며, Shape에 종속되는 객체이다.
/////
///// basePosition을 기준점으로 하는 2개 이상의 CGPoint로 만들어진 라인으로 구성된다. 폴리라인의 캡 스타일도 지정할 수 있다.
//@objc open class Polyline : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - line: Polyline을 구성하는 CGPoint 배열
//    ///     - styleIndex: Polyline에 적용할 PolylineStyleSet에 속한 PolylineStyle의 index
//    @objc required public init(line: [CGPoint], styleIndex: UInt)
//
//    /// 2개 이상의 CGPoint로 구성된다.
//    @objc public var line: [CGPoint] { get }
//
//    /// ShapeStyleSet에서 사용할 표출 인덱스를 지정한다.
//    @objc public var styleIndex: UInt { get }
//}
//
///// 지도상에 특정 선형을 2d Polyline으로 표시하는  PolylineShape 클래스.
/////
///// basePosition을 기준으로 정점을 구성한다
/////
///// PolylineShape를 추가하기 위해서는 먼저 KakaoMap에 ShapeLayer를 추가한 뒤, 해당 Layer에 PolylineShape를 추가할 수 있다.
/////
///// show, hide, style변경 및 이동/회전이 가능하다.
/////
///// PolylineShape는 사용자가 직접 생성할 수 없으며, PolylineShapeOptions class를 이용하여 Layer에 추가하면 해당 Object를 얻을 수 있다.
//@objc open class PolylineShape : NSObject, KakaoMapsSDK.Shape {
//
//    /// PolylineShape를 보여준다.
//    public func show()
//
//    /// PolylineShape를 숨긴다.
//    public func hide()
//
//    /// PolylineShape의 style과 Data를 변경한다.
//    ///
//    /// PolylineShape의 style과 표시하는 polyline Data를 변경하고자 할 때 사용한다. 단, polyline Data를 바꿀때는 해당 PolylineShape 객체가 가리키는 본질이 변하지 않을때만 사용한다. 즉 전혀 다른 PolylineShape 객체일때는 PolylineShape를 하나 더 만드는것을 권장한다.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 styleID
//    ///     - lines: 업데이트 할 폴리라인 데이터.
//    @objc public func changeStyleAndData(styleID: String, lines: [KakaoMapsSDK.Polyline])
//
//    /// Shape가 속한 layerID
//    public var layerID: String? { get }
//
//    /// Shape의 ID
//    public var shapeID: String { get }
//
//    /// Shape의 base Position
//    @objc public var basePosition: KakaoMapsSDK.MapPoint { get }
//
//    /// PolylineShape의 position
//    ///
//    /// 새로운 값을 assign 하면, 해당 PolylineShape의 position이 업데이트된다.
//    @objc public var position: KakaoMapsSDK.MapPoint
//
//    /// PolylineShape의 Orientation (radian)
//    ///
//    /// 새로운 orientation값을 assign하면, PolylineShape의 orientation 값이 업데이트된다.
//    public var orientation: Double
//
//    /// PolylineShape가 현재 지도에 표시되는지 여부
//    public var isShow: Bool { get }
//
//    /// 사용자 객체
//    public var userObject: AnyObject?
//}
//
///// PolylineShape생성 옵션 클래스
/////
///// PolylineShape는 지도상의 특정 2d polyline을 표시할 때 사용한다. basePosition을 기준점으로 오프셋 좌표인 CGPoint로 이루어진 하나 이상의 폴리라인으로 구성된다.
/////
///// CGPoint로 이루어진 폴리라인을 받아 위경도 좌표계에 폴리라인을 표시한다.
/////
///// Style은 PolylineShape에 속한 Polyline마다 StyleSet을 이용하여 다르게 표출할수도 있다.
/////
///// PolylineShape의 id를 별도로 지정하지 않는 경우, 내부적으로 자동으로 부여한다.
//@objc open class PolylineShapeOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 높을수록 더 위에 그려진다.
//    @objc public init(styleID: String, zOrder: Int)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - shapeID: Shape의 ID
//    ///     - styleID: 사용할 ShapeStyle ID
//    ///     - zOrder: Shape의 렌더링 우선순위. 높을수록 더 위에 그려진다.
//    @objc public init(shapeID: String, styleID: String, zOrder: Int)
//
//    /// Shape의 ID
//    @objc public var shapeID: String? { get }
//
//    /// Shape가 표출될 StyleID
//    @objc public var styleID: String { get }
//
//    /// Shape의 렌더링 우선순위.
//    ///
//    /// 높을수록 더 위에 그려지며, Shape type끼리만 유효하다.
//    ///
//    /// 즉, zOrder = 0 인 Shape는 zOrder = 1 인 shape보다 아래에 그려진다.
//    @objc public var zOrder: Int { get }
//
//    /// shape의 base position
//    @objc public var basePosition: KakaoMapsSDK.MapPoint
//
//    /// Shape에 속한 Polyline 배열
//    ///
//    /// 1개 이상의 폴리라인으로 구성된다.
//    ///
//    /// - SeeAlso: Polyline
//    @objc public var polylines: [KakaoMapsSDK.Polyline]
//}
//
///// PolylineStyle 클래스.
/////
///// PolylineShape를 레벨별로 다른 스타일로 표출하고자 할 때 사용한다.
/////
///// PerLevelPolylineStyle Unit 클래스를 추가하여 레벨별로 표출할 스타일을 지정할 수 있다.
//@objc open class PolylineStyle : NSObject {
//
//    /// initializer
//    ///
//    /// - parameter styles: PolylineStyle을 구성할 단위레벨별 PerLevelPolylineStyle 배열
//    @objc public init(styles: [KakaoMapsSDK.PerLevelPolylineStyle])
//
//    /// 추가한 PerLevelPolylineStyle 배열
//    @objc public var styles: [KakaoMapsSDK.PerLevelPolylineStyle] { get }
//}
//
///// PolylineStyleSet 클래스
/////
///// Shape 내부에 여러개의 Polyline이 존재할 경우, PolylineStyle은 Shape 내부 여러개의 폴리라인에 똑같은 스타일로 일괄적으로 적용된다.
/////
///// 반면 PolylineStyleSet은 PolylineShape 내부에 여러개의 폴리라인이 있을 때, 각 폴리라인마다 다른 스타일을 적용할 수 있다.
/////
///// 즉, 하나의 스타일을 추가하더라도 폴리곤마다 다르게 표출할 수 있도록 정의할 수 있다.
//@objc open class PolylineStyleSet : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameter styleSetID: styleSet ID
//    @objc public init(styleSetID: String)
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - styleSetID: styleSet ID
//    ///     - styles: PolylineStyleSet을 구성할 PolylineStyle 배열
//    ///     - capType: Polyline에 시작/끝지점에 표시될 capType 지정. 스타일셋에 등록된 모든 PolylineStyle은 일괄적으로 이 capType이 적용된다.
//    @objc public convenience init(styleSetID: String, styles: [KakaoMapsSDK.PolylineStyle], capType: PolylineCapType = .square)
//
//    /// styleSet에 추가될 LevelStyle을 추가한다.
//    ///
//    /// - parameter style: 추가할 style
//    @objc public func addStyle(_ style: KakaoMapsSDK.PolylineStyle)
//
//    /// styleSet ID
//    @objc public var styleSetID: String { get }
//
//    /// 추가할 shapeStyles
//    @objc public var styles: [KakaoMapsSDK.PolylineStyle] { get }
//
//    /// 해당 스타일을 적용한 Polyline의 시작/끝지점에 표시될 capType
//    ///
//    /// - SeeAlso: PolylineCapType
//    @objc public var capType: PolylineCapType { get }
//}
//
///// Primitive 정점을 구성하는 유틸리티 클래스
/////
///// Circle, Rectangle을 구성할 수 있다.
//@objc open class Primitives : NSObject {
//
//    /// wgs84 좌표계 상의 두 점 사이의 거리를 구한다.
//    /// - parameters:
//    ///     - p1: 첫번째 점
//    ///     - p2: 두번째 점
//    /// - returns: 두 점 사이의 거리(meter)    
//    @objc public static func distance(p1: KakaoMapsSDK.MapPoint, p2: KakaoMapsSDK.MapPoint) -> Double
//
//    /// CirclePoint를 가져온다.
//    ///
//    /// - parameters:
//    ///     - radius: Circle의 반지름(meter)
//    ///     - numPoints : circle을 구성할 포인트 개수.
//    ///     - cw: 시계방향으로 구성할지에 대한 여부. false인경우 시계반대방향으로 리턴된다.
//    /// - returns: Circle형태의 CGPoint 배열
//    @objc public static func getCirclePoints(radius: Double, numPoints: Int, cw: Bool) -> [CGPoint]
//
//    /// CirclePoint를 가져온다.
//    ///
//    /// - parameters:
//    ///     - radius: Circle의 반지름(meter)
//    ///     - numPoints : circle을 구성할 포인트 개수.
//    ///     - cw: 시계방향으로 구성할지에 대한 여부. false인경우 시계반대방향으로 리턴된다.
//    ///     - center : CirclePoint를  지도 좌표계로 생성하기 위해 중심점을 지정
//    /// - returns: Circle형태의 MapPoint배열
//    @objc public static func getCirclePoints(radius: Double, numPoints: Int, cw: Bool, center: KakaoMapsSDK.MapPoint) -> [KakaoMapsSDK.MapPoint]
//
//    /// RectanglePoint를 가져온다.
//    ///
//    /// - parameters:
//    ///     - width: Rectangle의 너비(meter)
//    ///     - height: Rectnagle의 높이(meter)
//    ///     - cw: 시계방향으로 구성할지에 대한 여부. false인경우 시계반대방향으로 리턴된다.
//    /// - returns: Rectangle형태의 CGPoint 배열
//    @objc public static func getRectanglePoints(width: Double, height: Double, cw: Bool) -> [CGPoint]
//
//    /// RectanglePoint를 가져온다.
//    ///
//    /// - parameters:
//    ///     - width: Rectangle의 너비(meter)
//    ///     - height: Rectnagle의 높이(meter)
//    ///     - cw: 시계방향으로 구성할지에 대한 여부. false인경우 시계반대방향으로 리턴된다.
//    ///     - center : Rectangle Point를  지도 좌표계로 생성하기 위해 중심점을 지정
//    /// - returns: Circle형태의 MapPoint 배열
//    @objc public static func getRectanglePoints(width: Double, height: Double, cw: Bool, center: KakaoMapsSDK.MapPoint) -> [KakaoMapsSDK.MapPoint]
//
//    /// startPoint ~ endPoint까지 Curve Point를 생성한다.
//    ///
//    /// - parameters:
//    ///     - startPoint: 시작 point
//    ///     - endPoint: 끝 point
//    ///     - isLeft: 시작-끝을 기준으로 왼쪽으로 휘어지는 커브인지에 대한 여부. false인경우 오른쪽으로 휘어지는 커브 point를 생성한다.
//    /// - returns: 생성한 곡선 MapPoint 배열
//    @objc public static func getCurvePoints(startPoint: KakaoMapsSDK.MapPoint, endPoint: KakaoMapsSDK.MapPoint, isLeft: Bool) -> [KakaoMapsSDK.MapPoint]
//
//    override dynamic public init()
//}
//
///// Animation 시간동안 시작점에서 끝점까지 지정된 방향으로 진행되는 형태의 애니메이션.
/////
///// Route Animator에 적용할 수 있다.
//@objc public class ProgressAnimationEffect : NSObject, KakaoMapsSDK.RouteAnimationEffect {
//
//    /// Initializer
//    ///
//    /// - parameter direction: progress 진행방향
//    /// - parameter type: RouteLine의 진행타입.
//    @objc public init(direction: ProgressDirection, type: RouteProgressType)
//
//    /// 시작지점(0.0~1.0)
//    @objc public var startPoint: Float { get }
//
//    /// 종료지점(0.0~1.0)
//    @objc public var endPoint: Float { get }
//
//    /// progress 진행 방향
//    @objc public var direction: ProgressDirection
//
//    /// RouteLine 진행 타입
//    @objc public var type: RouteProgressType
//
//    /// 애니메이션 지속 시간, 반복 횟수 등 세부사항 지정
//    public var interpolation: AnimationInterpolation
//
//    /// 애니메이션 종료 시 애니메이터에 속한 객체들을 숨길지에 대한 여부.
//    ///
//    /// true로 설정하면 애니메이션이 종료되면 객체들이 화면에서 자동으로 사라진다.
//    public var hideAtStop: Bool
//
//    /// 애니메이션 종료시 초기 상태로 리셋 여부
//    public var resetToInitialState: Bool
//}
//
///// 로드뷰를 그리기 위한 클래스.
/////
///// 로드뷰는 바로 그려지지 않고, 로드뷰지점 데이터를 요청하여 데이터가 수신되면 그려진다.
//@objc open class Roadview : KakaoMapsSDK.ViewBase {
//
//    /// 로드뷰를 요청한다.
//    /// 
//    /// 요청 결과에 따라 이벤트가 발생된다.
//    ///
//    /// - parameters:
//    ///     - position: 로드뷰를 요청할 지점 위치
//    ///     - markers: 로드뷰에 표시할 마커들. 없을 경우 nil.
//    ///     - lookAt: 초기 로드뷰 진입시 바라볼 방향. 지정하지 않을 경우 nil. 지정하지 않을 경우 정북 수평방향을 바라본다.
//    open func requestRoadview(position: KakaoMapsSDK.MapPoint, markers: [KakaoMapsSDK.PanoramaMarker]? = nil, lookAt: KakaoMapsSDK.RoadviewLookAt? = nil)
//
//    /// 로드뷰를 요청한다.
//    /// 
//    /// 요청 결과에 따라 이벤트가 발생된다.
//    ///
//    /// - parameter position: 로드뷰를 요청할 지점 위치.
//    /// - parameter panoID: 파노라마 ID.
//    /// - parameter markers: 로드뷰에 표시할 마커들. 없을 경우 nil.
//    /// - parameter lookAt: 초기 로드뷰 진입시 바라볼 방향. 지정하지 않을 경우 nil. 지정하지 않을 경우 정북 수평방향을 바라본다.
//    @objc open func requestRoadview(position: KakaoMapsSDK.MapPoint, panoID: String?, markers: [KakaoMapsSDK.PanoramaMarker]? = nil, lookAt: KakaoMapsSDK.RoadviewLookAt? = nil)
//
//    /// 로드뷰 뷰와 연결된 지도 뷰를 지정한다.
//    ///
//    /// 지도 뷰와 연결하면 지도 뷰가 회전하면 로드뷰 뷰도 회전하고, 로드뷰 지점 이동에 따라 지도 뷰도 이동한다.
//    ///
//    /// - parameter viewName: 연결할 지도 뷰의 이름. 해당 이름의 지도뷰가 없을 경우 아무 동작 없음.
//    @objc open func linkMapView(_ viewName: String)
//
//    /// 로드뷰 뷰와 연결된 지도 뷰를 해제한다.
//    @objc open func unlinkMapView()
//
//    /// 뷰를 다시 그린다.
//    @objc open func refresh()
//
//    /// 로고의 위치를 지정한다.
//    /// 로고는 SpriteGUI 와 같은 방식으로 화면상의 특정위치에 고정적으로 표시되므로, 다른 GUI 와 겹치는 현상을 피하기 위해 로고의 위치를 이동시키는 데 사용한다.
//    /// 위치 지정방식은 SpriteGUI와 동일하다.
//    ///
//    /// - parameters:
//    ///     - origin: 로고의 alignment
//    ///     - position: alignment 기준점으로부터의 offset
//    @objc public func setLogoPosition(origin: GuiAlignment, position: CGPoint)
//
//    /// 로드뷰 카메라의 pan값
//    @objc open var pan: Double { get }
//
//    /// 로드뷰 카메라의 tilt값
//    @objc open var tilt: Double { get }
//
//    /// 뷰의 활성화 상태
//    ///
//    /// `true`인 경우 렌더링이 실행되며,`false`인 경우 렌더링을 하지 않는다.
//    @objc open var isEnabled: Bool
//
//    /// 로드뷰 이벤트 delegate를 지정한다.
//    @objc open var eventDelegate: (any KakaoMapsSDK.RoadviewEventDelegate)?
//
//    /// 포커스 변경 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    open func addFocusChangedEventHandler<U>(target: U, handler: @escaping (U) -> (Bool) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// 리사이즈 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    open func addViewResizedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.Roadview) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//
//    /// 뷰 탭 이벤트 핸들러를 추가한다.
//    ///
//    /// - parameter target: 이벤트를 수신할 target object
//    /// - parameter handler: 이벤트를 수신할 method
//    /// - returns: 추가된 이벤트 핸들러.
//    open func addRoadviewTappedEventHandler<U>(target: U, handler: @escaping (U) -> (KakaoMapsSDK.ViewInteractionEventParam) -> Void) -> any KakaoMapsSDK.DisposableEventHandler where U : AnyObject
//}
//
///// Roadview의 이벤트 delegate.
//@objc public protocol RoadviewEventDelegate {
//
//    /// 로드뷰의 크기가 변경되었을 때 발생.
//    ///
//    /// - parameter roadview: Roadview
//    @objc optional func roadviewDidResized(_ roadview: KakaoMapsSDK.Roadview)
//
//    /// 파노라마가 갱신되었을 때 발생.
//    /// - parameter panoId: 갱신된 파노라마 ID
//    @objc optional func panoramaUpdated(_ panoId: String)
//
//    /// 포커스 변경시 발생.
//    ///
//    /// - parameter roadview: Roadview
//    /// - parameter focus: 포커스 상태
//    @objc optional func roadviewFocusDidChanged(roadview: KakaoMapsSDK.Roadview, focus: Bool)
//
//    /// 로드뷰 요청 결과 수신시 발생.
//    ///
//    /// - parameter roadview: Roadview
//    /// - parameter panoID: 파노라마 ID
//    /// - parameter date: 촬영일자
//    /// - parameter position: 파노라마 지점 위치
//    @objc func roadviewResultDidReceived(roadview: KakaoMapsSDK.Roadview, panoID: String, date: String, position: KakaoMapsSDK.MapPoint)
//
//    /// 로드뷰 요청 결과 결과없음 수신시 발생.
//    ///
//    /// - parameter roadview: Roadview
//    @objc optional func noRoadviewResult(_ roadview: KakaoMapsSDK.Roadview)
//
//    /// 로드뷰 요청 실패시 발생.
//    ///
//    /// - parameter roadview: Roadview
//    @objc optional func roadviewRequestDidFailed(_ roadview: KakaoMapsSDK.Roadview)
//
//    /// 잘못된 요청 (ex. index범위 밖의 과거사진 요청).
//    ///
//    /// - parameter roadview: Roadview
//    @objc optional func invalidRoadviewRequest(_ roadview: KakaoMapsSDK.Roadview)
//
//    /// 로드뷰의 영역이 클릭되었을 때 호출.
//    ///
//    /// - parameter roadview: Roadview
//    /// - parameter point: 클릭된 위치
//    @objc optional func roadviewDidTapped(roadview: KakaoMapsSDK.Roadview, point: CGPoint)
//}
//
///// 로드뷰 viewInfo. Roadview로 view가 생성된다.
//@objc public class RoadviewInfo : KakaoMapsSDK.ViewInfo {
//}
//
//extension RoadviewInfo {
//
//    /// Initializer
//    ///
//    /// - parameter viewName: view의 이름
//    /// - parameter appName: Cocoa에 등록된 app 이름. 따로 등록된 내용이 없을 경우 "roadview" 사용.
//    /// - parameter viewInfoName: viewInfo의 이름. 미지정시 type에 따른 기본값.
//    /// - parameter enabled: 초기 활성화 여부. 기본값은 true.
//    @objc dynamic public convenience init(viewName: String, appName: String = "roadview", viewInfoName: String = "roadview", enabled: Bool = true)
//}
//
///// 로드뷰가 화면에 표시될 때 카메라가 바라보는 방향을 지정하기 위한 클래스
//@objc open class RoadviewLookAt : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - pan: 카메라 회전각(radian, 정북기준 시계방향).
//    ///     - tilt: 카메라 기울임각(radian, 지평선과 평행 기준, 양수값이 지면방향)
//    @objc public init(pan: Double, tilt: Double)
//
//    /// Initializer
//    ///
//    /// - parameter position: 카메라가 바라볼 위치
//    @objc public init(position: KakaoMapsSDK.MapPoint)
//
//    /// 카메라 회전각(radian, 정북기준 시계방향).
//    @objc public var pan: Double { get }
//
//    /// 카메라 기울임각(radian, 지평선과 평행 기준, 양수값이 지면방향)
//    @objc public var tilt: Double { get }
//
//    /// 카메라가 바라볼 위치
//    @objc public var position: KakaoMapsSDK.MapPoint? { get }
//
//    /// RoadviewLookAt Type.
//    @objc public var lookAtType: RoadviewLookAtType { get }
//}
//
///// 맵에 표시되는 Route를 나타내는 클래스.
/////
///// Route는 Polyline/MapPolyline 과 마찬가지로 선을 그리는 기능을 하지만 경로선을 표현하기 위한 기능을 추가로 가지고 있다.
/////
///// 예를 들면 레벨별로 디테일 조절 처리가 들어간다. 즉, 상위 레벨일수록 RoutePoints가 rough하게 표시되며, 하위레벨일수록 자세하게 표시된다.
/////
///// 따라서 맵에 경로를 표시할 때 사용하기에 적절하다. show/hide/style 변경 등이 가능하다.
/////
///// 하나 이상의 RouteSegment로 이루어진다. Route는 레벨별로 디테일 조절 처리가 들어간다.
/////
///// Route를 추가하기 위해서는 먼저 KakaoMap에 RouteLayer를 추가한 뒤, 해당 Layer에 Route를 추가한다.
/////
///// Route는 사용자가 직접 생성할 수 없으며, RouteLayer를 통해 해당 Object를 얻을 수 있다.
//@objc public class Route : NSObject {
//
//    /// Route를 보여준다.
//    @objc public func show()
//
//    /// Route를 숨긴다.
//    @objc public func hide()
//
//    /// Route의 style과 Data를 변경한다.
//    ///
//    /// Route의 Style과 함께 Route가 표시하는 RouteSegment Data를 변경하고자 할 때 사용한다. 단, RouteSegment Data를 바꿀때는 해당 Route 객체가 가리키는 본질이 변하지 않을때만 사용한다. 즉 전혀 다른 Route 객체일때는 Route를 하나 더 만드는것을 권장한다.
//    /// ex. 경로 탐색 결과를 보여주고, 교통 정보가 업데이트 되어서 스타일과 segment가 바뀌어야 하는 경우.
//    /// ex. 경로 탐색 결과를 여러개 보여주고, disabled route <-> enabled route 로 style 전환이 필요한 경우.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 styleID
//    ///     - segments: 변경할 route segments data.
//    @objc public func changeStyleAndData(styleID: String, segments: [KakaoMapsSDK.RouteSegment])
//
//    /// 특정 위치에 해당하는 경로선상 진행도를 가져온다.
//    ///
//    /// 진행도의 기준 진행 방향은 시작점 -> 끝점 방향이다.
//    ///
//    /// position 값이 정확히 경로선상에 있는 값이 아닌 경우 경로선상의 가장 가까운 위치를 찾아 해당 위치로 진행도를 계산한다.
//    ///
//    /// - parameter position: 경로선 상의 진행도를 얻어올 위치
//    /// - returns : 위치에 해당하는 진행도 (0.0 ~ 1.0).
//    @objc public func getProgressAlongRouteLine(position: KakaoMapsSDK.MapPoint) -> Float
//
//    /// RouteLine 상의 지정한 진행도에 해당하는 위치 및 방향을 가져온다.
//    ///
//    /// 진행도의 기준 진행 방향은 시작점 -> 끝점 방향이다.
//    ///
//    /// - parameter progress: 진행도(0.0~1.0).
//    /// - returns : 진행도에 해당하는 지점의 RoutePointInfo. 진행도를 확인할 수 없는 상태(정상적으로 view에 등록되어 있지 않은 상태)인 경우 nil.
//    public func getRoutePointInfoOnRoute(progress: Float) -> KakaoMapsSDK.RoutePointInfo?
//
//    /// RouteLine의 진행도를 변경한다.
//    ///
//    /// RouteLine의 현재 진행도에서 새로 지정한 진행도로 변경된다. 기존에 변경이 진행중이던 내용이 있으면 중지되고 중지된 상태에서 새로 지정한 진행도로 변경된다.
//    ///
//    /// 진행도의 기준 진행 방향은 시작점 -> 끝점 방향이다.
//    ///
//    /// 초기값은 progress : 0.0, type : .clearFromStart
//    ///
//    /// progress가 동일하게 0.0 이어도 type이 .clearFromStart와 .fillFromStart는 다른 상태임에 주의해야 한다.
//    ///
//    /// - parameters
//    ///     - progress: 진행도(0.0~1.0).
//    ///     - type: 진행 타입.
//    ///     - duration: 변경 진행 시간(milliseconds)
//    ///     - callback: 변경 완료 콜백
//    @objc public func setProgress(progress: Float, type: RouteProgressType, duration: UInt, callback: ((KakaoMapsSDK.Route?) -> Void)? = nil)
//
//    /// RouteLine의 진행도를 가져온다.
//    ///
//    /// 진행도 및 진행 타입을 가져온다.
//    ///
//    /// - returns: 현재 RouteProgressInfo. 즉시 리턴됨. 진행도를 가져올 수 없는 상태(정상적으로 view에 등록되어 있지 않은 상태)인 경우 nil.
//    public func getProgress() -> KakaoMapsSDK.RouteProgressInfo?
//
//    /// Route의 ID
//    @objc public var routeID: String { get }
//
//    /// Route가 속한 Layer의 ID
//    @objc public var layerID: String { get }
//
//    /// Route의 렌더링 우선순위. 값이 클수록 위에 그려진다.
//    ///
//    /// 새로운 zOrder로 assgin하면, 해당 Route의 zOrder가 업데이트된다.
//    ///
//    /// zOrder = 0인 Route는 zOrder = 1 인 Route보다 아래에 그려진다.
//    @objc public var zOrder: Int
//
//    /// Route가 표출되고있는지에 대한 여부를 가져온다.
//    @objc public var isShow: Bool { get }
//
//    /// 사용자 객체
//    @objc public var userObject: AnyObject?
//}
//
///// Route 의 애니메이션 효과 지정 인터페이스
//@objc public protocol RouteAnimationEffect {
//
//    /// 애니메이션 효과 옵션
//    @objc var interpolation: AnimationInterpolation { get set }
//
//    /// 애니메이션 종료시 해당 route를 숨길지 여부
//    @objc var hideAtStop: Bool { get set }
//
//    /// 애니메이션 종료시 초기 상태로 돌아갈지 여부.
//    @objc var resetToInitialState: Bool { get set }
//}
//
///// Route에 Animation 효과를 주기 위한 클래스
/////
///// Animator를 생성해서 Animator에 효과를 주고자 하는 poi를 넣고, animator를 동작시키는 방식이다.
/////
///// Animator는 사용자가 직접 생성할 수 없으며, RouteManager를 통해서만 생성한 객체를 받아서 사용할 수 있다.
//@objc public class RouteAnimator : NSObject, KakaoMapsSDK.Animator {
//
//    /// Animator를 동작시킨다.
//    ///
//    /// Animator에 추가된 route가 하나도 없을 경우, 동작하지 않는다. start를 호출한 이후에는 animator에 route를 추가하거나 지울 수 없다. 추가하고자 하는 경우, stop을 호출하고 추가해야한다.
//    ///
//    /// Start 호출 이후 애니메이션이 끝나면 animator에 추가된 route는 비워지므로, 다시 start를 호출하려면 route를 추가해야한다.
//    ///
//    /// Route Interface에 있는 애니메이션은 animator가 start되면 모두 멈춘다.
//    public func start()
//
//    /// Animator 동작을 멈춘다.
//    ///
//    /// Stop이 호출되면 애니메이션이 끝난것으로 간주되어 animator에 속한 route는 모두 비워지므로, animator를 다시 동작시키려면 다시 route를 animator에 추가해야한다.
//    public func stop()
//
//    /// Animator 의 종료 콜백을 지정한다. Start 된 애니메이션이 종료되거나 stop이 호출되면 지정한 callback 이 호출된다. nil 로 지정해서 기존에 지정했던 callback을 제거할 수 있다. 기본값 nil.
//    ///
//    /// - parameter callback: Animator에 추가할 종료 콜백.
//    public func setStopCallback(_ callback: (((any KakaoMapsSDK.Animator)?) -> Void)?)
//
//    /// Animator에 route를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 route를 추가한다. start() 를 호출한 이후에는 애니메이션이 끝나기 전까지 route를 추가할 수 없다.
//    ///
//    /// - parameter poi: Animator에 추가할 route
//    @objc public func addRoute(_ route: KakaoMapsSDK.Route)
//
//    /// Animator에 여러개의 route를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 route를 추가한다. start() 를 호출한 이후에는 애니메이션이 끝나기 전까지 route를 추가할 수 없다.
//    ///
//    /// - parameter pois: Animator에 추가할 route 배열
//    @objc public func addRoutes(_ routes: [KakaoMapsSDK.Route])
//
//    /// Animator에 추가한 route를 모두 지운다.
//    ///
//    /// start() 호출 이후에는 동작하지 않는다.
//    @objc public func clearAllRoutes()
//
//    /// 추가한 animatorID
//    public var animatorID: String { get }
//
//    /// Animator 시작 여부
//    public var isStart: Bool { get }
//}
//
///// Route객체를 관리하는 단위인 RouteLayer 클래스.
/////
///// Route를 추가/삭제 등 관리할 수 있으며, 일종의 그룹처럼 관리가 가능하다.
/////
///// 사용자가 직접 객체를 생성할 수 없으며, RouteManager를 통해 객체를 간접적으로 생성할 수 있다.
//@objc open class RouteLayer : NSObject {
//
//    /// 현재 layer에 속한 Route를 일괄적으로 지운다.
//    @objc public func clearAllRoutes()
//
//    /// 현재 Layer에 Route를 추가한다.
//    ///
//    /// 하나의 레이어안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 nil을 리턴한다.
//    ///
//    /// - SeeAlso: RouteSegment
//    /// - parameters:
//    ///     - option: 추가할 segment의 option.
//    ///     - callback: Route 추가가 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성한 Route 객체
//    @objc public func addRoute(option: KakaoMapsSDK.RouteOptions, callback: ((KakaoMapsSDK.Route?) -> Void)? = nil) -> KakaoMapsSDK.Route?
//
//    /// 현재 Layer에서 특정 Route를 제거한다.
//    ///
//    /// - parameters:
//    ///     - routeID: 제거할 routeID
//    ///     - callback: Route제거가 완료되었을 때, 호출할 callback(optional)
//    @objc public func removeRoute(routeID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에서 특정 Route를 제거한다.
//    ///
//    /// - parameters:
//    ///     - routeIDs: 제거할 routeID 배열
//    ///     - callback: Route제거가 완료되었을 때, 호출할 callback(optional)
//    @objc public func removeRoutes(routeIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속한 특정 Route를 보여준다.
//    ///
//    /// - parameter routeIDs: 보여줄 routeID 배열
//    @objc public func showRoutes(routeIDs: [String])
//
//    /// 현재 Layer에 속한 특정 Route를 숨긴다.
//    ///
//    /// - parameter routeIDs: 숨길 routeID 배열
//    @objc public func hideRoutes(routeIDs: [String])
//
//    /// 현재 Layer에 속한 Route를 가져온다.
//    ///
//    /// - parameter routeID: 가져올 routeID
//    /// - returns: ID에 해당하는 Route객체. 없을경우 nil
//    @objc public func getRoute(routeID: String) -> KakaoMapsSDK.Route?
//
//    /// 현재 Layer에 속한 다수의 Route를 가져온다.
//    ///
//    /// - parameter routeIDs: 가져올 routeID 배열
//    /// - returns: ID에 해당하는 Route객체 배열. 없을경우 nil
//    @objc public func getRoutes(routeIDs: [String]) -> [KakaoMapsSDK.Route]?
//
//    /// 현재 레이어에 속한 모든 Route를 가져온다.
//    ///
//    /// - returns: 현재 Layer에 추가되어있는 모든 Route 객체 배열
//    @objc public func getAllRoutes() -> [KakaoMapsSDK.Route]?
//
//    /// RouteLayer ID
//    @objc public var layerID: String { get }
//
//    /// RouteLayer의 visible 상태.
//    ///
//    /// layer의 on/off 상태를 나타내며, layer에 속한 객체의 show/hide는 별도로 동작시켜야한다.
//    ///
//    /// 즉, layer의 visible이 true여도 layer에 속한 객체의 show를 호출해야 보이고, visible이 false라면 layer에 속한 객체는 화면에 표시되지 않는다.
//    @objc public var visible: Bool
//
//    /// RouteLayer의 렌더링 우선순위
//    ///
//    /// 값이 클수록 위에 그려진다. 같은 RouteLayer끼리만 유효하다.
//    ///
//    /// 즉, zOrder = 0 인 RouteLayer에 속한 Route는 zOrder = 1 인 RouteLayer에 속한 Route보다 아래에 그려진다.
//    @objc public var zOrder: Int { get }
//}
//
///// KakaoMap에서 Route 객체를 관리하기 위한 클래스
/////
///// RotueLayer의 추가/삭제 등의 관리와 Route를 표시하기 위한 Style 추가가 가능하다.
/////
///// KakaoMap에 종속적이므로 KakaoMap이 삭제된 뒤에도 사용하지 않도록 주의하여야 한다.
//@objc public class RouteManager : NSObject {
//
//    /// RouteStyleSet을 추가한다.
//    ///
//    /// Route가 여러개의 RouteSegment로 구성되는 경우, 하나의 스타일셋으로 segment별로 다르게 표시할 수 있다. 같은 styleID로 추가하더라도 overwrite되지 않는다.
//    ///
//    /// - SeeAlso: RouteStyle
//    /// - parameter styleSet: 추가할 RouteStyleSet
//    @objc public func addRouteStyleSet(_ styleSet: KakaoMapsSDK.RouteStyleSet)
//
//    /// RouteLayer를 추가한다.
//    ///
//    /// Route관리할 수 있는 단위인 RouteLayer를 추가한다. 이미 KakaoMap에 추가되어있는 ID와 동일한 layer를 추가하고자 하는 경우, 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - layerID: 추가할 routeLayer ID
//    ///     - zOrder: layer의 렌더링 우선순위. 값이 높을수록 위에 그려진다.
//    /// - returns: 생성한 RouteLayer 객체
//    @objc public func addRouteLayer(layerID: String, zOrder: Int) -> KakaoMapsSDK.RouteLayer?
//
//    /// KakaoMap에 추가한 RouteLayer를 가져온다.
//    ///
//    /// - parameter layerID: 가져올 RouteLayer ID
//    /// - returns: ID에 해당하는 routerLayer 객체. 없을경우 nil 리턴
//    @objc public func getRouteLayer(layerID: String) -> KakaoMapsSDK.RouteLayer?
//
//    /// KakaoMap에 추가한 RouteLayer를 제거한다.
//    ///
//    /// - parameter layerID: 제거할 layer ID
//    @objc public func removeRouteLayer(layerID: String)
//
//    /// RouteAnimator를 추가한다.
//    ///
//    /// RouteAnimator 객체는 사용자가 직접 생성할 수 없으며, Manager를 통해서만 생성 가능하다.
//    ///
//    /// - SeeAlso: RouteAnimator
//    /// - SeeAlso: RouteAnimationEffect
//    /// - parameters:
//    ///     - animatorID: 추가할 animatorID
//    ///     - effect: 애니메이션 효과 지정
//    /// - returns: 생성된 RouteAnimator
//    @objc public func addRouteAnimator(animatorID: String, effect: any KakaoMapsSDK.RouteAnimationEffect) -> KakaoMapsSDK.RouteAnimator?
//
//    /// 추가한 RouteAnimator를 삭제한다.
//    ///
//    /// - parameter animatorID: 삭제할 animator ID
//    @objc public func removeRouteAnimator(animatorID: String)
//
//    /// 추가한 모든 RouteAnimator를 제거한다.
//    @objc public func clearAllRouteAnimators()
//
//    /// 추가한 Animator를 가져온다.
//    ///
//    /// - parameter animatorID: animatorID
//    /// - returns: RouteAnimator
//    @objc public func getRouteAnimator(animatorID: String) -> KakaoMapsSDK.RouteAnimator?
//}
//
///// Route를 생성하기 위한 Route 생성 옵션 클래스.
//@objc open class RouteOptions : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - styleID: RouteStyleSet ID
//    ///     - zOrder: Route 렌더링 우선순위. 값이 클수록 위에 그려진다.
//    @objc public init(styleID: String, zOrder: Int)
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - routeID: Route 고유 ID
//    ///     - styleID: RouteStyleSet ID
//    ///     - zOrder: Route 렌더링 우선순위. 값이 클수록 위에 그려진다.
//    @objc public init(routeID: String, styleID: String, zOrder: Int)
//
//    /// Route ID. 생성시 별도로 지정하지 않는 경우, 내부적으로 id를 자동으로 부여한다.
//    @objc public var routeID: String? { get }
//
//    /// Route가 사용할 styleSet ID
//    @objc public var styleID: String { get }
//
//    /// Route 렌더링 우선순위
//    ///
//    /// 값이 클수록 위에 그려진다. 같은 Route끼리만 유효하다.
//    ///
//    /// 즉, zOrder = 0 인 Route는 zOrder = 1 인 Route보다 아래에 그려진다.
//    @objc public var zOrder: Int { get }
//
//    /// Route를 구성하는 RouteSegment 배열.
//    ///
//    /// Route는 하나 이상의 RouteSegment로 이루어진다. RouteSegment는 두개 이상의 정점으로 이루어지며, 각 Segment마다 StyleSet의 index를 부여하여 RouteSegment단위로 스타일을 다르게 표시할 수 있다.
//    ///
//    /// - SeeAlso: RouteSegment
//    @objc public var segments: [KakaoMapsSDK.RouteSegment]
//}
//
///// RoutePattern 클래스
/////
///// Route에 표시할 패턴을 정의하는 클래스.
//@objc open class RoutePattern : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - pattern: 사용할 패턴 이미지
//    ///     - distance: 패턴이 표시되는 간격
//    ///     - symbol: 반복적으로 그려지는 패턴 외에, 한번 표시되어 segment의 속성을 표현하는 심볼
//    ///     - pinStart: 패턴의 시작지점을 고정할지에 대한 여부
//    ///     - pinEnd: 패턴의 끝지점을 고정할지에 대한 여부
//    @objc public init(pattern: UIImage, distance: Float, symbol: UIImage?, pinStart: Bool, pinEnd: Bool)
//
//    /// 사용할 패턴 이미지
//    @objc public var pattern: UIImage? { get }
//
//    /// 패턴 이미지 외에 패턴의 속성을 표시할 심볼
//    @objc public var symbol: UIImage? { get }
//
//    /// 패턴이 표시되는 간격
//    @objc public var distance: Float { get }
//
//    /// 패턴이 시작지점에 고정적으로 그려지게 하는 여부
//    @objc public var pinStart: Bool { get }
//
//    /// 패턴이 끝지점에 고정적으로 그려지게 하는 여부 
//    @objc public var pinEnd: Bool { get }
//}
//
///// RoutePointInfo
//public struct RoutePointInfo {
//}
//
///// RouteProgressInfo
//public struct RouteProgressInfo {
//}
//
///// Route를 나타내는 RouteSegment 클래스.
/////
///// Route는 하나 이상의 segment로 구성되고, Segment는 두 개 이상의 라인 포인트로 이루어지며, 모든 라인 포인트를 순서대로 연결한 선으로 그려진다.
/////
///// 각 RouteSegment별로 다른 styleIndex를 적용하여 다르게 표시할 수 있다.
//@objc public class RouteSegment : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - points: Segment를 구성하는 라인 포인트 배열
//    ///     - styleIndex: Segment를 표시할 style의 인덱스
//    @objc public init(points: [KakaoMapsSDK.MapPoint], styleIndex: UInt)
//
//    /// 라인 포인트 배열
//    @objc public var points: [KakaoMapsSDK.MapPoint] { get }
//
//    /// segment를 표시할 스타일 인덱스
//    @objc public var styleIndex: UInt { get }
//}
//
///// RouteStyle 클래스.
/////
///// Route의 style을 지정하기 위해 사용한다. 한개 이상의 PerLevelRouteStyle 로 구성된다.
//@objc open class RouteStyle : NSObject {
//
//    /// initializer
//    ///
//    /// - parameter styles: RouteStyle을 구성할 단위레벨별 PerLevelRouteStyle 배열
//    @objc public init(styles: [KakaoMapsSDK.PerLevelRouteStyle])
//
//    /// 추가한 PerLevelRouteStyle 배열
//    @objc public var styles: [KakaoMapsSDK.PerLevelRouteStyle] { get }
//}
//
///// RouteStyleSet 클래스
/////
///// Route를 구성하는 여러개의 RouteSegment마다 다른 스타일을 적용하고자 할 때 사용한다. StyleSet에 추가한 스타일의 인덱스를 RouteSegment마다 지정할 수 있다.
/////
///// 또한 RouteSegment마다 사용하고자 하는 Route Pattern 또한 해당 클래스에서 추가 할 수 있다. 패턴도 style과 마찬가지로 인덱스로 지정할 수 있다.
//@objc open class RouteStyleSet : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameter styleID: StyleID
//    @objc public init(styleID: String)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - styleID: StyleSet ID
//    ///     - styles: RouteStyleSet을 구성할 RouteStyle 배열
//    @objc public convenience init(styleID: String, styles: [KakaoMapsSDK.RouteStyle])
//
//    /// styleSet에 추가할 LevelStyle을 추가한다.
//    ///
//    /// - SeeAlso: RouteStyle
//    /// - parameter style: 추가할 RouteStyle
//    @objc public func addStyle(_ style: KakaoMapsSDK.RouteStyle)
//
//    /// StyleSet에 RoutePattern을 추가한다.
//    ///
//    /// - SeeAlso: RoutePattern
//    /// - parameter pattern: 추가하고자 하는 패턴
//    @objc public func addPattern(_ pattern: KakaoMapsSDK.RoutePattern)
//
//    /// styleSet ID
//    @objc public var styleSetID: String { get }
//
//    /// 추가한 RouteStyle 배열
//    @objc public var styles: [KakaoMapsSDK.RouteStyle] { get }
//
//    /// 추가한 RoutePattern의 배열
//    @objc public var patterns: [KakaoMapsSDK.RoutePattern] { get }
//}
//
/////KakaoMapsSDK
/////
/////SDK 사용을 위한 초기화 클래스
//@objc public class SDKInitializer : NSObject {
//
//    /// 앱키 및 developer 사이트 phase를 지정하여 사용 인증할 준비를 한다.
//    ///
//    /// - parameters
//    ///    -   appKey : 앱키
//    ///    -   phase: phase
//    @objc public static func InitSDK(appKey: String, phase: KAPhase = .real)
//
//    @objc public static func GetPhase() -> KAPhase
//
//    /// AppKey
//    ///
//    /// - returns: appKey
//    @objc public static func GetAppKey() -> String
//
//    override dynamic public init()
//}
//
///// AnimationEffect중 Animation 시간동안 지정된 Keyframe 에 따라 회전 변환을 수행하는 애니메이션 효과.
/////
///// Poi에 적용할 수 있다.
//@objc public class ScaleAlphaAnimationEffect : KakaoMapsSDK.KeyFrameAnimationEffect {
//
//    /// Initializer
//    @objc dynamic public init()
//
//    /// 애니메이션 키프레임을 추가한다.
//    ///
//    ///  - parameter frame: 추가할 키프레임.
//    @objc public func addKeyframe(_ frame: KakaoMapsSDK.ScaleAlphaAnimationKeyFrame)
//}
//
///// ScaleAlphaAnimation 을 구성하기 위해 하나의 keyframe을 구성하기 위한 클래스
//@objc public class ScaleAlphaAnimationKeyFrame : KakaoMapsSDK.AnimationKeyFrame {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - scale: 확대변환 값. 1.0 기준 확대축소값.
//    ///     - alpha: 투명도 값 0.0 ~ 1.0
//    ///     - interpolation: 프레임 시간, 보간 방법.
//    @objc public init(scale: Vector2, alpha: Float, interpolation: AnimationInterpolation)
//
//    /// 투명도 값. 0.0~1.0
//    @objc public var alpha: Float
//
//    /// 확대축소변환. 1.0 기준 확대값.
//    @objc public var scale: Vector2
//}
//
///// AnimationEffect중 Animation 시간동안 지정된 Keyframe 에 따라 회전 변환을 수행하는 애니메이션 효과.
/////
///// Poi에 적용할 수 있다.
//@objc public class ScaleAnimationEffect : KakaoMapsSDK.KeyFrameAnimationEffect {
//
//    /// Initializer
//    @objc dynamic public init()
//
//    /// 애니메이션 키프레임을 추가한다.
//    ///
//    ///  - parameter frame: 추가할 키프레임.
//    @objc public func addKeyframe(_ frame: KakaoMapsSDK.ScaleAnimationKeyFrame)
//}
//
///// ScaleAnimation 을 구성하기 위해 하나의 keyframe을 구성하기 위한 클래스
//@objc public class ScaleAnimationKeyFrame : KakaoMapsSDK.AnimationKeyFrame {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - scale: 확대변환 값. 1.0 기준 확대축소값.
//    ///     - interpolation: 프레임 시간, 보간 방법.
//    @objc public init(scale: Vector2, interpolation: AnimationInterpolation)
//
//    /// 확대축소변환. 1.0 기준 확대값.
//    @objc public var scale: Vector2
//}
//
///// Shape protocol
//@objc public protocol Shape {
//
//    /// Shape 표출
//    @objc func show()
//
//    /// Shape 숨김
//    @objc func hide()
//
//    /// Shape ID
//    @objc var shapeID: String { get }
//
//    /// Shape이 속한 레이어 ID
//    @objc var layerID: String? { get }
//
//    /// Shape orientation
//    @objc var orientation: Double { get set }
//
//    /// Shape 표출 여부
//    @objc var isShow: Bool { get }
//
//    /// 사용자 객체
//    @objc var userObject: AnyObject? { get set }
//}
//
///// ShapeAnimation을 생성할 때 Animation Effect 종류를 정의하는 프로토콜.
//@objc public protocol ShapeAnimationEffect {
//
//    /// 애니메이션의 지속시간,  프레임간의 보간 방법등을 지정
//    @objc var interpolation: AnimationInterpolation { get set }
//
//    /// 애니메이션 종료시 대상 객체를 숨길지 여부를 지정.
//    @objc var hideAtStop: Bool { get set }
//
//    /// 애니메이션 재생 횟수.
//    @objc var playCount: UInt { get set }
//}
//
///// Shape에 애니메이션 효과를 주기 위한 Animator 클래스.
/////
///// Animator를 생성해서 애니메이션 효과를 주고자 하는 Shape를 Animator에 넣어서 animator를 동작시키는 방식이다.
/////
///// Animator는 사용자가 직접 생성할 수 없으며, ShapeManager를 통해서만 생성한 객체를 받아서 사용할 수 있다.
//@objc public class ShapeAnimator : NSObject, KakaoMapsSDK.Animator {
//
//    /// Animator를 동작시킨다.
//    ///
//    /// Animator에 추가된 Shape가 없으면 start함수는 동작하지 않는다. start를 호출한 이후에는 Animator에   Shape를 추가하거나 지울 수 없다.
//    ///
//    /// 추가하고자 하는 경우, stop을 호출하고 추가해야한다.
//    ///
//    /// start 호출 이후 애니메이션이 끝나면 Animator에 추가된 Shape는 비워지므로, 다시 start를 호출하려면 Shape를 추가해야한다.
//    ///
//    /// Shape Interface에 있는 이동/회전등의 동작은 Animator가 start되면 멈춘다.
//    public func start()
//
//    /// Animator의 동작을 멈춘다.
//    ///
//    /// stop이 호출되면 다시 애니메이션이 끝난것으로 간주되어 Animator에 속한 Shape는 모두 비워지므로, Animator를 다시 동작시키리면 다시 Shape를 Animator에 추가해야한다.
//    public func stop()
//
//    /// Animator 의 종료 콜백을 지정한다. Start 된 애니메이션이 종료되거나 stop이 호출되면 지정한 callback 이 호출된다. nil 로 지정해서 기존에 지정했던 callback을 제거할 수 있다. 기본값 nil.
//    ///
//    /// - parameter callback: Animator에 추가할 종료 콜백.
//    public func setStopCallback(_ callback: (((any KakaoMapsSDK.Animator)?) -> Void)?)
//
//    /// Animator에 MapPolygonShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 MapPolygonShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 MapPolygonShape를 추가할 수 없다.
//    ///
//    /// - parameter shape: Animator에 추가할 MapPolygonShape
//    @objc public func addMapPolygonShape(_ shape: KakaoMapsSDK.MapPolygonShape)
//
//    /// Animator에 여러개의 MapPolygonShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 MapPolygonShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 MapPolygonShape를 추가할 수 없다.
//    ///
//    /// - parameter shapes: Animator에 추가할 MapPolygonShape 배열
//    @objc public func addMapPolygonShapes(_ shapes: [KakaoMapsSDK.MapPolygonShape])
//
//    /// Animator에 PolygonShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 PolygonShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 PolygonShape를 추가할 수 없다.
//    ///
//    /// - parameter shape: Animator에 추가할 PolygonShape
//    @objc public func addPolygonShape(_ shape: KakaoMapsSDK.PolygonShape)
//
//    /// Animator에 여러개의 PolygonShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 PolygonShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 PolygonShape를 추가할 수 없다.
//    ///
//    /// - parameter shapes: Animator에 추가할 PolygonShape 배열
//    @objc public func addPolygonShapes(_ shapes: [KakaoMapsSDK.PolygonShape])
//
//    /// Animator에 MapPolylineShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 MapPolylineShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 MapPolylineShape를 추가할 수 없다.
//    ///
//    /// - parameter shape: Animator에 추가할 MapPolylineShape
//    @objc public func addMapPolylineShape(_ shape: KakaoMapsSDK.MapPolylineShape)
//
//    /// Animator에 여러개의 MapPolylineShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 MapPolylineShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 MapPolylineShape를 추가할 수 없다.
//    ///
//    /// - parameter shapes: Animator에 추가할 MapPolylineShape 배열
//    @objc public func addMapPolylineShapes(_ shapes: [KakaoMapsSDK.MapPolylineShape])
//
//    /// Animator에 PolylineShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 PolylineShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 PolylineShape를 추가할 수 없다.
//    ///
//    /// - parameter shape: Animator에 추가할 PolylineShape
//    @objc public func addPolylineShape(_ shape: KakaoMapsSDK.PolylineShape)
//
//    /// Animator에 여러개의 PolylineShape를 추가한다.
//    ///
//    /// 등록한 Animation에 동작시키고자 하는 PolylineShape를 추가한다. start()를 호출한 이후에는 애니메이션이 끝나기 전까지 PolylineShape를 추가할 수 없다.
//    ///
//    /// - parameter shapes: Animator에 추가할 PolylineShape 배열
//    @objc public func addPolylineShapes(_ shapes: [KakaoMapsSDK.PolylineShape])
//
//    /// Animator에 추가한 shape를 모두 지운다.
//    ///
//    /// start() 호출 이후에는 동작하지 않는다.
//    @objc public func clearAllShapes()
//
//    /// 추가한 animatorID
//    public var animatorID: String { get }
//
//    /// Animator 동작이 완료되고 나면 Animator에 추가된 폴리곤을 사라지게 할 지에 대한 여부
//    @objc public var hideAtStop: Bool
//
//    /// Animator 시작 여부
//    public var isStart: Bool { get }
//}
//
///// Shape를 관리하는 단위인 ShapeLayer 클래스.
/////
///// Shape를 추가/삭제 등 관리할 수 있으며, 일종의 그룹처럼 관리가 가능하다.
/////
///// 사용자가 직접 객체를 생성할 수 없으며, LabelManager를 통해 객체를 간접적으로 생성할 수 있다.
//@objc open class ShapeLayer : NSObject {
//
//    /// ShapeLayer의 visible 상태.
//    ///
//    /// layer의 on/off 상태를 나타내며, layer에 속한 객체의 show/hide는 별도로 동작시켜야한다.
//    ///
//    /// 즉, layer의 visible이 true여도 layer에 속한 객체의 show를 호출해야 보이고, visible이 false라면 layer에 속한 객체는 화면에 표시되지 않는다.
//    @objc public var visible: Bool
//
//    /// 현재 레이어에 속한 모든 PolygonShape, MapPolygonShape를 표시한다.
//    @objc public func showAllPolygonShapes()
//
//    /// 현재 레이어에 속한 모든 PolygonShape, MapPolygonShape를 숨긴다.
//    @objc public func hideAllPolygonShapes()
//
//    /// 현재 레이어에 속한 모든 PolylineShape, MapPolylineShape를 표시한다.
//    @objc public func showAllPolylineShapes()
//
//    /// 현재 레이어에 속한 모든 PolylineShape, MapPolylineShape를 숨긴다..
//    @objc public func hideAllPolylineShapes()
//
//    /// 현재 레이어에 속한 모든 Shape를 표시한다.
//    @objc public func showAllShapes()
//
//    /// 현재 레이어에 속한 모든 Shape를 숨긴다.
//    @objc public func hideAllShapes()
//
//    /// 현재 layer에 있는 모든 item을 일괄적으로 지운다.
//    @objc public func clearAllShapes()
//
//    /// 현재 Layer에 MapPolygonShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 nil을 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 MapPolygonShape 옵션
//    ///     - callback: MapPolygonShape객체가 생성이 완료됐을 때 호출할 콜백함수(optional)
//    /// - returns: 생성된 MapPolygonShape 객체
//    @objc public func addMapPolygonShape(_ shapeOptions: KakaoMapsSDK.MapPolygonShapeOptions, callback: ((KakaoMapsSDK.MapPolygonShape?) -> Void)? = nil) -> KakaoMapsSDK.MapPolygonShape?
//
//    /// 현재 Layer에 다수의 MapPolygonShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 MapPolygonShape 옵션 배열
//    ///     - callback: 생성한 다수의 MapPolygonShape가 모두 생성이 완료되었을 때, 호출할 콜백함수(optional)
//    /// - returns: 생성된 MapPolygonShape 객체 배열
//    @objc public func addMapPolygonShapes(_ shapeOptions: [KakaoMapsSDK.MapPolygonShapeOptions], callback: (([KakaoMapsSDK.MapPolygonShape]?) -> Void)? = nil) -> [KakaoMapsSDK.MapPolygonShape]?
//
//    /// 현재 Layer에서 특정 MapPolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: Layer에서 제거할 MapPolygonShape Id
//    ///     - callback : Layer에서 해당 Shape제거가 완료되었을 때, 호출할 콜백함수(optional)
//    @objc public func removeMapPolygonShape(shapeID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에서 다수의 MapPolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: Layer에서 제거할 MapPolygonShape Id 배열
//    ///     - callback: Layer에서 id에 해당하는 모든 shape제거가 완료되었을 때, 호출할 콜백함수(optional)
//    @objc public func removeMapPolygonShapes(shapeIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속한 특정 MapPolygonShape를 보여준다.
//    ///
//    /// - parameter shapeIDs: 보여줄 MapPolygonShape ID 배열
//    @objc public func showMapPolygonShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 특정 MapPolygonShape를 숨긴다.
//    ///
//    /// - parameter shapeIDs: 숨길 MapPolygonShape ID 배열
//    @objc public func hideMapPolygonShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 MapPolygonShape를 가져온다.
//    ///
//    /// - parameter shapeID: 가져올 MapPolygonShape ID
//    /// - returns: ID에 해당하는 MapPolygonShape 객체, 없을경우 nil.
//    @objc public func getMapPolygonShape(shapeID: String) -> KakaoMapsSDK.MapPolygonShape?
//
//    /// 현재 Layer에 속한 다수의 MapPolygonShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 MapPolygonShape ID 배열
//    /// - returns: ID에 해당하는 MapPolygonShape 객체 배열, 없을경우 nil.
//    @objc public func getMapPolygonShapes(shapeIDs: [String]) -> [KakaoMapsSDK.MapPolygonShape]?
//
//    /// 현재 Layer에 속한 모든 MapPolygonShape를 가져온다.
//    ///
//    /// - returns: 현재 Layer에 추가된 MapPolygonShape 배열
//    @objc public func getAllMapPolygonShapes() -> [KakaoMapsSDK.MapPolygonShape]?
//
//    /// 현재 Layer에 PolygonShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 PolygonShape 옵션
//    ///     - callback: PolygonShape객체가 생성이 완료됐을 때 호출할 콜백함수(optional)
//    /// - returns: 생성된 PolygonShape 객체
//    @objc public func addPolygonShape(_ shapeOptions: KakaoMapsSDK.PolygonShapeOptions, callback: ((KakaoMapsSDK.PolygonShape?) -> Void)? = nil) -> KakaoMapsSDK.PolygonShape?
//
//    /// 현재 Layer에 다수의 PolygonShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 PolygonShape 옵션 배열
//    ///     - callback: PolygonShape객체가 생성이 완료됐을 때 호출할 콜백함수(optional)
//    /// - returns: 생성된 Shape 객체 배열
//    @objc public func addPolygonShapes(_ shapeOptions: [KakaoMapsSDK.PolygonShapeOptions], callback: (([KakaoMapsSDK.PolygonShape]?) -> Void)? = nil) -> [KakaoMapsSDK.PolygonShape]?
//
//    /// 현재 Layer에서 특정 PolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: Layer에서 제거할 PolygonShape Id
//    ///     - callback: Layer에서 해당 Shape제거가 완료되었을 때, 호출할 콜백함수(optional)
//    @objc public func removePolygonShape(shapeID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에서 다수의 PolygonShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: Layer에서 제거할 PolygonShape Id 배열
//    ///     - callback: Layer에서 id에 해당하는 모든 shape제거가 완료되었을 때, 호출할 콜백함수(optional)
//    @objc public func removePolygonShapes(shapeIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속한 특정 PolygonShape를 보여준다.
//    ///
//    /// - parameter shapeIDs: 보여줄 PolygonShape ID 배열
//    @objc public func showPolygonShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 특정 PolygonShape를 숨긴다.
//    ///
//    /// - parameter shapeIDs: 숨길 PolygonShape ID 배열
//    @objc public func hidePolygonShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 PolygonShape를 가져온다.
//    ///
//    /// - parameter shapeID: 가져올 PolygonShape ID
//    /// - returns: ID에 해당하는 PolygonShape 객체, 없을경우 nil.
//    @objc public func getPolygonShape(shapeID: String) -> KakaoMapsSDK.PolygonShape?
//
//    /// 현재 Layer에 속한 다수의 PolygonShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 PolygonShape ID 배열
//    /// - returns: ID에 해당하는 PolygonShape 객체 배열, 없을경우 nil.
//    @objc public func getPolygonShapes(shapeIDs: [String]) -> [KakaoMapsSDK.PolygonShape]?
//
//    /// 현재 Layer에 속한 모든 PolygonShape를 가져온다.
//    ///
//    /// - returns: 현재 Layer에 추가된 PolygonShape 배열
//    @objc public func getAllPolygonShapes() -> [KakaoMapsSDK.PolygonShape]?
//
//    /// 현재 Layer에 MapPolylineShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 MapPolylineShape 옵션
//    ///     - callback: 생성한 MapPolylineShape 생성이 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성된 MapPolylineShape 객체
//    @objc public func addMapPolylineShape(_ shapeOptions: KakaoMapsSDK.MapPolylineShapeOptions, callback: ((KakaoMapsSDK.MapPolylineShape?) -> Void)? = nil) -> KakaoMapsSDK.MapPolylineShape?
//
//    /// 현재 Layer에 다수의 MapPolylineShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 MapPolylineShape 옵션
//    ///     - callback: 생성한 MapPolylineShape 생성이 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성된 MapPolylineShape객체 배열
//    @objc public func addMapPolylineShapes(_ shapeOptions: [KakaoMapsSDK.MapPolylineShapeOptions], callback: (([KakaoMapsSDK.MapPolylineShape]?) -> Void)? = nil) -> [KakaoMapsSDK.MapPolylineShape]?
//
//    /// 현재 Layer에서 특정 MapPolylineShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeID: Layer에서 제거할 MapPolylineShape ID
//    ///     - callback: Layer에서 지정한 MapPolylineShape가 지워졌을 때, 호출할 callback(optional)
//    @objc public func removeMapPolylineShape(shapeID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에서 다수의 MapPolylineShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeIDs: Layer에서 제거할 MapPolylineShape ID 배열
//    ///     - callback: Layer에서 지정한 MapPolylineShape가 모두 지워졌을 때, 호출할 callback(optional)
//    @objc public func removeMapPolylineShapes(shapeIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속한 특정 MapPolylineShape를 보여준다.
//    ///
//    /// - parameter shapeIDs: 보여줄 MapPolylineShape ID 배열
//    @objc public func showMapPolylineShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 특정 MapPolylineShape를 숨긴다.
//    ///
//    /// - parameter shapeIDs: 숨길 MapPolylineShape ID 배열
//    @objc public func hideMapPolylineShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 MapPolylineShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 MapPolylineShape
//    /// - returns: ID에 해당하는 MapPolylineShape 객체. 없을 경우 nil
//    @objc public func getMapPolylineShape(shapeID: String) -> KakaoMapsSDK.MapPolylineShape?
//
//    /// 현재 Layer에 속한 다수의 MapPolylineShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 MapPolylineShape ID
//    /// - returns: ID에 해당하는 MapPolylineShape 객체. 없을 경우 nil
//    @objc public func getMapPolylineShapes(shapeIDs: [String]) -> [KakaoMapsSDK.MapPolylineShape]?
//
//    /// 현재 Layer에 속한 모든 MapPolylineShape를 가져온다.
//    ///
//    /// - returns: 현재 Layer에 추가되어있는 모든 MapPolylineShape 객체 배열
//    @objc public func getAllMapPolylineShapes() -> [KakaoMapsSDK.MapPolylineShape]?
//
//    /// 현재 Layer에 PolylineShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 PolylineShape 옵션
//    ///     - callback: 생성한 MapPolylineShape 생성이 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성된 PolylineShape 객체
//    @objc public func addPolylineShape(_ shapeOptions: KakaoMapsSDK.PolylineShapeOptions, callback: ((KakaoMapsSDK.PolylineShape?) -> Void)? = nil) -> KakaoMapsSDK.PolylineShape?
//
//    /// 현재 Layer에 다수의 PolylineShape를 추가한다.
//    ///
//    /// 하나의 레이어 안에 중복 ID로 추가할 수 없으며, 기존에 같은 아이디가 존재할 경우 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - shapeOptions: 생성할 PolylineShape 옵션
//    ///     - callback: 생성한 MapPolylineShape 생성이 완료되었을 때, 호출할 callback(optional)
//    /// - returns: 생성된 PolylineShape 객체 배열
//    @objc public func addPolylineShapes(_ shapeOptions: [KakaoMapsSDK.PolylineShapeOptions], callback: (([KakaoMapsSDK.PolylineShape]?) -> Void)? = nil) -> [KakaoMapsSDK.PolylineShape]?
//
//    /// 현재 Layer에서 특정 PolylineShape를 지운다.
//    ///
//    /// - parameter shapeID: Layer에서 제거할 PolylineShape ID
//    @objc public func removePolylineShape(shapeID: String, callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에서 다수의 PolylineShape를 지운다.
//    ///
//    /// - parameters:
//    ///     - shapeIDs: Layer에서 제거할 PolylineShape ID 배열
//    ///     - callback: Layer에서 지정한 PolylineShape가 모두 지워졌을 때, 호출할 callback(optional)
//    @objc public func removePolylineShapes(shapeIDs: [String], callback: (() -> Void)? = nil)
//
//    /// 현재 Layer에 속한 특정 PolylineShape를 보여준다.
//    ///
//    /// - parameter shapeIDs: 보여줄 PolylineShape ID 배열
//    @objc public func showPolylineShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 특정 PolylineShape를 숨긴다.
//    ///
//    /// - parameter shapeIDs: 숨길 PolylineShape ID 배열
//    @objc public func hidePolylineShapes(shapeIDs: [String])
//
//    /// 현재 Layer에 속한 PolylineShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 PolylineShapeID
//    /// - returns: ID에 해당하는 PolylineShape 객체. 없을 경우 nil
//    @objc public func getPolylineShape(shapeID: String) -> KakaoMapsSDK.PolylineShape?
//
//    /// 현재 Layer에 속한 다수의 PolylineShape를 가져온다.
//    ///
//    /// - parameter shapeIDs: 가져올 PolylineShapeID
//    /// - returns: ID에 해당하는 PolylineShape 객체. 없을 경우 nil
//    @objc public func getPolylineShapes(shapeIDs: [String]) -> [KakaoMapsSDK.PolylineShape]?
//
//    /// 현재 Layer에 속한 모든 PolylineShape를 가져온다.
//    ///
//    /// - returns: 현재 Layer에 추가되어있는 모든 PolylineShape 객체 배열
//    @objc public func getAllPolylineShapes() -> [KakaoMapsSDK.PolylineShape]
//
//    /// ShapeLayer의 ID
//    @objc public var layerID: String { get }
//
//    /// ShapeLayer의 렌더링 우선순위.
//    ///
//    /// 높은 zOrder의 Layer에 속한 Shape가 더 위에 그려지며, ShapeLayer type끼리만 유효하다.
//    ///
//    /// 즉, zOrder = 0 인 ShapeLayer에 속한 Shape는 zOrder = 1 인 ShapeLayer에 속한 Shape보다 아래에 그려진다.
//    @objc public var zOrder: Int { get }
//}
//
///// KakaoMap에서 사용자 shape를 사용하고 관리하기 위한 클래스
/////
///// ShapeLayer의 추가/삭제 등의 관리와 shape의 style, animator추가가 가능하다.
/////
///// KakaoMap에 종속적이므로 KakaoMap이 삭제된 뒤에도 사용하지 않도록 주의하여야 한다.
//@objc public class ShapeManager : NSObject {
//
//    /// PolygonStyleSet을 추가한다.
//    ///
//    /// PolygonShape의 Polygon이 여러개인 경우, Polygon마다 다른 스타일을 설정할 수 있다. 같은 styleID로 추가하더라도 overwrite되지 않는다.
//    ///
//    /// - SeeAlso: PolygonStyleSet
//    /// - parameter styles: 추가할 PolygonStyleSet
//    @objc open func addPolygonStyleSet(_ styles: KakaoMapsSDK.PolygonStyleSet)
//
//    /// PolylineStyleSet을 추가한다.
//    ///
//    /// PolylineShape의 Polyline이 여러개인 경우, Polyline마다 다른 스타일을 설정할 수 있다. 같은 styleID로 추가하더라도 overwrite되지 않는다.
//    ///
//    /// - SeeAlso: PolylineStyleSet
//    /// - parameter styles: 추가할 PolylineStyleSet
//    @objc open func addPolylineStyleSet(_ styles: KakaoMapsSDK.PolylineStyleSet)
//
//    /// ShapeLayer를 추가한다.
//    ///
//    /// Shape를 관리할 수 있는 단위인 ShapeLayer를 추가한다. 이미 KakaoMap에 추가되어있는 ID와 동일한 layer를 추가하고자 하는 경우, 기존 객체를 리턴한다.
//    ///
//    /// - parameters:
//    ///     - layerID: 추가할 shapeLayerID
//    ///     - zOrder: layer의 렌더링 우선순위. 높을수록 위에 그려진다.
//    ///     - passType: ShapeLayer의 passType. 해당 레이어에 추가한 Shape가 그려지는 순서를 지정할 수 있다.
//    /// - returns: 생성한 ShapeLayer 객체
//    /// - SeeAlso: ShapeLayerPassType
//    @objc open func addShapeLayer(layerID: String, zOrder: Int, passType: ShapeLayerPassType = .default) -> KakaoMapsSDK.ShapeLayer?
//
//    /// KakaoMap에 추가한 ShapeLayer를 가져온다.
//    ///
//    /// - parameter layerID: 가져올 shapeLayerID
//    /// - returns: ID에 해당하는 shapeLayer객체. 없을경우 nil 리턴
//    @objc open func getShapeLayer(layerID: String) -> KakaoMapsSDK.ShapeLayer?
//
//    /// KakaoMap에 추가한 ShaeLayer를 제거한다.
//    ///
//    /// - parameter layerID: 제거할 layer의 ID
//    @objc open func removeShapeLayer(layerID: String)
//
//    /// ShapeAnimator를 추가한다.
//    ///
//    /// ShapeAnimator 객체는 사용자가 직접 생성할 수 없으며, Manager를 통해서만 생성이 가능하다. 이미 존재하는 AnimatorID로는 overwrite되지 않는다.
//    ///
//    /// - SeeAlso: AnimationInterpolation
//    /// - SeeAlso: WaveAnimationEffect
//    /// - parameters:
//    ///     - animatorID: ShapeAnimator ID
//    ///     - effect: ShapeAnimationEffect type의 애니메이션 효과 지정
//    /// - returns: 생성된 Animator 객체
//    @objc public func addShapeAnimator(animatorID: String, effect: any KakaoMapsSDK.ShapeAnimationEffect) -> KakaoMapsSDK.ShapeAnimator?
//
//    /// 추가한 ShapeAnimator 객체를 제거한다.
//    ///
//    /// - parameter animatorID: 제거할 animatorID
//    @objc public func removeShapeAnimator(animatorID: String)
//
//    /// 추가되어있는 모든 ShapeAnimaotr를 제거한다.
//    @objc public func clearAllShapeAnimators()
//
//    /// 추가한 ShapeAnimator 객체를 가져온다.
//    ///
//    /// - parameter animatorID: 가져올 AnimatorID
//    /// - returns: animatorID에 해당하는 ShapeAnimator 객체. 존재하지 않을 경우 nil 리턴
//    @objc public func getShapeAnimator(animatorID: String) -> KakaoMapsSDK.ShapeAnimator?
//}
//
///// SpriteGui Class
/////
///// 기본적으로 main layout을 가지고 있으며, mainLayout에 GuiComponent를 활용하여 원하는 GUI를 구성한다.
//@objc open class SpriteGui : KakaoMapsSDK.GuiBase {
//
//    /// initializer
//    ///
//    /// SpriteGui 생성시 별도로 지정하지 않으면 default layout은 vertical layout으로 지정된다.
//    ///
//    /// - parameter name: Gui 이름
//    @objc public init(_ name: String)
//
//    /// mainLayout에 Child component를 추가한다.
//    ///
//    /// - parameter component: GuiComponent
//    @objc public func addChild(_ component: KakaoMapsSDK.GuiComponentBase)
//
//    /// mainLayout에 추가된 component 중 하나를 가져온다.
//    ///
//    /// - parameter componentId: GuiComponent Id
//    /// - returns: Id에 해당하는 GuiComponent. 없을경우 nil
//    override public func getChild(_ componentId: String) -> KakaoMapsSDK.GuiComponentBase?
//
//    /// mainLayout의 childComponent 배치 방향. Vertical 혹은 Horizontal
//    @objc public var arrangement: LayoutArrangement
//
//    /// main Layout에 Gui 컴포넌트의 구분선 표시 여부
//    @objc public var showSplitLine: Bool
//
//    /// main Layout에 Gui 컴포넌트의 구분선 컬러
//    @objc public var splitLineColor: UIColor
//
//    /// main Layout에 Gui 컴포넌트의 구분선 두께
//    @objc public var splitLineWidth: Int
//
//    /// mainLayout의 배경 컬러
//    @objc public var bgColor: UIColor
//
//    /// Gui의 main layout
//    @objc public var main: KakaoMapsSDK.GuiLayout { get }
//
//    /// Gui가 그려질 origin을 지정한다. 이 origin을 기준점으로 position이 적용된다.
//    ///
//    /// 값을 세팅하면, 별도의 updateGui() 호출 없이도 바로 반영된다.
//    @objc open var origin: GuiAlignment
//
//    /// origin으로 부터의 Position을 지정한다.
//    ///
//    /// 값을 세팅하면, 별도의 updateGui() 호출 없이도 바로 반영된다.
//    @objc open var position: CGPoint
//
//    /// SpriteGu를 회전시킬 orientation 값
//    ///
//    /// 값을 세팅하면, 별도의 updateGui() 호출 없이도 바로 반영된다.
//    @objc open var orientation: Double
//}
//
///// SpriteGuiLayer - 화면상에 고정되는 형태의 GUI 들을 담는 Layer
//@objc open class SpriteGuiLayer : NSObject {
//
//    /// SpriteGuiLayer의 visible 상태.
//    ///
//    /// layer의 on/off 상태를 나타내며, layer에 속한 객체의 show/hide는 별도로 동작시켜야한다.
//    ///
//    /// 즉, layer의 visible이 true여도 layer에 속한 객체의 show를 호출해야 보이고, visible이 false라면 layer에 속한 객체는 화면에 표시되지 않는다.
//    @objc public var visible: Bool
//
//    /// 추가한 모든 SpriteGui를 지운다.
//    @objc public func clear()
//
//    /// SpriteGui를 현재 레이어에 추가한다.
//    ///
//    /// SpriteGui를 레이어에 추가하기 전까지는 화면에 표시되지 않는다.
//    ///
//    /// 같은 이름으로 중복으로 추가할 수 없다.
//    ///
//    /// - parameter gui: 추가할 SpriteGui 객체
//    @objc public func addSpriteGui(_ gui: KakaoMapsSDK.SpriteGui)
//
//    /// SpriteGui를 현재 레이어에서 제거한다.
//    ///
//    /// - parameter gui: 제거할 SpriteGui 객체
//    @objc public func removeSpriteGui(_ gui: KakaoMapsSDK.SpriteGui)
//
//    /// guiName을 Key로 갖는 SpriteGui를 현재 레이어에서 제거한다.
//    ///
//    /// - parameter guiName: 제거할 SpriteGui의 guiName
//    @objc public func removeSpriteGui(guiName: String)
//
//    /// SpriteGuiLayer에 추가되어있는 SpriteGui를 guiName을 Key로 가져온다.
//    ///
//    /// - parameter guiName: 가져올 SpriteGui의 guiName
//    /// - returns: 이름에 해당하는 SpriteGui. 없을경우 nil
//    @objc public func getSpriteGui(guiName: String) -> KakaoMapsSDK.SpriteGui?
//
//    /// SpriteGuiLayer에 특정 guiName을 가진 SpriteGui가 존재하는지 체크한다.
//    ///
//    /// - parameter guiName: 추가되어있는지 확인할 SpriteGui guiName
//    /// - returns: 존재 여부. 이미 추가되어있는 guiName의 경우 true, 아니면 false를 리턴한다.
//    @objc public func isSpriteGuiExist(guiName: String) -> Bool
//
//    /// SpriteGuiLayer에 추가한 모든 SpriteGui를 가져온다.
//    ///
//    /// - returns: 추가된 모든 SpriteGui 객체 배열
//    @objc public func getAllSpriteGuis() -> [KakaoMapsSDK.SpriteGui]?
//}
//
///// Terrain layer 이벤트 파라미터 구조체.
//public struct TerrainInteractionEventParam {
//
//    /// KakaoMap
//    public let kakaoMap: KakaoMapsSDK.KakaoMap
//
//    /// 클릭 위치
//    public let position: KakaoMapsSDK.MapPoint
//}
//
///// 글씨 색, 외곽선 색, 폰트 크기, 외곽선 두께 등의 스타일 속성을 지정하는 클래스.
//@objc open class TextStyle : NSObject {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - fontSize: font 크기
//    ///     - fontColor: font 컬러
//    ///     - strokeThickness: font 외곽선 두께
//    ///     - strokeColor: font 외곽선 색깔
//    ///     - font: 사용할 font 이름
//    ///     - charSpace: 자간. 0~4 사이값을 권장
//    ///     - lineSpace: 행간
//    ///     - aspectRatio : 장평
//    @objc public init(fontSize: UInt = 20, fontColor: UIColor = UIColor.black, strokeThickness: UInt = 2, strokeColor: UIColor = UIColor.white, font: String = "", charSpace: Int = 0, lineSpace: Float = 1.0, aspectRatio: Float = 1.0)
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - fontSize: font 크기
//    ///     - fontColor: font 컬러
//    @objc public convenience init(fontSize: UInt, fontColor: UIColor)
//
//    /// 글씨의 색
//    @objc open var fontColor: UIColor { get }
//
//    /// 글씨 외곽선 색
//    @objc open var strokeColor: UIColor { get }
//
//    /// 글씨 크기
//    @objc open var fontSize: UInt { get }
//
//    /// 글씨 외곽선의 두께
//    @objc open var strokeThickness: UInt { get }
//
//    /// 폰트
//    @objc open var font: String { get }
//
//    /// 자간
//    @objc open var charSpace: Int { get }
//
//    /// 행간
//    @objc open var lineSpace: Float { get }
//
//    /// 장평
//    @objc open var aspectRatio: Float { get }
//}
//
///// KakaoMap 오브젝트의 tracking을 관리하는 클래스
/////
///// 설정한 오브젝트의 position, orientation을 카메라가 따라간다.
/////
///// 한번에 하나의 객체만 tracking 가능하며, tracking중에 다른 객체를 tracking하고자 할 경우 stop을 호출해야 다른 객체를 tracking 할 수 있다.
//@objc public class TrackingManager : NSObject {
//
//    /// 지정한 poi의 tracking을 시작한다.
//    ///
//    /// - parameter poi: tracking하고자하는 poi 객체
//    @objc public func startTrackingPoi(_ poi: KakaoMapsSDK.Poi)
//
//    /// 현재 tracking하고 있는 객체의 tracking을 멈춘다.
//    @objc public func stopTracking()
//
//    /// 지정한 객체의 tracking을 위치만 추적할것인지,  객체 회전값도 추적할것인지를 지정한다.
//    ///
//    /// 기본적으로 위치만 추적하며 true로 설정할 경우 객체의 회전값도 카메라가 tracking한다.
//    @objc public var isTrackingRoll: Bool
//
//    /// 현재 tracking mode인지에 대한 여부.
//    ///
//    /// 특정 obejct를 tracking하여 position및 orientation을 카메라가 따라가는중일경우, true 리턴.
//    ///
//    /// 한번에 하나의 객체만 tracking할 수 있으므로 해당 값이 true일 경우 또 다른 객체를 트래킹 할 수 없다.
//    @objc public var isTracking: Bool { get }
//}
//
///// AnimationEffect중 Animation 시간동안 지정된 Keyframe 에 따라 이동, 회전, 확대 변환을 수행하는 애니메이션 효과.
/////
///// Poi에 적용할 수 있다.
//@objc public class TransformAnimationEffect : KakaoMapsSDK.KeyFrameAnimationEffect {
//
//    /// Initializer
//    @objc dynamic public init()
//
//    /// 애니메이션 키프레임을 추가한다.
//    ///
//    ///  - parameter frame: 추가할 키프레임.
//    @objc public func addKeyframe(_ frame: KakaoMapsSDK.TransformAnimationKeyFrame)
//}
//
///// TransformAnimation 을 구성하기 위해 하나의 keyframe을 구성하기 위한 클래스
///// 회전, 확대축소, 이동 변환 및 투명도 값으로 구성된다.
//@objc public class TransformAnimationKeyFrame : KakaoMapsSDK.AnimationKeyFrame {
//
//    /// Initializer
//    ///
//    /// - parameters:
//    ///     - translation: 이동할 픽셀단위값. 화면 scale 값이 곱해져서 적용됨.
//    ///     - rotation: 회전 변환값. 시계 방향 radian 값.
//    ///     - scale: 확대변환 값. 1.0 기준 확대축소값.
//    ///     - alpha: 투명도 값. 0.0~1.0
//    ///     - interpolation: 프레임 시간, 보간 방법.
//    @objc public init(translation: Vector2, rotation: Float, scale: Vector2, alpha: Float, interpolation: AnimationInterpolation)
//
//    /// 회전변환, 시계 방향 radian 값.
//    @objc public var rotation: Float
//
//    /// 확대축소변환. 1.0 기준 확대값.
//    @objc public var scale: Vector2
//
//    /// 픽셀 이동변환. 이동할 픽셀단위값. 화면 scale 값이 곱해져서 적용됨.
//    @objc public var translation: Vector2
//
//    /// 투명도 값. 0.0~1.0
//    @objc public var alpha: Float
//}
//
///// API의 뷰 클래스들의 베이스 클래스
//@objc open class ViewBase : NSObject, NativeEventDelegate {
//
//    /// 뷰의 이름을 가져온다.
//    ///
//    /// - returns: 뷰의 이름
//    @objc open func viewName() -> String
//
//    /// 뷰의 위치 및 크기.
//    ///
//    /// viewRect를 지정하면, view의 위치 및 크기가 업데이트된다. 
//    @objc open var viewRect: CGRect
//
//    ///
//    /// 생성한 View의 타입을 가져온다.
//    @objc open var mapType: MapType { get }
//
//    /// 제스쳐 동작 활성화 상태를 지정한다.
//    ///
//    /// - parameter type: 제스쳐 동작 종류.
//    /// - parameter enable: 활성화 상태
//    @objc open func setGestureEnable(type gestureType: GestureType, enable: Bool)
//}
//
///// API에서 보여줄 View의 이름과 종류, 사용할 설정을 지정한다.
/////
///// View를 어떻게 보여줄지에 대한 세부 설정은 config file로 컨피그 서버에 저장되어 있다.
//@objc public class ViewInfo : NSObject {
//
//    /// ViewInfo의 종류.
//    @objc public var viewInfoType: ViewInfoType { get }
//
//    /// Cocoa에 등록된 app 이름.
//    @objc public var appName: String { get }
//
//    /// View의 이름.
//    @objc public var viewName: String { get }
//
//    /// 사용할 viewInfo의 이름. ex)'map'
//    @objc public var viewInfoName: String { get }
//
//    /// 초기 활성화 여부
//    @objc public var enabledInitially: Bool { get }
//}
//
///// 뷰 이벤트 파라미터 구조체.
//public struct ViewInteractionEventParam {
//
//    /// View
//    public let view: KakaoMapsSDK.ViewBase
//
//    /// 클릭 위치.
//    public let point: CGPoint
//}
//
///// WaveAnimation에서 레벨별로 정의되는 속성.
//@objc public class WaveAnimationData : NSObject {
//
//    /// Initializer
//    ///  - parameters
//    ///     - startAlpha: 애니메이션이 시작할 때 Shape의 알파값
//    ///     - endAlpha: 애니메이션이 끝날 때 Shape의 알파값
//    ///     - startRadius: 애니메이션이 시작할때 Shape의 스케일 값(px)
//    ///     - endRadius: 애니메이션이 끝날 때 Shape의 스케일 값(px)
//    ///     - level: 애니메이션이 적용될 레벨
//    @objc public init(startAlpha: Float, endAlpha: Float, startRadius: Float, endRadius: Float, level: Int)
//
//    /// 애니메이션이 시작될때의 알파값
//    @objc public var startAlpha: Float { get }
//
//    /// 애니메이션이 끝날때의 알파값
//    @objc public var endAlpha: Float { get }
//
//    /// 애니메이션이 시작될때의 스케일
//    @objc public var startRadius: Float { get }
//
//    /// 애니메이션이 끝날때의 스케일
//    @objc public var endRadius: Float { get }
//
//    /// 애니메이션 적용 레벨
//    @objc public var level: Int { get }
//}
//
///// ShapeAnimationEffect중 Animation시간 동안 알파값과 크기(scale)을 변경하는 애니메이션 효과 클래스.
/////
///// 레벨별로 시작/끝 알파값과 크기를 다르게 정의할 수 있다.
//@objc public class WaveAnimationEffect : NSObject, KakaoMapsSDK.ShapeAnimationEffect {
//
//    /// Initializer
//    override dynamic public init()
//
//    /// Initializer
//    /// - parameters:
//    ///     -  datas: WaveAnimationData 의 배열
//    @objc public init(datas: [KakaoMapsSDK.WaveAnimationData])
//
//    /// WaveAnimation을 레벨별로 정의한다.
//    ///
//    /// 레벨별로 애니메이션이 시작할 때, 끝날때의 알파값과 스케일(px)을 지정할 수 있다.
//    ///
//    /// 정의에 따라 애니메이션 시간 동안 Shape의  Fade In/Out과 확대/축소 등을 정의할 수 있다.
//    ///
//    /// - parameters:
//    ///     - startAlpha: 애니메이션이 시작할 때 Shape의 알파값
//    ///     - endAlpha: 애니메이션이 끝날 때 Shape의 알파값
//    ///     - startRadius: 애니메이션이 시작할때 Shape의 스케일 값(px)
//    ///     - endRadius: 애니메이션이 끝날 때 Shape의 스케일 값(px)
//    ///     - level: 애니메이션이 적용될 레벨
//    @objc public func addAnimationData(startAlpha: Float, endAlpha: Float, startRadius: Float, endRadius: Float, level: Int)
//
//    /// 정의한 WaveAnimation Data
//    @objc public var datas: [KakaoMapsSDK.WaveAnimationData] { get }
//
//    /// 애니메이션 지속 시간, 보간방법  지정
//    public var interpolation: AnimationInterpolation
//
//    /// 애니메이션 재생 횟수.
//    public var playCount: UInt
//
//    /// 애니메이션 종료 시 애니메이터에 속한 객체들을 숨길지에 대한 여부.
//    ///
//    /// true로 설정하면 애니메이션이 종료되면 객체들이 화면에서 자동으로 사라진다.
//    public var hideAtStop: Bool
//}
//
///// WaveText class
/////
///// 지도상에 흐르는 글씨를 표현하기 위한 클래스. Poi는 한 점을 표시하기 위해 사용되고, WaveText는 지도상에 여러개의 점을 표시하기 위해 사용한다.
/////
///// WaveText를 지도상에 추가하기 위해서는 먼저  KakaoMap에 LabelLayer를 추가한 뒤, 해당 Layer에 WaveText를 추가할 수 있다.
/////
///// WaveText 객체는 사용자가 직접 생성할 수 없으며, WaveTextOptions Class를 이용하여 Layer에 추가하면 해당 Object를 얻을 수 있다.
//@objc open class WaveText : NSObject, KakaoMapsSDK.Label {
//
//    /// WaveText를 보여준다.
//    public func show()
//
//    /// WaveText를 숨긴다.
//    public func hide()
//
//    /// WaveText의 Style을 바꾼다.
//    ///
//    /// LabelManager에 등록한 WaveTextStyle의 키를 이용하여 Style을 변경한다.
//    ///
//    /// - parameters:
//    ///     - styleID: 변경할 Style의 ID
//    ///     - enableTransition: 스타일 변경시 transition효과 적용 여부.
//    public func changeStyle(styleID: String, enableTransition: Bool = false)
//
//    /// WaveText의 text와 Data를 바꾼다.
//    ///
//    /// WaveText의 text와 style을 바꿀 때 사용한다.
//    ///
//    /// - parameters:
//    ///     - text: 바꾸고자 하는 WaveText의 text
//    ///     - styleID: 변경할 styleID.
//    @objc public func changeTextAndStyle(text: String, styleID: String)
//
//    /// WaveText가 추가된 ViewBase
//    @objc public var view: KakaoMapsSDK.ViewBase? { get }
//
//    /// WaveText가 속한 LayerID
//    public var layerID: String { get }
//
//    /// WaveText의 ID
//    public var itemID: String { get }
//
//    /// WaveText가 현재 뷰에 보여지고 있는지 여부
//    public var isShow: Bool { get }
//
//    /// 사용자 객체
//    public var userObject: AnyObject?
//}
//
///// WaveText 생성 옵션 클래스
//@objc open class WaveTextOptions : NSObject {
//
//    /// initializer
//    ///
//    /// - parameter styleID: 사용할 WaveTextStyle ID
//    @objc required public init(styleID: String)
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - styleID: 사용할 WaveTextStyleID
//    ///     - waveTextID: waveTextID 지정. 지정하지 않을 경우 자동으로 부여된다.
//    @objc public init(styleID: String, waveTextID: String)
//
//    /// WaveTextID. 지정하지 않을 경우 자동으로 부여된다.
//    @objc public var itemID: String? { get }
//
//    /// WaveText의 styleID
//    @objc public var styleID: String
//
//    /// WaveText의 렌더링 우선순위
//    @objc public var rank: UInt
//
//    /// WaveText의 text
//    @objc public var text: String
//
//    /// WaveText가 표시 될 points
//    @objc public var points: [KakaoMapsSDK.MapPoint]?
//}
//
///// WaveTextStyle을 지정하는 클래스.
/////
///// WaveText를 레벨별로 다른 스타일로 표출하고 싶은 경우, PerLevelWaveTextStyle에 스타일 표출 레벨을 지정한 후 일종의 styleSet인 WaveTextStyle을 생성하여 사용한다.
/////
///// LabelManager를 통해 Style을 등록한다. 등록된 style의 ID를 WaveText에 지정해주면, WaveText가 해당 스타일로 생성된다.
/////
///// 혹은 등록된 styleID로 WaveText의 스타일을 변경할 수 있다.
//@objc open class WaveTextStyle : NSObject {
//
//    /// initializer
//    ///
//    /// - parameters:
//    ///     - styleID: WaveTextStyle의 ID
//    ///     - styles: WaveTextStyle을 구성할 단위레벨별 PerLevelWaveTextStyle 배열
//    @objc public init(styleID: String, styles: [KakaoMapsSDK.PerLevelWaveTextStyle])
//
//    /// 추가된 PerLevelWaveTextStyle
//    @objc public var styles: [KakaoMapsSDK.PerLevelWaveTextStyle] { get }
//
//    /// WaveTextStyle ID
//    @objc public var styleID: String { get }
//}
//
///// Zone 진입 이벤트 파라미터 구조체.
//public struct ZoneEnterEventParam {
//
//    /// KakaoMap
//    public let kakaoMap: KakaoMapsSDK.KakaoMap
//
//    /// Zone type
//    public let zoneType: String
//
//    /// Zone Id
//    public let zoneId: String
//
//    /// Zone detail id
//    public let zoneDetailId: String
//
//    /// Zone details
//    public let zoneDetails: [String]
//
//    /// Zone link info
//    public let zoneLinkInfos: [String : [KakaoMapsSDK.ZoneLinkInfo]]
//}
//
///// Zone 떠남 이벤트 파라미터 구조체.
//public struct ZoneLeaveEventParam {
//
//    /// KakaoMap
//    public let kakaoMap: KakaoMapsSDK.KakaoMap
//
//    /// Zone type
//    public let zoneType: String
//
//    /// Zone Id
//    public let zoneId: String
//
//    /// Zone detail id
//    public let zoneDetailId: String
//
//    /// Zone details
//    public let zoneDetails: [String]
//}
//
///// Zone 연결 정보를 전달하기 위한 클래스
///// 건물 일부 층이 서로 연결된 경우와 같이 다른 Zone 이지만 Zone의 일부가 서로 연결되어 있는 경우 연결 정보가 전달된다.
//@objc public class ZoneLinkInfo : NSObject {
//
//    /// Default initializer
//    override dynamic public init()
//
//    /// Initializer
//    /// - parameters:
//    ///     - zoneId: 연결된 zone ID
//    ///     - detailId: 연결된 zone의 detail ID
//    @objc public convenience init(zoneId: String, detailId: String)
//
//    /// 연결된 zone의 ID
//    @objc public var zoneId: String
//
//    /// 연결된 zone의 detail ID
//    @objc public var detailId: String
//}
//
///// 지도의 특정 구역(Zone)을 표시하는 오버레이 레이어를 관리하기 위한 클래스
//@objc public class ZoneManager : NSObject {
//
//    /// Zone의 유무를 체크하는 Rect 크기 지정.
//    /// Rect는 view의 중심에 위치한, ViewSize * xy scale 크기의 Rect가 된다. 해당 Rect 안에 zone이 들어올 경우 KakaoMapEventDelegate.onEnterZone이 호출된다.
//    /// Zone이 Rect밖으로 나갈 경우 KakaoMapEventDelegate.onLeaveZone이 호출된다.
//    ///
//    /// - parameters
//    ///     - zoneType: Zone의 type
//    ///     - level: scale 지정할 레벨.
//    ///     - scale: Scale 값(0.1~1.0). 기본값 (1.0, 1.0)
//    @objc public func setZoneCheckRectScale(zoneType: String, level: Int, scale: Vector2)
//
//    /// Zone의 상세 레이어를 표시한다.
//    /// detailId는 KakaoMapEventDelegate.onEnterZone로 전달되는 details 중에 선택할 수 있다. 
//    ///
//    /// - parameters
//    ///     - zoneType: Zone의 type
//    ///     - zoneId: Zone의 ID
//    ///     - detailId: Zone의 상세 레이어 ID (ex. 1F)
//    @objc public func showZoneDetail(zoneType: String, zoneId: String, detailId: String)
//
//    /// Zone의 상세 레이어를 숨긴다.
//    ///
//    /// - parameter zoneType: 상세 레이어를 숨길 zone의 type
//    @objc public func hideZoneDetail(zoneType: String)
//}
//
