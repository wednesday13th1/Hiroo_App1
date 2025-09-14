//
//  MenuViewController.swift
//  Hiroo App
//
//  Created by 井上　希稟 on 2025/09/03.
//

// MenuViewController.swift
//
//  MenuViewController.swift
//  Hiroo App
//
//  Created by XX on 2025/09/03.
//
import SideMenu
import UIKit

    final class SideMenuViewController: UITableViewController {
        private let items = [NSLocalizedString("back", comment: ""), NSLocalizedString("schoolmap", comment: ""), NSLocalizedString("web", comment: "")]
        
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
            
            // get the presenting navigation controller
            guard let presentingNav = presentingViewController as? UINavigationController else {
                dismiss(animated: true, completion: nil)
                return
            }
            
            switch selectedItem {
            case "back":
                dismiss(animated: true) {
                    let vc = SelectSchoolViewController()
                    presentingNav.pushViewController(vc, animated: true)
                }
                
            case "schoolmap":
                dismiss(animated: true) {
                    let vc = SchoolsViewController()
                    presentingNav.pushViewController(vc, animated: true)
                }
                
            case "web":
                dismiss(animated: true) {
                    let vc = WebsiteViewController()
                    presentingNav.pushViewController(vc, animated: true)
                }
                
            default:
                break
            }
        }
    }

