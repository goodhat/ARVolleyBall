//
//  dealWithResponse.swift
//  finalProject
//
//  Created by Richard Chou on 2018/6/1.
//  Copyright © 2018年 Richard Chou. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit


/*
 userData:
     winOrlose: -1 -> win
                -2 -> lose
                0,1,2,3... -> pass the ball
     forceVector
     positionVector
*/

extension  ViewController{
    func tellOpponent(result: String){
        if (result == "win"){
            //firebase winOrLose = -1
            
        }else{
            //firebase winOrLose = -2
            
        }
    }
    
    func tellOpponent(force: SCNVector3, position: SCNVector3){
        //firebase winOrLose >= 0
        //firebase position = position
        //firebase force = force
    }
    
    func waitForResponse(){
        //observe winOrlose
        //if winOrLose == -1 then I lose
        //lose()
        
        //if winOrLose == -2 then I win
        //win()
        
        //if winOrlose >= 0 then the ball get back
        //force = firebase force
        //position = fire position
        //ball?.position = position
        //ball?.physicsBody?.applyForce(force, asImpulse:true)
        
    }
    
}
