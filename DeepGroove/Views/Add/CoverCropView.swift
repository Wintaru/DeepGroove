import SwiftUI

struct CoverCropView: View {
    let image: UIImage
    let onConfirm: (CGRect?) -> Void

    @State private var cropRect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)

                    DraggableCropOverlay(
                        normalizedRect: $cropRect,
                        imageSize: image.size,
                        containerSize: geo.size
                    )


                }
            }

            VStack(spacing: 14) {
                Text("Drag corners to crop")
                    .font(.headline)
                Text("Adjust the selection to the album cover, then search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    onConfirm(cropRect)
                } label: {
                    Label("Search with Crop", systemImage: "crop")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Use Full Photo") { onConfirm(nil) }
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Draggable overlay

private struct DraggableCropOverlay: View {
    @Binding var normalizedRect: CGRect
    let imageSize: CGSize
    let containerSize: CGSize

    @GestureState private var tlDrag: CGSize = .zero
    @GestureState private var trDrag: CGSize = .zero
    @GestureState private var blDrag: CGSize = .zero
    @GestureState private var brDrag: CGSize = .zero

    private let handleSize: CGFloat = 26

    private var liveRect: CGRect {
        let m = metrics(imageSize: imageSize, containerSize: containerSize)
        guard m.w > 0, m.h > 0 else { return normalizedRect }
        var r = normalizedRect
        if tlDrag != .zero {
            let ndx = tlDrag.width / m.w, ndy = tlDrag.height / m.h
            r = CGRect(x: r.minX + ndx, y: r.minY + ndy, width: r.width - ndx, height: r.height - ndy)
        }
        if trDrag != .zero {
            let ndx = trDrag.width / m.w, ndy = trDrag.height / m.h
            r = CGRect(x: r.minX, y: r.minY + ndy, width: r.width + ndx, height: r.height - ndy)
        }
        if blDrag != .zero {
            let ndx = blDrag.width / m.w, ndy = blDrag.height / m.h
            r = CGRect(x: r.minX + ndx, y: r.minY, width: r.width - ndx, height: r.height + ndy)
        }
        if brDrag != .zero {
            let ndx = brDrag.width / m.w, ndy = brDrag.height / m.h
            r = CGRect(x: r.minX, y: r.minY, width: r.width + ndx, height: r.height + ndy)
        }
        return clamped(r)
    }

    var body: some View {
        let cf = displayFrame(for: liveRect, imageSize: imageSize, containerSize: containerSize)

        ZStack {
            Canvas { context, size in
                var mask = Path()
                mask.addRect(CGRect(origin: .zero, size: size))
                mask.addRect(cf)
                context.fill(mask, with: .color(.black.opacity(0.5)), style: FillStyle(eoFill: true))
                context.stroke(Path(cf), with: .color(.white),
                               style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
            }
            .allowsHitTesting(false)

            // Top-left
            Circle().fill(.white).frame(width: handleSize, height: handleSize).shadow(radius: 2)
                .position(CGPoint(x: cf.minX, y: cf.minY))
                .gesture(DragGesture(minimumDistance: 0)
                    .updating($tlDrag) { v, s, _ in s = v.translation }
                    .onEnded { v in commit(corner: .topLeft, t: v.translation) })

            // Top-right
            Circle().fill(.white).frame(width: handleSize, height: handleSize).shadow(radius: 2)
                .position(CGPoint(x: cf.maxX, y: cf.minY))
                .gesture(DragGesture(minimumDistance: 0)
                    .updating($trDrag) { v, s, _ in s = v.translation }
                    .onEnded { v in commit(corner: .topRight, t: v.translation) })

            // Bottom-left
            Circle().fill(.white).frame(width: handleSize, height: handleSize).shadow(radius: 2)
                .position(CGPoint(x: cf.minX, y: cf.maxY))
                .gesture(DragGesture(minimumDistance: 0)
                    .updating($blDrag) { v, s, _ in s = v.translation }
                    .onEnded { v in commit(corner: .bottomLeft, t: v.translation) })

            // Bottom-right
            Circle().fill(.white).frame(width: handleSize, height: handleSize).shadow(radius: 2)
                .position(CGPoint(x: cf.maxX, y: cf.maxY))
                .gesture(DragGesture(minimumDistance: 0)
                    .updating($brDrag) { v, s, _ in s = v.translation }
                    .onEnded { v in commit(corner: .bottomRight, t: v.translation) })
        }
    }

    private enum Corner { case topLeft, topRight, bottomLeft, bottomRight }

    private func commit(corner: Corner, t: CGSize) {
        let m = metrics(imageSize: imageSize, containerSize: containerSize)
        guard m.w > 0, m.h > 0 else { return }
        let ndx = t.width / m.w, ndy = t.height / m.h
        let r = normalizedRect
        let raw: CGRect
        switch corner {
        case .topLeft:
            raw = CGRect(x: r.minX + ndx, y: r.minY + ndy, width: r.width - ndx, height: r.height - ndy)
        case .topRight:
            raw = CGRect(x: r.minX, y: r.minY + ndy, width: r.width + ndx, height: r.height - ndy)
        case .bottomLeft:
            raw = CGRect(x: r.minX + ndx, y: r.minY, width: r.width - ndx, height: r.height + ndy)
        case .bottomRight:
            raw = CGRect(x: r.minX, y: r.minY, width: r.width + ndx, height: r.height + ndy)
        }
        normalizedRect = clamped(raw)
    }
}

// MARK: - Shared helpers

private struct DisplayMetrics {
    let w: CGFloat, h: CGFloat, ox: CGFloat, oy: CGFloat
}

private func metrics(imageSize: CGSize, containerSize: CGSize) -> DisplayMetrics {
    let ia = imageSize.width / imageSize.height
    let ca = containerSize.width / containerSize.height
    if ia > ca {
        let w = containerSize.width, h = w / ia
        return DisplayMetrics(w: w, h: h, ox: 0, oy: (containerSize.height - h) / 2)
    } else {
        let h = containerSize.height, w = h * ia
        return DisplayMetrics(w: w, h: h, ox: (containerSize.width - w) / 2, oy: 0)
    }
}

private func displayFrame(for norm: CGRect, imageSize: CGSize, containerSize: CGSize) -> CGRect {
    let m = metrics(imageSize: imageSize, containerSize: containerSize)
    return CGRect(x: m.ox + norm.minX * m.w, y: m.oy + norm.minY * m.h,
                  width: norm.width * m.w, height: norm.height * m.h)
}

private func clamped(_ r: CGRect) -> CGRect {
    let minSz: CGFloat = 0.05
    let x = max(0, min(r.minX, 1 - minSz))
    let y = max(0, min(r.minY, 1 - minSz))
    let w = max(minSz, min(r.width, 1 - x))
    let h = max(minSz, min(r.height, 1 - y))
    return CGRect(x: x, y: y, width: w, height: h)
}
