import Foundation
import CoreLocation


final class ClusteringHelper {

    // MARK: MST (Minimum Spanning Tree) 구성
    
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
    
    
    // MARK: 클러스터 트리 구축 (간소화: 거리 임계값으로 분할)
    
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
        let unionFind = UnionFind<String>()
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
    
    
    // MARK: 클러스터 정제 및 노이즈 분리
    
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
    
    // MARK: 최종 ClusterInfo 변환
    
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
                maxDistance: maxDistance,
                pinDict: pinDict
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
    
    // MARK: 유틸리티 메서드
    
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
    // MARK: KDTree 구현

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

// MARK: Union-Find 자료구조 (MST 알고리즘용)

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

// MARK: 최적화된 Core Distance 계산 (KDTree 활용)

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
    
    /// 줌 레벨과 매물 분포를 모두 고려한 maxDistance를 계산합니다.
    /// Core distance의 75% 백분위수와 동적 기준 거리를 모두 고려하여 적응형 클러스터링을 제공합니다.
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록 (PinInfo 배열)
    ///   - k: minPts (core distance 계산용, 기본값 3)
    ///   - multiplier: 배율 (기본값 1.0, 1.5나 2.0으로 조정 가능)
    ///   - zoomLevel: 현재 줌 레벨 (6-14, 기본값 12)
    /// - Returns: 줌 레벨과 매물 분포를 고려한 maxDistance (미터 단위)
    /// - Note: 데이터 분포에 따라 동적으로 조정된 기준 거리를 사용하여 더 정확한 클러스터링을 제공합니다
    func calculateZoomIndependentMaxDistance(pins: [PinInfo], k: Int = 3, multiplier: Double = 1.0, zoomLevel: Double = 12.0) -> Double {
        // 1. Core distance 계산
        let coreDistances = computeCoreDistancesOptimized(pins: pins, k: k)
        
        // 2. nil이 아닌 값들만 필터링
        let validCoreDistances = coreDistances.compactMap { $0.value }
        
        guard !validCoreDistances.isEmpty else {
            // Core distance가 없는 경우 줌 레벨 기반 기본값 반환
            return getBaseDistanceForZoom(zoomLevel: zoomLevel)
        }
        
        // 3. Core distance를 오름차순 정렬
        let sortedCoreDistances = validCoreDistances.sorted()
        
        // 4. 75% 백분위수 계산
        let percentileIndex = Int(floor(0.75 * Double(sortedCoreDistances.count - 1)))
        let percentile75 = sortedCoreDistances[percentileIndex]
        
        // 5. 데이터 분포를 고려한 동적 기준 거리 계산
        let zoomBasedDistance = getBaseDistanceForZoom(zoomLevel: zoomLevel, coreDistances: coreDistances)
        
        // 6. 매물 분포 기반 거리와 동적 기준 거리를 가중 평균으로 결합
        let mrdBasedDistance = percentile75 * multiplier
        
        // 7. 줌 레벨에 따른 가중치 계산
        let zoomWeight = calculateZoomWeight(zoomLevel: zoomLevel)
        let mrdWeight = 1.0 - zoomWeight
        
        // 8. 가중 평균으로 최종 maxDistance 계산
        let maxDistance = (zoomBasedDistance * zoomWeight) + (mrdBasedDistance * mrdWeight)
        
        // 9. 최소값과 최대값 범위 내로 제한 (동적 기준 거리 기반)
        let minDistance = zoomBasedDistance * 0.3
        let maxAllowedDistance = zoomBasedDistance * 2.0
        
        let finalDistance = max(minDistance, min(maxAllowedDistance, maxDistance))
        
        return finalDistance
    }
    
