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
    @State private var isSearchBarEditing: Bool = false
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeSearchMapContainer())
    }
    
    var body: some View {
        ZStack {
            KakaoMapView(
                draw: .constant(container.model.shouldDrawMap),
                centerCoordinate: container.model.centerCoordinate,
                isInteractive: !isSearchBarEditing,
                pinInfoList: container.model.pinInfoList,
                onMapReady: { maxDistance in
                    container.handle(.updateMaxDistance(maxDistance))
                },
                onMapChanged: { center, maxDistance in
                    container.handle(.mapDidStopMoving(center, maxDistance))
                },
                onPOITap: { estateId in
                    print("🧶 POI Tap \(estateId)")
                    // 클릭한 매물의 상세 정보 표시 -> 클릭한 매물의 estate_id를 디테일뷰로 전달
                },
                onPOIGroupTap: { estateIds in
                    print("🧶🧶🧶POIS Tap \(estateIds)")
                    // 클릭한 클러스터의 매물들의 상세 정보 표시 -> 클릭한 클러스터의 estate_id 배열을 EstateSrollView로 전달
                }
            )
            
            VStack {
                SearchBar(
                    text: $container.model.addressQuery,
                    isEditing: $isSearchBarEditing,
                    onSubmit: { query in
                        container.handle(.searchBarSubmitted(query))
                        hideKeyboard()
                        isSearchBarEditing = false
                    }
                )
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            
            if container.model.isLoading {
                ProgressView()
            }
            
            if let errorMessage = container.model.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            container.handle(.requestLocationPermission)
        }
        .onChange(of: container.model.backToLogin) { needsLogin in
            if needsLogin {
                isLoggedIn = false
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    var onSubmit: (String) -> Void
    
    var body: some View {
        HStack {
            TextField("주소 검색", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                    }
                )
                .onTapGesture {
                    isEditing = true
                }
                .onSubmit {
                    onSubmit(text)
                }
            
            if isEditing {
                Button(action: {
                    isEditing = false
                    text = ""
                    hideKeyboard()
                }) {
                    Text("취소")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default, value: isEditing)
            }
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                      to: nil, from: nil, for: nil)
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
