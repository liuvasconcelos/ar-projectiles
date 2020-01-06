//
//  ViewController.swift
//  Projectiles
//
//  Created by Livia Vasconcelos on 05/01/20.
//  Copyright © 2020 Livia Vasconcelos. All rights reserved.
//

import UIKit
import ARKit
import Each

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var planeDetectedLabel: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    var basketAdded: Bool = false
    var power: Float = 1
    let timer = Each(0.05).seconds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configuration.planeDetection = .horizontal
        sceneView.debugOptions = [SCNDebugOptions.showWorldOrigin, SCNDebugOptions.showFeaturePoints]
        sceneView.session.run(configuration)
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tap)
        tap.cancelsTouchesInView = false
    }

    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        let location = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        
        if let hitTest = hitTestResult.first {
            self.addBasket(hitTestResult: hitTest)
        }
    }
    
    func addBasket(hitTestResult: ARHitTestResult) {
        if !basketAdded {
            let basketScene = SCNScene(named: "Basketball.scnassets/Basketball.scn")
            let basketNode  = basketScene?.rootNode.childNode(withName: "Basket", recursively: false)
            let positionOfPlane = hitTestResult.worldTransform.columns.3
            
            let xPosition = positionOfPlane.x
            let yPosition = positionOfPlane.y
            let zPosition = positionOfPlane.z
            
            basketNode?.position = SCNVector3(xPosition, yPosition, zPosition)
            basketNode?.physicsBody = SCNPhysicsBody(type: .static,
                                                     shape: SCNPhysicsShape(node: basketNode ?? SCNNode(),
                                                                            options: [SCNPhysicsShape.Option.keepAsCompound: true,
                                                                                 SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
            if let basketNode = basketNode {
                self.sceneView.scene.rootNode.addChildNode(basketNode)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.basketAdded = true
                }
            }
        }
    
    }
    
    @IBAction func addButtonClicked(_ sender: Any) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.planeDetectedLabel.isHidden = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.planeDetectedLabel.isHidden = true
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded {
            timer.perform { () -> NextStep in
                self.power = self.power + 1.0
                return .continue
            }
        }
    }
    
    func shootBall() {
        guard let pointOfView = self.sceneView.pointOfView else { return }
        
        self.removeOtherBalls()
        let transform = pointOfView.transform
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let orientation = SCNVector3(-transform.m31, -transform.m32, -transform.m33)
        let position = location + orientation
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ball")
        ball.position = position
        ball.name = "Basketball"
        let body = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        body.restitution = 0.2  
        ball.physicsBody = body
        ball.physicsBody?.applyForce(SCNVector3(orientation.x * power,
                                                orientation.y * power,
                                                orientation.z * power),
                                     asImpulse: true)
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.basketAdded {
            self.timer.stop()
            self.shootBall()
        }
        self.power = 1
    }
    
    deinit {
        self.timer.stop()
    }
    
    func removeOtherBalls() {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name == "Basketball" {
                node.removeFromParentNode()
            }
        }
    }
    
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}
