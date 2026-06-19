import UIKit

final class ChartViewController: UIViewController {

    private let chartCollectionView: UICollectionView
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let selectedCandleTitleLabel = UILabel()
    private let selectedCandleStack = UIStackView()
    private let recommendationTitleLabel = UILabel()
    private let recommendationContainer = UIView()
    private let recommendationLabel = UILabel()

    private var candleViews: [CandleInfoView] = []
    private var candles: [CandleData] = []
    private var selectedIndex = 0

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
        setupCollectionView()
        setupSelectedCandleSection()
        setupRecommendationSection()
        makeConstraints()
        chartCollectionView.reloadData()
        selectCandle(at: 0, scrollPosition: [])
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

    func setupCollectionView() {
        chartCollectionView.backgroundColor = UIColor(white: 0.10, alpha: 1)
        chartCollectionView.layer.cornerRadius = Layout.containerCornerRadius
        chartCollectionView.showsHorizontalScrollIndicator = false
        chartCollectionView.alwaysBounceHorizontal = true
        chartCollectionView.dataSource = self
        chartCollectionView.delegate = self
        chartCollectionView.register(CandleCell.self, forCellWithReuseIdentifier: CandleCell.reuseId)
        chartCollectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(chartCollectionView)
    }

    func setupSelectedCandleSection() {
        selectedCandleTitleLabel.text = Messages.detailsTitle
        selectedCandleTitleLabel.font = .boldSystemFont(ofSize: Fonts.sectionTitle)
        selectedCandleTitleLabel.textColor = .white
        selectedCandleTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectedCandleTitleLabel)

        selectedCandleStack.axis = .vertical
        selectedCandleStack.spacing = Layout.infoSpacing
        selectedCandleStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectedCandleStack)

        let titles = [Messages.openPrice, Messages.closePrice, Messages.highPrice, Messages.lowPrice]
        candleViews = titles.map(CandleInfoView.init)
        candleViews.forEach { selectedCandleStack.addArrangedSubview($0) }
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

            chartCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.outerPadding),
            chartCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.outerPadding),
            chartCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.outerPadding),
            chartCollectionView.heightAnchor.constraint(equalToConstant: Layout.chartHeight),

            selectedCandleTitleLabel.topAnchor.constraint(equalTo: chartCollectionView.bottomAnchor, constant: Layout.sectionSpacing),
            selectedCandleTitleLabel.leadingAnchor.constraint(equalTo: chartCollectionView.leadingAnchor),
            selectedCandleTitleLabel.trailingAnchor.constraint(equalTo: chartCollectionView.trailingAnchor),

            selectedCandleStack.topAnchor.constraint(equalTo: selectedCandleTitleLabel.bottomAnchor, constant: Layout.infoTopSpacing),
            selectedCandleStack.leadingAnchor.constraint(equalTo: chartCollectionView.leadingAnchor),
            selectedCandleStack.trailingAnchor.constraint(equalTo: chartCollectionView.trailingAnchor),

            recommendationTitleLabel.topAnchor.constraint(equalTo: selectedCandleStack.bottomAnchor, constant: Layout.sectionSpacing),
            recommendationTitleLabel.leadingAnchor.constraint(equalTo: chartCollectionView.leadingAnchor),
            recommendationTitleLabel.trailingAnchor.constraint(equalTo: chartCollectionView.trailingAnchor),

            recommendationContainer.topAnchor.constraint(equalTo: recommendationTitleLabel.bottomAnchor, constant: Layout.infoTopSpacing),
            recommendationContainer.leadingAnchor.constraint(equalTo: chartCollectionView.leadingAnchor),
            recommendationContainer.trailingAnchor.constraint(equalTo: chartCollectionView.trailingAnchor),
            recommendationContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Layout.outerPadding),

            recommendationLabel.topAnchor.constraint(equalTo: recommendationContainer.topAnchor, constant: Layout.recommendationInsets),
            recommendationLabel.leadingAnchor.constraint(equalTo: recommendationContainer.leadingAnchor, constant: Layout.recommendationInsets),
            recommendationLabel.trailingAnchor.constraint(equalTo: recommendationContainer.trailingAnchor, constant: -Layout.recommendationInsets),
            recommendationLabel.bottomAnchor.constraint(equalTo: recommendationContainer.bottomAnchor, constant: -Layout.recommendationInsets)
        ])
    }

    func selectCandle(at index: Int, scrollPosition: UICollectionView.ScrollPosition) {
        guard candles.indices.contains(index) else { return }

        selectedIndex = index
        let candle = candles[index]
        candleViews[0].updateValue(candle.openText)
        candleViews[1].updateValue(candle.closeText)
        candleViews[2].updateValue(candle.highText)
        candleViews[3].updateValue(candle.lowText)

        chartCollectionView.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: scrollPosition)
        chartCollectionView.reloadData()
    }

    func showRecommendation(for candle: CandleData) {
        recommendationLabel.text = candle.recommendation.message
        recommendationLabel.textColor = candle.recommendation.color
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
        selectCandle(at: indexPath.item, scrollPosition: .centeredHorizontally)
    }
}

