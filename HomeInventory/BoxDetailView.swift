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
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediaCornerRadius, style: .continuous))
                        } placeholder: {
                            ProgressView()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.appSurface)
                }
                Section {
                    Text("Number: \(detail.number)")
                        .foregroundStyle(Color.appTextPrimary)
                    if let description = detail.description {
                        Text(description)
                            .foregroundStyle(Color.appTextPrimary)
                    }
                }
                .listRowBackground(Color.appSurface)

                Section {
                    ForEach(detail.items ?? []) { item in
                        NavigationLink {
                            ItemDetailView(item: item, boxNumber: detail.number)
                        } label: {
                            HStack(alignment: .top, spacing: 8) {
                                if let filename = item.photoFilename {
                                    AsyncImage(url: viewModel.photoURL(for: filename)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.mediaCornerRadius, style: .continuous))
                                    } placeholder: {
                                        ProgressView()
                                            .frame(width: 60, height: 60)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .foregroundStyle(Color.appTextPrimary)
                                    if let note = item.note {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(Color.appTextSecondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.appSurface)
                    }
                }
            } else if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.appBackground)
            } else {
                Text("Error loading box details")
                    .foregroundStyle(Color.appError)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.appSurfaceSecondary)
            }
        }
        .navigationTitle("Box Details")
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(Color.appPrimary)
            }
        }
        .sheet(isPresented: $addItem) {
            AddItemView(boxId: viewModel.boxId, onDone: refresh)
        }
        .task {
            await viewModel.fetch()
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }

    private func refresh() {
        addItem = false
        Task {
            await viewModel.fetch()
        }
    }
}
