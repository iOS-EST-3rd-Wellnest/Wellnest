//
//  WeatherBadge.swift
//  Wellnest
//
//  Created by 박동언 on 8/30/25.
//

import SwiftUI

struct WeatherBadge: View {
    let item: WeatherItem
    var showCurrentOnly: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            AsyncImage(url: URL(string: item.icon)) { phase in
                switch phase {
                case .empty:
                    ProgressView().scaleEffect(0.7)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .trailing, spacing: 0) {
                if showCurrentOnly {
                    Text("\(item.temp)°")
                        .font(.subheadline)
                        .monospacedDigit()
                } else {
                    Text("\(item.tempMin)° / \(item.tempMax)°")
                        .font(.subheadline)
                        .monospacedDigit()
                }
            }
        }
    }
}

#Preview {
    let sample = WeatherItem(
        temp: 27,
        tempMin: 24,
        tempMax: 30,
        status: "맑음",
        icon: "https://openweathermap.org/img/wn/02d@2x.png",
        dt: Date()
    )

    return WeatherBadge(item: sample)
        .background(Color(.systemBackground))
}
