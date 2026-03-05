//
//  UIComponents.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/25/26.
//

import SwiftUI

struct ComicHeader: View {
    // Conform to a View ,a visual component that SwiftUI should know how to draw
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
    }
}
