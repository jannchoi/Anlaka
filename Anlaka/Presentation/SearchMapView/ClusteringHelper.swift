import Foundation
import CoreLocation

/*
 MARK: - 데이터 모델 설명
 
 PinInfo: 지도에 표시되는 개별 매물 정보
 - estateId: String - 매물 고유 식별자
 - latitude, longitude: Double - 위도, 경도 좌표
 - image: String? - 매물 이미지 URL
 - title: String - 매물 제목
 
 ClusterInfo: 클러스터링된 매물 그룹 정보
 - estateIds: [String] - 클러스터에 포함된 매물 ID 배열
 - centerCoordinate: CLLocationCoordinate2D - 클러스터 중심 좌표
 - count: Int - 클러스터에 포함된 매물 개수
 - representativeImage: String? - 클러스터 대표 이미지 URL
 */

final class ClusteringHelper {
    // MARK: - 1. 클러스터링 진입 메서드
    
    /// - Parameters:
    ///   - pins: 매물 목록
    /// - Returns: 클러스터링된 ClusterInfo 배열과 노이즈 PinInfo 배열
    func cluster(pins: [PinInfo]) -> (clusters: [ClusterInfo], noise: [PinInfo]) {
        guard !pins.isEmpty else { return (clusters: [], noise: []) }
        
        // 1. Core Distance 계산 (KDTree 기반 최적화, k=3으로 설정)
        let coreDistances = computeCoreDistancesOptimized(pins: pins, k: 3)
        
        // 2. 줌 레벨에 독립적인 maxDistance 계산
        let maxDistance = calculateZoomIndependentMaxDistance(pins: pins, k: 3, multiplier: 1.8)
        
        // 3. Mutual Reachability Graph 구성
        let edges = buildMutualReachabilityEdges(pins: pins, coreDistances: coreDistances)
        
        // 4. MST (Minimum Spanning Tree) 구성
        let mstEdges = computeMST(edges: edges)
        
        // 5. 클러스터 트리 구축 (간소화: 거리 임계값으로 분할)
        let clusters = buildClusterTree(mstEdges: mstEdges, threshold: maxDistance)
        
        // 5. 클러스터 정제 및 노이즈 분리 (최소 크기 2로 설정)
        let (validClusters, noiseIds) = extractValidClustersAndNoise(from: clusters, minClusterSize: 2, allPins: pins)
        
        // 6. 클러스터 간 겹침 방지를 위한 추가 정제 (주석처리 - 입력 그대로 출력)
        // let refinedClusters = refineClustersToPreventOverlap(validClusters: validClusters, allPins: pins)
        let refinedClusters = validClusters // 입력 그대로 출력
        
        // 7. pinDict 생성
        let pinDict = Dictionary(uniqueKeysWithValues: pins.map { ($0.estateId, $0) })
        
        // 8. 최종 ClusterInfo 변환 (maxDistance 전달)
        let clusterInfos = generateClusterInfo(from: refinedClusters, pinDict: pinDict, coreDistances: coreDistances, maxDistance: maxDistance)
        
        // 9. 노이즈 PinInfo 배열 생성
        let noisePins = noiseIds.compactMap { pinDict[$0] }
        
        return (clusters: clusterInfos, noise: noisePins)
    }

    
    // MARK: - 2. core distance 계산
    
    /// 각 매물의 core distance를 계산합니다.
    /// Core distance는 해당 매물에서 k번째로 가까운 이웃까지의 거리입니다.
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록 (PinInfo 배열)
    ///   - k: minPts (core distance를 계산할 이웃 수 기준, 보통 3-5)
    /// - Returns: 각 PinInfo의 estateId를 키로 하고 core distance를 값으로 하는 딕셔너리 (이웃이 부족한 경우 nil)
    func computeCoreDistances(pins: [PinInfo], k: Int) -> [String: Double?] {
        var coreDistances: [String: Double?] = [:]
        
        for (index, pin) in pins.enumerated() {
            var distances: [Double] = []
            
            // 모든 다른 점과의 거리 계산
            for (otherIndex, otherPin) in pins.enumerated() {
                if index != otherIndex {
                    let distance = haversineDistance(
                        from: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude),
                        to: CLLocationCoordinate2D(latitude: otherPin.latitude, longitude: otherPin.longitude)
                    )
                    distances.append(distance)
                }
            }
            
            // k번째 최근접 이웃까지의 거리 (core distance)
            if distances.count >= k {
                distances.sort()
                coreDistances[pin.estateId] = distances[k - 1]
            } else {
                coreDistances[pin.estateId] = nil
            }
        }
        
