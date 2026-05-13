import SpriteKit
import UIKit

final class GameScene: SKScene {
    
    // MARK: - Nodes
    private let circle = SKShapeNode(circleOfRadius: 80)
    private let comboLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let timingLabel = SKLabelNode(fontNamed: "AvenirNext-Regular")
    private let startLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let headerNode = SKSpriteNode(imageNamed: "header")
    
    // MARK: - State Management
    private enum GameState {
        case waitingToStart
        case countdown
        case playing
        case gameOver
    }
    
    private var gameState: GameState = .countdown
    private var expectedTapTime: TimeInterval = 0
    private let targetInterval: TimeInterval = 1.0
    private var combo: Int = 0
    private var bestCombo: Int = UserDefaults.standard.integer(forKey: "BestCombo")
    
    // Pre-load haptics for zero latency
    private let impactMed = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    
    // MARK: - Game Flow

    private func beginCountdown() {
        gameState = .countdown
        circle.fillColor = .white
        circle.removeAllActions()
        timingLabel.fontColor = .white
        
        // Clear instructions immediately
        startLabel.text = ""
        startLabel.removeAllActions()
        comboLabel.text = "BEST \(bestCombo)"
        comboLabel.alpha = 1.0
        
        circle.isHidden = false
        circle.setScale(0.6)
        circle.alpha = 0.5
        
        let countValues = ["3", "2", "1"]
        var index = 0
        
        let countdownAction = SKAction.repeat(SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self, index < countValues.count else { return }
                self.timingLabel.text = countValues[index]
                
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 0.8, duration: 0.1),
                    SKAction.scale(to: 0.6, duration: 0.1)
                ])
                self.circle.run(pulse)
                self.impactMed.impactOccurred()
                index += 1
            },
            SKAction.wait(forDuration: targetInterval)
        ]), count: 3)
        
        run(SKAction.sequence([
            countdownAction,
            SKAction.run { [weak self] in self?.startGameplay() }
        ]))
    }

    private func handleTap() {
        let now = CACurrentMediaTime()
        let diff = now - expectedTapTime // Positive = Late, Negative = Early
        let absDiff = abs(diff)
        
        // Create the precision string (e.g., "+0.002" or "-0.015")
        let sign = diff >= 0 ? "+" : "-"
        let precisionText = String(format: "\(sign)%.3f", absDiff)
        
        if absDiff < 0.20 {
            processHit(diff: absDiff, precisionText: precisionText)
            expectedTapTime += targetInterval
        } else {
            endGame(with: precisionText)
        }
    }

    private func processHit(diff: Double, precisionText: String) {
        combo += 1
        comboLabel.text = "\(combo)"
        if comboLabel.alpha == 0 { comboLabel.run(SKAction.fadeIn(withDuration: 0.2)) }
        
        let (status, color, scale, feedback) = getFeedback(for: diff)
        
        // Show "PERFECT (+0.001)"
        timingLabel.text = "\(status) (\(precisionText))"
        timingLabel.fontColor = color
        
        circle.fillColor = color
        impactMed.impactOccurred(intensity: feedback)
        animateCircle(to: scale)
        
        circle.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.1),
            SKAction.run { [weak self] in self?.circle.fillColor = .white }
        ]))
    }

    private func endGame(with precisionText: String) {
        circle.removeAllActions()
        gameState = .gameOver
        
        // Determine miss direction
        let tooDirection = precisionText.hasPrefix("-") ? "TOO EARLY" : "TOO LATE"

        circle.fillColor = .systemRed
        
        impactHeavy.impactOccurred()

        let currentScore = combo
        comboLabel.text = "SCORE \(currentScore)"
        comboLabel.fontSize = 40
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.69)
        
        startLabel.fontSize = 18
        startLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.10)
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ]))
        startLabel.run(pulse)
        
        if currentScore > bestCombo {
            bestCombo = currentScore
            UserDefaults.standard.set(bestCombo, forKey: "BestCombo")
            
            timingLabel.text = "🏆 NEW HIGH SCORE! 🏆"
            timingLabel.fontColor = .white
            
        } else {
            
            timingLabel.text = "\(tooDirection) (\(precisionText))"
            timingLabel.fontColor = .systemRed
        }

        startLabel.text = "TAP TO RESTART"
    }

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupNodes()
        showWaitingScreen()
    }
    
    private func showWaitingScreen() {
        gameState = .waitingToStart
        
        circle.isHidden = false
        circle.setScale(1.0)
        circle.fillColor = .white
        circle.removeAllActions()
        circle.alpha = 0.8
        
        timingLabel.text = "Tap every second"
        timingLabel.fontColor = .white
        
        startLabel.text = "BEGIN"
        comboLabel.text = "BEST \(bestCombo)"
        comboLabel.alpha = 1.0
        comboLabel.fontSize = 34
        
        startLabel.removeAllActions()
        
        // Make the start text pulse so they know it's interactive
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ]))
        startLabel.run(pulse)
    }
    
    private func setupNodes() {
        let midX = size.width / 2
        let midY = size.height / 2
        
        // Circle setup
        circle.fillColor = .white
        circle.strokeColor = .clear
        circle.position = CGPoint(x: midX, y: midY)
        circle.isHidden = true
        addChild(circle)
        
        // Combo Label
        comboLabel.fontSize = 34
        comboLabel.position = CGPoint(x: midX, y: size.height * 0.69)
        comboLabel.text = "0"
        addChild(comboLabel)
        
        // Timing Feedback Label
        timingLabel.fontSize = 28
        timingLabel.position = CGPoint(x: midX, y: size.height * 0.24)
        timingLabel.text = "GET READY"
        addChild(timingLabel)
        
        // Instructions Label
        startLabel.fontSize = 18
        startLabel.position = CGPoint(x: midX, y: size.height * 0.10)
        startLabel.text = "TAP EVERY SECOND"
        startLabel.preferredMaxLayoutWidth = size.width * 0.8
        startLabel.numberOfLines = 2
        startLabel.verticalAlignmentMode = .center
        addChild(startLabel)
        
        // Header Image
        headerNode.position = CGPoint(x: midX, y: size.height * 0.91)
        headerNode.setScale(0.36)
        headerNode.alpha = 0.95
        addChild(headerNode)
    }

    private func startGameplay() {
        gameState = .playing
        combo = 0
        comboLabel.text = "0"
        comboLabel.alpha = 1.0
        comboLabel.fontSize = 54
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.76)
        
        timingLabel.text = "GO!"
        circle.run(SKAction.scale(to: 1.0, duration: 0.2))
        circle.alpha = 1.0
        
        expectedTapTime = CACurrentMediaTime() + targetInterval
    }

    // MARK: - Input Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        impactMed.prepare()
        impactHeavy.prepare()
        switch gameState {
        case .waitingToStart:
            beginCountdown()
        case .playing:
            handleTap()
        case .gameOver:
            beginCountdown()
        case .countdown:
            break // Ignore taps during countdown
        }
    }
    
    private func getFeedback(for diff: Double) -> (String, UIColor, CGFloat, CGFloat) {
        if diff < 0.05 { return ("PERFECT", .cyan, 1.2, 1.0) }
        if diff < 0.12 { return ("GREAT", .green, 1.1, 0.7) }
        return ("GOOD", .orange, 1.05, 0.4)
    }

    private func animateCircle(to scale: CGFloat) {
        let grow = SKAction.scale(to: scale, duration: 0.05)
        let shrink = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([grow, shrink])
        
        circle.removeAction(forKey: "pulse")
        circle.run(sequence, withKey: "pulse")
    }
}
