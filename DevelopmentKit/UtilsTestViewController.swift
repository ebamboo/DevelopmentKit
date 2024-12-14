//
//  UtilsTestViewController.swift
//  Jasmine
//
//  Created by ebamboo on 2021/11/26.
//

import UIKit

class UtilsTestViewController: UIViewController {
    
    let titles = [
        "Keychain", "ModelAnimator", "已删除，等待优化",
        "自定义虚线视图DashView", "自定义UIView每个圆角大小RoundView", "自定义UICollectionViewFlowLayout",
        "UIImage+Transform 测试", "自定义 Stepper", "自定义评分控件",
        "标签样式CollectionViewTagLayout", "ScrollView简单嵌套"
    ]
    
    lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.dataSource = self
        view.delegate = self
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Jasmine"
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
}

extension UtilsTestViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
        cell?.textLabel?.text = titles[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row == 0 {
            navigationController?.pushViewController(KeychainViewController(), animated: true)
            return
        }
        if indexPath.row == 1 {
            navigationController?.pushViewController(PresentingViewController(), animated: true)
            return
        }
        if indexPath.row == 2 {
            
            return
        }
        if indexPath.row == 3 {
            navigationController?.pushViewController(DashTestViewController(), animated: true)
            return
        }
        if indexPath.row == 4 {
            navigationController?.pushViewController(RoundViewTestViewController(), animated: true)
            return
        }
        if indexPath.row == 5 {
            navigationController?.pushViewController(FlowLayoutTestViewController(), animated: true)
            return
        }
        if indexPath.row == 6 {
            navigationController?.pushViewController(UIImageTransformTestViewController(), animated: true)
            return
        }
        if indexPath.row == 7 {
            navigationController?.pushViewController(StepperTestViewController(), animated: true)
            return
        }
        if indexPath.row == 8 {
            navigationController?.pushViewController(GradeTestViewController(), animated: true)
            return
        }
        if indexPath.row == 9 {
            navigationController?.pushViewController(TagLayoutTestViewController(), animated: true)
            return
        }
        if indexPath.row == 10 {
            navigationController?.pushViewController(NestedScrollViewTestViewController(), animated: true)
            return
        }
    }
    
}
