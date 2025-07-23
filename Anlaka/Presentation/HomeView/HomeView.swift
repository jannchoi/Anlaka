//
//  HomeView.swift
//  Anlaka
//
//  Created by 최정안 on 5/15/25.
//

import SwiftUI

// HomeView - 메인 화면
struct HomeView: View {
    let di: DIContainer
    @StateObject private var container: HomeContainer
    @Binding var path: NavigationPath
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @State private var searchText = ""
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self.di = di
        self._path = path
        _container = StateObject(wrappedValue: di.makeHomeContainer())
        
        // 네비게이션 바 투명하게 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            Color.WarmLinen
                .ignoresSafeArea()
            
            ZStack(alignment: .top) {
                // 컨텐츠 스크롤뷰
                ScrollView {
                    ZStack(alignment: .top) {
                        // 오늘의 부동산 - 전체 상단 영역
                        renderTodayEstate()
                            .frame(height: 400)
                        
                        // 검색바를 오늘의 부동산 위에 배치
                        searchBar
                            .padding(.horizontal)
                            .padding(.top, 80) // 상단 영역에 충분한 여백
                    }
                    
                    VStack(spacing: 24) {
                        // 카테고리
                        SectionTitleView(title: "카테고리", hasViewAll: false)
                            .padding(.top, 16) // 상단 섹션 아래 간격 추가
                        CategoryEstateView(onCategoryTapped: { category in
                            container.handle(.goToCategory(categoryType: category))
                        })
                        
                        // 최신 매물
                        SectionTitleView(title: "좋아요 매물", hasViewAll: true) {
                            container.handle(.goToEstatesAll(type: .latest))
                        }
                        renderFavoriteEstate()
                        
                        // 인기 매물
                        SectionTitleView(title: "인기 매물", hasViewAll: true) {
                            container.handle(.goToEstatesAll(type: .hot))
                        }
                        renderHotEstate()
                        
                        // 토픽 부동산
                        SectionTitleView(title: "토픽 부동산", hasViewAll: false)
                        renderTopicEstate()
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.bottom)
                }
                .refreshable {
                    // 사용자가 스크롤을 당겨서 새로고침할 때
                    container.handle(.refreshData)
                }
            }
        }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .category(let categoryType):
                    LazyView(content: CategoryDetailView(categoryType: categoryType))
                        .onAppear {
                            container.resetNavigation()
                        }
                case .estatesAll(let type):
                    LazyView(content: EstatesAllView(listType: type))
                        .onAppear {
                            container.resetNavigation()
                        }
                case .topicWeb:
                    // This is handled by the sheet, not navigation
                    EmptyView()
                case .search:
                    LazyView(content: SearchMapView(di: di,path: $path))
                        .onAppear {
                            container.resetNavigation()
                        }
                }
            }
            .onChange(of: container.model.navigationDestination) { destination in
                if let destination = destination {
                    path.append(destination)
                }
            }
            .fullScreenCover(item: Binding(
                get: { container.model.selectedEstateId},
                set: { container.model.selectedEstateId = $0 }
            )) { identifiableString in

                LazyView(content: EstateDetailView(di: di,estateId: identifiableString.id))
            }
            .sheet(isPresented: $container.model.showSafariSheet) {
                if let url = container.model.safariURL {
                    SafariWebView(url: url)
                }
            }
        
        .onAppear {
            container.handle(.initialRequest)
        }
        .edgesIgnoringSafeArea(.top) // 상단 SafeArea 무시
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.MainTextColor)
            
            TextField("검색어를 입력해주세요", text: $searchText)
                .font(.system(size: 14))
                .disabled(true) // 입력은 불가능
        }
        .padding(8)
        .background(Color.Alabaster.opacity(0.9))
        .cornerRadius(10)
        .contentShape(Rectangle()) // 전체 영역을 탭 가능하게 설정
        .onTapGesture {
            container.handle(.goToSearch)
        }
    }
    

}

// 1. 오늘의 부동산 뷰
struct TodayEstateView: View {
    let entity: [TodayEstateWithAddress]
    let onTap: () -> Void
    
