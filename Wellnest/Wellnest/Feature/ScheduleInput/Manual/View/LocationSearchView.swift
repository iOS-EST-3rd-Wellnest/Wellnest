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

    private let allowedCategories: [MKPointOfInterestCategory] = [
        .cafe, .restaurant, .fitnessCenter, .park, .school, .library, .hospital, .pharmacy, .stadium
    ]

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                FocusableTextField(
                    text: $query,
                    placeholder: "장소를 입력해주세요.",
                    isFirstResponder: true,
                    clearButtonMode: .whileEditing,
                )
                .frame(height: 20)
                .onChange(of: query) { newValue in
                    if newValue.isEmpty {
                        completerWrapper.clearResults()
                    } else {
                        completerWrapper.updateQuery(newValue)

                    }
                }
                Divider()

                List {
                    if !query.isEmpty {
                        VStack(alignment: .leading) {
                            Text(query).bold()
                            Text("사용자 지정 위치")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .listRowSeparator(.hidden)
                        .onTapGesture {
                            selectedLocation = query
                            isPresented = false
                            dismiss()
                        }
                    }
                    ForEach(completerWrapper.completions, id: \.self) { completion in
                        VStack(alignment: .leading) {
                            Text(completion.title).bold()
                            Text(completion.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .contentShape(Rectangle())        
                        .onTapGesture {
                            let center = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
                            handleSelect(completion: completion, center: center)
                        }
                    }
                }
                .listStyle(.plain)
                .frame(maxWidth: .infinity)
                if completerWrapper.isFiltering {
                    ProgressView().padding(.top, 8)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("위치 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button {
                        isPresented = false
                        dismiss()
                    } label: {
                        Image(systemName: "xmark").foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                // 한국 전체 힌트 + 사용 위치 설정(가능하면 실제 위치로 설정)
                completerWrapper.center = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
            }
            .onDisappear {
                UIApplication.hideKeyboard()
            }
        }
    }

}

extension LocationSearchView {

    private func handleSelect(
        completion: MKLocalSearchCompletion,
        center: CLLocationCoordinate2D
    ) {
        Task { @MainActor in
            do {
                let items = try await resolveToMeaningfulPlaces(
                    from: completion,
                    center: center,
                    allowed: allowedCategories
                )
                selectedLocation = items.first?.name ?? completion.title
            } catch {
                selectedLocation = completion.title
            }
            isPresented = false
            dismiss()
        }
    }

    func resolveToMeaningfulPlaces(
        from completion: MKLocalSearchCompletion,
        center: CLLocationCoordinate2D,
        allowed: [MKPointOfInterestCategory]
    ) async throws -> [MKMapItem] {
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = "\(completion.title) \(completion.subtitle)".trimmingCharacters(in: .whitespaces)
        req.resultTypes = .pointOfInterest
        req.pointOfInterestFilter = MKPointOfInterestFilter(including: allowed)
        req.region = MKCoordinateRegion(center: center,
                                        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15))

        let resp = try await MKLocalSearch(request: req).start()
        return resp.mapItems
            .filter { isInKorea($0.placemark.coordinate) }
            .sorted { lhs, rhs in
                guard let l = lhs.placemark.location, let r = rhs.placemark.location else { return false }
                let c = CLLocation(latitude: center.latitude, longitude: center.longitude)
                return l.distance(from: c) < r.distance(from: c)
            }
    }

    private func isInKorea(_ coord: CLLocationCoordinate2D) -> Bool {
        let (lat, lon) = (coord.latitude, coord.longitude)
        return (33.0...38.8).contains(lat) && (124.0...132.2).contains(lon)
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

final class SearchCompleterWrapper: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var isFiltering: Bool = false

    private let completer = MKLocalSearchCompleter()
    private var filterTask: Task<Void, Never>?

    // 기준 좌표(현위치 권장)
    var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)

    override init() {
        super.init()
        completer.resultTypes = [.pointOfInterest]
        completer.delegate = self
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.5, longitude: 127.8),
            span: MKCoordinateSpan(latitudeDelta: 6.0, longitudeDelta: 6.0)
        )
    }

    func updateRegion(_ region: MKCoordinateRegion) { completer.region = region }

    func updateQuery(_ query: String) {
        let normalized = query.precomposedStringWithCanonicalMapping
        completer.queryFragment = normalized
    }

    func clearResults() { completions = [] }

    // 한글 포함 여부(자모 조합 후 “가나다” 영역에 한 글자라도 있으면 true)
    private static func containsHangul(_ s: String) -> Bool {
        s.unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) }
    }

    private static func isInKorea(_ coord: CLLocationCoordinate2D) -> Bool {
        let (lat, lon) = (coord.latitude, coord.longitude)
        return (33.0...38.8).contains(lat) && (124.0...132.2).contains(lon)
    }

    // 자동완성 후보를 실제 검색으로 해석해서 한국만 남김
    private static func filterCompletionsToKorea(
        _ completions: [MKLocalSearchCompletion],
        center: CLLocationCoordinate2D
    ) async -> [MKLocalSearchCompletion] {
        let head = Array(completions.prefix(12))
        return await withTaskGroup(of: MKLocalSearchCompletion?.self) { group in
            for c in head {
                group.addTask {
                    let req = MKLocalSearch.Request(completion: c)
                    req.resultTypes = .pointOfInterest
                    req.region = MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
                    )
                    do {
                        let resp = try await MKLocalSearch(request: req).start()
                        if let first = resp.mapItems.first {
                            if first.placemark.isoCountryCode == "KR" || self.isInKorea(first.placemark.coordinate) {
                                return c
                            }
                        }
                    } catch { }
                    return nil
                }
            }
            var kept: [MKLocalSearchCompletion] = []
            for await r in group { if let c = r { kept.append(c) } }
            return kept
        }
    }
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // 디바운스 + 이전 작업 취소
        filterTask?.cancel()

        let raw = completer.results
        let center = self.center

        Task { @MainActor in
            self.isFiltering = true
        }

        filterTask = Task.detached { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 200_000_000) // debounce

            let base: [MKLocalSearchCompletion]
            if raw.contains(where: { Self.containsHangul($0.title) || Self.containsHangul($0.subtitle) }) {
                base = raw.filter { Self.containsHangul($0.title) || Self.containsHangul($0.subtitle) }
            } else {
                base = Array(raw.prefix(8))
            }

            let geoFiltered = await Self.filterCompletionsToKorea(base, center: center)

            // 🔸 결과 publish도 메인에서
            await MainActor.run {
                self.completions = geoFiltered
                self.isFiltering = false
            }
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search Failure", error.localizedDescription)
    }
}