        return coreDistances
    }
    
    
    // MARK: - 3. mutual reachability graph 구성
    
    /// 모든 매물 쌍 간의 mutual reachability distance를 계산하여 간선 리스트를 생성합니다.
    /// Mutual reachability distance = max(coreDistance(p1), coreDistance(p2), distance(p1, p2))
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록 (PinInfo 배열)
    ///   - coreDistances: 각 매물의 core distance (estateId -> Double? 딕셔너리)
    /// - Returns: 간선 리스트 (estateId1, estateId2, mutualReachabilityDistance) 튜플 배열
    /// - Note: O(n²) 복잡도로, 모든 매물 쌍을 계산합니다
    func buildMutualReachabilityEdges(pins: [PinInfo], coreDistances: [String: Double?]) -> [(String, String, Double)] {
        var edges: [(String, String, Double)] = []
        
        for i in 0..<pins.count {
            for j in (i+1)..<pins.count {
                let pin1 = pins[i]
                let pin2 = pins[j]
                
                // 두 점 간의 거리
                let distance = haversineDistance(
                    from: CLLocationCoordinate2D(latitude: pin1.latitude, longitude: pin1.longitude),
                    to: CLLocationCoordinate2D(latitude: pin2.latitude, longitude: pin2.longitude)
                )
                
                // Core distances
                let core1: Double = coreDistances[pin1.estateId].flatMap { $0 } ?? Double.infinity
                let core2: Double = coreDistances[pin2.estateId].flatMap { $0 } ?? Double.infinity
                
                // Mutual reachability distance = max(core1, core2, distance)
                let mutualReachability = max(core1, core2, distance)
                
                edges.append((pin1.estateId, pin2.estateId, mutualReachability))
            }
        }
        
        return edges
    }
    
    
    // MARK: - 4. MST (Minimum Spanning Tree) 구성
    
    /// Kruskal 알고리즘을 사용하여 mutual reachability graph에서 최소 신장 트리를 구성합니다.
    /// 
    /// - Parameters:
    ///   - edges: mutual reachability edge 목록 (estateId1, estateId2, distance) 튜플 배열
    /// - Returns: MST에 포함된 간선 목록 (estateId1, estateId2, distance) 튜플 배열
    /// - Note: Union-Find 자료구조를 사용하여 O(E log E) 복잡도로 구현
    func computeMST(edges: [(String, String, Double)]) -> [(String, String, Double)] {
        // Kruskal 알고리즘 구현
        let sortedEdges = edges.sorted { $0.2 < $1.2 } // 거리 기준 오름차순 정렬
        
        var mstEdges: [(String, String, Double)] = []
        var unionFind = UnionFind<String>()
        
        // 모든 노드 초기화
        for edge in edges {
            unionFind.makeSet(edge.0)
            unionFind.makeSet(edge.1)
        }
        
        // MST 구성
        for edge in sortedEdges {
            let (node1, node2, _) = edge
            
            if unionFind.find(node1) != unionFind.find(node2) {
                unionFind.union(node1, node2)
                mstEdges.append(edge)
            }
        }
        
        return mstEdges
    }
    
    
    // MARK: - 5. 클러스터 트리 구축 (간소화: 거리 임계값으로 분할)
    
    /// MST 간선을 거리 임계값으로 분할하여 클러스터 후보들을 생성합니다.
    /// 임계값보다 큰 간선을 제거하면 연결된 컴포넌트들이 클러스터가 됩니다.
    /// 
    /// - Parameters:
    ///   - mstEdges: MST 간선들 (estateId1, estateId2, distance) 튜플 배열
    ///   - threshold: 클러스터 분할을 위한 거리 임계값 (미터 단위)
    /// - Returns: 클러스터 후보들 (각 클러스터는 estateId 배열)
    /// - Note: Union-Find를 사용하여 연결된 컴포넌트를 찾습니다
    func buildClusterTree(mstEdges: [(String, String, Double)], threshold: Double) -> [[String]] {
        // 임계값보다 큰 간선들을 제거하여 클러스터 분할
        let filteredEdges = mstEdges.filter { $0.2 <= threshold }
        
        // Union-Find를 사용하여 연결된 컴포넌트 찾기
        var unionFind = UnionFind<String>()
        var allNodes = Set<String>()
        
        // 모든 노드 초기화
        for edge in filteredEdges {
            unionFind.makeSet(edge.0)
            unionFind.makeSet(edge.1)
            allNodes.insert(edge.0)
            allNodes.insert(edge.1)
        }
        
        // 간선으로 연결
        for edge in filteredEdges {
            unionFind.union(edge.0, edge.1)
        }
        
        // 연결된 컴포넌트별로 그룹화
        var clusters: [String: [String]] = [:]
        for node in allNodes {
            let root = unionFind.find(node)
            clusters[root, default: []].append(node)
        }
        
        return Array(clusters.values)
    }
    
    
    // MARK: - 6. 클러스터 정제 및 노이즈 분리
    
    /// 클러스터 후보들에서 유효한 클러스터와 노이즈를 분리합니다.
    /// 최소 크기 미만의 클러스터는 제거하고, 클러스터에 포함되지 않은 매물들을 노이즈로 분류합니다.
    /// 
    /// - Parameters:
    ///   - clusters: 후보 클러스터 배열 (각 클러스터는 estateId 배열)
    ///   - minClusterSize: 최소 클러스터 크기 (이 크기 미만은 노이즈로 처리)
    ///   - allPins: 전체 PinInfo 배열 (노이즈 판별을 위해 사용)
    /// - Returns: 유효한 클러스터와 노이즈 ID 배열 (validClusters: [[String]], noiseIds: [String])
    /// - Note: 클러스터에 포함되지 않은 모든 매물이 노이즈로 분류됩니다
    func extractValidClustersAndNoise(from clusters: [[String]], minClusterSize: Int, allPins: [PinInfo]) -> (validClusters: [[String]], noiseIds: [String]) {
        var validClusters: [[String]] = []
        
        for cluster in clusters {
            if cluster.count >= minClusterSize {
                // 클러스터 크기 제한 없이 모든 클러스터 유지
                validClusters.append(cluster)
            }
        }
        
        // 모든 클러스터에 포함된 estateId들
        let clusteredIds = Set(validClusters.flatMap { $0 })
        
        // 전체 estateId들
        let allIds = Set(allPins.map { $0.estateId })
        
        // 클러스터에 포함되지 않은 estateId들이 노이즈
        let noiseIds = Array(allIds.subtracting(clusteredIds))
        
        return (validClusters: validClusters, noiseIds: noiseIds)
    }
    

    
    /// 클러스터 간 겹침을 방지하기 위해 클러스터를 정제합니다.
    /// 클러스터 간 거리가 너무 가까우면 더 큰 클러스터를 우선하고 작은 클러스터는 분해합니다.
    /// 
    /// - Parameters:
    ///   - validClusters: 유효한 클러스터 배열 (각 클러스터는 estateId 배열)
    ///   - allPins: 전체 PinInfo 배열
    /// - Returns: 겹침이 방지된 클러스터 배열
    private func refineClustersToPreventOverlap(validClusters: [[String]], allPins: [PinInfo]) -> [[String]] {
        guard validClusters.count > 1 else { return validClusters }
        
        // 줌 레벨에 독립적인 maxDistance 계산
        let maxDistance = calculateZoomIndependentMaxDistance(pins: allPins, k: 3, multiplier: 1.5)
        
        let pinDict = Dictionary(uniqueKeysWithValues: allPins.map { ($0.estateId, $0) })
        var refinedClusters: [[String]] = []
        var processedClusters = Set<Int>()
        
        // 클러스터를 크기 순으로 정렬 (큰 클러스터 우선)
        let sortedClusterIndices = validClusters.enumerated().sorted { $0.element.count > $1.element.count }.map { $0.offset }
        
        for mainIndex in sortedClusterIndices {
            if processedClusters.contains(mainIndex) { continue }
            
            let mainCluster = validClusters[mainIndex]
            let mainCenter = calculateClusterCenter(clusterIds: mainCluster, pinDict: pinDict)
            var mergedCluster = mainCluster
            processedClusters.insert(mainIndex)
            
            // 다른 클러스터들과의 거리 확인
            for otherIndex in sortedClusterIndices {
                if otherIndex == mainIndex || processedClusters.contains(otherIndex) { continue }
                
                let otherCluster = validClusters[otherIndex]
                let otherCenter = calculateClusterCenter(clusterIds: otherCluster, pinDict: pinDict)
                
                // 두 클러스터 중심점 간의 거리 계산
                let distance = haversineDistance(from: mainCenter, to: otherCenter)
                
                // 거리가 너무 가까우면 (maxDistance의 1.5배 이내) 병합 고려
                if distance <= maxDistance * 1.5 {
                    // 클러스터 내 모든 매물 간의 최대 거리 확인
                    let allPinsInBothClusters = (mainCluster + otherCluster).compactMap { pinDict[$0] }
                    let maxInternalDistance = calculateMaxInternalDistance(pins: allPinsInBothClusters)
                    
                    // 내부 거리가 허용 범위 내라면 병합
                    if maxInternalDistance <= maxDistance * 2.0 {
                        mergedCluster.append(contentsOf: otherCluster)
                        processedClusters.insert(otherIndex)
                    }
                }
            }
            
            refinedClusters.append(mergedCluster)
        }
        
        return refinedClusters
    }
    
    /// 클러스터의 중심점을 계산합니다.
    /// 
    /// - Parameters:
    ///   - clusterIds: 클러스터 내 매물 ID 배열
    ///   - pinDict: 매물 ID로 PinInfo를 조회할 수 있는 딕셔너리
    /// - Returns: 클러스터 중심점
    private func calculateClusterCenter(clusterIds: [String], pinDict: [String: PinInfo]) -> CLLocationCoordinate2D {
        let pinInfos = clusterIds.compactMap { pinDict[$0] }
        return calculateWeightedCenter(pinInfos: pinInfos)
    }
    
    /// 매물 배열 내에서 가장 멀리 떨어진 두 매물 간의 거리를 계산합니다.
    /// 
    /// - Parameters:
    ///   - pins: 매물 배열
    /// - Returns: 최대 내부 거리 (미터)
    private func calculateMaxInternalDistance(pins: [PinInfo]) -> Double {
        guard pins.count > 1 else { return 0 }
        
        var maxDistance = 0.0
        
        for i in 0..<pins.count {
            for j in (i+1)..<pins.count {
                let distance = haversineDistance(
                    from: CLLocationCoordinate2D(latitude: pins[i].latitude, longitude: pins[i].longitude),
                    to: CLLocationCoordinate2D(latitude: pins[j].latitude, longitude: pins[j].longitude)
                )
                maxDistance = max(maxDistance, distance)
            }
        }
        
        return maxDistance
    }
    
    // MARK: - 7. 최종 ClusterInfo 변환
    
    /// 클러스터 ID 배열을 ClusterInfo 객체 배열로 변환합니다.
    /// 각 클러스터의 중심 좌표, 매물 개수, 대표 이미지 등을 계산합니다.
    /// 
    /// - Parameters:
    ///   - clusterIds: estateId 기준의 클러스터들 (각 클러스터는 estateId 배열)
    ///   - pinDict: estateId로 PinInfo를 조회할 수 있는 딕셔너리
    ///   - coreDistances: 각 매물의 core distance (사용하지 않음)
    ///   - zoomLevel: 현재 지도 줌 레벨 (반지름 계산용)
    /// - Returns: 클러스터링된 ClusterInfo 배열 (중심 좌표, 개수, 대표 이미지, 최대 반지름 포함)
    /// - Note: 중심 좌표는 클러스터 내 모든 매물의 평균 좌표로 계산됩니다
    func generateClusterInfo(
        from clusterIds: [[String]], 
        pinDict: [String: PinInfo],
        coreDistances: [String: Double?]? = nil,
        maxDistance: Double? = nil,
        zoomLevel: Double = 12.0
    ) -> [ClusterInfo] {
        var clusterInfos: [ClusterInfo] = []
        
        // 첫 번째 패스: 기본 ClusterInfo 생성 (maxRadius 계산을 위해)
        for clusterIds in clusterIds {
            guard !clusterIds.isEmpty else { continue }
            
            // 클러스터 내 모든 PinInfo 수집
            let pinInfos = clusterIds.compactMap { pinDict[$0] }
            guard !pinInfos.isEmpty else { continue }
            
            // 중심 좌표 계산 (정확한 Haversine 거리 기반 가중 평균)
            let centerCoordinate = calculateWeightedCenter(pinInfos: pinInfos)
            
            // 대표 이미지 (첫 번째 매물의 이미지 사용)
            let representativeImage = pinInfos.first?.image
            
            let clusterInfo = ClusterInfo(
                estateIds: clusterIds,
                centerCoordinate: centerCoordinate,
                count: clusterIds.count,
                representativeImage: representativeImage,
                opacity: nil, // 투명도는 Coordinator에서 계산
                maxRadius: 50.0 // 임시 값, 나중에 업데이트
            )
            
            clusterInfos.append(clusterInfo)
        }
        
        // 두 번째 패스: maxRadius 계산 및 업데이트
        for i in 0..<clusterInfos.count {
            let clusterInfo = clusterInfos[i]
            let maxRadius = calculateOptimalMaxRadius(
                clusterIds: clusterInfo.estateIds,
                centerCoordinate: clusterInfo.centerCoordinate,
                coreDistances: coreDistances,
                allClusterInfos: clusterInfos,
                maxDistance: maxDistance
            )
            
            // 새로운 ClusterInfo 생성 (maxRadius 포함)
            let updatedClusterInfo = ClusterInfo(
                estateIds: clusterInfo.estateIds,
                centerCoordinate: clusterInfo.centerCoordinate,
                count: clusterInfo.count,
                representativeImage: clusterInfo.representativeImage,
                opacity: clusterInfo.opacity,
                maxRadius: maxRadius
            )
            
            clusterInfos[i] = updatedClusterInfo
        }
        
        return clusterInfos
    }
    

    
    /// 클러스터의 중심 좌표를 정확한 Haversine 거리 기반으로 계산합니다.
    /// 단순 평균 대신 가중 평균을 사용하여 더 정확한 중심점을 계산합니다.
    /// 
    /// - Parameters:
    ///   - pinInfos: 클러스터 내 매물 목록
    /// - Returns: 정확한 중심 좌표 (CLLocationCoordinate2D)
    /// - Note: 사용자에게 표시되는 좌표이므로 정확한 Haversine 거리를 사용합니다
    private func calculateWeightedCenter(pinInfos: [PinInfo]) -> CLLocationCoordinate2D {
        guard !pinInfos.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        
        if pinInfos.count == 1 {
            return CLLocationCoordinate2D(latitude: pinInfos[0].latitude, longitude: pinInfos[0].longitude)
        }
        
        // 클러스터 경계 계산
        let minLat = pinInfos.map { $0.latitude }.min()!
        let maxLat = pinInfos.map { $0.latitude }.max()!
        let minLon = pinInfos.map { $0.longitude }.min()!
        let maxLon = pinInfos.map { $0.longitude }.max()!
        
        // 경계의 중심점 계산 (가장 안전한 중심점)
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // 클러스터 내 모든 매물이 중심점으로부터의 거리를 고려하여 조정
        var adjustedCenterLat = centerLat
        var adjustedCenterLon = centerLon
        
        // 클러스터 크기가 작은 경우 (5개 이하) 가중 평균 사용
        if pinInfos.count <= 5 {
            let basePin = pinInfos[0]
            var totalWeight = 0.0
            var weightedLatSum = 0.0
            var weightedLonSum = 0.0
            
            for pin in pinInfos {
                let distance = haversineDistance(
                    from: CLLocationCoordinate2D(latitude: basePin.latitude, longitude: basePin.longitude),
                    to: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                )
                
                let weight = distance > 0 ? 1.0 / distance : 1.0
                totalWeight += weight
                weightedLatSum += pin.latitude * weight
                weightedLonSum += pin.longitude * weight
            }
            
            adjustedCenterLat = weightedLatSum / totalWeight
            adjustedCenterLon = weightedLonSum / totalWeight
        }
        
        // 조정된 중심점이 클러스터 경계 내에 있는지 확인
        let finalCenterLat = max(minLat, min(maxLat, adjustedCenterLat))
        let finalCenterLon = max(minLon, min(maxLon, adjustedCenterLon))
        
        return CLLocationCoordinate2D(latitude: finalCenterLat, longitude: finalCenterLon)
    }
    
    // MARK: - 유틸리티 메서드
    
    /// Haversine 공식을 사용한 두 좌표 간의 정확한 거리를 계산합니다.
    /// 지구의 곡률을 고려하여 정확한 거리를 계산합니다.
    /// 
    /// - Parameters:
    ///   - from: 시작 좌표 (CLLocationCoordinate2D)
    ///   - to: 도착 좌표 (CLLocationCoordinate2D)
    /// - Returns: 두 좌표 간의 거리 (미터 단위)
    private func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
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
    
    /// Haversine 공식을 사용한 두 좌표 간의 정확한 거리를 계산합니다.
    /// 
    /// - Parameters:
    ///   - from: 시작 좌표 (CLLocationCoordinate2D)
    ///   - to: 도착 좌표 (CLLocationCoordinate2D)
    /// - Returns: 두 좌표 간의 거리 (미터 단위)
    fileprivate static func haversineDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
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
}
// MARK: - KDTree 구현

