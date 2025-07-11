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
                            .padding(.top, 60) // 상단 영역에 충분한 여백
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true) // 네비게이션 바 완전히 숨김
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
        .background(Color.white.opacity(0.9))
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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // TabView로 페이지 처리
                TabView(selection: $currentPage) {
                    ForEach(Array(entity.enumerated()), id: \.offset) { index, item in
                        ZStack(alignment: .bottom) {
                            CustomAsyncImage(imagePath: item.summary.thumbnail)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                            
                            // 텍스트 콘텐츠
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.address)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(item.summary.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                
                                Text(item.summary.introduction)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            .padding(20)
                            .padding(.bottom, 40)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
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
                            .font(.caption)
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
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color.MainTextColor)
            
            Spacer()
            
            if hasViewAll {
                Button(action: {
                    onViewAllTapped?()
                }) {
                    Text("View All")
                        .font(.subheadline)
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
                    VStack(alignment: .leading, spacing: 8) {
                        // 썸네일 이미지
                        CustomAsyncImage(imagePath: entity[index].summary.thumbnail
                        )
                        .frame(width: 200, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        // 정보
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(entity[index].summary.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(entity[index].summary.area)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 4) {
                                Text("월세")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(entity[index].summary.deposit)/\(entity[index].summary.monthlyRent)")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.MainTextColor)
                            }
                            
                            Text(entity[index].address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: 200)
                    .background(Color.white)
                    .cornerRadius(12)
                    .onTapGesture {
                         onTap(entity[index].summary.estateId)
                     }
                }
            }
            .padding(.horizontal)
        }
    }

}

// 5. 인기 매물 뷰
struct HotEstateItemView: View {
    let item: HotEstateWithAddress
    let onTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 썸네일 이미지
            CustomAsyncImage(imagePath: item.summary.thumbnail)
                .frame(width: 200, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    item.summary.isRecommended ?
                    Text("추천")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.OliveMist)
                        .cornerRadius(4)
                        .padding(6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    : nil
                )
                
            
            // 정보 섹션
            itemInfoSection
        }
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(12)
        .onTapGesture {
            onTap(item.summary.estateId)
        }
    }
    
    private var itemInfoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.summary.title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Color.MainTextColor)
                .lineLimit(1)
            
            priceInfoView
            addressAndAreaView
            likesView
        }
    }
    
    private var priceInfoView: some View {
        HStack {
            Text("월세")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(item.summary.deposit)/\(item.summary.monthlyRent)")
                .font(.subheadline)
                .fontWeight(.bold)
        }
    }
    
    private var addressAndAreaView: some View {
        HStack {
            Text(item.address)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(item.summary.area)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var likesView: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text("\(item.summary.likeCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
        }
    }
}
// 6. 토픽 부동산 뷰
struct TopicEstateView: View {
    let entity: TopicEstateEntity
    let onTap: (URL?) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
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
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func topicCell(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entity.items[index].title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.MainTextColor)
            
            Text(entity.items[index].content)
                .font(.subheadline)
                .foregroundColor(Color.SubText)
                .lineLimit(2)
            
            Text(entity.items[index].date)
                .font(.caption)
                .foregroundColor(Color.SubText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
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
                .frame(height: 200)
        case .success(let data):
            HotEstateView(entity: data, onTap: { estateId in
                container.handle(.goToDetail(estateId: estateId))
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
