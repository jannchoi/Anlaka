//
//  EstateDetailView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI

// MARK: - EstateDetailView 초기화 메서드 수정
struct EstateDetailView: View {
    let di: DIContainer
    @Environment(\.dismiss) private var dismiss
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @StateObject private var container: EstateDetailContainer
    @State private var path = NavigationPath()
    @State private var showPaymentStartView = false
    
    // estateId로 초기화하는 경우
    init(di: DIContainer,estateId: String) {
        self._container = StateObject(wrappedValue: di.makeEstateDetailContainer(estateId: estateId))
        self.di = di
    }
    
    // estate 객체로 초기화하는 경우
    init(di: DIContainer,estate: DetailEstateEntity) {
        self._container = StateObject(wrappedValue: di.makeEstateDetailContainer(estate: estate))
        self.di = di
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.WarmLinen
                    .ignoresSafeArea()
                
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        navigationBar
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                renderDetailEstate()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 80) // 예약 버튼의 높이만큼 패딩 추가
                        }
                    }
                    
                    if case .success(let data) = container.model.detailEstate {
                        reservationButton(isReserved: data.detail.isReserved)
                            .padding(.horizontal)
                            .background(Color.white)
                    }
                    
                    // PaymentStartView 오버레이
                    if showPaymentStartView, let payment = container.model.iamportPayment {
                        PaymentStartView(
                            di: di,
                            iamportPayment: payment,
                            showPaymentStartView: $showPaymentStartView,
                            onCancel: {
                                container.handle(.resetReservation)
                            }
                        )
                    }
                }
            }
            .navigationDestination(for: String.self) { opponent_id in
                if !opponent_id.isEmpty {
                    ChattingView(opponent_id: opponent_id, di: di, path: $path)
                }
            }
        }
        .fullScreenCover(item: Binding(
            get: { container.model.selectedEstateId },
            set: { container.model.selectedEstateId = $0 }
        )) { identifiableString in
            EstateDetailView(di: di,estateId: identifiableString.id)
        }
        .onChange(of: container.model.iamportPayment) { payment in
            if payment != nil {
                showPaymentStartView = true
            }
        }
        .onAppear {
            container.handle(.initialRequest)
        }
        .onChange(of: container.model.opponent_id) { opponent_id in
            if let opponent_id = opponent_id {
                path.append(opponent_id)
            }
        }
    }
    
}

// MARK: - NavigationBar
extension EstateDetailView {
    private var navigationBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image("chevron")
                    .font(.headline)
                    .foregroundColor(.MainTextColor)
            }
            
            Spacer()
            
            if case .success(let data) = container.model.detailEstate {
                Text(data.detail.title)
                    .font(.soyoHeadline)
                    .foregroundColor(.MainTextColor)
            }
            
            Spacer()
            
            if case .success = container.model.detailEstate {
                Button {
                    container.handle(.likeButtonTapped)
                } label: {
                    Image(container.model.isLiked ? "Like_Fill" : "Like_Empty")
                        .font(.title2)
                        .foregroundColor(container.model.isLiked ? Color.OliveMist : Color.Deselected)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
    }
}

// MARK: - TopThumbnailView
extension EstateDetailView {
    @ViewBuilder
    private func topThumbnailView(thumbnails: [String]) -> some View {
        TabView {
            ForEach(0..<thumbnails.count, id: \.self) { index in
                CustomAsyncImage.detail(imagePath: thumbnails[index])
                    .frame(height: 250)
                    .clipped()
            }
        }
        .tabViewStyle(PageTabViewStyle())
        .frame(height: 250)
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(1)/\(thumbnails.count)")
                        .font(.pretendardCaption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding()
                }
            }
        )
    }
}

// MARK: - WatchingBar
extension EstateDetailView {
    private func watchingBar(likeCount: String) -> some View {
        HStack {
            Text("\(likeCount)명이 함께 보는중")
                .font(.pretendardCaption)
                .foregroundColor(.secondary)
                .padding(.leading, 16)
            Spacer()
        }
        .frame(height: 27)
        .background(Color.SoftSage)
    }
}

