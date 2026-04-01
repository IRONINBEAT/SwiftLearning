import UIKit

class TradeCell: UITableViewCell {
    
    private let tickLabel = UILabel()
    private let decisionLabel = UILabel()
    private let priceLabel = UILabel()
    private let detailsLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with trade: TradeRecord) {
        tickLabel.text = "Tick #\(trade.tickNumber)"
        priceLabel.text = "FROM = \(trade.lastPrice.twoDigits)$ -> TO =  \(trade.currentPrice.twoDigits)$"
        
        switch trade.decision {
        case .buy:
            decisionLabel.text = "\(trade.decision.rawValue)"
            decisionLabel.textColor = .systemGreen
            detailsLabel.text = "Куплено по: \(trade.currentPrice.twoDigits)$"
            detailsLabel.isHidden = false
        case .sell:
            decisionLabel.text = "\(trade.decision.rawValue)"
            decisionLabel.textColor = .systemRed
            let incomeText = trade.income.map { "Доход: \($0 >= 0 ? "+" : "")\($0.twoDigits)$" } ?? ""
            detailsLabel.text = "Продано по: \(trade.currentPrice.twoDigits)$\n\(incomeText)"
            detailsLabel.isHidden = false
        case .ignore:
            decisionLabel.text = "\(trade.decision.rawValue)"
            decisionLabel.textColor = .systemYellow
            detailsLabel.text = ""
            detailsLabel.isHidden = true
        }
    }
}

private extension TradeCell {
    
    private func setupUI() {
        backgroundColor = UIColor(white: 0.15, alpha: 1)
        selectionStyle = .none
        
        // Tick Label
        tickLabel.font = .systemFont(ofSize: Fonts.tickLabelSize)
        tickLabel.textColor = .lightGray
        tickLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tickLabel)
        
        // Decision Label
        decisionLabel.font = .boldSystemFont(ofSize: Fonts.decisionLabelSize)
        decisionLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(decisionLabel)
        
        // Price Label
        priceLabel.font = .systemFont(ofSize: Fonts.priceLabelSize)
        priceLabel.textColor = .white
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(priceLabel)
        
        // Details Label
        detailsLabel.font = .systemFont(ofSize: Fonts.detailsLabelSize)
        detailsLabel.textColor = .white
        detailsLabel.numberOfLines = .zero
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(detailsLabel)
        
        NSLayoutConstraint.activate([
            tickLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.tickLabelTopAnchor),
            tickLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.tickLabelLeadingAnchor),
            
            decisionLabel.topAnchor.constraint(equalTo: tickLabel.bottomAnchor, constant: Constants.decisionLabelTopAnchor),
            decisionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.decisionLabelLeadingAnchor),
            
            priceLabel.centerYAnchor.constraint(equalTo: decisionLabel.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.priceLabelTrailingAnchor),
            
            detailsLabel.topAnchor.constraint(equalTo: decisionLabel.bottomAnchor, constant: Constants.detailsLabelTopAnchor),
            detailsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.detailsLabelLeadingAnchor),
            detailsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.detailsLabelTrailingAnchor),
            detailsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.detailsLabelBottomAnchor)
        ])
    }
}

private extension TradeCell {
    
    enum Constants {
        static let tickLabelTopAnchor: CGFloat = 8
        static let tickLabelLeadingAnchor: CGFloat = 12
        
        static let decisionLabelTopAnchor: CGFloat = 4
        static let decisionLabelLeadingAnchor: CGFloat = 12
        
        static let priceLabelTrailingAnchor: CGFloat = 12
        
        static let detailsLabelTopAnchor: CGFloat = 8
        static let detailsLabelLeadingAnchor: CGFloat = 12
        static let detailsLabelTrailingAnchor: CGFloat = 12
        static let detailsLabelBottomAnchor: CGFloat = 8
    }
    
    enum Fonts {
        static let tickLabelSize: CGFloat = 12
        static let decisionLabelSize: CGFloat = 14
        static let priceLabelSize: CGFloat = 12
        static let detailsLabelSize: CGFloat = 12
    }
}
