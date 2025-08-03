//
//  HorizontalDividerView.swift
//  Swiftcord
//
//  Created by Vincent Kwok on 9/7/22.
//

import SwiftUI

struct HorizontalDividerView: View {
	var body: some View {
		Rectangle().fill(Color(NSColor.separatorColor).opacity(0.3)).frame(height: 0.5)
	}
}

struct HorizontalDividerView_Previews: PreviewProvider {
    static var previews: some View {
		HorizontalDividerView().frame(width: 100)
    }
}