fileprivate class KDTree {
    private var root: KDNode?
    
    init(pins: [PinInfo]) {
        guard !pins.isEmpty else { return }
        root = buildTree(pins: pins, depth: 0)
    }
    
    /// 두 매물 간의 근사 거리를 빠르게 계산합니다.
    /// Haversine 공식 대신 유클리드 거리를 사용하여 성능을 향상시킵니다.
    /// 
    /// - Parameters:
    ///   - pin1: 첫 번째 매물 (PinInfo)
    ///   - pin2: 두 번째 매물 (PinInfo)
    /// - Returns: 두 매물 간 근사 거리 (미터 단위)
    /// - Note: 정확도는 Haversine보다 떨어지지만 3-5배 빠른 계산 속도를 제공합니다
    static func fastDistanceApproximation(pin1: PinInfo, pin2: PinInfo) -> Double {
        // 유클리드 거리 근사 (빠른 계산)
        let latDiff = pin1.latitude - pin2.latitude
        let lonDiff = pin1.longitude - pin2.longitude
        
        // 위도/경도를 미터로 변환
        let metersPerDegreeLat = 111000.0
        let metersPerDegreeLon = 111000.0 * cos(pin1.latitude * .pi / 180)
        
        let latDiffMeters = latDiff * metersPerDegreeLat
        let lonDiffMeters = lonDiff * metersPerDegreeLon
        
        // 유클리드 거리 계산
        return sqrt(latDiffMeters * latDiffMeters + lonDiffMeters * lonDiffMeters)
    }
    
    func kNearestNeighbors(of targetPin: PinInfo, k: Int) -> [Neighbor] {
        guard let root = root else { return [] }
        
        var neighbors: [Neighbor] = []
        var maxDistance = Double.infinity
        
        searchNearestNeighbors(node: root, targetPin: targetPin, k: k, neighbors: &neighbors, maxDistance: &maxDistance, depth: 0)
        
        return neighbors.sorted { $0.distance < $1.distance }
    }
    
    private func buildTree(pins: [PinInfo], depth: Int) -> KDNode? {
        guard !pins.isEmpty else { return nil }
        
        let axis = depth % 2 // 0: 위도, 1: 경도
        
        let sortedPins = pins.sorted { pin1, pin2 in
            if axis == 0 {
                return pin1.latitude < pin2.latitude
            } else {
                return pin1.longitude < pin2.longitude
            }
        }
        
        let medianIndex = sortedPins.count / 2
        let medianPin = sortedPins[medianIndex]
        
        let leftPins = Array(sortedPins[..<medianIndex])
        let rightPins = Array(sortedPins[(medianIndex + 1)...])
        
        let leftChild = buildTree(pins: leftPins, depth: depth + 1)
        let rightChild = buildTree(pins: rightPins, depth: depth + 1)
        
        return KDNode(pin: medianPin, left: leftChild, right: rightChild, axis: axis)
    }
    
    private func searchNearestNeighbors(node: KDNode, targetPin: PinInfo, k: Int, neighbors: inout [Neighbor], maxDistance: inout Double, depth: Int) {
        // k-NN 탐색에서는 빠른 근사 거리 사용
        let distance = KDTree.fastDistanceApproximation(pin1: targetPin, pin2: node.pin)
        
        // 현재 노드가 타겟과 다른 경우에만 추가
        if node.pin.estateId != targetPin.estateId {
            if neighbors.count < k {
                neighbors.append(Neighbor(pin: node.pin, distance: distance))
                if neighbors.count == k {
                    neighbors.sort { $0.distance < $1.distance }
                    maxDistance = neighbors.last!.distance
                }
            } else if distance < maxDistance {
                neighbors.removeLast()
                neighbors.append(Neighbor(pin: node.pin, distance: distance))
                neighbors.sort { $0.distance < $1.distance }
                maxDistance = neighbors.last!.distance
            }
        }
        
        let axis = depth % 2
        let targetValue = axis == 0 ? targetPin.latitude : targetPin.longitude
        let nodeValue = axis == 0 ? node.pin.latitude : node.pin.longitude
        
        // 자식 노드 탐색
        if targetValue < nodeValue {
            if let left = node.left {
                searchNearestNeighbors(node: left, targetPin: targetPin, k: k, neighbors: &neighbors, maxDistance: &maxDistance, depth: depth + 1)
            }
            if let right = node.right, abs(targetValue - nodeValue) < maxDistance {
                searchNearestNeighbors(node: right, targetPin: targetPin, k: k, neighbors: &neighbors, maxDistance: &maxDistance, depth: depth + 1)
            }
        } else {
            if let right = node.right {
                searchNearestNeighbors(node: right, targetPin: targetPin, k: k, neighbors: &neighbors, maxDistance: &maxDistance, depth: depth + 1)
            }
            if let left = node.left, abs(targetValue - nodeValue) < maxDistance {
                searchNearestNeighbors(node: left, targetPin: targetPin, k: k, neighbors: &neighbors, maxDistance: &maxDistance, depth: depth + 1)
            }
        }
    }
}

