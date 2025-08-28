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
    
    @EnvironmentObject private var hiddenTabBar: TabBarState
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text("일정을 초기상태로")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("등록된 모든 일정이 삭제되며 이 작업은 되돌릴 수 없습니다.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                
                HStack {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(.yellow)
                        .font(.system(size: 40))
                    
                    VStack(alignment: .leading) {
                        Text("변경된 계획으로")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("초기화를 통해 언제든 새로운 시작을 할 수 있습니다.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
            }
            
            Spacer()
            
            FilledButton(title: "데이터 초기화", backgroundColor: .red) {
                showAlert = true
            }
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
