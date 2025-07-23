//
//  RerservedEstatesView.swift
//  Anlaka
//
//  Created by 최정안 on 6/9/25.
//

import SwiftUI

struct RerservedEstatesView: View {
    let di: DIContainer
    @Binding var path: NavigationPath
    
    init(di: DIContainer, path: Binding<NavigationPath>) {
        self.di = di
        self._path = path
    }
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .onAppear {
                CurrentScreenTracker.shared.setCurrentScreen(.estateDetail)
            }
    }
}

