//
//  AirPlayButton.swift
//  SpotiUI
//
//  Created by Mazy Lawzey on 28.03.2026.
//

import SwiftUI
import AVKit
import AppKit

struct AirPlayButton: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.isRoutePickerButtonBordered = false
        return picker
    }
    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {}
}
