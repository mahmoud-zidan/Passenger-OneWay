//
//  Notification.swift
//  Passenger_OneWay
//
//  Created by Mahmoud Ismaeil Atito on 5/4/18.
//  Copyright © 2018 OneWay. All rights reserved.
//

import UIKit

class Notification: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("@@@ Notification @@@")
        NavigationBarItems()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }    
    private func NavigationBarItems(){
        // logo
        let Imagetitle = UIImageView(image: #imageLiteral(resourceName: "track.png"))
        Imagetitle.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        Imagetitle.contentMode = .scaleAspectFill
        navigationItem.titleView = Imagetitle
        
        let ProfileBtn = UIButton(type: .system)
        ProfileBtn.setImage(#imageLiteral(resourceName: "businessman.png").withRenderingMode(.alwaysOriginal), for: .normal)
        ProfileBtn.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView : ProfileBtn)
        
    }

}
