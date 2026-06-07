import UIKit

final class RootTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
}

private extension RootTabBarController {

    func setupTabs() {
        let tradingViewController = ViewController()
        let tradingNavigationController = UINavigationController(rootViewController: tradingViewController)
        tradingNavigationController.tabBarItem = UITabBarItem(
            title: "Торговля",
            image: UIImage(systemName: "chart.line.uptrend.xyaxis"),
            selectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis.circle.fill")
        )

        viewControllers = [tradingNavigationController]
    }

    func setupAppearance() {
        tabBar.tintColor = .systemGreen
        tabBar.unselectedItemTintColor = .lightGray
        tabBar.backgroundColor = UIColor(white: 0.08, alpha: 1)
    }
}
