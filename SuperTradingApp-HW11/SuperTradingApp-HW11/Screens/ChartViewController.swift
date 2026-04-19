import UIKit

final class ChartViewController: UIViewController {

    private let chartCollectionView: UICollectionView
    private let lineChartView = LineChartView()
    private let chartModeStackView = UIStackView()
    private let candleModeButton = UIButton(type: .system)
    private let lineModeButton = UIButton(type: .system)
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let chartContainerView = UIView()
    private let selectedPointTitleLabel = UILabel()
    private let selectedPointStack = UIStackView()
    private let recommendationTitleLabel = UILabel()
    private let recommendationContainer = UIView()
    private let recommendationLabel = UILabel()

    private var infoViews: [CandleInfoView] = []
    private var candles: [ChartEntry] = []
    private var selectedIndex = 0
    private var chartMode: ChartMode = .candles {
        didSet {
            guard oldValue != chartMode else { return }
            updateChartMode()
        }
    }

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.candleSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: Layout.sideInset, bottom: 0, right: Layout.sideInset)
        chartCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Messages.title
        view.backgroundColor = .black

        candles = CandleFactory.makeCandles(count: 28)

        setupScrollView()
        setupChartModeToggle()
        setupChartViews()
        setupSelectedPointSection()
        setupRecommendationSection()
        makeConstraints()
        chartCollectionView.reloadData()
        lineChartView.points = candles.map(\.linePoint)
        lineChartView.onPointSelected = { [weak self] index in
            self?.selectEntry(at: index, updateCollectionSelection: false, scrollPosition: [])
        }
        selectEntry(at: 0, updateCollectionSelection: true, scrollPosition: [])
        updateChartMode()
    }
}

private extension ChartViewController {

