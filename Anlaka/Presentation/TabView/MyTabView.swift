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
        case home, favorite, profile
    }
    
    @State private var selected: Tab = .home
    
    // 각 뷰를 State로 관리하여 메모리에 유지
    @State private var homeView: HomeView
    @State private var favoriteView = FavoriteEstatesView()
    @State private var profileView = ProfileView()
    
    init(di: DIContainer) {
        self.di = di
        // State 프로퍼티는 init에서 직접 초기화할 수 없으므로 _homeView로 초기화
        _homeView = State(initialValue: HomeView(di: di))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selected) {
                Group {
                    homeView
                        .tag(Tab.home)
                    
                    favoriteView
                        .tag(Tab.favorite)
                    
                    profileView
                        .tag(Tab.profile)
                }
                .toolbar(.hidden, for: .tabBar)
            }
            
            tabBar
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
                selected = .profile
            } label: {
                VStack(alignment: .center) {
                    Image(selected == .profile ? "User_Fill" : "User_Empty")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30)
                    if selected == .profile {
                        Text("프로필")
                            .font(.system(size: 11))
                    }
                }
            }
            .foregroundStyle(selected == .profile ? Color.DeepForest : Color.Deselected)
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
