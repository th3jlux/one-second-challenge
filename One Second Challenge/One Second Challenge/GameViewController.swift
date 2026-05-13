//
//  GameViewController.swift
//  One Second
//
//  Created by Thej Kumar Siddhotam Arulraj on 13.05.26.
//
import UIKit
import SpriteKit

final class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let view = self.view as? SKView else {
            return
        }

        let scene = GameScene(size: view.bounds.size)

        scene.scaleMode = .resizeFill

        view.presentScene(scene)

        view.ignoresSiblingOrder = true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
