//
//  HomeView.swift
//  Anlaka
//
//  Created by 최정안 on 5/15/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack{
            Text("Hello, World!")
        }.onAppear{
            print("HomeView")
        }
    }
}

#Preview {
    HomeView()
}
