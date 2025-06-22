//
//  BoxDetailView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//

import SwiftUI

struct BoxDetailView: View {
    let boxId: Int
    @State private var detail: BoxDetail?
    @State private var loading = false
    @State private var addItem = false
    @State private var name = ""
    @State private var note = ""
    @State private var photo: Data?

    var body: some View {
        List {
            if let detail = detail {
                Section {
                    Text("Number: \(detail.number)")
                    if let description = detail.description {
                        Text(description)
                    }
                }

                Section {
                    ForEach(detail.items ?? []) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.name)
                            if let note = item.note {
                                Text(note)
                                    .font(.caption)
                            }
                            if let filename = item.photoFilename {
                                AsyncImage(url: APIClient.shared.photoURL(for: filename)) { image in
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
                        .padding(.vertical, 4)
                    }
                }
            } else if loading {
                ProgressView()
            } else {
                Text("Error loading box details")
            }
        }
        .navigationTitle("Box Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $addItem) {
            AddItemView(boxId: boxId, onDone: refresh)
        }
        .task {
            await fetch()
        }
    }

    private func fetch() async {
        loading = true
        defer { loading = false }

        do {
            detail = try await APIClient.shared.getBox(boxId)
        } catch {
            print("Error fetching box details: \(error)")
        }
    }

    private func refresh() {
        addItem = false
        Task {
            await fetch()
        }
    }
}
