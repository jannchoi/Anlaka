//
//  SearchMapView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI
import CoreLocation

struct SearchMapView: View {
    let di: DIContainer
    @StateObject private var container: SearchMapContainer
    
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @State private var showSearchAddress = false
    @State private var path = NavigationPath()
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeSearchMapContainer())
    }
    
    var body: some View {
        ZStack {
            KakaoMapView(
                draw: .constant(container.model.shouldDrawMap),
                centerCoordinate: container.model.centerCoordinate,
                pinInfoList: container.model.pinInfoList,
                onMapReady: { maxDistance in
                    container.handle(.updateMaxDistance(maxDistance))
                },
                onMapChanged: { center, maxDistance in
                    container.handle(.mapDidStopMoving(center, maxDistance))
                },
                onPOITap: { estateId in
                    print("🧶 POI Tap \(estateId)")
                    container.handle(.poiSelected(estateId))
                },
                onPOIGroupTap: { estateIds in
                    print("🧶🧶🧶POIS Tap \(estateIds)")
                    container.handle(.poiGroupSelected(estateIds))
                }
            )
            
            VStack {
                SearchBar(searchBarTapped: $showSearchAddress, placeholder: container.model.searchedData?.title)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                // FilterButtonView 추가
                FilterButtonView(
                    selectedIndex: container.model.selectedFilterIndex,
                    onFilterTap: { index in
                        container.handle(.selectFilter(index))
                    }
                )
                
                if let filterIndex = container.model.selectedFilterIndex {
                    if filterIndex == 0 {
                        CategoryOptionView(
                            selectedCategories: container.model.selectedCategories,
                            onCategorySelect: { category in
                                container.handle(.selectCategory(category))
                            }
                        )
                        .transition(.opacity)
                    } else {
                        SliderView(
                            filterType: filterIndex,
                            areaRange: container.model.selectedAreaRange,
                            monthlyRentRange: container.model.selectedMonthlyRentRange,
                            depositRange: container.model.selectedDepositRange,
                            onAreaRangeChange: { range in
                                container.handle(.updateAreaRange(range))
                            },
                            onMonthlyRentChange: { range in
                                container.handle(.updateMonthlyRentRange(range))
                            },
                            onDepositChange: { range in
                                container.handle(.updateDepositRange(range))
                            }
                        )
                        .transition(.opacity)
                    }
                }
                
                Spacer()
                
                // EstateScrollView 추가
                if container.model.showEstateScroll {
                    EstateScrollView(
                        estates: container.model.filteredEstates,
                        onEstateSelect: { estateId in
                            path.append(SearchMapRoute.detail(estateId: estateId))
                        },
                        onClose: {
                            container.handle(.hideEstateScroll)
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            if container.model.isLoading {
                ProgressView()
            }
            
            if let errorMessage = container.model.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SearchMapRoute.self) { route in // 추가
            switch route {
            case .detail(let estateId):
                LazyView(content: EstateDetailView(estateId: estateId))
            }}
                .animation(.easeInOut(duration: 0.3), value: container.model.selectedFilterIndex) // 추가
                .animation(.easeInOut(duration: 0.3), value: container.model.showEstateScroll) // 추가
                .onAppear {
                    container.handle(.requestLocationPermission)
                }
                .onChange(of: container.model.backToLogin) { needsLogin in
                    if needsLogin {
                        isLoggedIn = false
                    }
                }
                .fullScreenCover(isPresented: $showSearchAddress) {
                    SearchAddressView(
                        di: di,
                        isPresented: $showSearchAddress,
                        onAddressSelected: { selectedAddress in
                            
                            container.handle(.searchBarSubmitted(selectedAddress))
                            
                        },
                        onDismiss: {
                            print("onDismiss")
                        }
                    )
                }
        }
    }

struct SearchBar: View {
    @Binding var searchBarTapped: Bool
    var placeholder: String?
    private var resolvedPlaceholder : String {
        return (placeholder ?? "").isEmpty ? "주소를 입력하세요" : (placeholder ?? "")
    }
    var body: some View {
        ZStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                Text(resolvedPlaceholder)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.warmLinen.withAlphaComponent(0.6)))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.8), lineWidth: 1)
                )
        )
        .onTapGesture {
            searchBarTapped = true
        }
    }
}



// MARK: - FilterButtonView
struct FilterButtonView: View {
    let selectedIndex: Int?
    let onFilterTap: (Int?) -> Void
    