    /// 줌 레벨에 따른 가중치를 계산합니다.
    /// 줌 레벨이 낮을수록 줌 기반 거리에 더 높은 가중치를 부여합니다.
    /// 
    /// - Parameter zoomLevel: 현재 줌 레벨 (6-14)
    /// - Returns: 줌 기반 거리에 대한 가중치 (0.0-1.0)
    private func calculateZoomWeight(zoomLevel: Double) -> Double {
        switch zoomLevel {
        case 6: return 0.8   // 매우 낮은 줌 - 줌 기반 거리에 높은 가중치
        case 7: return 0.7
        case 8: return 0.6
        case 9: return 0.5
        case 10: return 0.4
        case 11: return 0.3
        case 12: return 0.2  // 중간 줌 - 균형잡힌 가중치
        case 13: return 0.1
        case 14: return 0.05 // 높은 줌 - MRD 기반 거리에 높은 가중치
        default: return 0.2
        }
    }
    
    // MARK: - 최적 반지름 계산 함수들
    
    /// 클러스터의 최적 maxRadius를 계산합니다.
    /// 클러스터의 실제 지리적 범위를 상한선과 하한선 사이에서 루트 보간법으로 매핑합니다.
    /// 
    /// - Parameters:
    ///   - clusterIds: 클러스터 내 매물 ID 배열
    ///   - centerCoordinate: 클러스터 중심 좌표
    ///   - coreDistances: 각 매물의 core distance (estateId -> Double? 딕셔너리)
    ///   - allClusterInfos: 모든 클러스터 정보 배열
    ///   - maxDistance: 클러스터링에 사용된 최대 거리 (겹침 방지용)
    ///   - pinDict: 매물 ID로 PinInfo를 조회할 수 있는 딕셔너리
    /// - Returns: 최적화된 maxRadius (pt 단위, 지리적 범위 비례 매핑)
    /// - Note: 루트 보간법을 사용하여 실제 반지름을 상한선과 하한선 사이에서 비례적으로 매핑하여 겹침을 방지합니다
    private func calculateOptimalMaxRadius(
        clusterIds: [String],
        centerCoordinate: CLLocationCoordinate2D,
        coreDistances: [String: Double?]?,
        allClusterInfos: [ClusterInfo],
        maxDistance: Double? = nil,
        pinDict: [String: PinInfo]? = nil
    ) -> Double {
        let clusterCount = clusterIds.count
        
        // 상한선과 하한선 설정 (클러스터 간 거리의 40%로 제한, 최솟값 25pt)
        let maxAllowedRadius = (maxDistance ?? 100.0) * 0.4 // 상한선: 클러스터 간 거리의 40%
        let minRadius = 25.0 // 하한선: 최소 25pt로 가독성 보장
        
        // 클러스터의 실제 지리적 범위 계산
        let actualRadius: Double
        if clusterCount == 1 {
            actualRadius = minRadius // 노이즈는 최소 크기
        } else {
            // 클러스터 내 매물 간 최대 거리를 반지름으로 사용
            if let pinDict = pinDict {
                let pinInfos = clusterIds.compactMap { pinDict[$0] }
                let maxInternalDistance = calculateMaxInternalDistance(pins: pinInfos)
                actualRadius = max(maxInternalDistance * 0.5, minRadius) // 최대 거리의 절반을 반지름으로
            } else {
                // pinDict가 없는 경우 기본값 사용
                actualRadius = minRadius + (maxAllowedRadius - minRadius) * 0.5
            }
        }
        
        // 모든 클러스터의 실제 반지름을 계산하여 최소/최대값 찾기
        let allActualRadii = calculateAllActualRadii(allClusterInfos: allClusterInfos, pinDict: pinDict)
        let minActualRadius = allActualRadii.min() ?? minRadius
        let maxActualRadius = allActualRadii.max() ?? maxAllowedRadius
        
        // 실제 반지름을 상한선과 하한선 사이에서 루트 보간법으로 매핑
        let finalRadius: Double
        if minActualRadius == maxActualRadius {
            finalRadius = (minRadius + maxAllowedRadius) / 2 // 모든 클러스터가 같은 크기인 경우 중간값
        } else {
            let ratio = (actualRadius - minActualRadius) / (maxActualRadius - minActualRadius)
            // 루트 보간법 적용: sqrt(ratio)를 사용하여 비선형 매핑
            let rootRatio = sqrt(ratio)
            finalRadius = minRadius + (maxAllowedRadius - minRadius) * rootRatio
        }
        
        return finalRadius
    }
    
