//
//  MyPageView.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import SwiftUI

// MARK: - MyPageView
struct MyPageView: View {
    @StateObject private var container: MyPageContainer
    @StateObject private var temporaryMessageManager = TemporaryLastMessageManager.shared
    let di: DIContainer
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @Binding var path: NavigationPath
    @State private var showLogoutAlert = false
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self.di = di
        self._path = path
        _container = StateObject(wrappedValue: di.makeMyPageContainer())
    }
    
    var body: some View {
        ZStack {
            Color.WarmLinen
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 커스텀 Navigation Bar
                CustomNavigationBar(
                    title: "마이 페이지",
                    rightButton: {
                        Button(action: {
                            showLogoutAlert = true
                        }) {
                            Text("로그아웃")
                                .font(.pretendardFootnote)
                                .foregroundColor(Color.MainTextColor)
                        }
                    }
                )
            
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Section
                    ProfileView(
                        profileInfo: container.model.profileInfo,
                        onEditProfile: {
                            path.append(AppRoute.MyPageRoute.editProfile)
                        },
                        onAddEstate: {
                            container.handle(.addMyEstate)
                        }
                    )
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    
                    // Chatting Section
                    ChattingSectionView(
                        chatRoomList: container.model.chatRoomList,
                        updatedRoomIds: container.model.updatedRoomIds,
                        onRoomTap: { roomId in
                            path.append(AppRoute.MyPageRoute.chatRoom(roomId: roomId))
                        }
                    )
                    .padding(.top, 32)
                }
                .padding(.bottom, 100) // TabBar 높이만큼 하단 padding 추가
            }
            .refreshable {
                // 사용자가 스크롤을 당겨서 새로고침할 때
                container.handle(.refreshData)
            }
        }
        }
        .navigationDestination(for: AppRoute.MyPageRoute.self) { route in
            switch route {
            case .chatRoom(let roomId):
                ChattingView(roomId: roomId, di: di, path: $path)
                    .id(roomId) // roomId가 변경될 때마다 새로운 뷰 인스턴스 생성
            case .editProfile:
                EditProfileView(di: di, path: $path)
            }
        }
        .onChange(of: container.model.backToLogin) { backToLogin in
            print(" MyPageView onChange 감지: backToLogin = \(backToLogin)")
            if backToLogin {
                print(" MyPageView에서 isLoggedIn을 false로 설정")
                isLoggedIn = false
            }
        }
        .onAppear {
            container.handle(.initialRequest)
            CurrentScreenTracker.shared.setCurrentScreen(.profile)
            
            // MyPageView 진입 시 뱃지 상태 업데이트
            // ChatNotificationCountManager.shared.forceUpdateBadge()
        }

        .onChange(of: temporaryMessageManager.temporaryMessages) { _ in
            // 임시 마지막 메시지가 변경되면 채팅방 목록 새로고침
            container.handle(.refreshData)
        }
        .alert("로그아웃", isPresented: $showLogoutAlert) {
            Button("취소", role: .cancel) { }
            Button("로그아웃", role: .destructive) {
                print(" 로그아웃 버튼 클릭됨")
                // container에서 로그아웃 처리 (isLoggedIn 설정 포함)
                container.handle(.logout)
            }
        } message: {
                            Text("정말 로그아웃하시겠습니까?")
                    .font(.pretendardBody)
        }
    }
}

// MARK: - ChattingSectionView
struct ChattingSectionView: View {
    let chatRoomList: [ChatRoomEntity]
    let updatedRoomIds: Set<String>
    let onRoomTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            SectionTitleView(title: "Chatting", hasViewAll: false)
                .padding(.horizontal, 16)
            
            ChattingRoomListView(
                chatRoomList: chatRoomList,
                updatedRoomIds: updatedRoomIds,
                onRoomTap: onRoomTap
            )
        }
    }
}

// MARK: - ProfileView
struct ProfileView: View {
    let profileInfo: MyProfileInfoEntity?
    let onEditProfile: () -> Void
    let onAddEstate: () -> Void
    
    var body: some View {
        if let profileInfo = profileInfo {
            ProfileContentView(
                profileInfo: profileInfo,
                onEditProfile: onEditProfile,
                onAddEstate: onAddEstate
            )
        } else {
            ProfileErrorView()
        }
    }
}

// MARK: - ProfileContentView
struct ProfileContentView: View {
    let profileInfo: MyProfileInfoEntity
    let onEditProfile: () -> Void
    let onAddEstate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ProfileHeaderView(
                profileInfo: profileInfo,
                onEditProfile: onEditProfile,
                onAddEstate: onAddEstate
            )
            
            ProfileInfoView(profileInfo: profileInfo)
            
            IntroductionView(introduction: profileInfo.introduction)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - ProfileHeaderView
struct ProfileHeaderView: View {
    let profileInfo: MyProfileInfoEntity
    let onEditProfile: () -> Void
    let onAddEstate: () -> Void
    
