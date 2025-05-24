//
//  SearchMapView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI
import CoreLocation

struct SearchMapView: View {
    let di: DIContainer
    @StateObject private var container: SearchMapContainer
    @State var draw: Bool = false
    @State private var isMapReady: Bool = false
    @State private var isSearchBarEditing: Bool = false // 검색 바 편집 상태 추가
    
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeSearchMapContainer())
    }
    
    var body: some View {
        ZStack {
            if isMapReady {
                KakaoMapView(
                    draw: $draw,
                    centerCoordinate: container.model.centerCoordinate,
                    isInteractive: !isSearchBarEditing, // 검색 중이면 지도 상호작용 비활성화
                    pinInfoList: container.model.pinInfoList, // 핀 정보 전달
                    onCenterChanged: { newCenter in
                        container.handle(.updateCenterCoordinate(newCenter))
                    },
                    onMapReady: { maxDistance in
                        // 지도가 준비되고 maxDistance가 계산되면 호출
                        container.handle(.mapDidStopMoving(center: container.model.centerCoordinate, maxDistance: maxDistance))
                    }
                )
            } else {
                Color.gray.opacity(0.1)
                    .ignoresSafeArea(.all)
            }
            
            // Search Bar Overlay
            VStack {
                SearchBarView(
                    searchText: $container.model.addressQuery,
                    onSubmitted: { text in
                        container.handle(.searchBarSubmitted(text))
                    },
                    onEditingChanged: { isEditing in
                        isSearchBarEditing = isEditing // 편집 상태 업데이트
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
            }
            
            if isSearchBarEditing {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 오버레이를 터치하면 키보드 닫기
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        isSearchBarEditing = false
                    }
                    .ignoresSafeArea(.all)
            }
            
            // Loading Indicator
            if container.model.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            // Current Location Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if container.model.isLocationPermissionGranted {
                            if let currentLocation = container.model.currentLocation {
                                container.handle(.updateCenterCoordinate(currentLocation))
                            }
                        } else {
                            container.handle(.requestLocationPermission)
                        }
                    }) {
                        Image(systemName: container.model.isLocationPermissionGranted ? "location.fill" : "location")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 100)
                }
            }
            
            // Estate Count Info (for debugging)
            if !container.model.estates.isEmpty {
                VStack {
                    HStack {
                        EstateCountView(count: container.model.estates.count)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(.top, 80)
                .padding(.leading, 16)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("SearchMapView appeared")
            isMapReady = true
            draw = true
            container.handle(.requestLocationPermission)
        }
        .onDisappear {
            draw = false
            isMapReady = false
            print("SearchMapView disappeared")
        }
        .alert("오류", isPresented: .constant(container.model.errorMessage != nil), actions: {
            Button("확인") {
                container.model.errorMessage = nil
            }
        }, message: {
            if let errorMessage = container.model.errorMessage {
                Text(errorMessage)
            }
        })
    }
}


// MARK: - Estate Count View (for debugging/preview)
struct EstateCountView: View {
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: "house.fill")
                .foregroundColor(.blue)
                .font(.system(size: 14))
            Text("매물 \(count)개")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

struct SearchBarView: View {
    @Binding var searchText: String
    let onSubmitted: (String) -> Void
    let onEditingChanged: (Bool) -> Void // 편집 상태 변경 클로저 추가
    let placeholder: String
    
    @State private var isEditing = false
    
    init(searchText: Binding<String>,
         placeholder: String = "주소를 검색하세요",
         onSubmitted: @escaping (String) -> Void,
         onEditingChanged: @escaping (Bool) -> Void) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onSubmitted = onSubmitted
        self.onEditingChanged = onEditingChanged
    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField(placeholder, text: $searchText) { isEditing in
                    self.isEditing = isEditing
                    onEditingChanged(isEditing) // 편집 상태 전달
                } onCommit: {
                    onSubmitted(searchText)
                    hideKeyboard()
                    self.isEditing = false
                    onEditingChanged(false)
                }
                .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if isEditing {
                Button("취소") {
                    isEditing = false
                    onEditingChanged(false)
                    searchText = ""
                    hideKeyboard()
                }
                .foregroundColor(.blue)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}
// Helper extension to hide keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
