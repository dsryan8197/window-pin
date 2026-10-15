import AppKit
import CoreMedia
import CoreVideo
import ScreenCaptureKit

/// A small always-on-top panel showing a live view of another app's window.
final class PinnedWindow: NSObject, NSWindowDelegate, SCStreamOutput, SCStreamDelegate {
    let target: AppWindow
    var onClose: ((PinnedWindow) -> Void)?

    private let scWindow: SCWindow
    private let panel: NSPanel
    private let preview = PreviewView(frame: .zero)
    private let frameQueue = DispatchQueue(label: "window-pin.frames")
    private var stream: SCStream?
    private var watchTimer: Timer?
    private var capturedSize: CGSize
    private var isClosed = false

    init(target: AppWindow, scWindow: SCWindow, cascadeIndex: Int) {
        self.target = target
        self.scWindow = scWindow
        capturedSize = target.bounds.size

        panel = NSPanel(
            contentRect: Self.initialFrame(for: target.bounds.size, cascadeIndex: cascadeIndex),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .hudWindow, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        super.init()

        panel.title = target.displayName
        panel.level = .floating
        panel.isFloatingPanel = true
        // This app is never the active one, so the panel must not hide when it isn't.
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.contentAspectRatio = target.bounds.size
        panel.contentMinSize = NSSize(width: 120, height: 80)
        panel.delegate = self
        panel.contentView = preview

        preview.onDoubleClick = { [weak self] in self?.goToWindow() }
        preview.menu = makeContextMenu()
    }

    func start() {
        let filter = SCContentFilter(desktopIndependentWindow: scWindow)
        let stream = SCStream(filter: filter, configuration: Self.configuration(for: capturedSize), delegate: self)
        do {
            try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: frameQueue)
        } catch {
            debugLog("couldn't add stream output: \(error)")
            close()
            return
        }
        self.stream = stream
        stream.startCapture { [weak self] error in
            guard let error else { return }
            debugLog("couldn't start capture of \(self?.target.menuTitle ?? "?"): \(error)")
            DispatchQueue.main.async { self?.close() }
        }

        panel.orderFrontRegardless()

        // Follow the original window's size, and unpin it once it closes.
        watchTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkOriginal()
        }
    }

    func bringToFront() {
        panel.orderFrontRegardless()
    }

    func close() {
        panel.close()
        tearDown()
    }

    /// Runs once, whether the panel was closed from its close button or from a menu.
    private func tearDown() {
        guard !isClosed else { return }
        isClosed = true
        watchTimer?.invalidate()
        watchTimer = nil
        stream?.stopCapture(completionHandler: nil)
        stream = nil
        onClose?(self)
    }

    // MARK: Capture

    private static func configuration(for size: CGSize) -> SCStreamConfiguration {
        let scale = NSScreen.screens.map(\.backingScaleFactor).max() ?? 2
        let config = SCStreamConfiguration()
        config.width = max(1, Int(size.width * scale))
        config.height = max(1, Int(size.height * scale))
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.queueDepth = 5
        config.showsCursor = false
        config.pixelFormat = kCVPixelFormatType_32BGRA
        return config
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
              let statusValue = attachments.first?[.status] as? Int,
              SCFrameStatus(rawValue: statusValue) == .complete,
              let pixelBuffer = sampleBuffer.imageBuffer,
              let surface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue()
        else { return }
        DispatchQueue.main.async { [weak self] in
            self?.preview.show(surface)
        }
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        debugLog("capture of \(target.menuTitle) stopped: \(error)")
        DispatchQueue.main.async { [weak self] in self?.close() }
    }

    private func checkOriginal() {
        guard let current = WindowCatalog.window(id: target.id) else {
            debugLog("\(target.menuTitle) closed")
            close()
            return
        }
        let size = current.bounds.size
        guard size.width >= 1, size.height >= 1,
              abs(size.width - capturedSize.width) > 1 || abs(size.height - capturedSize.height) > 1
        else { return }

        capturedSize = size
        stream?.updateConfiguration(Self.configuration(for: size)) { error in
            if let error { debugLog("couldn't follow resize: \(error)") }
        }
        let width = panel.contentLayoutRect.width
        panel.contentAspectRatio = size
        panel.setContentSize(NSSize(width: width, height: width * size.height / size.width))
    }

    // MARK: Panel

    /// A small panel in the bottom-right corner of the main screen, scaled to the window's shape.
    private static func initialFrame(for size: CGSize, cascadeIndex: Int) -> NSRect {
        let maxSize = CGSize(width: 360, height: 300)
        let scale = min(maxSize.width / max(size.width, 1), maxSize.height / max(size.height, 1), 1)
        let contentSize = CGSize(width: max(120, size.width * scale), height: max(80, size.height * scale))
        let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let offset = CGFloat(cascadeIndex % 6) * 28
        return NSRect(
            x: visible.maxX - contentSize.width - 20 - offset,
            y: visible.minY + 20 + offset,
            width: contentSize.width,
            height: contentSize.height
        )
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()

        let goItem = NSMenuItem(title: "Go to Window", action: #selector(goToWindow), keyEquivalent: "")
        goItem.target = self
        menu.addItem(goItem)

        let opacityItem = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        let opacityMenu = NSMenu()
        for percent in [100, 85, 70, 50, 30] {
            let item = NSMenuItem(title: "\(percent)%", action: #selector(setOpacity(_:)), keyEquivalent: "")
            item.target = self
            item.tag = percent
            item.state = percent == 100 ? .on : .off
            opacityMenu.addItem(item)
        }
        opacityItem.submenu = opacityMenu
        menu.addItem(opacityItem)

        menu.addItem(.separator())
        let unpinItem = NSMenuItem(title: "Unpin", action: #selector(unpin), keyEquivalent: "")
        unpinItem.target = self
        menu.addItem(unpinItem)
        return menu
    }

    @objc private func goToWindow() {
        WindowFocus.bringToFront(target)
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        panel.alphaValue = CGFloat(sender.tag) / 100
        sender.menu?.items.forEach { $0.state = $0 === sender ? .on : .off }
    }

    @objc private func unpin() {
        close()
    }

    func windowWillClose(_ notification: Notification) {
        tearDown()
    }
}

/// Shows the latest captured frame, scaled to fit.
private final class PreviewView: NSView {
    var onDoubleClick: (() -> Void)?
    private let contentLayer = CALayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        contentLayer.contentsGravity = .resizeAspect
        contentLayer.backgroundColor = NSColor.black.cgColor
        layer = contentLayer
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ surface: IOSurface) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        contentLayer.contents = surface
        CATransaction.commit()
    }

    override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onDoubleClick?()
        } else {
            super.mouseDown(with: event)
        }
    }
}
