import AppKit
import SwiftUI

/// `--render-popup <folder>` writes PNGs of the pop-up's content for a few
/// snaps, over a flat stand-in for the glass. For checking layout without
/// screen recording or the Accessibility permission.
enum PopupSnapshots {
    @MainActor
    static func write(to folder: URL) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let area = CGRect(x: 0, y: 0, width: 1728, height: 1080)
        let cases: [(String, SnapAction, Int)] = [
            ("left-1-half", .leftHalf, 0), ("left-2-two-thirds", .leftHalf, 1), ("left-3-third", .leftHalf, 2),
            ("top-2-two-thirds", .topHalf, 1), ("bottom-right-1", .bottomRight, 0), ("maximise", .maximise, 0),
            ("centre", .centre, 0),
        ]
        for (name, action, step) in cases {
            let current = CGRect(x: 300, y: 200, width: 1000, height: 640)
            let frame = action.frame(in: area, step: step, current: current)
            let model = PopupModel()
            model.update(with: .init(action: action, step: step, frame: frame, area: area))
            let view = PopupView(model: model)
                .background(RoundedRectangle(cornerRadius: 28).fill(Color(white: 0.9)))
                .padding(24)
                .background(Color(red: 0.78, green: 0.76, blue: 0.72))
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.cgImage else { continue }
            let rep = NSBitmapImageRep(cgImage: image)
            try? rep.representation(using: .png, properties: [:])?.write(to: folder.appendingPathComponent("\(name).png"))
        }
    }
}
