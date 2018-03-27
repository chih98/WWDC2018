//: # VoicePong
//: ### - Marko Crnkovic
//: Welcome to VoicePong, a twist on a classic game! To play VoicePong, you must use your voice to move your paddle, VS the CPU's paddle. Good luck!
import PlaygroundSupport
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
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
    
    var playerScore = 0
    var cpuScore = 0
    
    // Sometimes the ball likes stick to a side. These ints cound up to 25. If an int equals 25, the program will apply a 45º SE, or NE force to knock the ball out of the wall. Array's flush afte 100 to not consume too much memory, so the app still runs smoothly after a while. This also prevents the ball from going horizontally, or vertically, anywhere, not just the wall. The wall was just such a prominent problem. Arrays were initially used, but were too taxing, and it was realized that they were actually not needed.
    var xCount: Int = 0
    var yCount: Int = 0
    
    var prevX: CGFloat = 0.0
    var prevY: CGFloat = 0.0
    
    // Creating background thread timer to check for ball. Clears up main thread for performance.
    var timer: DispatchSourceTimer!
    
    var isPlaying = false
    
    override func didMove(to view: SKView) {
        
        setup()
        
        startGame()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // What's a good Playground without a little error catching?
        if let loc = touches.first?.location(in: self) {
            
            if self.nodes(at: loc).contains(self.stopL) {
                
                if self.stopL.text == "Stop" {
                
                    self.stopL.text = "Begin"
                
                    self.stopGame()
                    
                } else {
                    
                    self.stopL.text = "Stop"
                    self.startGame()
                    
                }
                
                return
                
            } else if self.nodes(at: loc).contains(self.resetScoreL) && self.resetScoreL.alpha == 1 {
                
                self.playerScore = 0
                self.cpuScore = 0
                
                self.playerScoreL.text = "\(self.playerScore)"
                self.cpuScoreL.text = "\(self.cpuScore)"
                
                return
            }
            
            if loc.y < -319.0 {
                
                self.playerPaddle.run(.moveTo(y: -319.0, duration: 0.3))
                
            } else if loc.y > 319.0 {
                
                self.playerPaddle.run(.moveTo(y: 319.0, duration: 0.3))
                
            } else {
            
                self.playerPaddle.run(.moveTo(y: loc.y, duration: 0.3))
            
            }
            
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
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
        
        
        if self.playerScore < 5 {
            
            self.cpuPaddle.run(SKAction.moveTo(y: self.ball.position.y, duration: 1.0))
        
        } else if self.playerScore < 10 {
            
            self.cpuPaddle.run(SKAction.moveTo(y: self.ball.position.y, duration: 0.8))
            
        } else if self.playerScore < 15 {
            
            // This is intentional. It gives the player false hope ;)
            self.cpuPaddle.run(SKAction.moveTo(y: self.ball.position.y, duration: 1))
            
        } else if self.playerScore < 20 {
            
            self.cpuPaddle.run(SKAction.moveTo(y: self.ball.position.y, duration: 0.5))
            
        } else if self.playerScore < 15 {
            
            self.cpuPaddle.run(SKAction.moveTo(y: self.ball.position.y, duration: 0.3))
            
        } else if self.playerScore < 20 {
            
            // Some more false hope...
            self.cpuPaddle.run(SKAction.moveTo(y: self.ball.position.y, duration: 0.8))
            
        } else {
            
            // No more Mr. Nice Guy!
            self.cpuPaddle.run(SKAction.moveTo(y: self.ball.position.y, duration: 0.3))
            
        }
    
        
        // Sometimes the ball sticks to the top or bottom, this is fixing that. TODO: FixThis
        
    }
    
    
    // Starts the game by moving the ball, randomly in a 45º angle in a randomly chosen direction (NE, SE, NW, SW)
    func startGame() {
        
        self.isPlaying = true
        
        
        
        self.stopL.text = "Stop"
        self.resetScoreL.run(.fadeOut(withDuration: 0.3))
        self.playerScoreL.run(SKAction.fadeOut(withDuration: 0.5))
        self.cpuScoreL.run(SKAction.fadeOut(withDuration: 0.5))
    
        let i = arc4random_uniform(3)
        switch i {
            
            case 0 :
                self.ball.physicsBody?.applyImpulse(CGVector(dx: -20, dy: -20))
        
            case 1:
                self.ball.physicsBody?.applyImpulse(CGVector(dx: 20, dy: -20))
            
            case 2:
                self.ball.physicsBody?.applyImpulse(CGVector(dx: -20, dy: 20))

            default:
                self.ball.physicsBody?.applyImpulse(CGVector(dx: 20, dy: 20))
            
        }
        
    }
    
    func stopGame() {
        
        self.isPlaying = false
        
        self.ball.physicsBody?.velocity = .zero
        self.resetScoreL.run(.fadeIn(withDuration: 0.5))
        
        self.playerScoreL.run(SKAction.fadeIn(withDuration: 0.5))
        self.cpuScoreL.run(SKAction.fadeIn(withDuration: 0.5))
        
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { (_) in
            
            self.ball.run(SKAction.move(to: CGPoint(x: 0, y: 0), duration: 0.3))
            
        }
        
    }
    
    func flashScore() {
        
        let scoreSequence = SKAction.sequence([.fadeIn(withDuration: 0.3), .wait(forDuration: 0.3), .fadeOut(withDuration: 0.3)])
        
        
        self.playerScoreL.run(scoreSequence)
        self.cpuScoreL.run(scoreSequence)
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
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

    /// Add ball's point to update and check arrays
    func addLoc(loc: CGPoint) {
        
    // If this isn't here, then the game automatically starts after a few seconds. It's before the DispatchQueue, because calling the background thread for nothing is just plain stupid.
    guard loc != CGPoint(x: 0.0, y: 0.0) else { return }
    
        if self.xCount >= 2 {
            
            self.xCount = 0
            self.ball.physicsBody?.velocity = .zero
            self.ball.physicsBody?.applyImpulse(CGVector(dx: 20, dy: 20))

            
        }
        
        if self.yCount >= 2 {
            
            self.yCount = 0
            self.ball.physicsBody?.velocity = .zero
            self.ball.physicsBody?.applyImpulse(CGVector(dx: 20, dy: -20))

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
    
    // Loads resources, and sets things up
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
        
        self.playerGoal = self.childNode(withName: "PlayerGoal") as! SKSpriteNode
        self.cpuGoal = self.childNode(withName: "CPUGoal") as! SKSpriteNode
        
        self.resetScoreL = self.childNode(withName: "ResetScore") as! SKLabelNode
        
        let border = SKPhysicsBody(edgeLoopFrom: self.frame)
        border.friction = 0
        border.restitution = 1
        
        self.physicsBody = border
        
        // Collision tracking time!
        self.physicsWorld.contactDelegate = self
        
        // Creating timer for ball
        self.timer = DispatchSource.makeTimerSource()
        self.timer.schedule(deadline: .now(), repeating: .milliseconds(500), leeway: .milliseconds(100))
        
        self.timer.setEventHandler {
            
            if self.isPlaying {
                
                self.addLoc(loc: self.ball.position)
                
            }
            
        }
        
    }
    
}
// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFit
    sceneView.showsFPS = true
    sceneView.isAsynchronous = true
 
    // Present the scene
    sceneView.presentScene(scene)
}

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