    func setupScrollView() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }

    func setupChartModeToggle() {
        chartModeStackView.axis = .horizontal
        chartModeStackView.spacing = Layout.modeButtonSpacing
        chartModeStackView.distribution = .fillEqually
        chartModeStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartModeStackView)

        configureModeButton(candleModeButton, imageName: "chart.bar.xaxis", action: #selector(showCandles))
        configureModeButton(lineModeButton, imageName: "chart.xyaxis.line", action: #selector(showLineChart))

        chartModeStackView.addArrangedSubview(candleModeButton)
        chartModeStackView.addArrangedSubview(lineModeButton)
    }

    func configureModeButton(_ button: UIButton, imageName: String, action: Selector) {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .large
        configuration.baseForegroundColor = .white
        configuration.baseBackgroundColor = UIColor(white: 0.16, alpha: 1)
        configuration.image = UIImage(systemName: imageName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = configuration
        button.tintColor = .white
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    func setupChartViews() {
        chartContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartContainerView)

        chartCollectionView.backgroundColor = UIColor(white: 0.10, alpha: 1)
        chartCollectionView.layer.cornerRadius = Layout.containerCornerRadius
        chartCollectionView.showsHorizontalScrollIndicator = false
        chartCollectionView.alwaysBounceHorizontal = true
        chartCollectionView.dataSource = self
        chartCollectionView.delegate = self
        chartCollectionView.register(CandleCell.self, forCellWithReuseIdentifier: CandleCell.reuseId)
        chartCollectionView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(chartCollectionView)

        lineChartView.translatesAutoresizingMaskIntoConstraints = false
        chartContainerView.addSubview(lineChartView)
    }

    func setupSelectedPointSection() {
        selectedPointTitleLabel.font = .boldSystemFont(ofSize: Fonts.sectionTitle)
        selectedPointTitleLabel.textColor = .white
        selectedPointTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectedPointTitleLabel)

        selectedPointStack.axis = .vertical
        selectedPointStack.spacing = Layout.infoSpacing
        selectedPointStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectedPointStack)

        let titles = [Messages.openPrice, Messages.closePrice, Messages.highPrice, Messages.lowPrice, Messages.timePoint]
        infoViews = []
        for title in titles {
            let view = CandleInfoView(title)
            infoViews.append(view)
            selectedPointStack.addArrangedSubview(view)
        }
    }

    func setupRecommendationSection() {
        recommendationTitleLabel.text = Messages.recommendationTitle
        recommendationTitleLabel.font = .boldSystemFont(ofSize: Fonts.sectionTitle)
        recommendationTitleLabel.textColor = .white
        recommendationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recommendationTitleLabel)

        recommendationContainer.backgroundColor = UIColor(white: 0.12, alpha: 1)
        recommendationContainer.layer.cornerRadius = Layout.containerCornerRadius
        recommendationContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(recommendationContainer)

        recommendationLabel.text = Messages.recommendationPlaceholder
        recommendationLabel.textColor = .lightGray
        recommendationLabel.font = .systemFont(ofSize: Fonts.recommendation)
        recommendationLabel.numberOfLines = 0
        recommendationLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendationContainer.addSubview(recommendationLabel)
    }

    func makeConstraints() {
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safe.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            chartModeStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.outerPadding),
            chartModeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.outerPadding),
            chartModeStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.outerPadding),

            chartContainerView.topAnchor.constraint(equalTo: chartModeStackView.bottomAnchor, constant: Layout.chartTopSpacing),
            chartContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.outerPadding),
            chartContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.outerPadding),
            chartContainerView.heightAnchor.constraint(equalToConstant: Layout.chartHeight),

            chartCollectionView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            chartCollectionView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            chartCollectionView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            chartCollectionView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),

            lineChartView.topAnchor.constraint(equalTo: chartContainerView.topAnchor),
            lineChartView.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            lineChartView.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            lineChartView.bottomAnchor.constraint(equalTo: chartContainerView.bottomAnchor),

            selectedPointTitleLabel.topAnchor.constraint(equalTo: chartContainerView.bottomAnchor, constant: Layout.sectionSpacing),
            selectedPointTitleLabel.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            selectedPointTitleLabel.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),

            selectedPointStack.topAnchor.constraint(equalTo: selectedPointTitleLabel.bottomAnchor, constant: Layout.infoTopSpacing),
            selectedPointStack.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            selectedPointStack.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),

            recommendationTitleLabel.topAnchor.constraint(equalTo: selectedPointStack.bottomAnchor, constant: Layout.sectionSpacing),
            recommendationTitleLabel.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            recommendationTitleLabel.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),

            recommendationContainer.topAnchor.constraint(equalTo: recommendationTitleLabel.bottomAnchor, constant: Layout.infoTopSpacing),
            recommendationContainer.leadingAnchor.constraint(equalTo: chartContainerView.leadingAnchor),
            recommendationContainer.trailingAnchor.constraint(equalTo: chartContainerView.trailingAnchor),
            recommendationContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.outerPadding),

            recommendationLabel.topAnchor.constraint(equalTo: recommendationContainer.topAnchor, constant: Layout.recommendationInsets),
            recommendationLabel.leadingAnchor.constraint(equalTo: recommendationContainer.leadingAnchor, constant: Layout.recommendationInsets),
            recommendationLabel.trailingAnchor.constraint(equalTo: recommendationContainer.trailingAnchor, constant: -Layout.recommendationInsets),
            recommendationLabel.bottomAnchor.constraint(equalTo: recommendationContainer.bottomAnchor, constant: -Layout.recommendationInsets)
        ])
    }

    func updateChartMode() {
        let isCandles = chartMode == .candles
        chartCollectionView.isHidden = !isCandles
        lineChartView.isHidden = isCandles

        updateModeButtonAppearance(candleModeButton, isActive: isCandles)
        updateModeButtonAppearance(lineModeButton, isActive: !isCandles)
        selectedPointTitleLabel.text = isCandles ? Messages.selectedCandleTitle : Messages.selectedPointTitle

        if !isCandles {
            lineChartView.selectPoint(at: selectedIndex, notify: false)
        }
    }

    func updateModeButtonAppearance(_ button: UIButton, isActive: Bool) {
        button.configuration?.baseBackgroundColor = isActive ? .systemBlue : UIColor(white: 0.16, alpha: 1)
        button.configuration?.baseForegroundColor = .white
    }

    func updateInfoSection(with candle: ChartEntry) {
        infoViews[0].updateValue(candle.openText)
        infoViews[1].updateValue(candle.closeText)
        infoViews[2].updateValue(candle.highText)
        infoViews[3].updateValue(candle.lowText)
        infoViews[4].updateValue(candle.timeLabel)
    }

    func selectEntry(at index: Int, updateCollectionSelection: Bool, scrollPosition: UICollectionView.ScrollPosition) {
        guard candles.indices.contains(index) else { return }

        selectedIndex = index
        let candle = candles[index]

        updateInfoSection(with: candle)

        if updateCollectionSelection {
            chartCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: scrollPosition)
            chartCollectionView.reloadData()
        }

        lineChartView.selectPoint(at: index, notify: false)
    }

    func showRecommendation(for candle: ChartEntry) {
        recommendationLabel.text = candle.recommendation.message
        recommendationLabel.textColor = candle.recommendation.color
    }

    @objc func showCandles() {
        chartMode = .candles
    }

    @objc func showLineChart() {
        chartMode = .line
    }

    enum ChartMode {
        case candles
        case line
    }

    enum Messages {
        static let title = "График"
        static let selectedCandleTitle = "Выбранная свеча"
        static let selectedPointTitle = "Выбранная точка"
        static let recommendationTitle = "Рекомендации"
        static let recommendationPlaceholder = "Задержите палец на свече, чтобы получить совет: покупать, продавать или ждать."
        static let openPrice = "Цена открытия"
        static let closePrice = "Цена закрытия"
        static let highPrice = "Максимум"
        static let lowPrice = "Минимум"
        static let timePoint = "Время"
    }

    enum Layout {
        static let outerPadding: CGFloat = 16
        static let sideInset: CGFloat = 14
        static let chartHeight: CGFloat = 280
        static let candleCellWidth: CGFloat = 52
        static let candleSpacing: CGFloat = 10
        static let sectionSpacing: CGFloat = 24
        static let infoTopSpacing: CGFloat = 10
        static let infoSpacing: CGFloat = 8
        static let chartTopSpacing: CGFloat = 12
        static let modeButtonSpacing: CGFloat = 10
        static let containerCornerRadius: CGFloat = 16
        static let recommendationInsets: CGFloat = 16
    }

    enum Fonts {
        static let sectionTitle: CGFloat = 20
        static let recommendation: CGFloat = 16
    }
}