    /// 모든 클러스터의 실제 반지름을 계산합니다.
    /// 
    /// - Parameters:
    ///   - allClusterInfos: 모든 클러스터 정보 배열
    ///   - pinDict: 매물 ID로 PinInfo를 조회할 수 있는 딕셔너리
    /// - Returns: 모든 클러스터의 실제 반지름 배열 (pt 단위)
    private func calculateAllActualRadii(allClusterInfos: [ClusterInfo], pinDict: [String: PinInfo]?) -> [Double] {
        var actualRadii: [Double] = []
        
        for clusterInfo in allClusterInfos {
            let clusterCount = clusterInfo.estateIds.count
            
            if clusterCount == 1 {
                actualRadii.append(25.0) // 노이즈는 최소 크기 (25pt)
            } else {
                if let pinDict = pinDict {
                    let pinInfos = clusterInfo.estateIds.compactMap { pinDict[$0] }
                    let maxInternalDistance = calculateMaxInternalDistance(pins: pinInfos)
                    let actualRadius = max(maxInternalDistance * 0.5, 25.0)
                    actualRadii.append(actualRadius)
                } else {
                    actualRadii.append(25.0) // 기본값 (25pt)
                }
            }
        }
        
        return actualRadii
    }

    
}

// MARK: 적응형 k 계산 및 최적화된 클러스터링

extension ClusteringHelper {
    
    /// 줌 레벨과 데이터 특성을 고려한 적응형 k 계산
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록
    ///   - zoomLevel: 현재 줌 레벨 (6-14)
    /// - Returns: 최적화된 k값
    /// - Note: 데이터 크기에 따라 동적으로 k 상한을 조정하여 더 정확한 밀도 추정을 제공합니다
    func calculateAdaptiveK(pins: [PinInfo], zoomLevel: Double) -> Int {
        let n = pins.count
        
        // 1. 데이터 크기 기반 기본 k 계산
        let baseK = getBaseKBySize(n: n)
        
        // 2. 줌 레벨 기반 밀도 추정
        let densityFactor = estimateDensityWithKDTree(pins: pins, zoomLevel: zoomLevel)
        
        // 3. 동적 상한 계산 (로그 스케일)
        let maxK = calculateDynamicMaxK(dataSize: n)
        
        // 4. 최종 k 계산 및 동적 범위 제한
        let finalK = max(3, min(maxK, Int(Double(baseK) * densityFactor)))
        
        return finalK
    }
    
    /// 데이터 크기에 따른 동적 k 상한을 계산합니다.
    /// 로그 스케일을 사용하여 대용량 데이터에서도 적절한 세밀도를 유지합니다.
    /// 
    /// - Parameter dataSize: 데이터 크기
    /// - Returns: 동적으로 계산된 k 상한값
    /// - Note: 데이터 크기가 클수록 약간 더 큰 k를 허용하되, 계산 부담을 최소화합니다
    private func calculateDynamicMaxK(dataSize: Int) -> Int {
        // 로그 스케일 상한: min(100, log2(n))
        let logBasedMax = Int(log2(Double(dataSize)))
        let absoluteMax = 100
        
        // 데이터 크기별 세밀한 조정
        let adjustedMax: Int
        switch dataSize {
        case 0..<100:
            adjustedMax = 20      // 작은 데이터셋: 보수적 상한
        case 100..<1000:
            adjustedMax = 40      // 중간 데이터셋: 적당한 상한
        case 1000..<10000:
            adjustedMax = 60      // 큰 데이터셋: 더 큰 상한
        case 10000..<100000:
            adjustedMax = 80      // 매우 큰 데이터셋: 큰 상한
        default:
            adjustedMax = 100     // 대용량 데이터셋: 최대 상한
        }
        
        // 로그 기반 상한과 절대 상한 중 더 작은 값 선택
        let logMax = min(logBasedMax, absoluteMax)
        
        // 데이터 크기별 조정된 상한과 로그 기반 상한 중 더 작은 값 선택
        return min(adjustedMax, logMax)
    }
    
