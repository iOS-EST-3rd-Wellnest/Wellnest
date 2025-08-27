//
//  ResetDataView.swift
//  Wellnest
//
//  Created by 전광호 on 8/1/25.
//

import SwiftUI

struct ResetDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject private var hiddenTabBar: TabBarState
    
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.wellnestOrange)
                        .font(.system(size: 38))
                    
                    VStack(alignment: .leading) {
                        Text("앱을 초기상태로")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("앱에 저장된 모든 사용자 정보가 삭제되며 이 작업은 되돌릴 수 없습니다.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
                
                HStack {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .foregroundStyle(.wellnestOrange)
                        .font(.system(size: 42))
                    
                    VStack(alignment: .leading) {
                        Text("변경된 일상으로")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("필요하다면 초기화를 통해 언제든 새로운 시작을 할 수 있습니다.")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
            }
            
            Spacer()
            
            FilledButton(title: "데이터 초기화", backgroundColor: .red) {
                // TODO: 데이터 초기화
            }
        }
        .padding()
        .navigationTitle("데이터 초기화")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hiddenTabBar.isHidden = true
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    hiddenTabBar.isHidden = false
                    withAnimation { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.wellnestOrange)
                }
            }
        }
    }
}

#Preview {
    ResetDataView()
}