extension ChartViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        candles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandleCell.reuseId, for: indexPath) as! CandleCell
        cell.configure(with: candles[indexPath.item], isSelected: indexPath.item == selectedIndex)
        cell.onLongPress = { [weak self] in
            guard let self else { return }
            self.showRecommendation(for: self.candles[indexPath.item])
        }
        return cell
    }
}

extension ChartViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectEntry(at: indexPath.item, updateCollectionSelection: true, scrollPosition: .centeredHorizontally)
    }
}

extension ChartViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: Layout.candleCellWidth, height: Layout.chartHeight - (Layout.sideInset * 2))
    }
}

private struct ChartEntry {
    let open: Double
    let close: Double
    let high: Double
    let low: Double
    let bodyHeight: CGFloat
    let wickHeight: CGFloat
    let bodyTopOffset: CGFloat
    let wickTopOffset: CGFloat
    let isGrowing: Bool
    let timeLabel: String
    let recommendation: Recommendation

    var linePoint: LineChartPoint {
        LineChartPoint(price: close, title: timeLabel)
    }

    var openText: String { String(format: "%.2f", open) }
    var closeText: String { String(format: "%.2f", close) }
    var highText: String { String(format: "%.2f", high) }
    var lowText: String { String(format: "%.2f", low) }

    struct Recommendation {
        let message: String
        let color: UIColor
    }
}

private struct LineChartPoint {
    let price: Double
    let title: String
}

private enum CandleFactory {

