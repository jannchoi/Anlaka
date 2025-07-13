//
//  EstatesAllView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI

struct EstatesAllView: View {
    let listType: EstateListType
    
    var body: some View {
        Text("Estates All View: \(listType == .latest ? "Latest" : "Hot")")
    }
}
