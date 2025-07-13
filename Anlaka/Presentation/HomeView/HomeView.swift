//
//  HomeView.swift
//  Anlaka
//
//  Created by 최정안 on 5/15/25.
//

import SwiftUI

struct HomeView: View {
    let di: DIContainer
    @StateObject private var container: HomeContainer
    @State private var path = NavigationPath()
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeHomeContainer())
    }
    var body: some View {
        VStack{
            Text("Hello, World!")
        }.onAppear{
            print("HomeView")
        }
    }
    
}
struct TodayEstateView: View {
    let entity: [TodayEstateWithAddress]
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
struct CategoryEstateView: View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
struct SectionTitleView: View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
struct LatestView: View {
    let entity: [mockLatestData] = [mockData]
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
struct HotEstateView: View {
    let entity: [HotEstateWithAddress]
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
struct TopicEstateView: View {
    let entity: TopicEstateEntity
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
extension HomeView {
    @ViewBuilder
    func renderTodayEstate() -> some View {
        switch container.model.todayEstate {
        case .idle, .loading:
            ProgressView("오늘의 부동산 로딩 중…")
        case .success(let data):
            TodayEstateView(entity: data)
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(.red)
        }
    }
    @ViewBuilder
    func renderHotEstate() -> some View {
        switch container.model.hotEstate {
        case .idle, .loading:
            ProgressView("Hot 매물 로딩 중…")
        case .success(let data):
            HotEstateView(entity: data)
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(.red)
        }
    }
    @ViewBuilder
    func renderTopicEstate() -> some View {
        switch container.model.topicEstate {
        case .idle, .loading:
            ProgressView("Topic 로딩 중…")
        case .success(let data):
            TopicEstateView(entity: data)
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(.red)
        }
    }


}