    static func makeCandles(count: Int) -> [ChartEntry] {
        var prices: [Double] = []
        prices.reserveCapacity(count * 4)

        var startPrice = Double.random(in: 90...120)
        var rawCandles: [(open: Double, close: Double, high: Double, low: Double, timeLabel: String)] = []

        for index in 0..<count {
            let open = startPrice
            let delta = Double.random(in: -10...10)
            let close = max(20, open + delta)
            let high = max(open, close) + Double.random(in: 1...8)
            let low = max(5, min(open, close) - Double.random(in: 1...8))
            let timeLabel = makeTimeLabel(for: index)
            rawCandles.append((open, close, high, low, timeLabel))
            prices.append(contentsOf: [open, close, high, low])
            startPrice = close + Double.random(in: -4...4)
        }

        let minPrice = prices.min() ?? 0
        let maxPrice = prices.max() ?? 1
        let spread = max(maxPrice - minPrice, 1)
        let drawingHeight = CandleCell.Layout.drawingAreaHeight
        let bodyWidth = CandleCell.Layout.bodyWidth
        let minimumBodyHeight = CandleCell.Layout.minimumBodyHeight

        return rawCandles.map { candle in
            let highY = CGFloat((maxPrice - candle.high) / spread) * drawingHeight
            let lowY = CGFloat((maxPrice - candle.low) / spread) * drawingHeight
            let openY = CGFloat((maxPrice - candle.open) / spread) * drawingHeight
            let closeY = CGFloat((maxPrice - candle.close) / spread) * drawingHeight

            let wickHeight = max(lowY - highY, bodyWidth)
            let bodyTop = min(openY, closeY)
            let bodyHeight = max(abs(openY - closeY), minimumBodyHeight)
            let recommendation = makeRecommendation(open: candle.open, close: candle.close)

            return ChartEntry(
                open: candle.open,
                close: candle.close,
                high: candle.high,
                low: candle.low,
                bodyHeight: bodyHeight,
                wickHeight: wickHeight,
                bodyTopOffset: bodyTop,
                wickTopOffset: highY,
                isGrowing: candle.close >= candle.open,
                timeLabel: candle.timeLabel,
                recommendation: recommendation
            )
        }
    }

    static func makeRecommendation(open: Double, close: Double) -> ChartEntry.Recommendation {
        let variants: [(String, UIColor)]
        if close - open > 3 {
            variants = [
                ("Покупать: свеча уверенно растет.", .systemGreen),
                ("Ждать: рост уже сильный, можно дождаться следующей точки входа.", .systemYellow)
            ]
        } else if open - close > 3 {
            variants = [
                ("Продавать: цена заметно снижается.", .systemRed),
                ("Ждать: падение резкое, лучше не входить импульсивно.", .systemYellow)
            ]
        } else {
            variants = [
                ("Ждать: движение нейтральное, сигнал слабый.", .systemYellow),
                ("Покупать: возможен аккуратный вход малым объемом.", .systemGreen),
                ("Продавать: если вы уже в позиции, можно зафиксировать часть прибыли.", .systemOrange)
            ]
        }

        let selected = variants.randomElement() ?? ("Ждать: недостаточно данных.", .systemYellow)
        return .init(message: selected.0, color: selected.1)
    }

    static func makeTimeLabel(for index: Int) -> String {
        let startHour = 9
        let hour = (startHour + index) % 24
        return String(format: "%02d:00", hour)
    }
}

private final class LineChartView: UIView {

    var onPointSelected: ((Int) -> Void)?

    var points: [LineChartPoint] = [] {
        didSet {
            if selectedIndex >= points.count {
                selectedIndex = max(points.count - 1, 0)
            }
            rebuildLabels()
            setNeedsLayout()
        }
    }