    @State private var currentPage: Int = 0
    @State private var imageBrightness: [Int: Bool] = [:] // 각 페이지별 밝기 상태 저장
    
var body: some View {
    GeometryReader { geometry in
        ZStack(alignment: .bottom) {
            // TabView로 페이지 처리
            TabView(selection: $currentPage) {
                ForEach(Array(entity.enumerated()), id: \.offset) { index, item in
                    ZStack(alignment: .bottom) {
                        CustomAsyncImage.detail(
                            imagePath: item.summary.thumbnail
                        ) { image in
                            // 이미지 로드 완료 시 밝기 확인
                            if let image = image {
                                checkImageBrightness(for: index, image: image)
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        
                        // 텍스트 콘텐츠
                        VStack(alignment: .leading, spacing: 8) {
                            // 주소 캡슐 - HStack에 직접 배경 적용
                            HStack {
                                HStack(spacing: 4) {
                                    Image("Location")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(getTextColor(for: index))
                                    
                                    Text(item.address)
                                        .font(.pretendardFootnote)
                                        .foregroundColor(getTextColor(for: index))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 11)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(getTextColor(for: index) == .Alabaster ? Color.black.opacity(0.4) : Color.Alabaster.opacity(0.6))
                                )
                                
                                Spacer() // 나머지 공간을 차지
                            }
                            
                            Text(item.summary.title)
                                .font(.soyoTitle2)
                                .foregroundColor(getTextColor(for: index))
                                .multilineTextAlignment(.leading)
                            
                            Text(item.summary.introduction)
                                .font(.pretendardBody)
                                .foregroundColor(getTextColor(for: index))
                                .multilineTextAlignment(.leading)
                                .lineLimit(2)
                        }
                        .padding(20)
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: getGradientColors(for: index)),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle()) // 전체 영역을 탭 가능하게
                    .onTapGesture {
                        onTap()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        }
    }
    .ignoresSafeArea() // 전체 영역을 무시
}
    
    // 이미지 밝기 확인 함수
    private func checkImageBrightness(for index: Int, image: UIImage) {
        if let brightness = image.averageBrightness() {
            let isBright = brightness > 0.7
            DispatchQueue.main.async {
                imageBrightness[index] = isBright
            }
        }
    }
    
    // 텍스트 색상 결정 함수
    private func getTextColor(for index: Int) -> Color {
        let isBright = imageBrightness[index] ?? false
        return isBright ? Color.black : Color.Alabaster
    }
    
    // 그라데이션 색상 결정 함수
    private func getGradientColors(for index: Int) -> [Color] {
        let isBright = imageBrightness[index] ?? false
        if isBright {
            return [Color.Alabaster.opacity(0.7), Color.Alabaster.opacity(0)]
        } else {
            return [Color.black.opacity(0.7), Color.black.opacity(0)]
        }
    }
}


// 2. 카테고리 부동산 뷰
struct CategoryEstateView: View {
    let categories = ["OneRoom", "Officetel", "Apartment", "Villa", "Storefront"]
    let titles = CategoryType.allCases
    let onCategoryTapped: (CategoryType) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<categories.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 70, height: 70)
                            
                            Image(categories[index])
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                        }
                        
                        Text(titles[index].rawValue)
                            .font(.pretendardCaption)
                            .foregroundColor(Color.MainTextColor)
                    }
                    .onTapGesture {
                        onCategoryTapped(titles[index])
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// 3. 섹션 타이틀 뷰
struct SectionTitleView: View {
    let title: String
    let hasViewAll: Bool
    var onViewAllTapped: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.soyoTitle3)
                .foregroundColor(Color.MainTextColor)
            
            Spacer()
            
            if hasViewAll {
                Button(action: {
                    onViewAllTapped?()
                }) {
                    Text("View All")
                        .font(.pretendardSubheadline)
                        .foregroundColor(Color.OliveMist)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// 4. 좋아요 한 매물 뷰
struct FavoriteView: View {
    let entity: [LikeEstateWithAddress]
    let onTap: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<entity.count, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 0) {
                        // 썸네일 이미지
                        CustomAsyncImage.thumbnail(
                            imagePath: entity[index].summary.thumbnail
                        )
                        .frame(width: 166, height: 130) // width를 200에서 176으로 줄임 (좌우 패딩 12씩 고려)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.top, 12) // 상단 패딩 추가
                        .frame(maxWidth: .infinity, alignment: .center) // 가운데 정렬

                        // 정보
                        VStack(alignment: .leading, spacing: 4) {
                            Spacer()
                                .frame(height: 4) // 썸네일과 텍스트 사이 일정한 간격 유지
                            HStack {
                                Text(entity[index].summary.category)
                                    .font(.pretendardCaption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(entity[index].summary.area)")
                                    .font(.pretendardCaption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Text("월세")
                                    .font(.pretendardCaption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(entity[index].summary.deposit)/\(entity[index].summary.monthlyRent)")
                                    .font(.pretendardSubheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.MainTextColor)
                            }
                            
                            Text(entity[index].address)
                                .font(.pretendardCaption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12) // 좌우 패딩 추가
                        .padding(.bottom, 12) // 하단 패딩 추가
                    }
                    .frame(width: 190)
                    .background(Color.Alabaster)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    .onTapGesture {
                         onTap(entity[index].summary.estateId)
                     }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8) // shadow가 잘리지 않도록 하단 패딩 추가
        }
    }

}

// 5. 인기 매물 뷰
struct HotEstateItemView: View {
    let item: HotEstateWithAddress
    let onTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 썸네일 이미지 with overlays
            ZStack {
                CustomAsyncImage.detail(
                    imagePath: item.summary.thumbnail
                )
                    .frame(width: 235, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 검은색 오버레이로 어둡게 만들기
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 235, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 오버레이 컨텐츠
                VStack(alignment: .leading, spacing: 0) {
                    // 상단 오버레이 (Fire 이미지, 추천 텍스트)
                    HStack {
                        // Leading: Fire 이미지 (항상 표시)
                        Image("Fire")
                            .resizable()
                            .foregroundColor(.Alabaster)
                            .frame(width: 23, height: 23)
                        
                        Spacer()
                        
                        // Trailing: 추천 텍스트
                        if item.summary.isRecommended {
                            Text("추천")
                                .font(.pretendardCaption2)
                                .fontWeight(.bold)
                                .foregroundColor(.Alabaster)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.OliveMist)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                    
                    Spacer()
                    
                    // 우측 하단: 제목
                    HStack {
                        Spacer()
                        
                        Text(item.summary.title)
                            .font(.soyoTitle3)
                            .foregroundColor(.Alabaster)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                    }
                }
            }
            .frame(width: 235, height: 130)
            .padding(.top, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 4)
            
            // 정보 섹션
            itemInfoSection
        }
        .frame(width: 259)
        .background(Color.Alabaster)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap(item.summary.estateId)
        }
    }
    
    private var itemInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            priceInfoView
            
            HStack {
                addressView
                
                Spacer()
                
                likesView
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
    
    private var priceInfoView: some View {
        HStack {
            Text("월세")
                .font(.pretendardCaption)
                .foregroundColor(.secondary)
            
            Text("\(item.summary.deposit)/\(item.summary.monthlyRent)")
                .font(.pretendardSubheadline)
                .fontWeight(.bold)
        }
    }
    
    private var addressView: some View {
        Text(item.address)
            .font(.pretendardCaption)
            .foregroundColor(.secondary)
    }
    
    private var likesView: some View {
        Text("\(item.summary.likeCount)명이 보는 중")
            .font(.pretendardCaption)
            .foregroundColor(Color.Alabaster)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.SubText)
            )
    }
}


struct HotEstateView: View {
    let entity: [HotEstateWithAddress]
    let onTap: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(entity.indices, id: \.self) { index in
                    HotEstateItemView(item: entity[index], onTap: onTap)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8) // shadow가 잘리지 않도록 하단 패딩 추가
        }
    }
}
// 6. 토픽 부동산 뷰
struct TopicEstateView: View {
    let entity: TopicEstateEntity
    let onTap: (URL?) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<entity.items.count, id: \.self) { index in
                Button(action: {
                    if let linkString = entity.items[index].link, let url = URL(string: linkString) {
                        onTap(url)
                    } else {
                        // If no link, pass nil
                        onTap(nil)
                    }
                }) {
                    topicCell(for: index)
                }
                .buttonStyle(PlainButtonStyle())
                
                if index < entity.items.count - 1 {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        //.background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
    }
    
    private func topicCell(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entity.items[index].title)
                .font(.soyoHeadline)
                .foregroundColor(Color.MainTextColor)
            
            Text(entity.items[index].content)
                .font(.pretendardSubheadline)
                .foregroundColor(Color.SubText)
                .lineLimit(2)
            
            Text(entity.items[index].date)
                .font(.pretendardCaption)
                .foregroundColor(Color.SubText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.Alabaster)
    }
}