// MARK: - MetaDataView
extension EstateDetailView {
    private func metaDataView(data: DetailEstateWithAddrerss) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            VStack{
                HStack{       if data.detail.isSafeEstate {
                    Image("Safty Mark")
                }
                    Spacer()
                }
                HStack{            
                    Text(data.address)
                        .font(.pretendardSubheadline)
                        .foregroundColor(.MainTextColor)
                    Spacer()}
            }
            
            
            HStack {
                Text("월세")
                    .font(.soyoTitle3)
                    .foregroundColor(.MainTextColor)
                Text("\(data.detail.deposit)/\(data.detail.monthlyRent)")
                    .font(.soyoTitle3)
                    .foregroundColor(.MainTextColor)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack{Text("관리비: \(data.detail.maintenanceFee)")
                        .font(.pretendardCaption)
                        .foregroundColor(.SubText)
                    Spacer()}
                HStack{ Text("면적: \(data.detail.area)")
                        .font(.pretendardCaption)
                        .foregroundColor(.SubText)
                    Spacer()}
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading) // 이 부분이 핵심!
    }
}


// MARK: - OptionView
extension EstateDetailView {
    private func optionView(options: OptionEntity, parkingCount: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("옵션 정보")
                .font(.soyoHeadline)
                .foregroundColor(.MainTextColor)
            
            if !options.description.isEmpty {
                Text(options.description)
                    .font(.pretendardCaption)
                    .foregroundColor(.MainTextColor)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                optionItem(title: "냉장고", imageName: "Refrigerator", isAvailable: options.refrigerator)
                optionItem(title: "세탁기", imageName: "WashingMachine", isAvailable: options.washer)
                optionItem(title: "에어컨", imageName: "AirConditioner", isAvailable: options.airConditioner)
                optionItem(title: "옷장", imageName: "Closet", isAvailable: options.closet)
                optionItem(title: "신발장", imageName: "ShoeCabinet", isAvailable: options.shoeRack)
                optionItem(title: "전자레인지", imageName: "Microwave", isAvailable: options.microwave)
                optionItem(title: "싱크대", imageName: "Sink", isAvailable: options.sink)
                optionItem(title: "TV", imageName: "Television", isAvailable: options.tv)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image("Parking")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.SubText)
                    Text("세대별 차량 \(parkingCount)대 주차 가능")
                        .font(.pretendardCaption)
                        .foregroundColor(.SubText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white)
                .overlay(
                    Capsule()
                        .stroke(Color.gray, lineWidth: 1)
                )
                .clipShape(Capsule())
            }
        }
    }
    private func optionItem(title: String, imageName: String, isAvailable: Bool) -> some View {
        VStack(spacing: 4) {
            Image(imageName)
                .foregroundColor(isAvailable ? Color.MainTextColor : Color.Deselected)
            Text(title)
                .font(.pretendardCaption2)
                .foregroundColor(isAvailable ? Color.MainTextColor : Color.Deselected)
        }
    }
}

// MARK: - DetailDescriptionView 수정 (섹션 타이틀 추가)
extension EstateDetailView {
    private func detailDescriptionView(description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("상세 설명")
                .font(.soyoHeadline)
                .foregroundColor(.MainTextColor)
            
            Text(description)
                .font(.pretendardCaption)
                .foregroundColor(Color.SubText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - SimilarEstatesView 수정
struct SimilarEstatesView: View {
    let entity: [SimilarEstateWithAddress]
    let onTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("유사한 매물")
                .font(.soyoHeadline)
                .foregroundColor(.MainTextColor)
                .padding(.leading, 16)
            horizontalScrollView
            recommendationFooter
                .padding(.leading, 16)
        }
    }
    
    private var horizontalScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<entity.count, id: \.self) { index in
                    similarEstateCard(at: index)
                }
            }
            .padding(.leading, 16)
        }
    }
    
    private func similarEstateCard(at index: Int) -> some View {
        let item = entity[index]
        
        return HStack(spacing: 12) {
            thumbnailImage(for: item)
            estateInfo(for: item)
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .frame(width: 250, height: 120)
        .padding(.vertical, 4)
        .onTapGesture {
            onTap(item.summary.estateId)
        }
    }
    
    private func thumbnailImage(for item: SimilarEstateWithAddress) -> some View {
        CustomAsyncImage(imagePath: item.summary.thumbnail)
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func estateInfo(for item: SimilarEstateWithAddress) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            categoryText(item.summary.category)
            priceText(item.summary.deposit, item.summary.monthlyRent)
            areaText(item.summary.area)
            addressText(item.address)
        }
    }
    
    private func categoryText(_ category: String) -> some View {
        Text(category)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.OliveMist)
    }
    
    private func areaText(_ area: String) -> some View {
        Text(area)
            .font(.caption)
            .foregroundColor(.SubText)
    }
    
    private func priceText(_ deposit: String, _ monthlyRent: String) -> some View {
        Text("\(deposit)/\(monthlyRent)")
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundColor(.MainTextColor)
    }
    
    private func addressText(_ address: String) -> some View {
        Text(address)
            .font(.caption)
            .foregroundColor(.SubText)
            .lineLimit(1)
    }
    
    private var recommendationFooter: some View {
        HStack {
            Image("Safty")
                .resizable()
                .frame(width: 20, height: 20)
            Text("새싹 AI 알고리즘 기반으로 추천된 매물입니다.")
                .font(.caption)
                .foregroundColor(.SubText)
        }
    }
}

