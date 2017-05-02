//
//  extension.swift
//  High Rise
//
//  Created by 陈金伙 on 2017/4/20.
//  Copyright © 2017年 Ray Wenderlich. All rights reserved.
//

import SceneKit

extension ViewController : SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        for node in scnScene.rootNode.childNodes {
            if node.presentation.position.y <= -3 {
                node.removeFromParentNode()
            }
        }
    }
}
extension ViewController:SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        if ((contact.nodeA.physicsBody?.categoryBitMask == Int(PlayerBoxCategory)) && (contact.nodeB.physicsBody?.categoryBitMask == Int(BulletCategory)))
        {
            
            ViewController.gameOver = true
            if (ViewController.collionVioce)
            {
                playSound(sound: "collision", node: contact.nodeA)
            }
           ViewController.collionVioce = false
        }
    }
}