    /// 데이터 크기 기반 기본 k 계산
    /// 
    /// - Parameter n: 데이터 개수
    /// - Returns: 기본 k값
    private func getBaseKBySize(n: Int) -> Int {
        switch n {
        case 0..<100: return 3
        case 100..<500: return 5
        case 500..<2000: return 8
        default: return 12
        }
    }
    
    /// 줌 레벨과 데이터 분포를 고려한 동적 기준 거리 계산
    /// 
    /// - Parameters:
    ///   - zoomLevel: 현재 줌 레벨 (6-14)
    ///   - coreDistances: Core distance 딕셔너리 (데이터 분포 분석용)
    /// - Returns: 데이터 분포에 맞게 조정된 기준 거리 (미터)
    /// - Note: Core distance의 분산을 분석하여 기준 거리를 동적으로 조정합니다
    private func getBaseDistanceForZoom(zoomLevel: Double, coreDistances: [String: Double?]? = nil) -> Double {
        let baseDistance: Double
        switch zoomLevel {
        case 6: baseDistance = 5000   // 122km의 약 4%
        case 7: baseDistance = 2500   // 61km의 약 4%
        case 8: baseDistance = 1200   // 30km의 약 4%
        case 9: baseDistance = 600    // 15km의 약 4%
        case 10: baseDistance = 300   // 7km의 약 4%
        case 11: baseDistance = 150   // 3km의 약 4%
        case 12: baseDistance = 80    // 1km의 약 8%
        case 13: baseDistance = 40    // 500m의 약 8%
        case 14: baseDistance = 20    // 250m의 약 8%
        default: baseDistance = 100
        }
        
        // Core distance가 제공된 경우 데이터 분포 기반 조정
        guard let coreDistances = coreDistances else { return baseDistance }
        
        let validCoreDistances = coreDistances.compactMap { $0.value }
        guard !validCoreDistances.isEmpty else { return baseDistance }
        
        // 데이터 분포 분석
        let adjustedDistance = calculateDistributionAdjustedDistance(
            baseDistance: baseDistance,
            coreDistances: validCoreDistances
        )
        
        return adjustedDistance
    }
    
    /// Core distance의 분포를 분석하여 기준 거리를 동적으로 조정합니다.
    /// 
    /// - Parameters:
    ///   - baseDistance: 줌 레벨 기반 기본 거리
    ///   - coreDistances: 유효한 Core distance 배열
    /// - Returns: 데이터 분포에 맞게 조정된 거리
    /// - Note: 분산, IQR, 그리고 극값을 모두 고려하여 안정적인 조정을 수행합니다
    private func calculateDistributionAdjustedDistance(baseDistance: Double, coreDistances: [Double]) -> Double {
        guard coreDistances.count >= 3 else { return baseDistance } // 최소 3개 이상 필요
        
        let sortedDistances = coreDistances.sorted()
        let count = sortedDistances.count
        
        // 1. 기본 통계 계산
        let mean = sortedDistances.reduce(0, +) / Double(count)
        let variance = sortedDistances.reduce(0) { $0 + pow($1 - mean, 2) } / Double(count)
        let stdDev = sqrt(variance)
        
        // 2. IQR (Interquartile Range) 계산
        let q1Index = Int(floor(0.25 * Double(count - 1)))
        let q3Index = Int(floor(0.75 * Double(count - 1)))
        let q1 = sortedDistances[q1Index]
        let q3 = sortedDistances[q3Index]
        let iqr = q3 - q1
        
        // 3. 분산 기반 조정 팩터 (CV: Coefficient of Variation 사용)
        let coefficientOfVariation = stdDev / mean
        let varianceFactor = min(0.8, coefficientOfVariation * 0.5) // 최대 80% 증가
        
        // 4. IQR 기반 조정 팩터 (더 안정적인 지표)
        let iqrFactor = min(0.6, (iqr / mean) * 0.3) // 최대 60% 증가
        
        // 5. 극값 영향 최소화 (상위/하위 10% 제외)
        let lowerBound = Int(floor(0.1 * Double(count)))
        let upperBound = Int(floor(0.9 * Double(count)))
        let trimmedMean = Array(sortedDistances[lowerBound..<upperBound]).reduce(0, +) / Double(upperBound - lowerBound)
        let trimmedVariance = Array(sortedDistances[lowerBound..<upperBound]).reduce(0) { $0 + pow($1 - trimmedMean, 2) } / Double(upperBound - lowerBound)
        let trimmedStdDev = sqrt(trimmedVariance)
        let trimmedCV = trimmedStdDev / trimmedMean
        let trimmedFactor = min(0.4, trimmedCV * 0.4) // 최대 40% 증가
        
        // 6. 최종 조정 팩터 계산 (가중 평균)
        let finalFactor = (varianceFactor * 0.3) + (iqrFactor * 0.4) + (trimmedFactor * 0.3)
        
        // 7. 조정된 거리 계산
        let adjustedDistance = baseDistance * (1 + finalFactor)
        
        // 8. 합리적인 범위 내로 제한
        let minDistance = baseDistance * 0.5  // 최소 50%
        let maxDistance = baseDistance * 2.0  // 최대 200%
        
        return max(minDistance, min(maxDistance, adjustedDistance))
    }
    