fileprivate class KDNode {
    let pin: PinInfo
    let left: KDNode?
    let right: KDNode?
    let axis: Int
    
    init(pin: PinInfo, left: KDNode?, right: KDNode?, axis: Int) {
        self.pin = pin
        self.left = left
        self.right = right
        self.axis = axis
    }
}

fileprivate struct Neighbor {
    let pin: PinInfo
    let distance: Double
}

// MARK: - Union-Find 자료구조 (MST 알고리즘용)

private class UnionFind<T: Hashable> {
    private var parent: [T: T] = [:]
    private var rank: [T: Int] = [:]
    
    func makeSet(_ element: T) {
        if parent[element] == nil {
            parent[element] = element
            rank[element] = 0
        }
    }
    
    func find(_ element: T) -> T {
        if parent[element] != element {
            parent[element] = find(parent[element]!)
        }
        return parent[element]!
    }
    
    func union(_ x: T, _ y: T) {
        let rootX = find(x)
        let rootY = find(y)
        
        if rootX != rootY {
            if rank[rootX]! < rank[rootY]! {
                parent[rootX] = rootY
            } else if rank[rootX]! > rank[rootY]! {
                parent[rootY] = rootX
            } else {
                parent[rootY] = rootX
                rank[rootX]! += 1
            }
        }
    }
}

