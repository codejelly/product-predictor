//
//  ProductRow.swift
//  pricepredictor
//
//  Created by matthew chadwell on 2/25/26.
//

import SwiftUI

struct ProductRow: View {
    let product: Product // The "Input" for this row

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // The Image
            AsyncImage(url: URL(string: product.image.smallURL)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 60, height: 90)
            .cornerRadius(8)

            // Order of the elements
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)

                Text("ID: \(product.id, format: .number.grouping(.never))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer() // Pushes content to the left
        }
        .padding(.vertical, 4)
    }
}