// MARK: - CreaterInfoView 수정 (섹션 타이틀 추가)
extension EstateDetailView {
    private func createrInfoView(creator: UserInfoPresentation) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            Text("중개사 정보")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.MainTextColor)
                .padding(.leading, 16)
            
            HStack(spacing: 12) {
                CustomAsyncImage(imagePath: creator.profileImage)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(creator.nick)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.MainTextColor)
                    Text(creator.introduction)
                        .font(.caption)
                        .foregroundColor(.SubText)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image("Call Button")
                        .frame(width: 40, height: 40)
                    Button {
                        container.handle(.chatButtonTapped)
                    } label: {
                        Image("Chat Button")
                            .frame(width: 40, height: 40)
                    }
                    .disabled(container.model.opponent_id != nil)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .padding(.bottom, 10)
        }
    }
}


// MARK: - ReservationButton 수정
extension EstateDetailView {
    private func reservationButton(isReserved: Bool) -> some View {
        Button {
            container.handle(.reserveButtonTapped)
        } label: {
            Text(container.model.isReserved ? "예약 완료" : "예약하기")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(container.model.isReserved ? Color.Deselected : Color.OliveMist)
                .cornerRadius(12)
        }
        .disabled(container.model.isReserved)
        .padding(.vertical, 16)
        .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
    }
}

// MARK: - renderDetailEstate 수정
extension EstateDetailView {
    @ViewBuilder
    func renderDetailEstate() -> some View {
        switch container.model.detailEstate {
        case .idle, .loading:
            ProgressView("디테일뷰 로딩 중…")
            
        case .success(let data):
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    topThumbnailView(thumbnails: data.detail.thumbnails)
                    watchingBar(likeCount: data.detail.likeCount)
                }
                VStack(spacing: 16) {
                    metaDataView(data: data)
                    Divider()
                    optionView(options: data.detail.options, parkingCount: data.detail.parkingCount)
                    Divider()
                    detailDescriptionView(description: data.detail.description)
                    Divider()
                }
                .padding(.horizontal)
                renderSimilarEstate()
                Divider()
                createrInfoView(creator: data.detail.creator)
            }
            
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(Color.TomatoRed)
        case .requiresLogin:
            Text("세션이 만료되어 로그아웃되었습니다.")
                .foregroundColor(Color.TomatoRed)
                .task {
                    isLoggedIn = false
                }
        }
    }
    
    @ViewBuilder
    func renderSimilarEstate() -> some View {
        switch container.model.similarEstates {
        case .idle, .loading:
            ProgressView("유사한 매물 로딩 중…")
            
        case .success(let data):
            SimilarEstatesView(entity: data) { estateId in
                container.handle(.similarEstateSelected(estateId: estateId))
            }
        case .failure(let message):
            Text("에러: \(message)")
                .foregroundColor(Color.TomatoRed)
            
        case .requiresLogin:
            Text("세션이 만료되어 로그아웃되었습니다.")
                .foregroundColor(Color.TomatoRed)
                .frame(height: 400)
                .task {
                    isLoggedIn = false
                }
        }
    }
}

