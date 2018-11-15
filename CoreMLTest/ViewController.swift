//
//  ViewController.swift
//  CoreMLTest
//
//  Created by Max on 2018/11/12.
//  Copyright © 2018 Ever. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let tableView = UITableView()
    
    let titles = ["Vision","NaturalLanguage","CustomImageDetector"];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Core ML"
        
        tableView.frame = view.bounds;
        tableView.delegate = self;
        tableView.dataSource = self;
        
        view.addSubview(tableView);
    }
}


extension ViewController : UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return self.titles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "test")
        
        cell.textLabel?.text = titles[indexPath.row];
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
     
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            navigationController?.pushViewController(VisionViewController(), animated: true);
        case 1:
            navigationController?.pushViewController(NLViewController(), animated: true);
        case 2:
            navigationController?.pushViewController(ImageDetectorViewController(), animated: true);
        default: break
        }
    }
}


