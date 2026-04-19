import UIKit

final class ChartView: UIView {

    // MARK: - Public API

    func setInitialPrices(_ prices: [Double]) {
        self.prices = prices
        setNeedsDisplay()
        updateIndicatorPosition(animated: false)
    }

    func addPrice(_ price: Double) {
        prices.append(price)
        animateNewPoint()
    }

    // MARK: - Private State

    private var prices: [Double] = []

    // The static line layer (all points except the last segment)
    private let lineLayer = CAShapeLayer()
    // Animated segment layer (the new segment drawn to the latest point)
    private let animatedSegmentLayer = CAShapeLayer()
    // Gradient fill layer beneath the line
    private let gradientLayer = CAGradientLayer()

    // Pulsing indicator layers
    private let indicatorDot = CAShapeLayer()      // solid green dot
    private let indicatorRing = CAShapeLayer()     // pulsing outer ring

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupLayers()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        refreshStaticLine()
        updateIndicatorPosition(animated: false)
    }

    // MARK: - Layer Setup

    private func setupLayers() {
        // Gradient fill
        gradientLayer.colors = [
            UIColor.systemGreen.withAlphaComponent(0.35).cgColor,
            UIColor.systemGreen.withAlphaComponent(0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gradientLayer)

        // Static line
        lineLayer.fillColor    = UIColor.clear.cgColor
        lineLayer.strokeColor  = UIColor.systemGreen.cgColor
        lineLayer.lineWidth    = 2
        lineLayer.lineCap      = .round
        lineLayer.lineJoin     = .round
        layer.addSublayer(lineLayer)

        // Animated new-segment line (drawn on top)
        animatedSegmentLayer.fillColor   = UIColor.clear.cgColor
        animatedSegmentLayer.strokeColor = UIColor.systemGreen.cgColor
        animatedSegmentLayer.lineWidth   = 2
        animatedSegmentLayer.lineCap     = .round
        layer.addSublayer(animatedSegmentLayer)

        // Indicator ring (pulsing)
        indicatorRing.fillColor   = UIColor.clear.cgColor
        indicatorRing.strokeColor = UIColor.systemGreen.cgColor
        indicatorRing.lineWidth   = 1.5
        layer.addSublayer(indicatorRing)

        // Indicator dot (solid)
        indicatorDot.fillColor   = UIColor.systemGreen.cgColor
        indicatorDot.strokeColor = UIColor.clear.cgColor
        layer.addSublayer(indicatorDot)

        startPulseAnimation()
    }

    // MARK: - Drawing Helpers

    private func pointForIndex(_ index: Int, in rect: CGRect) -> CGPoint {
        guard prices.count > 1 else { return CGPoint(x: rect.midX, y: rect.midY) }

        let minY = prices.min() ?? 0
        let maxY = prices.max() ?? 1
        let rangeY = maxY - minY == 0 ? 1 : maxY - minY

        let padding: CGFloat = 20
        let drawWidth  = rect.width  - padding * 2
        let drawHeight = rect.height - padding * 2

        let x = padding + CGFloat(index) / CGFloat(prices.count - 1) * drawWidth
        let normalised = CGFloat((prices[index] - minY) / rangeY)
        let y = padding + (1 - normalised) * drawHeight
        return CGPoint(x: x, y: y)
    }

    private func buildLinePath(upToIndex endIndex: Int, in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        guard endIndex > 0, prices.count > 1 else { return path }

        path.move(to: pointForIndex(0, in: rect))
        for i in 1...endIndex {
            path.addLine(to: pointForIndex(i, in: rect))
        }
        return path
    }

    private func buildFillPath(upToIndex endIndex: Int, in rect: CGRect) -> UIBezierPath {
        let path = buildLinePath(upToIndex: endIndex, in: rect)
        guard !path.isEmpty else { return path }

        let lastPoint = pointForIndex(endIndex, in: rect)
        path.addLine(to: CGPoint(x: lastPoint.x, y: rect.height))
        path.addLine(to: CGPoint(x: pointForIndex(0, in: rect).x, y: rect.height))
        path.close()
        return path
    }

    // MARK: - Static Line Refresh

    private func refreshStaticLine() {
        guard !prices.isEmpty else { return }
        let rect = bounds
        let lastIndex = prices.count - 1

        let linePath = buildLinePath(upToIndex: lastIndex, in: rect)
        lineLayer.path = linePath.cgPath

        let fillPath = buildFillPath(upToIndex: lastIndex, in: rect)

        // Use a mask on the gradient layer
        let maskShape = CAShapeLayer()
        maskShape.path = fillPath.cgPath
        gradientLayer.mask = maskShape
    }

    // MARK: - Animate New Point (Task 4)

    private func animateNewPoint() {
        guard prices.count >= 2 else {
            refreshStaticLine()
            updateIndicatorPosition(animated: false)
            return
        }

        let rect = bounds
        let lastIndex  = prices.count - 1
        let prevIndex  = lastIndex - 1

        let fromPoint = pointForIndex(prevIndex, in: rect)
        let toPoint   = pointForIndex(lastIndex, in: rect)

        // Draw the new segment from prevPoint → newPoint
        let segmentPath = UIBezierPath()
        segmentPath.move(to: fromPoint)
        segmentPath.addLine(to: toPoint)
        animatedSegmentLayer.path = segmentPath.cgPath

        // Animate strokeEnd 0→1
        let drawAnimation = CABasicAnimation(keyPath: "strokeEnd")
        drawAnimation.fromValue = 0
        drawAnimation.toValue   = 1
        drawAnimation.duration  = 0.5
        drawAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        drawAnimation.fillMode  = .forwards
        drawAnimation.isRemovedOnCompletion = false

        animatedSegmentLayer.add(drawAnimation, forKey: "drawSegment")

        // After the segment finishes drawing, bake it into the static line
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.animatedSegmentLayer.path = nil
            self.animatedSegmentLayer.removeAnimation(forKey: "drawSegment")
            self.refreshStaticLine()
        }

        // Move indicator to new position
        updateIndicatorPosition(animated: true)
    }

    // MARK: - Indicator Position

    private func updateIndicatorPosition(animated: Bool) {
        guard !prices.isEmpty else { return }

        let rect      = bounds
        let lastIndex = prices.count - 1
        let center    = pointForIndex(lastIndex, in: rect)

        let dotRadius: CGFloat  = 5
        let ringRadius: CGFloat = 10

        let dotRect  = CGRect(x: center.x - dotRadius,  y: center.y - dotRadius,  width: dotRadius * 2,  height: dotRadius * 2)
        let ringRect = CGRect(x: center.x - ringRadius, y: center.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2)

        if animated {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.5)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            indicatorDot.path  = UIBezierPath(ovalIn: dotRect).cgPath
            indicatorRing.path = UIBezierPath(ovalIn: ringRect).cgPath
            CATransaction.commit()
        } else {
            indicatorDot.path  = UIBezierPath(ovalIn: dotRect).cgPath
            indicatorRing.path = UIBezierPath(ovalIn: ringRect).cgPath
        }
    }

    // MARK: - Pulse Animation (Task 3)

    private func startPulseAnimation() {
        // Alpha: 1 → 0.3 → 1 (infinite)
        let alphaAnim = CABasicAnimation(keyPath: "opacity")
        alphaAnim.fromValue = 1.0
        alphaAnim.toValue   = 0.3
        alphaAnim.duration  = 0.9
        alphaAnim.autoreverses = true
        alphaAnim.repeatCount  = .infinity
        alphaAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Scale: 1 → 1.6 → 1 (infinite) — only ring, not the dot
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue   = 1.6
        scaleAnim.duration  = 0.9
        scaleAnim.autoreverses = true
        scaleAnim.repeatCount  = .infinity
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        indicatorRing.add(alphaAnim, forKey: "ringAlpha")
        indicatorRing.add(scaleAnim, forKey: "ringScale")

        // Dot also pulses alpha slightly
        let dotAlpha = CABasicAnimation(keyPath: "opacity")
        dotAlpha.fromValue = 1.0
        dotAlpha.toValue   = 0.5
        dotAlpha.duration  = 0.9
        dotAlpha.autoreverses = true
        dotAlpha.repeatCount  = .infinity
        dotAlpha.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        indicatorDot.add(dotAlpha, forKey: "dotAlpha")
    }
}
