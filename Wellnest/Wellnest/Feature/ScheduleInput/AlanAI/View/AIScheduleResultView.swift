//
//  AIScheduleResultView.swift
//  Wellnest
//
//  Created by junil on 8/4/25.
//

import SwiftUI

struct AIScheduleResultView: View {
    let healthPlan: HealthPlanResponse?
    let isLoading: Bool
    let errorMessage: String
    let rawResponse: String

    @Environment(\.dismiss) private var dismiss
    @State private var showRawResponse = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if !errorMessage.isEmpty {
                    errorView
                } else if let plan = healthPlan {
                    planContentView(plan)
                } else {
                    emptyView
                }
            }
            .navigationTitle("생성된 플랜")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !errorMessage.isEmpty && !rawResponse.isEmpty {
                        Button("원본 응답") {
                            showRawResponse = true
                        }
                        .font(.caption)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRawResponse) {
                RawResponseView(rawResponse: rawResponse)
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("AI가 플랜을 생성하고 있습니다...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Error View
    private var errorView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.red)

                Text("파싱 오류가 발생했습니다")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if !rawResponse.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI 응답 (파싱 실패):")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text(rawResponse)
                            .font(.caption)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Empty View
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)

            Text("플랜을 생성할 수 없습니다")
                .font(.headline)
                .fontWeight(.bold)

            Text("다시 시도해주세요")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Plan Content View
    private func planContentView(_ plan: HealthPlanResponse) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                planHeaderSection(plan)
                schedulesSection(plan.schedules)

                if let resources = plan.resources {
                    resourcesSection(resources)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }

    private func planHeaderSection(_ plan: HealthPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: planTypeIcon(plan.planType))
                    .foregroundColor(.blue)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(planTypeDisplayName(plan.planType))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }

                Spacer()
            }

            if let description = plan.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func schedulesSection(_ schedules: [ScheduleItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("일정")
                .font(.title3)
                .fontWeight(.bold)

            ForEach(schedules) { schedule in
                ScheduleCard(schedule: schedule)
            }
        }
    }

    private func resourcesSection(_ resources: ResourceInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("추천 정보")
                .font(.title3)
                .fontWeight(.bold)

            if let equipment = resources.equipment, !equipment.isEmpty {
                equipmentSection(equipment)
            }

            if let videos = resources.videos, !videos.isEmpty {
                videosSection(videos)
            }

            if let locations = resources.locations, !locations.isEmpty {
                locationsSection(locations)
            }

            if let products = resources.products, !products.isEmpty {
                productsSection(products)
            }
        }
    }

    private func equipmentSection(_ equipment: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("필요한 도구")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(equipment, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func videosSection(_ videos: [VideoResource]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("추천 영상")
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(videos) { video in
                VideoCard(video: video)
            }
        }
    }

    private func locationsSection(_ locations: [LocationResource]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("추천 장소")
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(locations) { location in
                LocationCard(location: location)
            }
        }
    }

    private func productsSection(_ products: [ProductResource]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("추천 상품")
                .font(.headline)
                .fontWeight(.semibold)

            ForEach(products) { product in
                ProductCard(product: product)
            }
        }
    }

    // MARK: - Helper Methods
    private func planTypeIcon(_ planType: String) -> String {
        switch planType {
        case "single": return "calendar.badge.plus"
        case "multiple": return "calendar"
        case "routine": return "repeat"
        default: return "calendar"
        }
    }

    private func planTypeDisplayName(_ planType: String) -> String {
        switch planType {
        case "single": return "단일 일정"
        case "multiple": return "여러 일정"
        case "routine": return "루틴"
        default: return "일정"
        }
    }
}

// MARK: - Raw Response View
struct RawResponseView: View {
    let rawResponse: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("AI 원본 응답")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("아래 응답에서 JSON 부분을 확인하고 문제를 파악해보세요:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text(rawResponse)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("원본 응답")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views (기존과 동일)

struct ScheduleCard: View {
    let schedule: ScheduleItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let day = schedule.day {
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    } else if let date = schedule.date {
                        Text(date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }

                    Text(schedule.time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                Text(schedule.duration)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(schedule.activity)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let intensity = schedule.intensity {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("강도: \(intensity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let location = schedule.location {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let notes = schedule.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct VideoCard: View {
    let video: VideoResource

    var body: some View {
        Button(action: {
            if let url = URL(string: video.url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                AsyncImage(url: URL(string: video.thumbnail ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(video.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if let duration = video.duration {
                        Text(duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct LocationCard: View {
    let location: LocationResource

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(locationTypeDisplayName(location.type))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }

                Spacer()

                if let rating = location.rating {
                    VStack {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func locationTypeDisplayName(_ type: String) -> String {
        switch type.lowercased() {
        case "gym": return "헬스장"
        case "park": return "공원"
        case "pool": return "수영장"
        case "studio": return "스튜디오"
        default: return type
        }
    }
}

struct ProductCard: View {
    let product: ProductResource

    var body: some View {
        Button(action: {
            if let link = product.link, let url = URL(string: link) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(product.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let price = product.price {
                        Text(price)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    if product.link != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AIScheduleResultView(
        healthPlan: nil,
        isLoading: false,
        errorMessage: "테스트 오류",
        rawResponse: "테스트 응답"
    )
}