// MARK: - 최적화된 Core Distance 계산 (KDTree 활용)

extension ClusteringHelper {
    
    /// KDTree를 사용하여 각 매물의 core distance를 효율적으로 계산합니다.
    /// 기존 O(n²) 복잡도를 O(n log n)으로 개선하여 대용량 데이터에서도 실시간 처리가 가능합니다.
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록 (PinInfo 배열)
    ///   - k: minPts (core distance를 계산할 이웃 수 기준, 동적으로 조정됨)
    /// - Returns: 각 PinInfo의 estateId를 키로 하고 core distance를 값으로 하는 딕셔너리 (이웃이 부족한 경우 nil)
    /// - Note: k는 매물 개수의 1/3로 동적 조정되며, 최소 1, 최대 원래 k값을 사용합니다
    func computeCoreDistancesOptimized(pins: [PinInfo], k: Int) -> [String: Double?] {
        var coreDistances: [String: Double?] = [:]
        
        // k 동적 조정
        let adjustedK = min(k, max(1, pins.count / 3)) // 매물 개수의 1/3, 최소 1, 최대 k
        
        // KDTree 구축
        let kdTree = buildKDTree(pins: pins)
        
        for pin in pins {
            // KDTree 기반 k-NN 검색 (근사 거리 사용)
            let neighbors = kdTree.kNearestNeighbors(of: pin, k: adjustedK)
            
            if neighbors.count >= adjustedK {
                // k번째 이웃까지의 거리 (core distance) - 근사 거리 사용
                let kDistance = neighbors[adjustedK - 1].distance
                coreDistances[pin.estateId] = kDistance
            } else if neighbors.count > 0 {
                // 후보군이 있지만 k개 미만인 경우
                let maxDistance = neighbors.max(by: { $0.distance < $1.distance })?.distance
                coreDistances[pin.estateId] = maxDistance
            } else {
                // 후보군이 0인 경우
                coreDistances[pin.estateId] = nil
            }
        }
        
        return coreDistances
    }
    
