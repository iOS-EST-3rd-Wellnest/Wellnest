//
//  TodayCardView.swift
//  Wellnest
//
//  Created by JuYong Lee on 8/26/25.
//

import SwiftUI

struct TodayCardView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var analyticsVM: AnalyticsViewModel
    @ObservedObject var homeVM: HomeViewModel
    @ObservedObject var manualScheduleVM: ManualScheduleViewModel
    @State private var isLandscape: Bool = UIScreen.main.bounds.width > UIScreen.main.bounds.height

    let isCompleteSchedules: [ScheduleItem]
    
    private let isDevicePad = UIDevice.current.userInterfaceIdiom == .pad
    
    private var planData: PlanCompletionData {
        analyticsVM.healthData.planCompletion
    }
    
    private var today: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "M월 d일"
        
        return df.string(from: Date.now)
    }
    
    private var cardHeight: CGFloat {
        isDevicePad ? 230 : 180
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(today)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: Spacing.layout) {
                if homeVM.goalList.isEmpty {
                    GoalSkeletonView(height: cardHeight)
                } else {
                    RoundedRectangle(cornerRadius: CornerRadius.large)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                        .frame(minHeight: cardHeight)
                        .roundedBorder(cornerRadius: CornerRadius.large)
                        .defaultShadow()
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: Spacing.content) {
                                Text("목표")
                                    .font(isDevicePad ? .title2 : .title3)
                                    .fontWeight(.semibold)
                                    .padding(.vertical, Spacing.inline)
                                
                                ForEach(homeVM.goalList, id: \.self) {
                                    Text("\($0)")
                                        .font(isDevicePad ? .headline : .subheadline)
                                }
                            }
                            .padding()
                            .padding(.top, isDevicePad ? Spacing.layout : 0)
                            .padding(.leading, isDevicePad ? Spacing.layout : 0)
                        }
                }
                
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
                    .frame(minHeight: cardHeight)
                    .roundedBorder(cornerRadius: CornerRadius.large)
                    .defaultShadow()
                    .overlay {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 18)
                            .frame(width: isDevicePad ? 140 : 120, height: isDevicePad ? 140 : 120)
                        
                        if planData.totalItems > 0 {
                            Circle()
                                .trim(from: 0, to: planData.completionRate)
                                .stroke(
                                    LinearGradient(
                                        colors: [.wellnestOrange],
                                        startPoint: .topTrailing,
                                        endPoint: .bottomLeading
                                    ),
                                    style: StrokeStyle(lineWidth: 18, lineCap: .round)
                                )
                                .frame(width: isDevicePad ? 140 : 120, height: isDevicePad ? 140 : 120)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: Spacing.inline) {
                                Text("\(Int(planData.completionRate * 100))%")
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text("남은 일정 \(planData.remainingItems)개")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            VStack(spacing: Spacing.inline) {
                                Text("\(Int(planData.completionRate * 100))%")
                                    .font(.title)
                                    .bold()
                            }
                        }
                    }
                
                let  scheduleWith: CGFloat = isDevicePad && isLandscape ? UIScreen.main.bounds.width / 2 : UIScreen.main.bounds.width / 2
                if isDevicePad {
                    if isCompleteSchedules.isEmpty {
                        VStack {
                            EmptyScheduleView(height: cardHeight)
                                .frame(minWidth: scheduleWith)
                        }
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            HomeScheduleView(manualScheduleVM: manualScheduleVM, isCompleteSchedules: isCompleteSchedules)
                        }
                        .frame(minWidth: scheduleWith)
                        .frame(height: cardHeight)
                    }
                }
            }
            .onAppear {
                UIDevice.current.beginGeneratingDeviceOrientationNotifications()
                isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
            }
            .onDisappear {
                UIDevice.current.endGeneratingDeviceOrientationNotifications()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                let orientation = UIDevice.current.orientation
                switch orientation {
                case .landscapeLeft, .landscapeRight:
                    isLandscape = true
                case .portrait, .portraitUpsideDown:
                    isLandscape = false
                default:
                    isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
                }
            }
        }
    }
}