    private let lineLayer = CAShapeLayer()
    private let gridLayer = CAShapeLayer()
    private let selectionLayer = CAShapeLayer()
    private let valueBubbleLabel = PaddingLabel()
    private var priceLabels: [UILabel] = []
    private var timeLabels: [UILabel] = []
    private var selectedIndex = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.10, alpha: 1)
        layer.cornerRadius = 16
        clipsToBounds = true

        gridLayer.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
        gridLayer.fillColor = UIColor.clear.cgColor
        gridLayer.lineWidth = 1
        layer.addSublayer(gridLayer)

        lineLayer.strokeColor = UIColor.systemCyan.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 3
        lineLayer.lineJoin = .round
        lineLayer.lineCap = .round
        layer.addSublayer(lineLayer)

        selectionLayer.fillColor = UIColor.systemBlue.cgColor
        selectionLayer.strokeColor = UIColor.white.cgColor
        selectionLayer.lineWidth = 2
        layer.addSublayer(selectionLayer)

        valueBubbleLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.95)
        valueBubbleLabel.textColor = .white
        valueBubbleLabel.font = .boldSystemFont(ofSize: 12)
        valueBubbleLabel.layer.cornerRadius = 10
        valueBubbleLabel.layer.masksToBounds = true
        valueBubbleLabel.isHidden = true
        valueBubbleLabel.translatesAutoresizingMaskIntoConstraints = true
        addSubview(valueBubbleLabel)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !points.isEmpty else {
            lineLayer.path = nil
            gridLayer.path = nil
            selectionLayer.path = nil
            valueBubbleLabel.isHidden = true
            return
        }

        drawGrid()
        drawLine()
        layoutPriceLabels()
        layoutTimeLabels()
        updateSelectionPath()
    }

    func selectPoint(at index: Int, notify: Bool) {
        guard points.indices.contains(index) else { return }
        selectedIndex = index
        setNeedsLayout()
        if notify {
            onPointSelected?(index)
        }
    }
}

private extension LineChartView {

    func rebuildLabels() {
        priceLabels.forEach { $0.removeFromSuperview() }
        timeLabels.forEach { $0.removeFromSuperview() }

        priceLabels = (0..<Layout.priceSteps).map { _ in
            let label = makeAxisLabel()
            addSubview(label)
            return label
        }

        let timeSteps = min(max(points.count, 2), Layout.maxTimeLabels)
        timeLabels = (0..<timeSteps).map { _ in
            let label = makeAxisLabel()
            label.textAlignment = .center
            addSubview(label)
            return label
        }
    }

