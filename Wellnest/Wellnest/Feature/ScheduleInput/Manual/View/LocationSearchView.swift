//
//  LocationSearchView.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/3/25.
//

import SwiftUI
import MapKit

struct LocationSearchView: View {
    @Binding var selectedLocation: String
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @StateObject private var completerWrapper = SearchCompleterWrapper()

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                FocusableTextField(
                    text: $query,
                    placeholder: "장소를 입력해주세요.",
                    isFirstResponder: true,
                    clearButtonMode: .whileEditing
                )
                .frame(height: 20)
                .onChange(of: query) { newValue in
                    if !newValue.isEmpty {
                        completerWrapper.updateQuery(newValue)
                    } else {
                        completerWrapper.clearResults()
                    }
                }
                Divider()
                List(completerWrapper.completions, id: \.self) { completion in
                    VStack(alignment: .leading) {
                        Text(completion.title).bold()
                        Text(completion.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .onTapGesture {
                        selectedLocation = completion.title
                        isPresented = false
                        dismiss()
                    }
                }
                .listStyle(.plain)


                Spacer()
            }
            .padding()
            .navigationTitle("위치 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
}

class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    var onUpdate: ([MKLocalSearchCompletion]) -> Void

    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onUpdate = onUpdate
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search Error", error.localizedDescription)
    }
}

class SearchCompleterWrapper: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.delegate = self
    }

    func updateQuery(_ query: String) {
        completer.queryFragment = query
    }

    func clearResults() {
        completions = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search Failure", error.localizedDescription)
    }
}
