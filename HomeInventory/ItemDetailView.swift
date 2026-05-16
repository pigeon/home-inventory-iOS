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
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediaCornerRadius, style: .continuous))
                    } placeholder: {
                        ProgressView()
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color.appSurface)
            }

            Section {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)

                if let note = item.note {
                    Text(note)
                        .foregroundStyle(Color.appTextPrimary)
                }

                if let boxNumber {
                    Text("Box: \(boxNumber)")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .listRowBackground(Color.appSurface)
        }
        .navigationTitle("Item Details")
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }
}

#Preview {
    let item = Item(id: 1, boxId: 1, name: "Sample", note: "Some note", photoURL: nil, photoFilename: nil, createdAt: .init())
    return NavigationStack { ItemDetailView(item: item, boxNumber: "1") }
}