    func makeAxisLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.72)
        label.translatesAutoresizingMaskIntoConstraints = true
        return label
    }

    func drawLine() {
        let path = UIBezierPath()
        let positions = pointPositions()

        for (index, point) in positions.enumerated() {
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        lineLayer.frame = bounds
        lineLayer.path = path.cgPath
    }

    func drawGrid() {
        let path = UIBezierPath()
        let drawingRect = chartRect
        let priceValues = priceStepValues()

        for value in priceValues {
            let y = yPosition(for: value)
            path.move(to: CGPoint(x: drawingRect.minX, y: y))
            path.addLine(to: CGPoint(x: drawingRect.maxX, y: y))
        }

        let indices = axisPointIndices(labelCount: timeLabels.count)
        for index in indices {
            let x = xPosition(for: index)
            path.move(to: CGPoint(x: x, y: drawingRect.minY))
            path.addLine(to: CGPoint(x: x, y: drawingRect.maxY))
        }

        gridLayer.frame = bounds
        gridLayer.path = path.cgPath
    }

    func layoutPriceLabels() {
        let values = priceStepValues()
        for (index, label) in priceLabels.enumerated() {
            let value = values[index]
            label.text = String(format: "%.2f", value)
            label.sizeToFit()
            let y = yPosition(for: value) - (label.bounds.height / 2)
            label.frame = CGRect(
                x: Layout.contentInsets.left,
                y: y,
                width: Layout.priceLabelWidth,
                height: label.bounds.height
            )
        }
    }

    func layoutTimeLabels() {
        let indices = axisPointIndices(labelCount: timeLabels.count)
        for (index, label) in timeLabels.enumerated() {
            let pointIndex = indices[index]
            label.text = points[pointIndex].title
            label.sizeToFit()
            let x = xPosition(for: pointIndex) - max(label.bounds.width, Layout.timeLabelWidth) / 2
            label.frame = CGRect(
                x: max(chartRect.minX, min(x, bounds.width - Layout.timeLabelWidth - Layout.contentInsets.right)),
                y: bounds.height - Layout.contentInsets.bottom + 6,
                width: Layout.timeLabelWidth,
                height: label.bounds.height
            )
        }
    }

    func updateSelectionPath() {
        guard points.indices.contains(selectedIndex) else {
            selectionLayer.path = nil
            valueBubbleLabel.isHidden = true
            return
        }

        let center = pointPositions()[selectedIndex]
        let markerPath = UIBezierPath(arcCenter: center, radius: Layout.selectionRadius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        selectionLayer.frame = bounds
        selectionLayer.path = markerPath.cgPath

        valueBubbleLabel.text = String(format: "%.2f", points[selectedIndex].price)
        valueBubbleLabel.sizeToFit()
        let bubbleWidth = valueBubbleLabel.bounds.width
        let bubbleHeight = valueBubbleLabel.bounds.height
        let bubbleX = max(Layout.contentInsets.left, min(center.x - bubbleWidth / 2, bounds.width - bubbleWidth - Layout.contentInsets.right))
        let bubbleY = max(Layout.contentInsets.top, center.y - bubbleHeight - 12)
        valueBubbleLabel.frame = CGRect(x: bubbleX, y: bubbleY, width: bubbleWidth, height: bubbleHeight)
        valueBubbleLabel.isHidden = false
    }

    func pointPositions() -> [CGPoint] {
        points.enumerated().map { index, point in
            CGPoint(x: xPosition(for: index), y: yPosition(for: point.price))
        }
    }

    func xPosition(for index: Int) -> CGFloat {
        let drawingRect = chartRect
        guard points.count > 1 else { return drawingRect.midX }
        let step = drawingRect.width / CGFloat(points.count - 1)
        return drawingRect.minX + (CGFloat(index) * step)
    }

    func yPosition(for value: Double) -> CGFloat {
        let drawingRect = chartRect
        let minPrice = points.map(\.price).min() ?? 0
        let maxPrice = points.map(\.price).max() ?? 1
        let spread = max(maxPrice - minPrice, 1)
        let progress = CGFloat((maxPrice - value) / spread)
        return drawingRect.minY + progress * drawingRect.height
    }

    func axisPointIndices(labelCount: Int) -> [Int] {
        guard labelCount > 0, !points.isEmpty else { return [] }
        guard labelCount > 1 else { return [0] }

        return (0..<labelCount).map { step in
            Int(round(CGFloat(step) * CGFloat(points.count - 1) / CGFloat(labelCount - 1)))
        }
    }

    func priceStepValues() -> [Double] {
        let minPrice = points.map(\.price).min() ?? 0
        let maxPrice = points.map(\.price).max() ?? 1
        let spread = max(maxPrice - minPrice, 1)

        return (0..<Layout.priceSteps).map { step in
            minPrice + (spread * Double(step) / Double(Layout.priceSteps - 1))
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let positions = pointPositions()
        guard let nearest = positions.enumerated().min(by: { lhs, rhs in
            abs(lhs.element.x - location.x) < abs(rhs.element.x - location.x)
        })?.offset else {
            return
        }

        selectPoint(at: nearest, notify: true)
    }

    var chartRect: CGRect {
        bounds.inset(by: Layout.contentInsets)
    }

    enum Layout {
        static let contentInsets = UIEdgeInsets(top: 18, left: 50, bottom: 34, right: 18)
        static let priceSteps = 5
        static let maxTimeLabels = 5
        static let selectionRadius: CGFloat = 6
        static let priceLabelWidth: CGFloat = 44
        static let timeLabelWidth: CGFloat = 52
    }
}

private final class PaddingLabel: UILabel {

    private let insets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fitting = super.sizeThatFits(size)
        return CGSize(width: fitting.width + insets.left + insets.right, height: fitting.height + insets.top + insets.bottom)
    }
}

private final class CandleCell: UICollectionViewCell {

    static let reuseId = "CandleCell"

    var onLongPress: (() -> Void)?

    private let drawingContainer = UIView()
    private let wickView = UIView()
    private let bodyView = UIView()
    private let bottomLabel = UILabel()

    private var bodyHeightConstraint: NSLayoutConstraint?
    private var wickHeightConstraint: NSLayoutConstraint?
    private var bodyTopConstraint: NSLayoutConstraint?
    private var wickTopConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        addGestureRecognizer(longPress)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionAppearance()
        }
    }

    func configure(with candle: ChartEntry, isSelected: Bool) {
        let candleColor: UIColor = candle.isGrowing ? .systemGreen : .systemRed

        bodyView.backgroundColor = candleColor
        wickView.backgroundColor = candleColor
        bodyHeightConstraint?.constant = candle.bodyHeight
        wickHeightConstraint?.constant = candle.wickHeight
        bodyTopConstraint?.constant = candle.bodyTopOffset + Layout.verticalInset
        wickTopConstraint?.constant = candle.wickTopOffset + Layout.verticalInset
        bottomLabel.text = candle.timeLabel

        self.isSelected = isSelected
    }
}

