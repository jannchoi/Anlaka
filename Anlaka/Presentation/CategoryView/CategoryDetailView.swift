//
//  CategoryDetailView.swift
//  Anlaka
//
//  Created by 최정안 on 5/20/25.
//

import SwiftUI

struct CategoryDetailView: View {
    let categoryType: CategoryType
    
    var body: some View {
        Text("Category Detail View: \(categoryType.rawValue)")
    }
}
