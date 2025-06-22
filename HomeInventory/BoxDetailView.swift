//
//  BoxDetailView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//

import SwiftUI

struct BoxDetailView: View {
    @StateObject private var viewModel: BoxDetailViewModel
    @State private var addItem = false

    init(boxId: Int) {
        _viewModel = StateObject(wrappedValue: BoxDetailViewModel(boxId: boxId))
    }

    var body: some View {
        List {
            if let detail = viewModel.detail {
                if let url = viewModel.boxPhotoURL {
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
                    Text("Number: \(detail.number)")
                    if let description = detail.description {
                        Text(description)
                    }
                }

                Section {
                    ForEach(detail.items ?? []) { item in
                        HStack(alignment: .top, spacing: 8) {
                            if let filename = item.photoFilename {
                                AsyncImage(url: viewModel.photoURL(for: filename)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 60, height: 60)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                if let note = item.note {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if viewModel.isLoading {
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
            AddItemView(boxId: viewModel.boxId, onDone: refresh)
        }
        .task {
            await viewModel.fetch()
        }
    }

    private func refresh() {
        addItem = false
        Task {
            await viewModel.fetch()
        }
    }
}