private extension CandleCell {

    func setupUI() {
        contentView.backgroundColor = .clear

        drawingContainer.backgroundColor = UIColor(white: 0.14, alpha: 1)
        drawingContainer.layer.cornerRadius = Layout.containerCornerRadius
        drawingContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(drawingContainer)

        wickView.layer.cornerRadius = Layout.wickWidth / 2
        wickView.translatesAutoresizingMaskIntoConstraints = false
        drawingContainer.addSubview(wickView)

        bodyView.layer.cornerRadius = Layout.bodyCornerRadius
        bodyView.translatesAutoresizingMaskIntoConstraints = false
        drawingContainer.addSubview(bodyView)

        bottomLabel.font = .systemFont(ofSize: Layout.labelFontSize, weight: .semibold)
        bottomLabel.textAlignment = .center
        bottomLabel.textColor = .lightGray
        bottomLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bottomLabel)

        wickHeightConstraint = wickView.heightAnchor.constraint(equalToConstant: 100)
        wickTopConstraint = wickView.topAnchor.constraint(equalTo: drawingContainer.topAnchor, constant: 20)
        bodyHeightConstraint = bodyView.heightAnchor.constraint(equalToConstant: 70)
        bodyTopConstraint = bodyView.topAnchor.constraint(equalTo: drawingContainer.topAnchor, constant: 30)

        NSLayoutConstraint.activate([
            drawingContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            drawingContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            drawingContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            drawingContainer.heightAnchor.constraint(equalToConstant: Layout.drawingAreaHeight + (Layout.verticalInset * 2)),

            wickView.centerXAnchor.constraint(equalTo: drawingContainer.centerXAnchor),
            wickView.widthAnchor.constraint(equalToConstant: Layout.wickWidth),
            wickTopConstraint!,
            wickHeightConstraint!,

            bodyView.centerXAnchor.constraint(equalTo: drawingContainer.centerXAnchor),
            bodyView.widthAnchor.constraint(equalToConstant: Layout.bodyWidth),
            bodyTopConstraint!,
            bodyHeightConstraint!,

            bottomLabel.topAnchor.constraint(equalTo: drawingContainer.bottomAnchor, constant: 8),
            bottomLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func updateSelectionAppearance() {
        drawingContainer.layer.borderWidth = isSelected ? 2 : 0
        drawingContainer.layer.borderColor = isSelected ? UIColor.white.cgColor : UIColor.clear.cgColor
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        onLongPress?()
    }

    enum Layout {
        static let drawingAreaHeight: CGFloat = 210
        static let bodyWidth: CGFloat = 30
        static let wickWidth: CGFloat = 4
        static let verticalInset: CGFloat = 10
        static let minimumBodyHeight: CGFloat = 18
        static let containerCornerRadius: CGFloat = 14
        static let bodyCornerRadius: CGFloat = 8
        static let labelFontSize: CGFloat = 11
    }
}

private final class CandleInfoView: UIView {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(_ title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.12, alpha: 1)
        layer.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = .lightGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        valueLabel.font = .boldSystemFont(ofSize: 16)
        valueLabel.textColor = .white
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateValue(_ value: String) {
        valueLabel.text = value
    }
}