extension ChartViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: Layout.candleCellWidth, height: Layout.chartHeight - (Layout.sideInset * 2))
    }
}

private extension ChartViewController {

    enum Messages {
        static let title = "График"
        static let detailsTitle = "Выбранная свеча"
        static let recommendationTitle = "Рекомендации"
        static let recommendationPlaceholder = "Задержите палец на свече, чтобы получить совет: покупать, продавать или ждать."
        static let openPrice = "Цена открытия"
        static let closePrice = "Цена закрытия"
        static let highPrice = "Максимум"
        static let lowPrice = "Минимум"
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
        static let containerCornerRadius: CGFloat = 16
        static let recommendationInsets: CGFloat = 16
    }

    enum Fonts {
        static let sectionTitle: CGFloat = 20
        static let recommendation: CGFloat = 16
    }
}

private struct CandleData {
    let open: Double
    let close: Double
    let high: Double
    let low: Double
    let bodyHeight: CGFloat
    let wickHeight: CGFloat
    let bodyTopOffset: CGFloat
    let wickTopOffset: CGFloat
    let isGrowing: Bool
    let recommendation: Recommendation

    var openText: String { String(format: "%.2f", open) }
    var closeText: String { String(format: "%.2f", close) }
    var highText: String { String(format: "%.2f", high) }
    var lowText: String { String(format: "%.2f", low) }

    struct Recommendation {
        let message: String
        let color: UIColor
    }
}

private enum CandleFactory {

    static func makeCandles(count: Int) -> [CandleData] {
        var prices: [Double] = []
        prices.reserveCapacity(count * 4)

        var startPrice = Double.random(in: 90...120)
        var rawCandles: [(open: Double, close: Double, high: Double, low: Double)] = []

        for _ in 0..<count {
            let open = startPrice
            let delta = Double.random(in: -10...10)
            let close = max(20, open + delta)
            let high = max(open, close) + Double.random(in: 1...8)
            let low = max(5, min(open, close) - Double.random(in: 1...8))
            rawCandles.append((open, close, high, low))
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

            return CandleData(
                open: candle.open,
                close: candle.close,
                high: candle.high,
                low: candle.low,
                bodyHeight: bodyHeight,
                wickHeight: wickHeight,
                bodyTopOffset: bodyTop,
                wickTopOffset: highY,
                isGrowing: candle.close >= candle.open,
                recommendation: recommendation
            )
        }
    }

    static func makeRecommendation(open: Double, close: Double) -> CandleData.Recommendation {
        let variants: [(String, UIColor)]
        if close - open > 3 {
            variants = [("Покупать: свеча уверенно растет.", .systemGreen), ("Ждать: рост уже сильный, можно дождаться следующей точки входа.", .systemYellow)]
        } else if open - close > 3 {
            variants = [("Продавать: цена заметно снижается.", .systemRed), ("Ждать: падение резкое, лучше не входить импульсивно.", .systemYellow)]
        } else {
            variants = [("Ждать: движение нейтральное, сигнал слабый.", .systemYellow), ("Покупать: возможен аккуратный вход малым объемом.", .systemGreen), ("Продавать: если вы уже в позиции, можно зафиксировать часть прибыли.", .systemOrange)]
        }

        let selected = variants.randomElement() ?? ("Ждать: недостаточно данных.", .systemYellow)
        return .init(message: selected.0, color: selected.1)
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

    func configure(with candle: CandleData, isSelected: Bool) {
        let candleColor: UIColor = candle.isGrowing ? .systemGreen : .systemRed

        bodyView.backgroundColor = candleColor
        wickView.backgroundColor = candleColor
        bodyHeightConstraint?.constant = candle.bodyHeight
        wickHeightConstraint?.constant = candle.wickHeight
        bodyTopConstraint?.constant = candle.bodyTopOffset + Layout.verticalInset
        wickTopConstraint?.constant = candle.wickTopOffset + Layout.verticalInset
        bottomLabel.text = candle.isGrowing ? "UP" : "DOWN"

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
