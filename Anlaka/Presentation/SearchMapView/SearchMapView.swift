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
    @State private var isMapReady: Bool = false  // 추가: 지도 준비 상태 관리
    
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeSearchMapContainer())
    }
    
    var body: some View {
        ZStack {
            // Kakao Map - 조건부 렌더링 추가
            if isMapReady {
                KakaoMapView(draw: $draw,
                             centerCoordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                             onCenterChanged: { newCenter in
                    print("📍 지도 중심 좌표 변경됨:", newCenter)
                },
                             onRadiusChanged: { radius in
                    print("📏 중심~모서리 거리:", radius, "meters")
                })
            } else {
                // 지도 로딩 중 placeholder
                Color.gray.opacity(0.1)
                    .ignoresSafeArea(.all)
            }
            
            // Search Bar Overlay
            VStack {
                SearchBarView(
                    searchText: $container.model.addressQuery,
                    onSubmitted: { text in
                        container.handle(.searchBarSubmitted(text))
                    }
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                Spacer()
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
                                container.handle(.mapDidStopMoving(center: currentLocation, maxDistance: container.model.maxDistance))
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
        }.navigationBarHidden(true)
        .onAppear {
            print("SearchMapView appeared")
            // 단계별 초기화
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isMapReady = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.draw = true
                    // 지도가 완전히 준비된 후 권한 요청
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        container.handle(.requestLocationPermission)
                    }
                }
            }
        }
        .onDisappear {
            self.draw = false
            self.isMapReady = false
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
    let placeholder: String
    
    @State private var isEditing = false
    
    init(searchText: Binding<String>,
         placeholder: String = "주소를 검색하세요",
         onSubmitted: @escaping (String) -> Void) {
        self._searchText = searchText
        self.placeholder = placeholder
        self.onSubmitted = onSubmitted
    }
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField(placeholder, text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        isEditing = true
                    }
                    .onSubmit {
                        onSubmitted(searchText)
                        hideKeyboard()
                        isEditing = false
                    }
                
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
