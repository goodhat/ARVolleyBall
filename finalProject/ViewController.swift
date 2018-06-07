//
//  ViewController.swift
//  finalProject
//
//  Created by Richard Chou on 2018/5/30.
//  Copyright © 2018年 Richard Chou. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var restartButton: UIButton!
   
    @IBOutlet weak var player: UILabel!
    @IBOutlet weak var opponent: UILabel!
    var myScore: Int = 0{
        didSet{
            player.text = "me:\(myScore)"
        }
    }
    var hisScore: Int = 0{
        didSet{
            opponent.text = "opponent:\(hisScore)"
        }
    }
    var ball: SCNNode?
    var field: SCNNode?
    var net: SCNNode?
    var outField: SCNNode?
    
    
    var beginLocation: CGPoint?
    var myBall: Bool = true
    var myTurn: Bool = true

    
    enum CollisionMask: Int {
        case ball = 1
        case field = 2
        case net = 4
        case outField = 8
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.debugOptions = ARSCNDebugOptions.showWorldOrigin
        sceneView.scene.physicsWorld.contactDelegate = self
        
 
        establishField()
        prepareBall()
    }
    
    
    
    func establishField(){
        func physicsWall(width: CGFloat, height: CGFloat, position: SCNVector3, name: String) -> SCNNode {
            let node = SCNNode(geometry: SCNPlane(width: width, height: height))
            node.position = position
            node.physicsBody = SCNPhysicsBody.static()
            node.name = name
            return node
        }

        field = physicsWall(width: 2, height: 6, position: SCNVector3(0,-1,-3), name: "field")
        field?.eulerAngles.x = -.pi/2
        field?.physicsBody?.categoryBitMask = CollisionMask.field.rawValue
        field?.physicsBody?.collisionBitMask = CollisionMask.ball.rawValue
        field?.physicsBody?.contactTestBitMask = CollisionMask.ball.rawValue
        
        net = physicsWall(width: 2, height: 1.5, position: SCNVector3(0,-0.75,-3), name:"net")
        net?.geometry?.materials.first?.diffuse.contents = UIColor.blue
        net?.physicsBody?.categoryBitMask = CollisionMask.net.rawValue
        net?.physicsBody?.collisionBitMask = CollisionMask.ball.rawValue
        net?.physicsBody?.contactTestBitMask = CollisionMask.ball.rawValue
        
        outField = physicsWall(width: 10, height: 30, position: SCNVector3(0,-1.5,-3), name:"outField")
        outField?.eulerAngles.x = -.pi/2
        outField?.geometry?.materials.first?.diffuse.contents = UIColor.red
        outField?.physicsBody?.categoryBitMask = CollisionMask.outField.rawValue
        outField?.physicsBody?.collisionBitMask = CollisionMask.ball.rawValue
        outField?.physicsBody?.contactTestBitMask = CollisionMask.ball.rawValue
        
        sceneView.scene.rootNode.addChildNode(field!)
        sceneView.scene.rootNode.addChildNode(net!)
        sceneView.scene.rootNode.addChildNode(outField!)

    }
    
    func prepareBall(){
        let basketballScene = SCNScene(named: "art.scnassets/basketball.scn")!
        ball = basketballScene.rootNode.childNode(withName: "Ball", recursively: true)
        ball?.scale = SCNVector3(0.003, 0.003, 0.003)
        ball?.physicsBody?.type = .kinematic
        if(myBall){
            ball?.position = SCNVector3(x: 0, y: -0.03, z: -0.3)
        }else{
            ball?.position = SCNVector3(x: 0, y: -0.03, z: -1)  // should adjust z
        }
        sceneView.scene.rootNode.addChildNode(ball!)
    }
    
    func newPlay(){
        ball?.removeFromParentNode()
        prepareBall()
        if(!myBall){
            waitForResponse()
        }
    }
    
    @IBAction func restart(_ sender: UIButton) {
        newPlay()
    }
    

    @IBAction func hitBall(_ sender: UIPanGestureRecognizer) {
        let targetView = sender.view!

        if sender.state == .began {
            beginLocation = sender.location(in: targetView)
        }
        if sender.state == .ended {
            if (distance(between: (ball?.position)!, and: getCameraPosition()) < 0.1) {
                let endLocation = sender.location(in: targetView)
                let panX = Float(endLocation.x-beginLocation!.x)
                let panY = Float(endLocation.y-beginLocation!.y)
                let cameraOrientation = getCameraOrientation()
                let force:Float = Float(pow((beginLocation!.x-endLocation.x),2) + pow((beginLocation!.y-endLocation.y),2))/10000
               
                ball?.physicsBody =  SCNPhysicsBody.dynamic()
                ball?.physicsBody?.categoryBitMask = CollisionMask.ball.rawValue
                ball?.physicsBody?.collisionBitMask = 15
                ball?.physicsBody?.contactTestBitMask = CollisionMask.field.rawValue | CollisionMask.outField.rawValue
                
                let panLength = sqrt(pow(panX, 2)+pow(panY, 2))
                let x = -cameraOrientation.z*panX/panLength -  cameraOrientation.x*panY/panLength
                let z =  cameraOrientation.x*panX/panLength  - cameraOrientation.z*panY/panLength
                let forceVector: SCNVector3 = SCNVector3(x:x*force, y:(cameraOrientation.y+1) * force, z: z*force)
                let ballPosition = ball?.position
                ball?.physicsBody?.applyForce(forceVector, asImpulse:true)
                
                
                //myTurn = false
                
                tellOpponent(force: forceVector, position: ballPosition!)
                //waitForResponse()

            }
        }
        
    }
    
    func getCameraOrientation()->SCNVector3{
        let centerPoint = sceneView.pointOfView!
        let cameraTransform = centerPoint.transform
        let cameraOrientation = SCNVector3(x: -cameraTransform.m31, y: -cameraTransform.m32, z: -cameraTransform.m33)
        return cameraOrientation
    }
    
    func getCameraPosition()->SCNVector3{
        let centerPoint = sceneView.pointOfView!
        let cameraTransform = centerPoint.transform
        let cameraLocation = SCNVector3(x:cameraTransform.m41, y: cameraTransform.m42, z:cameraTransform.m43)
        return cameraLocation
    }
    
    func distance(between a: SCNVector3, and b: SCNVector3)->Float{
        return (pow((a.x-b.x),2) + pow((a.y-b.y),2) + pow((a.z-b.z),2))
    }
    
    
    //SCNPhysicsContactDelegate
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if(myTurn){
            
            if (contact.nodeA.name! == "field" || contact.nodeB.name! == "field"){
                if((ball?.position.z)! > Float(-3)){ //lose this point
                    print("In! You did not catch it. You lose.")
                    lose()

                }
                else{ // win
                    win()
                    print("The opponent did not hit the ball to your side. You win!")
                }
            }
            else if(contact.nodeA.name! == "outField" || contact.nodeB.name! == "outField"){
                win()
                print("Out! You win!")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    
    
}


extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}
