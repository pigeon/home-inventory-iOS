import SwiftUI

struct ItemDetailView: View {
    let item: Item
    let boxNumber: String?

    private var photoURL: URL? {
        if let filename = item.photoFilename {
            return APIClient.shared.photoURL(for: filename)
        }
        return item.photoURL
    }

    var body: some View {
        List {
            if let url = photoURL {
                Section {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    } placeholder: {
                        ProgressView()
                    }
                }
            }

            Section {
                Text(item.name)
                    .font(.headline)

                if let note = item.note {
                    Text(note)
                }

                if let boxNumber {
                    Text("Box: \(boxNumber)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Item Details")
    }
}

#Preview {
    let item = Item(id: 1, boxId: 1, name: "Sample", note: "Some note", photoURL: nil, photoFilename: nil, createdAt: .init())
    return NavigationStack { ItemDetailView(item: item, boxNumber: "1") }
}
