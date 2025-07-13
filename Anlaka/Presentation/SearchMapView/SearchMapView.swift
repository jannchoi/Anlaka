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
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    @State private var showSearchAddress = false
    init(di: DIContainer) {
        self.di = di
        _container = StateObject(wrappedValue: di.makeSearchMapContainer())
    }
    
    var body: some View {
        ZStack {
            KakaoMapView(
                draw: .constant(container.model.shouldDrawMap),
                centerCoordinate: container.model.centerCoordinate,
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
                SearchBar(searchBarTapped: $showSearchAddress, placeholder: container.model.searchedData?.title)
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
        .fullScreenCover(isPresented: $showSearchAddress) {
            SearchAddressView(
                di: di,
                isPresented: $showSearchAddress,
                onAddressSelected: { selectedAddress in
                    // 주소 선택됨
                    print("searchmapview🥶🥶🥶",selectedAddress)
                    container.handle(.searchBarSubmitted(selectedAddress))

                },
                onDismiss: {
                    print("onDismiss")
                }
            )
        }
    }
    
    struct SearchBar: View {
        @Binding var searchBarTapped: Bool
        var placeholder: String?
        private var resolvedPlaceholder : String {
            return (placeholder ?? "").isEmpty ? "주소를 입력하세요" : (placeholder ?? "")
        }
        var body: some View {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                Text(resolvedPlaceholder)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3))
            )
            .onTapGesture {
                searchBarTapped = true
            }
        }
    }
    
}

