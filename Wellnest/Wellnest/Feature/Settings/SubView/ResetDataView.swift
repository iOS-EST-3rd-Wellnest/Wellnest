//
//  ResetDataView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI

struct ResetDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var ui: AppUIState
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 40))
                        
                            Text("앱에 저장된 모든 데이터를 초기 상태로 되돌립니다.")
                                .font(.headline)
                                .fontWeight(.bold)
                    }
                    
                    HStack {
                        Image(systemName: "trash.slash")
                            .foregroundStyle(.yellow)
                            .font(.system(size: 40))
                        
                            Text("한번 삭제된 데이터는 복구할 수 없습니다.")
                                .font(.headline)
                                .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                FilledButton(title: "데이터 삭제", backgroundColor: .red) {
                    
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            ui.isTabBarHidden = true
        }
        .onDisappear {
            ui.isTabBarHidden = false
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    ResetDataView()
}
