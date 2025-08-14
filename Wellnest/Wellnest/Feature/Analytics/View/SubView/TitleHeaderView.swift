//
//  TitleHeaderView.swift
//  Wellnest
//
//  Created by junil on 8/12/25.
//

import SwiftUI

struct TitleHeaderView: View {
    let name: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text("\(name)")
                            .foregroundStyle(.indigo)
                            .font(.title)
                            .fontWeight(.bold)
                        Text("님의 건강지표")
                            .font(.title)
                            .fontWeight(.semibold)
                    }
                }
                Spacer()
            }
        }
    }
}
