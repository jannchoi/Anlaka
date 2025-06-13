//
//  EstateDetailView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI

struct EstateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(TextResource.Global.isLoggedIn.text) private var isLoggedIn: Bool = true
    
    // estateId로 초기화하는 경우
    init(estateId: String) {
        
    }
    
    // estate 객체로 초기화하는 경우
    init(estate: DetailEstatePresentation) {
        
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Text("detailview")
            
        }
        .onAppear {
            print("detailview")
        }
    }
    private var headerBar: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(.mainText)
        }
    }
}