    /// KDTree를 활용한 밀도 기반 계층적 샘플링으로 밀도 추정 (줌 레벨 고려)
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록
    ///   - zoomLevel: 현재 줌 레벨
    /// - Returns: 밀도 조정 팩터
    /// - Note: 밀도가 높은 지역에서 더 많은 샘플을 선택하여 편향을 줄입니다
    private func estimateDensityWithKDTree(pins: [PinInfo], zoomLevel: Double) -> Double {
        let kdTree = KDTree(pins: pins)
        let sampleSize = min(50, pins.count)
        
        // 밀도 기반 샘플링
        let densityWeights = calculateDensityWeights(kdTree: kdTree, pins: pins) // O(n)
        let sampledIndices = selectWeightedSamples(weights: densityWeights, sampleSize: sampleSize) // O(n)
        
        var totalNearestDistance = 0.0
        var count = 0
        
        // 밀도 가중치 기반 샘플링으로 밀도 추정
        for idx in sampledIndices {
            let pin = pins[idx]
            let nearestNeighbors = kdTree.kNearestNeighbors(of: pin, k: 1) // O(log n)
            if let nearest = nearestNeighbors.first {
                totalNearestDistance += nearest.distance
                count += 1
            }
        }
        
        let avgNearestDistance = count > 0 ? totalNearestDistance / Double(count) : 0
        let baseDistance = getBaseDistanceForZoom(zoomLevel: zoomLevel)
        let densityRatio = avgNearestDistance / baseDistance
        
        // 밀도에 따른 조정 팩터 반환
        return getDensityFactor(densityRatio: densityRatio)
    }
    
    /// KDTree 노드의 밀도를 기반으로 각 포인트의 가중치를 계산합니다.
    /// 밀도가 높은 지역의 포인트에 더 높은 가중치를 부여합니다.
    /// 
    /// - Parameters:
    ///   - kdTree: 구축된 KDTree
    ///   - pins: 매물 목록
    /// - Returns: 각 포인트의 밀도 가중치 배열
    /// - Note: O(n) 복잡도로 모든 노드를 순회하며 밀도 가중치를 계산합니다
    private func calculateDensityWeights(kdTree: KDTree, pins: [PinInfo]) -> [Double] {
        var weights = [Double](repeating: 1.0, count: pins.count)
        
        // KDTree의 모든 노드를 순회하며 밀도 계산
        var nodeDensities: [String: Int] = [:] // estateId -> 노드 내 포인트 수
        
        // 각 포인트가 속한 노드의 크기를 계산
        for pin in pins {
            let nodeSize = calculateNodeSize(for: pin, in: kdTree)
            nodeDensities[pin.estateId] = nodeSize
        }
        
        // 노드 크기를 기반으로 가중치 계산
        let maxNodeSize = nodeDensities.values.max() ?? 1
        let minNodeSize = nodeDensities.values.min() ?? 1
        
        for (index, pin) in pins.enumerated() {
            let nodeSize = nodeDensities[pin.estateId] ?? 1
            
            // 밀도가 높은 노드(큰 노드)에 더 높은 가중치 부여
            if maxNodeSize > minNodeSize {
                let densityRatio = Double(nodeSize - minNodeSize) / Double(maxNodeSize - minNodeSize)
                weights[index] = 1.0 + (densityRatio * 2.0) // 최대 3배 가중치
            }
        }
        
        return weights
    }
    
