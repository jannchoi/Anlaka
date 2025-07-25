//
//  CommunityView.swift
//  Anlaka
//
//  Created by 최정안 on 7/18/25.
//

import SwiftUI
import CoreLocation

struct CommunityView: View {
    @StateObject private var container: CommunityContainer
    @State private var profileImageData: Data?
    @Binding var path: NavigationPath
    let di: DIContainer
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self._container = StateObject(wrappedValue: di.makeCommunityContainer())
        self._path = path
        self.di = di
    }
    
    var body: some View {
        ZStack {
            Color.WarmLinen
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomNavigationBar(
                    title: container.model.currentLocation,
                    rightButton: {
                        // 위치 찾기 버튼
                        Button(action: {
                            container.handle(.showLocationSearch)
                        }) {
                            Text("위치 찾기")
                                .font(.pretendardSubheadline)
                                .foregroundColor(.MainTextColor)
                        }
                    }
                )
                
                ScrollView {
                    VStack(spacing: 0) {
                        searchBar
                        
                        HStack(spacing: 12) {
                            sortView
                            categoryView
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        boardView
                    }
                }
                .onAppear {
                    container.handle(.onAppear)
                    CurrentScreenTracker.shared.setCurrentScreen(.community)
                }
            }
            
            // SearchAddressView 오버레이
            if container.model.showSearchAddressView {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        container.handle(.dismissLocationSearch)
                    }
                
                SearchAddressView(
                    di:di,
                    isPresented: $container.model.showSearchAddressView,
                    onAddressSelected: { searchData in
                        // SearchAddressView에서 선택된 위치 정보를 CommunityContainer로 전달
                        let coordinate = CLLocationCoordinate2D(
                            latitude: searchData.latitude,
                            longitude: searchData.longitude
                        )
                        container.handle(.locationSelected(coordinate, searchData.title))
                    },
                    onDismiss: {
                        container.handle(.dismissLocationSearch)
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.Alabaster)
                .cornerRadius(12)
                .padding()
            }
            
            // Posting Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    postingButton
                }
                .padding(.trailing, 20)
                .padding(.bottom, 58) // 탭바 높이(78) + 20 offset
            }
        }
        .navigationDestination(for: AppRoute.CommunityRoute.self) { route in
            switch route {
            case .posting:
                LazyView(content: PostingView(di: di, path: $path))
            case .postDetail(let postId):
                LazyView(content: PostDetailView(postId: postId, di: di, path: $path))
            }
        }
    }
    
    // MARK: - Posting Button
    private var postingButton: some View {
        Button(action: {
            path.append(AppRoute.CommunityRoute.posting)
        }) {
            ZStack {
                // 흰색 배경 원형
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
                
                // 연필 아이콘
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.OliveMist)
                    .frame(width: 30, height: 30)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            
            Image("Search")
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(Color.Gray60)
            
            TextField("검색어를 입력해주세요.", text: $container.model.searchText)
                .font(.pretendardBody)
                .foregroundColor(Color.MainTextColor)
                .onSubmit {
                    if container.model.searchText.isEmpty {
                        // 검색어가 비어있으면 현재 위치로 다시 로드
                        container.handle(.searchPosts(""))
                    } else {
                        container.handle(.searchPosts(container.model.searchText))
                    }
                }
                .onChange(of: container.model.searchText) { newValue in
                    if newValue.isEmpty {
                        // 검색어가 비어있으면 현재 위치로 다시 로드
                        container.handle(.searchPosts(""))
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.Alabaster)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Sort View
    private var sortView: some View {
        Menu {
            ForEach(TextResource.Community.Sort.allCases, id: \.self) { sort in
                Button(action: {
                    container.handle(.sortPosts(sort.text))
                }) {
                    HStack {
                        Text(sort.text)
                        if container.model.selectedSort == sort {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(container.model.selectedSort.text)
                    .font(.pretendardSubheadline)
                    .foregroundColor(Color.MainTextColor)
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(Color.Gray60)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.Alabaster)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.Gray60, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Category View
    private var categoryView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TextResource.Community.Category.allCases.filter { $0 != .all }, id: \.self) { category in
                    Button(action: {
                        if container.model.selectedCategory == category {
                            // If same category is selected, deselect it (go back to all)
                            container.handle(.filterByCategory(TextResource.Community.Category.all.text))
                        } else {
                            // Select new category
                            container.handle(.filterByCategory(category.text))
                        }
                    }) {
                        Text(category.text)
                            .font(.pretendardSubheadline)
                            .foregroundColor(container.model.selectedCategory == category ? Color.MainTextColor : Color.Gray75)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(container.model.selectedCategory == category ? Color.TagBackground : Color.clear)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.Gray60, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Board View
    private var boardView: some View {
        VStack(spacing: 0) {
            switch container.model.posts {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView()
                    .padding()
            case .success(let posts):
                if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "xmark.bin")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(Color.Gray60)
                        Text("검색 결과가 없습니다")
                            .font(.pretendardBody)
                            .foregroundColor(Color.Gray60)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(posts.enumerated()), id: \.element.postId) { index, post in
                            postCell(for: post)
                            
                            if index < posts.count - 1 {
                                Divider()
                                    .background(Color.Gray60)
                                    .padding(.horizontal, 16)
                            }
                            
                            // Load more when reaching the last item (위치 검색 모드에서만)
                            if index == posts.count - 1 && 
                               !container.model.isSearchMode && 
                               container.model.nextCursor != nil {
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        container.handle(.loadMorePosts)
                                    }
                            }
                        }
                        
                        // Loading indicator for pagination
                        if container.model.isLoadingMore {
                            ProgressView()
                                .padding()
                        }
                    }
                }
            case .failure(let error):
                Text("오류가 발생했습니다: \(error)")
                    .foregroundColor(Color.TomatoRed)
                    .padding()
            case .requiresLogin:
                Text("로그인이 필요합니다.")
                    .foregroundColor(Color.TomatoRed)
                    .padding()
            }
        }
        .background(Color.Alabaster)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Post Cell
    private func postCell(for post: PostSummaryResponseEntity) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Category Tag
                Text(post.category)
                    .font(.soyoCaption2)
                    .foregroundColor(Color.Gray60)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.TagBackground)
                    .cornerRadius(4)
                
                // Title
                Text(post.title)
                    .font(.pretendardSubheadline)
                    .foregroundColor(Color.MainTextColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Content
                Text(post.content)
                    .font(.soyoBody)
                    .foregroundColor(Color.Gray60)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Address, CreatedAt, Like Count
                HStack(spacing: 8) {
                    Text(post.address)
                        .font(.soyoCaption)
                        .foregroundColor(Color.Gray60)
                    
                    Text(PresentationMapper.formatRelativeTime(post.createdAt))
                        .font(.soyoCaption)
                        .foregroundColor(Color.Gray60)
                    
                    HStack(spacing: 4) {
                        Image(post.isLike ? "Like_Fill" : "Like_Empty")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(post.isLike ? Color.TomatoRed : Color.Gray60)
                        
                        Text(PresentationMapper.mapInt(post.likeCount))
                            .font(.soyoCaption)
                            .foregroundColor(Color.Gray60)
                    }
                }
            }
            
            Spacer()
            
            // Image Section
            if !post.files.isEmpty {
                ZStack(alignment: .topTrailing) {
                    CustomAsyncImage.listCell(imagePath: post.files[0])
                        .frame(width: 80, height: 80)
                        .cornerRadius(6)
                    
                    // Image Count Badge
                    if post.files.count > 1 {
                        Text("\(post.files.count)")
                            .font(.soyoCaption2)
                            .foregroundColor(Color.Alabaster)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(3)
                            .padding(4)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onTapGesture {
            path.append(post.postId)
        }
    }
}