    var body: some View {
        HStack {
            // Profile Image
            CustomAsyncImage(
                imagePath: profileInfo.profileImage,
                targetSize: CGSize(width: 80, height: 80)
            )
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            
            Spacer()
            
            // Add Estate Button
            AddEstateButton(onAddEstate: onAddEstate)
            
            // Edit Button
            EditProfileButton(onEditProfile: onEditProfile)
        }
    }
}

// MARK: - AddEstateButton
struct AddEstateButton: View {
    let onAddEstate: () -> Void
    
    var body: some View {
        Button(action: onAddEstate) {
            Text("매물 추가하기")
                .font(.pretendardCaption2)
                .foregroundColor(Color.MainTextColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.MainTextColor, lineWidth: 1)
                )
        }
    }
}

// MARK: - EditProfileButton
struct EditProfileButton: View {
    let onEditProfile: () -> Void
    
    var body: some View {
        Button(action: onEditProfile) {
            Image(systemName: "pencil")
                .foregroundColor(Color.MainTextColor)
                .font(.system(size: 16))
        }
    }
}

// MARK: - ProfileInfoView
struct ProfileInfoView: View {
    let profileInfo: MyProfileInfoEntity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(profileInfo.nick)
                    .font(.soyoTitle2)
                Spacer()
            }
            
            if let phone = profileInfo.phoneNum {
                HStack {
                    Text(phone)
                        .font(.pretendardSubheadline)
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - ProfileErrorView
struct ProfileErrorView: View {
    var body: some View {
        VStack {
            Text("프로필 데이터를 찾을 수 없습니다.")
                .foregroundColor(.white)
                .font(.soyoHeadline)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.tomatoRed)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - IntroductionView
struct IntroductionView: View {
    let introduction: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Introduction")
                .font(.soyoHeadline)
            
            Text(introduction ?? "I am a good person")
                .font(.pretendardBody)
                .foregroundColor(Color.MainTextColor)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// MARK: - ChattingRoomListView
struct ChattingRoomListView: View {
    let chatRoomList: [ChatRoomEntity]
    let updatedRoomIds: Set<String>
    let onRoomTap: (String) -> Void
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(chatRoomList.enumerated()), id: \.offset) { index, room in
                ChattingRoomCell(
                    room: room,
                    onTap: {
                        onRoomTap(room.roomId)
                    },
                    hasNewChat: updatedRoomIds.contains(room.roomId)
                )
                
                if index < chatRoomList.count - 1 {
                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}



// MARK: - ChattingRoomCell
struct ChattingRoomCell: View {
    let room: ChatRoomEntity
    let onTap: () -> Void
    let hasNewChat: Bool
    @StateObject private var viewModel: ChattingRoomCellViewModel
    
    init(room: ChatRoomEntity, onTap: @escaping () -> Void, hasNewChat: Bool) {
        self.room = room
        self.onTap = onTap
        self.hasNewChat = hasNewChat
        self._viewModel = StateObject(wrappedValue: ChattingRoomCellViewModel(roomId: room.roomId, initialRoom: room))
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile Image - 상대방의 프로필 이미지 사용
                if let opponent = getOpponentFromRoom(room) {
                    CustomAsyncImage.profile(
                        imagePath: opponent.profileImage
                    )
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    // 기본 이미지
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.gray)
                }
                
                // Chat Info
                ChatInfoView(
                    room: room,
                    hasNewChat: hasNewChat,
                    viewModel: viewModel
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 공통 헬퍼 함수
/// 채팅방에서 상대방 정보를 가져오는 공통 함수
func getOpponentFromRoom(_ room: ChatRoomEntity) -> UserInfoEntity? {
    guard let currentUser = UserDefaultsManager.shared.getObject(forKey: .profileData, as: MyProfileInfoEntity.self) else {
        print("❌ 현재 사용자 정보를 찾을 수 없음")
        return nil
    }
  
    // participants 중에서 currentUser가 아닌 상대방 찾기
    let opponent = room.participants.first { $0.userId != currentUser.userid }
  
    
    return opponent
}

// MARK: - ChatInfoView
struct ChatInfoView: View {
    let room: ChatRoomEntity
    let hasNewChat: Bool
    @ObservedObject var viewModel: ChattingRoomCellViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // 상대방의 닉네임 사용
                if let opponent = getOpponentFromRoom(room) {
                    Text(opponent.nick)
                        .font(.soyoHeadline)
                        .foregroundColor(Color.MainTextColor)
                } else {
                    Text("사용자")
                        .font(.soyoHeadline)
                        .foregroundColor(Color.MainTextColor)
                }
                
                Spacer()
                
                // 마지막 메시지 시각 표시
                if !viewModel.lastMessageTime.isEmpty {
                    Text(PresentationMapper.formatRelativeTime(viewModel.lastMessageTime))
                        .font(.pretendardCaption2)
                        .foregroundColor(.gray)
                        .padding(.trailing, 16)
                }
            }
            
            HStack {
                // 마지막 메시지 내용
                Text(viewModel.lastMessage)
                    .font(.pretendardCaption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Spacer()
                
                // 알림 카운트 배지
                if viewModel.notificationCount > 0 {
                    Text("\(viewModel.notificationCount)")
                        .font(.pretendardCaption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.tomatoRed)
                        .clipShape(Capsule())
                        .frame(minWidth: 16)
                        .padding(.trailing, 16)
                }
            }
        }
    }
}