    /// 특정 포인트가 속한 KDTree 노드의 크기를 계산합니다.
    /// 
    /// - Parameters:
    ///   - pin: 대상 포인트
    ///   - kdTree: KDTree
    /// - Returns: 노드 내 포인트 수
    private func calculateNodeSize(for pin: PinInfo, in kdTree: KDTree) -> Int {
        // 간단한 근사: k=5 이웃 검색으로 지역 밀도 추정
        let neighbors = kdTree.kNearestNeighbors(of: pin, k: 5)
        let avgDistance = neighbors.map { $0.distance }.reduce(0, +) / Double(neighbors.count)
        
        // 평균 거리가 작을수록 밀도가 높음
        let densityFactor = max(1.0, 100.0 / max(avgDistance, 1.0))
        return Int(densityFactor)
    }
    
    /// 가중치 기반 무작위 샘플링을 수행합니다.
    /// 밀도가 높은 지역에서 더 많은 샘플을 선택합니다.
    /// 
    /// - Parameters:
    ///   - weights: 각 포인트의 가중치 배열
    ///   - sampleSize: 선택할 샘플 수
    /// - Returns: 선택된 샘플 인덱스 배열
    /// - Note: O(n) 복잡도로 가중치 기반 샘플링을 수행합니다
    private func selectWeightedSamples(weights: [Double], sampleSize: Int) -> [Int] {
        guard !weights.isEmpty else { return [] }
        
        // 누적 가중치 계산
        var cumulativeWeights: [Double] = []
        var totalWeight = 0.0
        
        for weight in weights {
            totalWeight += weight
            cumulativeWeights.append(totalWeight)
        }
        
        var selectedIndices: [Int] = []
        var usedIndices = Set<Int>()
        
        // 가중치 기반 무작위 샘플링
        while selectedIndices.count < sampleSize && selectedIndices.count < weights.count {
            let randomValue = Double.random(in: 0..<totalWeight)
            
            // 이진 탐색으로 해당 가중치에 해당하는 인덱스 찾기
            var left = 0
            var right = cumulativeWeights.count - 1
            var selectedIndex = 0
            
            while left <= right {
                let mid = (left + right) / 2
                if randomValue <= cumulativeWeights[mid] {
                    selectedIndex = mid
                    right = mid - 1
                } else {
                    left = mid + 1
                }
            }
            
            // 중복 방지
            if !usedIndices.contains(selectedIndex) {
                selectedIndices.append(selectedIndex)
                usedIndices.insert(selectedIndex)
            }
        }
        
        return selectedIndices
    }
    
    /// 밀도 비율에 따른 조정 팩터 계산
    /// 
    /// - Parameter densityRatio: 밀도 비율 (실제 거리 / 기준 거리)
    /// - Returns: k 조정 팩터
    private func getDensityFactor(densityRatio: Double) -> Double {
        switch densityRatio {
        case 0..<0.3: return 1.5   // 매우 고밀도
        case 0.3..<0.7: return 1.2  // 고밀도
        case 0.7..<1.2: return 1.0  // 중밀도
        case 1.2..<2.0: return 0.8  // 저밀도
        default: return 0.6         // 매우 저밀도
        }
    }
    
