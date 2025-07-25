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
                            path.append(MyPageRoute.editProfile(di: di))
                        },
                        onAddEstate: {
                            container.handle(.addMyEstate)
                        }
                    )
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                    
                    // Chatting Section
                    VStack(spacing: 16) {
                        SectionTitleView(title: "Chatting", hasViewAll: false)
                            .padding(.horizontal, 16)
                        
                        ChattingRoomListView(
                            chatRoomList: container.model.chatRoomList,
                            updatedRoomIds: container.model.updatedRoomIds,
                            onRoomTap: { roomId in
                                    path.append(MyPageRoute.chatRoom(roomId: roomId, di: di))
                            }
                        )
                    }
                    .padding(.top, 32)
                }
            }
            .navigationTitle("마이 페이지")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: MyPageRoute.self) { route in
                switch route {
                case .chatRoom(let roomId, let di):
                    ChattingView(roomId: roomId, di: di, path: $path)
                case .editProfile(let di):
                    EditProfileView(di: di)
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

// MARK: - ProfileView
struct ProfileView: View {
    let profileInfo: MyProfileInfoEntity?
    let onEditProfile: () -> Void
    let onAddEstate: () -> Void
    
    var body: some View {
        if let profileInfo = profileInfo {
            VStack(spacing: 16) {
                HStack {
                    // Profile Image
                    AsyncImage(url: URL(string: profileInfo.profileImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    
                    Spacer()
                    
                    // Add Estate Button
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
                    
                    // Edit Button
                    Button(action: onEditProfile) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color.MainTextColor)
                            .font(.system(size: 16))
                    }
                }
                
                // User Info
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
                
                // Introduction Section
                IntroductionView(introduction: profileInfo.introduction)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        } else {
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
                AsyncImage(url: URL(string: room.lastChat?.sender.profileImage ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(String(room.lastChat?.sender.nick ?? ""))
                                .font(.caption)
                                .fontWeight(.medium)
                        )
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                
                // Chat Info
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
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