// HomeView 확장 - 각 컨테이너 렌더링 메서드
extension HomeView {
    
    @ViewBuilder
    func renderTodayEstate() -> some View {
        switch container.model.todayEstate {
        case .idle, .loading:
            ProgressView("오늘의 부동산 로딩 중…")
                .frame(height: 400)
        case .success(let data):
            TodayEstateView(entity: data, onTap: {
                if let firstItem = data.first {
                    container.handle(.goToDetail(estateId: firstItem.summary.estateId))
                }
            })
            .onAppear {
                // 이미지 프리로딩
                let imagePaths = data.map { $0.summary.thumbnail }
                CustomAsyncImage.preloadImages(imagePaths)
            }
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 400)
        case .requiresLogin:
            Text("세션이 만료되어 로그아웃되었습니다.")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 400)
                .task {
                    isLoggedIn = false
                }
        }
    }
    
    @ViewBuilder
    func renderHotEstate() -> some View {
        switch container.model.hotEstate {
        case .idle, .loading:
            ProgressView("Hot 매물 로딩 중…")
                .frame(height: 190)
        case .success(let data):
            HotEstateView(entity: data, onTap: { estateId in
                container.handle(.goToDetail(estateId: estateId))
            })
            .onAppear {
                // 이미지 프리로딩
                let imagePaths = data.map { $0.summary.thumbnail }
                CustomAsyncImage.preloadImages(imagePaths)
            }
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 190)
        case .requiresLogin:
            Text("세션이 만료되어 로그아웃되었습니다.")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 190)
                .task {
                    isLoggedIn = false
                }
        }
    }
    
    @ViewBuilder
    func renderTopicEstate() -> some View {
        switch container.model.topicEstate {
        case .idle, .loading:
            ProgressView("Topic 로딩 중…")
                .frame(height: 200)
        case .success(let data):
            TopicEstateView(entity: data, onTap: { url in
                if let url = url {
                    container.handle(.goToTopicWeb(url: url))
                } else {
                    // If no URL, we can navigate to a detail view or do nothing
                    // For now, we'll just not navigate anywhere
                }
            })
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 200)
        case .requiresLogin:
            Text("세션이 만료되어 로그아웃되었습니다.")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 400)
                .task {
                    isLoggedIn = false
                }
            
        }
    }
    @ViewBuilder
    private func renderFavoriteEstate() -> some View {
        switch container.model.likeLists {
        case .idle, .loading:
            ProgressView("좋아요 매물 로딩 중…")
                .frame(height: 200)
        case .success(let data):
            FavoriteView(entity: data, onTap: { estateId in
                container.handle(.goToDetail(estateId: estateId))
            })
            .onAppear {
                // 이미지 프리로딩
                let imagePaths = data.map { $0.summary.thumbnail }
                CustomAsyncImage.preloadImages(imagePaths)
            }
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 200)
        case .requiresLogin:
            Text("세션이 만료되어 로그아웃되었습니다.")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 200)
                .task {
                    isLoggedIn = false
                }
        }
    }
}
// Mock 데이터 구조 정의 (실제로는 별도 파일로 분리되어 있을 것입니다)
struct mockLatestData {
    struct Summary {
        let thumbnail: String
        let isRecommended: Bool
        let category: String
        let deposit: Double
        let monthlyRent: Double
        let area: Double
    }
    
    let summary: Summary
    let address: String
    
    init() {
        // 샘플 데이터
        self.summary = Summary(
            thumbnail: "https://example.com/image.jpg",
            isRecommended: Bool.random(),
            category: "원룸",
            deposit: 3000,
            monthlyRent: 20,
            area: 112.4
        )
        self.address = "문래동"
    }
}