    /// 최적화된 클러스터링 (O(n log n) 복잡도)
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록
    ///   - zoomLevel: 현재 줌 레벨 (6-14)
    /// - Returns: 클러스터링 결과
    func clusterOptimized(pins: [PinInfo], zoomLevel: Double) -> (clusters: [ClusterInfo], noise: [PinInfo]) {
        guard !pins.isEmpty else { return (clusters: [], noise: []) }
        let randomInt = Int.random(in: 0...100)
        
        // 1. 적응형 k 계산 (O(n log n))
        let k = calculateAdaptiveK(pins: pins, zoomLevel: zoomLevel)
        
        // 2. Core Distance 계산 (O(n log n))
        let coreDistances = computeCoreDistancesOptimized(pins: pins, k: k)
        
        // 3. 근사 Mutual Reachability 계산 (O(n log n))
        let edges = buildApproximateMutualReachability(pins: pins, coreDistances: coreDistances, k: k)
        
        // 4. 근사 MST 계산 (O(n log n))
        let mstEdges = computeApproximateMST(edges: edges)
        
        // 5. 줌 레벨과 매물 분포를 고려한 임계값 계산 (O(n log n))
        let maxDistance = calculateZoomIndependentMaxDistance(pins: pins, k: k, multiplier: 1.8, zoomLevel: zoomLevel)
        
        // 6. 클러스터 트리 구축 (O(n log n))
        let clusters = buildClusterTree(mstEdges: mstEdges, threshold: maxDistance)
        
        // 7. 클러스터 정제 및 노이즈 분리 (O(n))
        let (validClusters, noiseIds) = extractValidClustersAndNoise(from: clusters, minClusterSize: 2, allPins: pins)
        
        // 8. 최종 ClusterInfo 생성 (O(n))
        let pinDict = Dictionary(uniqueKeysWithValues: pins.map { ($0.estateId, $0) })
        let clusterInfos = generateClusterInfo(from: validClusters, pinDict: pinDict, coreDistances: coreDistances, maxDistance: maxDistance)
        let noisePins = noiseIds.compactMap { pinDict[$0] }
        return (clusters: clusterInfos, noise: noisePins)
    }
    
    /// 근사 Mutual Reachability 계산 (O(n log n))
    /// 
    /// - Parameters:
    ///   - pins: 매물 목록
    ///   - coreDistances: Core Distance 딕셔너리
    ///   - k: 고려할 이웃 수
    /// - Returns: 근사 Mutual Reachability 간선 목록
    private func buildApproximateMutualReachability(pins: [PinInfo], coreDistances: [String: Double?], k: Int) -> [(String, String, Double)] {
        let kdTree = KDTree(pins: pins)
        var edges: [(String, String, Double)] = []
        
        // 각 매물마다 k개의 가장 가까운 이웃만 고려
        for pin in pins {
            let neighbors = kdTree.kNearestNeighbors(of: pin, k: k)
            
            for neighbor in neighbors {
                let core1: Double = coreDistances[pin.estateId].flatMap { $0 } ?? Double.infinity
                let core2: Double = coreDistances[neighbor.pin.estateId].flatMap { $0 } ?? Double.infinity
                let mutualReachability = max(core1, core2, neighbor.distance)
                
                // 중복 방지를 위한 정렬된 추가
                let edge = pin.estateId < neighbor.pin.estateId ? 
                    (pin.estateId, neighbor.pin.estateId, mutualReachability) :
                    (neighbor.pin.estateId, pin.estateId, mutualReachability)
                
                if !edges.contains(where: { $0.0 == edge.0 && $0.1 == edge.1 }) {
                    edges.append(edge)
                }
            }
        }
        
        return edges
    }
    
    /// 근사 MST 계산 (O(n log n))
    /// 
    /// - Parameter edges: 근사 Mutual Reachability 간선 목록
    /// - Returns: MST 간선 목록
    private func computeApproximateMST(edges: [(String, String, Double)]) -> [(String, String, Double)] {
        // 간선 수가 O(n)이므로 기존 MST 알고리즘 사용 가능
        return computeMST(edges: edges) // O(n log n)
    }
}

