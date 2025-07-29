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
    let di: DIContainer
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @Binding var path: NavigationPath
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self.di = di
        self._path = path
        _container = StateObject(wrappedValue: di.makeMyPageContainer())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Profile Section
                ProfileView(
                    profileInfo: container.model.profileInfo,
                    onEditProfile: {
                        path.append(MyPageRoute.editProfile)
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
                        path.append(MyPageRoute.chatRoom(roomId: roomId, di: di))
                    }
                )
                .padding(.top, 32)
            }
        }
        .navigationTitle("마이 페이지")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: MyPageRoute.self) { route in
            switch route {
            case .chatRoom(let roomId, let di):
                ChattingView(roomId: roomId, di: di, path: $path)
            case .editProfile:
                EditProfileView(di: di, path: $path)
            }
        }
        .onChange(of: container.model.backToLogin) { backToLogin in
            if backToLogin {
                isLoggedIn = false
            }
        }
        .onAppear {
            container.handle(.initialRequest)
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
            CustomAsyncImage(imagePath: profileInfo.profileImage)
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
                .font(.system(size: 11))
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
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if let phone = profileInfo.phoneNum {
                HStack {
                    Text(phone)
                        .font(.subheadline)
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
                .font(.headline)
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
                .font(.headline)
                .fontWeight(.medium)
            
            Text(introduction ?? "I am a good person")
                .font(.body)
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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Profile Image
                CustomAsyncImage(imagePath: room.lastChat?.sender.profileImage)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                
                // Chat Info
                ChatInfoView(
                    room: room,
                    hasNewChat: hasNewChat
                )
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ChatInfoView
struct ChatInfoView: View {
    let room: ChatRoomEntity
    let hasNewChat: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(room.lastChat?.sender.nick ?? "")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(Color.MainTextColor)
                
                if hasNewChat {
                    Circle()
                        .fill(Color.tomatoRed)
                        .frame(width: 8, height: 8)
                }
            }
            
            Text(room.lastChat?.content ?? "")
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
}
