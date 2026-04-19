import UIKit

final class SplashScreenViewController: UIViewController {

    // MARK: - UI Elements

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "chart.line.uptrend.xyaxis.circle.fill")
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "TradeBot"
        label.font = .boldSystemFont(ofSize: 32)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "AI-powered trading simulator"
        label.font = .systemFont(ofSize: 15, weight: .light)
        label.textColor = UIColor.white.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let loadingLabel: UILabel = {
        let label = UILabel()
        label.text = "Загрузка данных..."
        label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor.systemGreen.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let progressBar: UIProgressView = {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.progressTintColor = .systemGreen
        pv.trackTintColor = UIColor(white: 0.2, alpha: 1)
        pv.layer.cornerRadius = 2
        pv.clipsToBounds = true
        pv.progress = 0
        pv.alpha = 0
        pv.translatesAutoresizingMaskIntoConstraints = false
        return pv
    }()

    // MARK: - Lifecycle

    var onFinished: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(iconImageView)
        view.addSubview(appNameLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(loadingLabel)
        view.addSubview(progressBar)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            iconImageView.widthAnchor.constraint(equalToConstant: 100),
            iconImageView.heightAnchor.constraint(equalToConstant: 100),

            appNameLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 20),
            appNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            loadingLabel.bottomAnchor.constraint(equalTo: progressBar.topAnchor, constant: -10),
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            progressBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 48),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -48),
            progressBar.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    // MARK: - Animation

    private func startAnimation() {
        // Phase 1: Icon rotates and pulses (mimicking LaunchScreen → animation start)
        startRotationAnimation()
        startPulseAnimation()

        // Fade in loading elements
        UIView.animate(withDuration: 0.5, delay: 0.3) {
            self.loadingLabel.alpha = 1
            self.progressBar.alpha = 1
        }

        // Phase 2: Progress bar fills over ~4 seconds
        animateProgress()

        // Phase 3: Transition to main app after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.transitionToMainApp()
        }
    }

    private func startRotationAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = 0
        rotation.toValue = CGFloat.pi * 2
        rotation.duration = 2.0
        rotation.repeatCount = .infinity
        rotation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        iconImageView.layer.add(rotation, forKey: "rotation")
    }

    private func startPulseAnimation() {
        // Alpha pulse
        UIView.animate(
            withDuration: 0.8,
            delay: 0,
            options: [.repeat, .autoreverse, .allowUserInteraction],
            animations: {
                self.iconImageView.alpha = 0.4
            }
        )

        // Scale pulse (slight)
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 1.12
        scale.duration = 0.8
        scale.autoreverses = true
        scale.repeatCount = .infinity
        scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        iconImageView.layer.add(scale, forKey: "scale")
    }

    private func animateProgress() {
        // Simulate loading steps
        let steps: [(Float, TimeInterval, String)] = [
            (0.2, 0.8, "Загрузка котировок..."),
            (0.5, 1.8, "Подключение к бирже..."),
            (0.75, 2.8, "Инициализация бота..."),
            (1.0, 4.0, "Готово!")
        ]

        for (progress, delay, text) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                UIView.animate(withDuration: 0.4) {
                    self.progressBar.setProgress(progress, animated: true)
                }
                self.loadingLabel.text = text
            }
        }
    }

    private func transitionToMainApp() {
        // Stop animations
        iconImageView.layer.removeAllAnimations()
        iconImageView.layer.removeAnimation(forKey: "rotation")
        iconImageView.layer.removeAnimation(forKey: "scale")

        // Fade out and complete
        UIView.animate(withDuration: 0.5, animations: {
            self.view.alpha = 0
        }, completion: { _ in
            self.onFinished?()
        })
    }
}
