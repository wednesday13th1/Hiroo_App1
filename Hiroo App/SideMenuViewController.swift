import UIKit

final class SideMenuViewController: UITableViewController {
    private let items = ["学校選択に戻る", "イベント一覧", "設定"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
    
    override func tableView(_ tv: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tv.deselectRow(at: indexPath, animated: true)
        
        let selectedItem = items[indexPath.row]
        
        switch selectedItem {
        case "Back to Home Screen":
            self.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                self?.routeToSelectSchool()
            })
        case "School Flooring":
            self.presentingViewController?.dismiss(animated: true, completion: {
                if let nav = UIApplication.shared.windows.first?.rootViewController as? UINavigationController {
                    let schoolVC = SchoolsViewController()
                    nav.pushViewController(schoolVC, animated: true)
                }
            })

        case "設定":
            print("設定 tapped")
            
        default:
            break
        }
    }
    private func routeToSelectSchool() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let selectVC = sb.instantiateViewController(withIdentifier: "SelectSchoolViewController") as? SelectSchoolViewController else {
            return
        }
        let nav = UINavigationController(rootViewController: selectVC)
        if let windowScene = view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
        } else {
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                window.rootViewController = nav
                window.makeKeyAndVisible()
            }
        }
    }
}