    /// 매물 목록을 기반으로 KDTree를 구축합니다.
    /// 위도와 경도를 번갈아가며 축으로 사용하여 공간을 효율적으로 분할합니다.
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록 (PinInfo 배열)
    /// - Returns: 구축된 KDTree 객체 (k-NN 검색에 사용)
    /// - Note: O(n log n) 복잡도로 트리를 구축합니다
    fileprivate func buildKDTree(pins: [PinInfo]) -> KDTree {
        return KDTree(pins: pins)
    }
    
    /// 두 매물 간의 근사 거리를 빠르게 계산합니다.
    /// Haversine 공식 대신 유클리드 거리를 사용하여 성능을 향상시킵니다.
    /// 
    /// - Parameters:
    ///   - pin1: 첫 번째 매물 (PinInfo)
    ///   - pin2: 두 번째 매물 (PinInfo)
    /// - Returns: 두 매물 간 근사 거리 (미터 단위)
    /// - Note: 정확도는 Haversine보다 떨어지지만 3-5배 빠른 계산 속도를 제공합니다
    func fastDistanceApproximation(pin1: PinInfo, pin2: PinInfo) -> Double {
        return KDTree.fastDistanceApproximation(pin1: pin1, pin2: pin2)
    }
    
    /// 줌 레벨에 독립적인 maxDistance를 계산합니다.
    /// Core distance의 75% 백분위수를 기반으로 계산하여 데이터 분포에 적응합니다.
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록 (PinInfo 배열)
    ///   - k: minPts (core distance 계산용, 기본값 3)
    ///   - multiplier: 배율 (기본값 1.0, 1.5나 2.0으로 조정 가능)
    /// - Returns: 줌 레벨에 독립적인 maxDistance (미터 단위)
    /// - Note: 데이터 분포에 따라 자동으로 조정되며, 줌 레벨과 무관하게 일관된 클러스터링을 제공합니다
    func calculateZoomIndependentMaxDistance(pins: [PinInfo], k: Int = 3, multiplier: Double = 1.0) -> Double {
        // 1. Core distance 계산
        let coreDistances = computeCoreDistancesOptimized(pins: pins, k: k)
        
        // 2. nil이 아닌 값들만 필터링
        let validCoreDistances = coreDistances.compactMap { $0.value }
        
        guard !validCoreDistances.isEmpty else {
            // Core distance가 없는 경우 기본값 반환
            return 100.0
        }
        
        // 3. Core distance를 오름차순 정렬
        let sortedCoreDistances = validCoreDistances.sorted()
        
        // 4. 75% 백분위수 계산
        let percentileIndex = Int(floor(0.75 * Double(sortedCoreDistances.count - 1)))
        let percentile75 = sortedCoreDistances[percentileIndex]
        
        // 5. 배율 적용하여 maxDistance 계산
        let maxDistance = percentile75 * multiplier
        
        // 디버깅용 로그 (나중에 제거 가능)
        print("🔍 줌 독립적 maxDistance 계산:")
        print("   - 총 매물 수: \(pins.count)")
        print("   - 유효한 core distance 수: \(validCoreDistances.count)")
        print("   - 75% 백분위수: \(percentile75)m")
        print("   - 최종 maxDistance: \(maxDistance)m (배율: \(multiplier))")
        
        return maxDistance
    }
    
