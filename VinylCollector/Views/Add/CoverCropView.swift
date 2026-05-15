import SwiftUI

struct CoverCropView: View {
    let image: UIImage
    let detectedRect: CGRect?
    let onConfirm: (CGRect?) -> Void

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width, height: geo.size.height)

                    if let rect = detectedRect {
                        CropRectOverlay(
                            normalizedRect: rect,
                            imageSize: image.size,
                            containerSize: geo.size
                        )
                    }
                }
            }

            VStack(spacing: 14) {
                if let rect = detectedRect {
                    Text("Album cover detected")
                        .font(.headline)
                    Text("Send just the highlighted region to improve identification?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        onConfirm(rect)
                    } label: {
                        Label("Search with Crop", systemImage: "crop")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("Use Full Photo") {
                        onConfirm(nil)
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Text("No cover region detected")
                        .font(.headline)
                    Text("The full photo will be sent to AI for identification.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        onConfirm(nil)
                    } label: {
                        Label("Search", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(edges: .top)
    }
}

private struct CropRectOverlay: View {
    let normalizedRect: CGRect
    let imageSize: CGSize
    let containerSize: CGSize

    // Maps normalized image coordinates to view coordinates, accounting for aspect-fit letterboxing.
    private var cropFrame: CGRect {
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        let displayWidth: CGFloat
        let displayHeight: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat

        if imageAspect > containerAspect {
            displayWidth = containerSize.width
            displayHeight = containerSize.width / imageAspect
            xOffset = 0
            yOffset = (containerSize.height - displayHeight) / 2
        } else {
            displayHeight = containerSize.height
            displayWidth = containerSize.height * imageAspect
            xOffset = (containerSize.width - displayWidth) / 2
            yOffset = 0
        }

        return CGRect(
            x: xOffset + normalizedRect.minX * displayWidth,
            y: yOffset + normalizedRect.minY * displayHeight,
            width: normalizedRect.width * displayWidth,
            height: normalizedRect.height * displayHeight
        )
    }

    var body: some View {
        Canvas { context, size in
            let highlight = cropFrame

            // Dim everything outside the detected region using even-odd fill
            var mask = Path()
            mask.addRect(CGRect(origin: .zero, size: size))
            mask.addRect(highlight)
            context.fill(mask, with: .color(.black.opacity(0.5)), style: FillStyle(eoFill: true))

            // Dashed border around the detected region
            context.stroke(
                Path(highlight),
                with: .color(.white),
                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
            )
        }
    }
}
