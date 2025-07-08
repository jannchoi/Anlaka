//
//  SearchAddressView.swift
//  Anlaka
//
//  Created by 최정안 on 6/3/25.
//

import SwiftUI

struct SearchAddressView: View {
    @Binding var isPresented: Bool
    let di: DIContainer
    @StateObject private var container: SearchAddressContainer
    
    // 상위 뷰로 데이터 전달을 위한 클로저
    let onAddressSelected: (SearchListData) -> Void
    let onDismiss: () -> Void
    init(di: DIContainer, isPresented: Binding<Bool>, onAddressSelected: @escaping (SearchListData) -> Void, onDismiss: @escaping () -> Void = {}) {
        self._isPresented = isPresented
        self.di = di
        self.onAddressSelected = onAddressSelected
        _container = StateObject(wrappedValue: di.makeSearchAddressContainer())
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 검색바
            searchHeader
            
            // 에러 메시지
            if let errorMessage = container.model.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // 메인 콘텐츠
            mainContent
        }
        .onAppear {
            container.onAddressSelected = { selectedData in
                onAddressSelected(selectedData)
                isPresented = false
            }
        }
    }
    
    private var searchHeader: some View {
        HStack {
            Button {
                onDismiss()
                isPresented = false
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            TextField("주소를 입력하세요", text: $container.model.query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    container.handle(.searchBarSubmitted(container.model.query))
                }
            
            Spacer(minLength: 8)
        }
        .padding()
    }
    
    private var mainContent: some View {
        HStack(spacing: 1) {
            // 왼쪽 컬럼 - 주소 검색 결과
            VStack {
                Text("주소 검색")
                    .font(.headline)
                    .padding(.vertical, 8)
                
                addressColumn
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
            
            // 오른쪽 컬럼 - 키워드 검색 결과
            VStack {
                Text("장소 검색")
                    .font(.headline)
                    .padding(.vertical, 8)
                
                keywordColumn
            }
        }
    }
    
    private var addressColumn: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                ForEach(Array(container.model.addressQueryData.enumerated()), id: \.offset) { index, data in
                    addressCell(data: data)
                        .onAppear {
                            if index == container.model.addressQueryData.count - 3 {
                                container.handle(.loadMoreIfNeeded)
                            }
                        }
                }
                
                // 빈 셀들로 높이 맞추기
                if container.model.keywordQueryData.count > container.model.addressQueryData.count {
                    ForEach(0..<(container.model.keywordQueryData.count - container.model.addressQueryData.count), id: \.self) { _ in
                        emptyCell
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var keywordColumn: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                ForEach(Array(container.model.keywordQueryData.enumerated()), id: \.offset) { index, data in
                    addressCell(data: data)
                        .onAppear {
                            if index == container.model.keywordQueryData.count - 3 {
                                container.handle(.loadMoreIfNeeded)
                            }
                        }
                }
                
                // 빈 셀들로 높이 맞추기
                if container.model.addressQueryData.count > container.model.keywordQueryData.count {
                    ForEach(0..<(container.model.addressQueryData.count - container.model.keywordQueryData.count), id: \.self) { _ in
                        emptyCell
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func addressCell(data: SearchListData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(data.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onTapGesture {
            container.handle(.selectAddress(data))
        }
    }
    
    private var emptyCell: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("")
                .font(.headline)
            
            Text("")
                .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.clear)
        .cornerRadius(8)
    }
}

