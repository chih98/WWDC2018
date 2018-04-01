import PlaygroundSupport
import SpriteKit
import Accelerate
import Metal
import Cocoa

public class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var ball = SKSpriteNode()
    var cpuPaddle = SKSpriteNode()
    var playerPaddle = SKSpriteNode()
    var playerGoal = SKSpriteNode()
    var cpuGoal = SKSpriteNode()
    
    // Labels
    var cpuScoreL = SKLabelNode()
    var playerScoreL = SKLabelNode()
    var stopL = SKLabelNode()
    var resetScoreL = SKLabelNode()
    var mainMenuL = SKLabelNode()
    
    // Camera
    var mainCamera = SKCameraNode()
    
    var playerScore = 0
    var cpuScore = 0
    
    // Sometimes the ball likes stick to a side. These ints count up to 2. If an int equals 2, the program will apply a 45º SE, or NE force to knock the ball out of the wall.
    var xCount: Int = 0
    var yCount: Int = 0
    
    var prevX: CGFloat = 0.0
    var prevY: CGFloat = 0.0

    
    var isPlaying = false
    var ballVector: Int = 20 // How hard to nudge the ball at the beginning. Determines ball speed
    
    var timer: Timer?
    
    // - MAIN MENU -
    var slowB = SKSpriteNode()
    var mediumB = SKSpriteNode()
    var fastB = SKSpriteNode()
    
    var lowB = SKSpriteNode()
    var sensitiveB = SKSpriteNode()
    var highB = SKSpriteNode()
    
    var startB = SKSpriteNode()
    
    // - TEXTURES -
    // Ball Speed
    let slowNormal = SKTexture(imageNamed: "Buttons/Ball-Speed/Slow-Normal.png")
    let slowHighlighted = SKTexture(imageNamed: "Buttons/Ball-Speed/Slow-Highlighted.png")
    
    let mediumNormal = SKTexture(imageNamed: "Buttons/Ball-Speed/Medium-Normal.png")
    let mediumHighlighted = SKTexture(imageNamed: "Buttons/Ball-Speed/Medium-Highlighted.png")
    
    let fastNormal = SKTexture(imageNamed: "Buttons/Ball-Speed/Fast-Normal.png")
    let fastHighlighted = SKTexture(imageNamed: "Buttons/Ball-Speed/Fast-Highlighted.png")
    
    // Mic Sensitivity
    let lowNormal = SKTexture(imageNamed: "Buttons/Mic-Sensitivity/Low-Normal.png")
    let lowHighlighted = SKTexture(imageNamed: "Buttons/Mic-Sensitivity/Low-Highlighted.png")
    
    let sensitiveNormal = SKTexture(imageNamed: "Buttons/Mic-Sensitivity/Medium-Normal.png")
    let sensitiveHighlighted = SKTexture(imageNamed: "Buttons/Mic-Sensitivity/Medium-Highlighted.png")
    
    let highNormal = SKTexture(imageNamed: "Buttons/Mic-Sensitivity/Sensitive-Normal.png")
    let highHighlighted = SKTexture(imageNamed: "Buttons/Mic-Sensitivity/Sensitive-Highlighted.png")
    
    // - MISC -
    // Ball Speed
    enum Speed {
        
        case slow
        case medium
        case fast
        
    }
    
    var ballSpeed: Speed = .slow
    
    // Mic Sensitivity - Must be public because microophone is handled by Playground main file.
    public enum Sensitivity: CGFloat {
        
        case low = 300
        case medium = 1000
        case high = 2000
        
    }
    
    public var micSensitivity: Sensitivity = .medium
    
     override public func didMove(to view: SKView) {
        
        setup()
        
    }
    
    override public func mouseDown(with event: NSEvent) {
        
        let loc = event.location(in: self)

            
        if self.nodes(at: loc).contains(self.stopL) {
            
            if self.stopL.text == "Stop" {
                
                self.stopL.text = "Begin"
                
                self.stopGame()
                
            } else {
                
                self.stopL.text = "Stop"
                self.startGame()
                
            }
            
        } else if self.nodes(at: loc).contains(self.resetScoreL) && self.resetScoreL.alpha == 1 {
            
            self.playerScore = 0
            self.cpuScore = 0
            
            self.playerScoreL.text = "\(self.playerScore)"
            self.cpuScoreL.text = "\(self.cpuScore)"
            
        } else if self.nodes(at: loc).contains(self.startB) {
            
            self.mainCamera.run(.moveTo(x: 0, duration: 0.5))
            
            Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { (_) in
            
                self.startGame()
            
            }
            
            
        } else if self.nodes(at: loc).contains(self.mainMenuL) && self.isPlaying == false {
            
            self.mainCamera.run(.moveTo(x: -1050, duration: 0.5))
            
        } else if self.nodes(at: loc).contains(self.slowB) {
            
            self.slowB.texture = self.slowHighlighted
            self.mediumB.texture = self.mediumNormal
            self.fastB.texture = self.fastNormal
            self.ballSpeed = .slow
            
        } else if self.nodes(at: loc).contains(self.mediumB) {
        
            self.slowB.texture = self.slowNormal
            self.mediumB.texture = self.mediumHighlighted
            self.fastB.texture = self.fastNormal
            self.ballSpeed = .medium
            
        } else if self.nodes(at: loc).contains(self.fastB) {
            
            self.slowB.texture = self.slowNormal
            self.mediumB.texture = self.mediumNormal
            self.fastB.texture = self.fastHighlighted
            self.ballSpeed = .fast
            
        } else if self.nodes(at: loc).contains(self.lowB) {
            
            self.lowB.texture = self.lowHighlighted
            self.sensitiveB.texture = self.sensitiveNormal
            self.highB.texture = self.highNormal
            self.micSensitivity = .low
            
        } else if self.nodes(at: loc).contains(self.sensitiveB) {
            
            self.lowB.texture = self.lowNormal
            self.sensitiveB.texture = self.sensitiveHighlighted
            self.highB.texture = self.highNormal
            self.micSensitivity = .medium
            
        } else if self.nodes(at: loc).contains(self.highB) {
            
            self.lowB.texture = self.lowNormal
            self.sensitiveB.texture = self.sensitiveNormal
            self.highB.texture = self.highHighlighted
            self.micSensitivity = .high
            
        }
        
    }
    
    
    override public func update(_ currentTime: TimeInterval) {
        
        // Making CPU Work
        
        // Working with game difficulty. The higher the player's score, the faster the CPU moves!
        
        if (!intersects(self.ball)) {
            
            // Ball is out of screen
            self.stopGame()
            
        }
        
        var pos = self.ball.position.y
        
        if pos > 319.0 {
            
            pos = 319.0
            
        } else if pos < -319.0 {
            
            pos = -319.0
            
        }
        
        var computerSpeed: TimeInterval = 1.0
        
        
        if self.playerScore < 5 {
            
            switch self.ballSpeed {
                
                case .slow:
                    computerSpeed = 1.0
                case .medium:
                    computerSpeed = 0.8
                default:
                    computerSpeed = 0.5
                
            }
            
        } else if self.playerScore < 10 {
            
            switch self.ballSpeed {
                
            case .slow:
                computerSpeed = 0.8
            case .medium:
                computerSpeed = 0.6
            default:
                computerSpeed = 0.4
                
            }
        } else if self.playerScore < 15 {
            
            // This is intentional. It gives the player false hope ;)
            switch self.ballSpeed {
                
            case .slow:
                computerSpeed = 1.0
            case .medium:
                computerSpeed = 0.8
            default:
                computerSpeed = 0.5
                
            }
        } else if self.playerScore < 20 {
            
            switch self.ballSpeed {
                
            case .slow:
                computerSpeed = 0.5
            case .medium:
                computerSpeed = 0.4
            default:
                computerSpeed = 0.25
                
            }
        } else if self.playerScore < 15 {
            
            switch self.ballSpeed {
                
            case .slow:
                computerSpeed = 0.3
            case .medium:
                computerSpeed = 0.2
            default:
                computerSpeed = 0.2
                
            }
            
        } else if self.playerScore < 20 {
            
            // Some more false hope...
            switch self.ballSpeed {
                
            case .slow:
                computerSpeed = 1.0
            case .medium:
                computerSpeed = 0.8
            default:
                computerSpeed = 0.5
                
            }
            
        } else {
            
            // No more Mr. Nice Guy!
            switch self.ballSpeed {
                
            case .slow:
                computerSpeed = 0.3
            case .medium:
                computerSpeed = 0.2
            default:
                computerSpeed = 0.2
                
            }
        }
        
        self.cpuPaddle.run(.moveTo(y: self.ball.position.y, duration: computerSpeed))
        
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        
        if contact.bodyA == self.ball.physicsBody && contact.bodyB == self.playerGoal.physicsBody || contact.bodyA == self.playerGoal.physicsBody && contact.bodyB == self.ball.physicsBody {
            
            self.cpuScore += 1
            self.cpuScoreL.text = "\(cpuScore)"
            
            self.flashScore()
            
        } else if contact.bodyA == self.ball.physicsBody && contact.bodyB == self.cpuGoal.physicsBody || contact.bodyA == self.cpuGoal.physicsBody && contact.bodyB == self.ball.physicsBody {
            
            self.playerScore += 1
            self.playerScoreL.text = "\(playerScore)"
            
            self.flashScore()
            
        }
        
    }
    
    // Moves Paddle to Point
    
    /// Between -319 and +319
    public func movePaddle(to loc: CGFloat) {
        
        guard self.isPlaying == true else {
            
            self.playerPaddle.run(.moveTo(y: 0.0, duration: 0.3))
            
            return
            
        }
        
        if loc < -319.0 {
            
            self.playerPaddle.run(.moveTo(y: -319.0, duration: 0.1))
            
        } else if loc > 319.0 {
            
            self.playerPaddle.run(.moveTo(y: 319.0, duration: 0.1))
            
        } else {
            
            self.playerPaddle.run(.moveTo(y: loc, duration: 0.2))
            
        }
        
    }

    
    func flashScore() {
        
        let scoreSequence = SKAction.sequence([.fadeIn(withDuration: 0.3), .wait(forDuration: 0.3), .fadeOut(withDuration: 0.3)])
        
        
        self.playerScoreL.run(scoreSequence)
        self.cpuScoreL.run(scoreSequence)
        
    }
    
    /// Add ball's point to update and check arrays
    func addLoc(loc: CGPoint) {
        
        // If this isn't here, then the game automatically starts after a few seconds. It's before the DispatchQueue, because calling the background thread for nothing is just plain stupid.
        guard loc != CGPoint(x: 0.0, y: 0.0) && self.isPlaying == true else { return }
        
        if self.xCount >= 2 {
            
            self.xCount = 0
            self.ball.physicsBody?.velocity = .zero
            
            if loc.x > self.prevX {
                
                self.ball.physicsBody?.applyImpulse(CGVector(dx: self.ballVector, dy: self.ballVector))
                
            } else {
                
                self.ball.physicsBody?.applyImpulse(CGVector(dx: -self.ballVector, dy: self.ballVector))

            }
            
            
        }
        
        if self.yCount >= 2 {
            
            self.yCount = 0
            self.ball.physicsBody?.velocity = .zero

            if loc.y > self.prevY {
                
                self.ball.physicsBody?.applyImpulse(CGVector(dx: self.ballVector, dy: -self.ballVector))
                
            } else {
                
                self.ball.physicsBody?.applyImpulse(CGVector(dx: self.ballVector, dy: self.ballVector))

                
            }
            
        }
        
        if loc.x == self.prevX {
            
            self.xCount += 1
            
        }
        
        if loc.y == self.prevY {
            
            self.yCount += 1
            
        }
        
        self.prevX = loc.x
        self.prevY = loc.y
        
    }
    
    func startGame() {
        
        // Chekcing that the game isn't already playing
        guard self.isPlaying == false else {return}
        
        self.isPlaying = true
        
        // UI Stuff
        self.stopL.text = "Stop"
        self.resetScoreL.run(.fadeOut(withDuration: 0.3))
        self.mainMenuL.run(.fadeOut(withDuration: 0.3))
        self.playerScoreL.run(SKAction.fadeOut(withDuration: 0.5))
        self.cpuScoreL.run(SKAction.fadeOut(withDuration: 0.5))
        
        // Getting the ball speed, and applying appropriate vector.
        
        
        switch self.ballSpeed {
            
            case .slow:
                    self.ballVector = 20
            
            case .medium:
                self.ballVector = 40
            
            default:
                self.ballVector = 60
            
            
        }
        
        let i = arc4random_uniform(3)
        switch i {
            
        case 0 :
            self.ball.physicsBody?.applyImpulse(CGVector(dx: -self.ballVector, dy: -self.ballVector))
            
        case 1:
            self.ball.physicsBody?.applyImpulse(CGVector(dx: self.ballVector, dy: -self.ballVector))
            
        case 2:
            self.ball.physicsBody?.applyImpulse(CGVector(dx: -self.ballVector, dy: self.ballVector))
            
        default:
            self.ball.physicsBody?.applyImpulse(CGVector(dx: self.ballVector, dy: self.ballVector))
            
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true, block: { (t) in
            
            self.timer = t
            self.addLoc(loc: self.ball.position)
        
        })
        
    }
    
    func stopGame() {
        
        self.isPlaying = false
        
        self.timer?.invalidate()
        
        self.stopL.text = "Begin"
        
        self.ball.physicsBody?.velocity = .zero
        self.resetScoreL.run(.fadeIn(withDuration: 0.5))
        self.mainMenuL.run(.fadeIn(withDuration: 0.5))
        
        self.playerScoreL.run(SKAction.fadeIn(withDuration: 0.5))
        self.cpuScoreL.run(SKAction.fadeIn(withDuration: 0.5))
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (_) in
            
            self.ball.run(SKAction.move(to: CGPoint(x: 0, y: 0), duration: 0.3))
            
        }
        
    }
    
    func setup() {
        
        let customFontURL = Bundle.main.url(forResource: "Phosphate", withExtension: "ttc")! as CFURL
        
        CTFontManagerRegisterFontsForURL(customFontURL, .process, nil)
        
        
        self.ball = self.childNode(withName: "Ball") as! SKSpriteNode
        self.cpuPaddle = self.childNode(withName: "CPUPaddle") as! SKSpriteNode
        
        self.playerPaddle = self.childNode(withName: "PlayerPaddle") as! SKSpriteNode
        
        self.cpuScoreL = self.childNode(withName: "CPUScore") as! SKLabelNode
        self.playerScoreL = self.childNode(withName: "PlayerScore") as! SKLabelNode
        self.stopL = self.childNode(withName: "StopL") as! SKLabelNode
        self.stopL.isUserInteractionEnabled = true
        self.mainMenuL = self.childNode(withName: "MainMenuL") as! SKLabelNode
        
        self.playerGoal = self.childNode(withName: "PlayerGoal") as! SKSpriteNode
        self.cpuGoal = self.childNode(withName: "CPUGoal") as! SKSpriteNode
        
        self.resetScoreL = self.childNode(withName: "ResetScore") as! SKLabelNode
        
        // Camera
        self.mainCamera = self.childNode(withName: "MainCamera") as! SKCameraNode
        
        // - MAIN MENU -
        self.slowB = self.childNode(withName: "SlowButton") as! SKSpriteNode
        self.slowB.texture = self.slowHighlighted
        
        self.mediumB = self.childNode(withName: "MediumButton") as! SKSpriteNode
        self.mediumB.texture = self.mediumNormal
        
        self.fastB = self.childNode(withName: "FastButton") as! SKSpriteNode
        self.fastB.texture = self.fastNormal
        
        self.startB = self.childNode(withName: "StartButton") as! SKSpriteNode
        
        self.lowB = self.childNode(withName: "LowButton") as! SKSpriteNode
        self.lowB.texture = self.lowNormal
        
        self.sensitiveB = self.childNode(withName: "SensitiveButton") as! SKSpriteNode
        self.sensitiveB.texture = self.sensitiveHighlighted
        
        self.highB = self.childNode(withName: "HighButton") as! SKSpriteNode
        self.highB.texture = self.highNormal
        
        self.camera = self.mainCamera
        
        self.camera?.position = CGPoint(x: -1050, y: 0)
        
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 1
        
        self.physicsBody = border
        
        // Collision tracking time!
        self.physicsWorld.contactDelegate = self
        
    }
    
}
