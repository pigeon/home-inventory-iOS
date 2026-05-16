//
//  AddBoxView.swift
//  HomeInventory
//
//  Created by Dmytro Golub on 03/06/2025.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// View for adding a new box. All business logic is handled by
/// ``AddBoxViewModel`` to better follow the MVVM pattern.
struct AddBoxView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddBoxViewModel
    #if os(iOS)
    @State private var isShowingCamera = false
    @State private var showCameraUnavailableAlert = false
    #endif

    init(onSave: @escaping (String, String?, Data?) -> Void) {
        _viewModel = StateObject(wrappedValue: AddBoxViewModel(onSave: onSave))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Number", text: $viewModel.number)
                    TextField("Description (Optional)", text: $viewModel.description)
                }
                .listRowBackground(Color.appSurface)
                PhotoPickerSection(photo: $viewModel.photo, onTakePhoto: cameraAction)
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                    .foregroundStyle(viewModel.canSave ? Color.appPrimary : Color.appTextSecondary)
                }
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            #if os(iOS)
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraImagePicker(photoData: $viewModel.photo)
                    .ignoresSafeArea()
            }
            .alert("Camera Unavailable", isPresented: $showCameraUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This device does not support camera capture.")
            }
            #endif
#if os(iOS)
            .navigationTitle("Add Box")
#else
            .navigationTitle("Add New Box")
#endif
        }
    }

    #if os(iOS)
    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showCameraUnavailableAlert = true
            return
        }
        isShowingCamera = true
    }
    #endif

    private var cameraAction: (() -> Void)? {
        #if os(iOS)
        presentCamera
        #else
        nil
        #endif
    }
}