    private let filterTitles = ["카테고리", "평수 선택", "월세 선택", "보증금 선택"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<filterTitles.count, id: \.self) { index in
                Button(action: {
                    onFilterTap(selectedIndex == index ? nil : index)
                }) {
                    Text(filterTitles[index])
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedIndex == index ? Color.oliveMist : Color.white)
                        .foregroundColor(selectedIndex == index ? .white : .black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - SliderView
struct SliderView: View {
    let filterType: Int
    let areaRange: ClosedRange<Double>
    let monthlyRentRange: ClosedRange<Double>
    let depositRange: ClosedRange<Double>
    let onAreaRangeChange: (ClosedRange<Double>) -> Void
    let onMonthlyRentChange: (ClosedRange<Double>) -> Void
    let onDepositChange: (ClosedRange<Double>) -> Void
    
    @State private var areaValues: ClosedRange<Double>
    @State private var monthlyRentValues: ClosedRange<Double>
    @State private var depositValues: ClosedRange<Double>
    
    init(filterType: Int,
         areaRange: ClosedRange<Double>,
         monthlyRentRange: ClosedRange<Double>,
         depositRange: ClosedRange<Double>,
         onAreaRangeChange: @escaping (ClosedRange<Double>) -> Void,
         onMonthlyRentChange: @escaping (ClosedRange<Double>) -> Void,
         onDepositChange: @escaping (ClosedRange<Double>) -> Void) {
        self.filterType = filterType
        self.areaRange = areaRange
        self.monthlyRentRange = monthlyRentRange
        self.depositRange = depositRange
        self.onAreaRangeChange = onAreaRangeChange
        self.onMonthlyRentChange = onMonthlyRentChange
        self.onDepositChange = onDepositChange
        
        _areaValues = State(initialValue: areaRange)
        _monthlyRentValues = State(initialValue: monthlyRentRange)
        _depositValues = State(initialValue: depositRange)
    }
    
    var body: some View {
        VStack(spacing: 12) {
  // 평수: 0~200, 월세: 0~5000, 보증금: 0~50000
switch filterType {
case 1:
    sliderContent(
        title: "평수",
        range: 0...200,
        values: $areaValues,
        unit: "평",
        onChange: onAreaRangeChange
    )
case 2:
    sliderContent(
        title: "월세",
        range: 0...5000,
        values: $monthlyRentValues,
        unit: "만원",
        onChange: onMonthlyRentChange
    )
case 3:
    sliderContent(
        title: "보증금",
        range: 0...50000,
        values: $depositValues,
        unit: "만원",
        onChange: onDepositChange
    )

            default:
                EmptyView()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
    
    private func sliderContent(
    title: String,
    range: ClosedRange<Double>,
    values: Binding<ClosedRange<Double>>,
    unit: String,
    onChange: @escaping (ClosedRange<Double>) -> Void
) -> some View {
    VStack(spacing: 16) {
        // 제목 및 범위 표시
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
            Spacer()
            Text("\(formatValue(values.wrappedValue.lowerBound, unit: unit)) ~ \(formatValue(values.wrappedValue.upperBound, unit: unit))")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        //백억
        // 커스텀 Range Slider
        CustomRangeSlider(
            range: range,
            values: values,
            unit: unit,
            onChange: onChange,
            filterType: filterType
        )
        .frame(height: 40)
        
        // 하단 눈금 - filterType별로 다르게 표시
        bottomLabels(for: filterType)
    }
}
}
struct CustomRangeSlider: View {
    let range: ClosedRange<Double>
    @Binding var values: ClosedRange<Double>
    let unit: String
    let onChange: (ClosedRange<Double>) -> Void
    let filterType: Int
    
    @State private var isDraggingLower = false
    @State private var isDraggingUpper = false
    
    @State private var dragStartLower: CGFloat = 0
    @State private var dragStartUpper: CGFloat = 0
    

    
    // 눈금 값에 따른 슬라이더 위치를 계산하는 함수
    private func calculatePosition(for value: Double, in range: ClosedRange<Double>, sliderWidth: CGFloat) -> CGFloat {
        let totalRange = range.upperBound - range.lowerBound
        return CGFloat((value - range.lowerBound) / totalRange) * sliderWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width
            let totalRange = range.upperBound - range.lowerBound
            
            // 낮은 값의 위치 계산
            let lowerPosition = calculatePosition(for: values.lowerBound, in: range, sliderWidth: sliderWidth)
            // 높은 값의 위치 계산
            let upperPosition = calculatePosition(for: values.upperBound, in: range, sliderWidth: sliderWidth)
            
            ZStack {
                // 배경 슬라이더 라인
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                // 선택된 범위 강조 라인
                Capsule()
                    .fill(LinearGradient(colors: [Color.teal, Color.black], startPoint: .leading, endPoint: .trailing))
                    .frame(width: upperPosition - lowerPosition, height: 4)
                    .offset(x: lowerPosition - sliderWidth/2 + (upperPosition - lowerPosition)/2)
                
                // 하단 knob (낮은 값)
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .shadow(radius: 2)
                    .offset(x: lowerPosition - sliderWidth/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDraggingLower {
                                    dragStartLower = lowerPosition
                                    isDraggingLower = true
                                }
                                let delta = value.translation.width
                                let newPosition = max(0, min(sliderWidth, dragStartLower + delta))
                                let newValue = range.lowerBound + (Double(newPosition) / Double(sliderWidth)) * totalRange
                                let clampedValue = max(range.lowerBound, min(values.upperBound, newValue))
                                values = clampedValue...values.upperBound
                                onChange(values)
                            }
                            .onEnded { _ in
                                isDraggingLower = false
                            }
                    )
                
                // 상단 knob (높은 값)
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .shadow(radius: 2)
                    .offset(x: upperPosition - sliderWidth/2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !isDraggingUpper {
                                    dragStartUpper = upperPosition
                                    isDraggingUpper = true
                                }
                                let delta = value.translation.width
                                let newPosition = max(0, min(sliderWidth, dragStartUpper + delta))
                                let newValue = range.lowerBound + (Double(newPosition) / Double(sliderWidth)) * totalRange
                                let clampedValue = max(values.lowerBound, min(range.upperBound, newValue))
                                values = values.lowerBound...clampedValue
                                onChange(values)
                            }
                            .onEnded { _ in
                                isDraggingUpper = false
                            }
                    )
                
                // 말풍선 (드래그 중일 때만 표시)
                if isDraggingLower || isDraggingUpper {
                    VStack {
                        Text("\(formatValue(values.lowerBound, unit: unit)) ~ \(formatValue(values.upperBound, unit: unit))")
                            .font(.system(size: 12, weight: .bold))
                            .padding(6)
                            .background(Color.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .shadow(radius: 2)
                        Spacer()
                    }
                    .offset(y: -35)
                }
            }
        }
    }
}


// 새로 추가되는 helper 메서드들
private func formatValue(_ value: Double, unit: String) -> String {
    switch unit {
    case "평":
        return "\(Int(value))평"
    case "만원":
        if value >= 10000 {
            // 1억 이상
            let billion = value / 10000
            return String(format: "%.1f억", billion)
        } else if value >= 1000 {
            // 1000만 이상 1억 미만
            let thousand = Int(value / 1000)
            return "\(thousand)천만"
        } else {
            return "\(Int(value))만"
        }
    default:
        return "\(Int(value))\(unit)"
    }
}

private func bottomLabels(for filterType: Int) -> some View {
    HStack {
        switch filterType {
        case 1: // 평수
            Text("최소")
            Spacer()
            Text("5평")
            Spacer()
            Text("100평")
            Spacer()
            Text("최대")
        case 2: // 월세
            Text("최소")
            Spacer()
            Text("30만")
            Spacer()
            Text("300만")
            Spacer()
            Text("최대")
        case 3: // 보증금
            Text("최소")
            Spacer()
            Text("200만")
            Spacer()
            Text("1억")
            Spacer()
            Text("최대")
        default:
            EmptyView()
        }
    }
    .font(.system(size: 12))
    .foregroundColor(.gray)
}
// MARK: - CategoryOptionView
struct CategoryOptionView: View {
    let selectedCategories: [String]
    let onCategorySelect: (String?) -> Void
    
    private let categories = ["원룸", "오피스텔", "아파트", "빌라", "상가"]
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("카테고리 선택")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                if !selectedCategories.isEmpty {
                    Button(action: {
                        onCategorySelect(nil)
                    }) {
                        Text("초기화")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        onCategorySelect(category)
                    }) {
                        Text(category)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 8)
                            .background(selectedCategories.contains(category) ? Color.oliveMist : Color.gray.opacity(0.1))
                            .foregroundColor(selectedCategories.contains(category) ? .white : .black)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

// MARK: - EstateScrollView
struct EstateScrollView: View {
    let estates: [DetailEstateEntity]
    let onEstateSelect: (String) -> Void
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("매물 \(estates.count)개")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            
            // 스크롤 뷰
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(estates, id: \.estateId) { estate in
                        EstateCardView(estate: estate) {
                            onEstateSelect(estate.estateId)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 200)
        }
        .background(Color.white)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(radius: 4)
    }
}

// MARK: - EstateCardView
struct EstateCardView: View {
    let estate: DetailEstateEntity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 썸네일 (실제로는 이미지 로딩 필요)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 100)
                    .cornerRadius(8)
                    .overlay(
                        Text("이미지")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(estate.category)
                        .font(.caption)
                        .foregroundColor(.oliveMist)
                    
                    Text(estate.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                    
                    Text("보증금 \(Int(estate.deposit))/월세 \(Int(estate.monthlyRent))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("\(Int(estate.area))평 · \(estate.floors)층")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("서울 영등포구 선유로9길 30")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 150)
    }
}


// MARK: - View Extension for specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

