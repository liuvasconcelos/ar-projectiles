//
//  ViewController.swift
//  Projectiles
//
//  Created by Livia Vasconcelos on 05/01/20.
//  Copyright © 2020 Livia Vasconcelos. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var planeDetectedLabel: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configuration.planeDetection = .horizontal
        sceneView.debugOptions = [SCNDebugOptions.showWorldOrigin, SCNDebugOptions.showFeaturePoints]
        sceneView.session.run(configuration)
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tap)
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
        let basketScene = SCNScene(named: "Basketball.scnassets/Basketball.scn")
        let basketNode  = basketScene?.rootNode.childNode(withName: "Basket", recursively: false)
        let positionOfPlane = hitTestResult.worldTransform.columns.3
        
        let xPosition = positionOfPlane.x
        let yPosition = positionOfPlane.y
        let zPosition = positionOfPlane.z
        
        basketNode?.position = SCNVector3(xPosition, yPosition, zPosition)
        
        if let basketNode = basketNode {
            self.sceneView.scene.rootNode.addChildNode(basketNode)
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
    
}

