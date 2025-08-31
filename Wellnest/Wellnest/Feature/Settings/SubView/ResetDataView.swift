//
//  ResetDataView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI
import CoreData

struct ResetDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hsClass
    
    @EnvironmentObject private var hiddenTabBar: TabBarState
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: vstackSpacing) {
                HStack {
                    Image(systemName: "apple.meditate")
                        .foregroundStyle(.yellow)
                        .font(.system(size: SymbolSize))
                    
                    VStack(alignment: .leading) {
                        Text("다시 처음으로")
                            .font(titleFont)
                            .fontWeight(.bold)
                        
                        Text("현재 등록된 모든 일정을 삭제하고 처음의 마음가짐으로 다시 시작하세요.")
                            .foregroundStyle(.secondary)
                            .font(subTitleFont)
                    }
                }
                
                HStack {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(.yellow)
                        .font(.system(size: SymbolSize))
                    
                    VStack(alignment: .leading) {
                        Text("변경된 계획으로")
                            .font(titleFont)
                            .fontWeight(.bold)
                        
                        Text("초기화를 통해 깔끔하게 정리하고, 변경된 계획으로 다시 시작할 수 있습니다.")
                            .foregroundStyle(.secondary)
                            .font(subTitleFont)
                    }
                }
                
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.yellow)
                        .font(.system(size: SymbolSize))
                    
                    VStack(alignment: .leading) {
                        Text("모든 일정 삭제")
                            .font(titleFont)
                            .fontWeight(.bold)
                        
                        Text("현재 등록된 모든 일정이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
                            .foregroundStyle(.secondary)
                            .font(subTitleFont)
                    }
                }
            }
            .padding()
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
            }
            
            Spacer()
            
            FilledButton(title: "데이터 초기화", backgroundColor: .red) {
                showAlert = true
            }
            .layoutWidth()
            .tabBarGlassBackground()
            .alert("모든 일정을 삭제하시겠습니까?", isPresented: $showAlert) {
                Button("삭제", role: .destructive) {
                    resetData()
                    hiddenTabBar.isHidden = false
                    withAnimation { dismiss() }
                }
                
                Button("취소", role: .cancel) { }
            } message: {
                Text("이 작업은 되돌릴 수 없습니다.")
            }
        }
        .padding(.horizontal)
        .padding(.bottom, Spacing.content)
        .navigationTitle("데이터 초기화")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hiddenTabBar.isHidden = true
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    hiddenTabBar.isHidden = false
                    withAnimation { dismiss() }
                } label: {
                    Image(systemName: "chevron.backward")
                        .foregroundColor(.wellnestOrange)
                }
            }
        }
    }
}

#Preview {
    ResetDataView()
        .environmentObject(TabBarState())

}

extension ResetDataView {
    private func resetData() {
        do {
            try CoreDataService.shared.deleteAll(ScheduleEntity.self)
            
            print("✅ 모든 일정 삭제 완료")
        }catch {
            print("❌ 일정 삭제 실패: \(error)")
        }
    }
}

extension ResetDataView {
    var vstackSpacing: CGFloat {
        if hsClass == .compact {
            return 40
        } else {
            return 60
        }
    }
    
    var SymbolSize: CGFloat {
        if hsClass == .compact {
            return 40
        } else {
            return 60
        }
    }
    
    var titleFont: Font {
        if hsClass == .compact {
            return .title3
        } else {
            return .title
        }
    }
    
    var subTitleFont: Font {
        if hsClass == .compact {
            return .footnote
        } else {
            return .body
        }
    }
}
