//
//  MyTabView.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import SwiftUI

struct MyTabView: View {
    let di: DIContainer
    
    enum Tab {
        case home, favorite, myPage
    }
    
    @State private var selected: Tab = .home
    @State private var homePath = NavigationPath()
    @State private var favoritePath = NavigationPath()
    @State private var myPagePath = NavigationPath()
    
    init(di: DIContainer) {
        self.di = di
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selected) {
                NavigationStack(path: $homePath) {
                    HomeView(di: di, path: $homePath)

                } .tag(Tab.home)
                
                NavigationStack(path: $favoritePath) {
                    FavoriteEstatesView(di: di, path: $favoritePath)

                } .tag(Tab.favorite)
                
                NavigationStack(path: $myPagePath) {
                    MyPageView(di: di, path: $myPagePath)

                } .tag(Tab.myPage)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            if shouldShowTabBar {
                tabBar
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private var shouldShowTabBar: Bool {
        switch selected {
        case .home:
            return homePath.isEmpty
        case .favorite:
            return favoritePath.isEmpty
        case .myPage:
            return myPagePath.isEmpty
        }
    }
    
    var tabBar: some View {
        HStack {
            Spacer()
            Button {
                selected = .home
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .home ? "Home_Fill" : "Home_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .home {
                        Text("홈")
                            .font(.system(size: 11))
                    }
                }
            }
            .foregroundStyle(selected == .home ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                selected = .favorite
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .favorite ? "Interest_Fill" : "Interest_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .favorite {
                        Text("관심매물")
                            .font(.system(size: 11))
                    }
                }
            }
            .foregroundStyle(selected == .favorite ? Color.DeepForest : Color.Deselected)
            Spacer()
            Button {
                selected = .myPage
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .myPage ? "User_Fill" : "User_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .myPage {
                        Text("프로필")
                            .font(.system(size: 11))
                    }
                }
            }
            .foregroundStyle(selected == .myPage ? Color.DeepForest : Color.Deselected)
            Spacer()
        }
        .padding(.vertical)
        .frame(height: 78)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(Color.white)
                .clipShape(
                    .rect(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        }
    }
}
