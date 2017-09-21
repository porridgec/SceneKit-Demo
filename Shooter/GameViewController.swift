//
//  GameViewController.swift
//  Shooter
//
//  Created by Hahn.Chan on 20/09/2017.
//  Copyright © 2017 Hahn Chan. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        spawnShape()
        setupHUD()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        scnView = view as! SCNView
        scnView.delegate = self
        scnView.isPlaying = true
    }
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.png"
        scnView.showsStatistics = true
//        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
    }
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
    }
    
    func spawnShape() {
        var geometry: SCNGeometry
        switch ShapeType.random() {
        case .box:
            geometry = SCNBox(width: 1.0, height: 1.0, length: 1.0, chamferRadius: 0.0)
        case .sphere:
            geometry = SCNSphere(radius: 0.5)
        case .pyramid:
            geometry = SCNPyramid(width: 1.0, height: 1.0, length: 1.0)
        case .torus:
            geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.25)
        case .capsule:
            geometry = SCNCapsule(capRadius: 0.3, height: 2.5)
        case .cylinder:
            geometry = SCNCylinder(radius: 0.3, height: 2.5)
        case .cone:
            geometry = SCNCone(topRadius: 0.25, bottomRadius: 0.5, height: 1.0)
        case .tube:
            geometry = SCNTube(innerRadius: 0.25, outerRadius: 0.5, height: 1.0)
        }
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color
        let geometryNode = SCNNode.init(geometry: geometry)
        geometryNode.name = color == .black ? "BAD" : "GOOD"
        let trailEmitter = createTrail(color: color, geometry: geometry)
//        geometryNode.addParticleSystem(trailEmitter)
        geometryNode.physicsBody = SCNPhysicsBody.init(type: .dynamic, shape: nil)
        // 1
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        // 2
        let force = SCNVector3(x: randomX, y: randomY , z: 0)
        // 3
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        // 4
        geometryNode.physicsBody?.applyForce(force,
                                             at: position, asImpulse: true)
        scnScene.rootNode.addChildNode(geometryNode)
    }
    
    func cleanScene() {
        // 1
        for node in scnScene.rootNode.childNodes {
            // 2
            if node.presentation.position.y < -2 {
                // 3
                node.removeFromParentNode()
            }
        }
    }
    
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem.init(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    }
    
    func setupHUD() {
        game.hudNode.position = SCNVector3.init(x: 0, y: 10, z: 0)
        scnScene.rootNode.addChildNode(game.hudNode)
    }
    
    func handleTouch(for node: SCNNode) {
        if node.name == "GOOD" {
            game.score += 1
        } else if node.name == "BAD" {
            game.lives -= 1
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if time > spawnTime {
            spawnShape()
            
            // 2
            spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
        }
        cleanScene()
        game.updateHUD()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if let result = hitResults.first {
            handleTouch(for: result.node)
            createExplosion(geometry: result.node.geometry!,
                            position: result.node.presentation.position,
                            rotation: result.node.presentation.rotation)
            result.node.removeFromParentNode()
        }
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem.init(named: "Explode.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }

}


