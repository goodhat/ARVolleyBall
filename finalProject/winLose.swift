//
//  winOrLose.swift
//  finalProject
//
//  Created by Richard Chou on 2018/6/2.
//  Copyright © 2018年 Richard Chou. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit


extension  ViewController{
    func win(){
        myScore += 1
        myBall = true
        myTurn = false
        //tellOpponent(result: "win")
        newPlay()
        
    }
    
    func lose(){
        hisScore += 1
        myBall = false
        myTurn = true
        //tellOpponent(result: "lose")
        newPlay()
    }
}