    // MARK: - 최적 반지름 계산 함수들
    
    /// 클러스터의 최적 maxRadius를 계산합니다.
    /// maxDistance를 기반으로 동적 범위를 설정하여 적응적인 클러스터링을 제공합니다.
    /// 
    /// - Parameters:
    ///   - clusterIds: 클러스터 내 매물 ID 배열
    ///   - centerCoordinate: 클러스터 중심 좌표
    ///   - coreDistances: 각 매물의 core distance (estateId -> Double? 딕셔너리)
    ///   - allClusterInfos: 모든 클러스터 정보 배열
    ///   - maxDistance: 클러스터링에 사용된 최대 거리 (동적 범위 설정용)
    /// - Returns: 최적화된 maxRadius (미터 단위, maxDistance 기반 동적 범위)
    /// - Note: maxDistance를 기반으로 반지름 범위를 동적으로 조정하여 데이터 분포에 적응합니다
    private func calculateOptimalMaxRadius(
        clusterIds: [String],
        centerCoordinate: CLLocationCoordinate2D,
        coreDistances: [String: Double?]?,
        allClusterInfos: [ClusterInfo],
        maxDistance: Double? = nil
    ) -> Double {
        let clusterCount = clusterIds.count
        
        // maxDistance 기반 동적 범위 설정
        let baseMaxDistance = maxDistance ?? 100.0
        let minRadius = baseMaxDistance * 0.1 // maxDistance의 10%
        let maxRadius = baseMaxDistance * 0.8 // maxDistance의 80%
        
        // 매물 수에 기반한 기본 반지름 계산 (로그 스케일 사용)
        let baseRadius: Double
        if clusterCount == 1 {
            baseRadius = minRadius // 노이즈는 최소 크기
        } else {
            // 로그 스케일을 사용하여 매물 수에 비례한 반지름 계산
            let logCount = log10(Double(clusterCount))
            let maxLogCount = log10(100.0) // 100개를 최대 기준으로 설정
            
            let ratio = min(1.0, logCount / maxLogCount)
            baseRadius = minRadius + (maxRadius - minRadius) * ratio
        }
        
        // 클러스터 간 겹침 방지를 위한 조정
        var adjustedRadius = baseRadius
        
        for otherCluster in allClusterInfos {
            let distance = haversineDistance(from: centerCoordinate, to: otherCluster.centerCoordinate)
            let totalRadius = adjustedRadius + otherCluster.maxRadius
            
            if distance < totalRadius && distance > 0 {
                // 겹침 발생 시, 거리의 절반으로 조정
                let safeRadius = distance / 2.0
                adjustedRadius = min(adjustedRadius, safeRadius)
            }
        }
        
        // 범위 제한 (maxDistance 기반)
        let finalRadius = max(minRadius, min(maxRadius, adjustedRadius))
        
        print("🔍 maxRadius 계산: count=\(clusterCount), base=\(baseRadius)m, final=\(finalRadius)m (maxDistance=\(baseMaxDistance)m)")
        
        return finalRadius
    }

    /// 다른 클러스터와의 거리를 기반으로 최대 반지름을 계산합니다.
    /// 가장 가까운 클러스터와의 거리의 절반을 반환하여 겹침을 방지합니다.
    /// 
    /// - Parameters:
    ///   - centerCoordinate: 현재 클러스터의 중심 좌표
    ///   - allClusterInfos: 모든 클러스터 정보 배열
    /// - Returns: 거리 기반 최대 반지름 (미터 단위)
    /// - Note: 다른 클러스터가 없는 경우 기본값 100m를 반환합니다
    private func calculateMaxRadiusFromClusterDistance(
        centerCoordinate: CLLocationCoordinate2D,
        allClusterInfos: [ClusterInfo]
    ) -> Double {
        var minDistance = Double.infinity
        for otherCluster in allClusterInfos {
            let distance = haversineDistance(from: centerCoordinate, to: otherCluster.centerCoordinate)
            minDistance = min(minDistance, distance)
        }
        return minDistance == Double.infinity ? 100.0 : minDistance / 2.0 // 기본값 100m, 최소 거리 반영
    }
    
    
}

