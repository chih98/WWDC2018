import PlaygroundSupport
import SpriteKit
import Accelerate
import AVFoundation

/*:

 # VoicePong
 
 Welcome to VoicePong! A game of Pong, controlled by your voice!
 
> PLEASE MAKE SURE ASSISTANT EDITOR IS OPEN
 
 */

var gameScene: GameScene?

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))

if let scene = GameScene(fileNamed: "GameScene") {
    
    // Errors may be thrown for line 24 and 25, this is an Xcode bug, everything is working fine, I belive it has to do with the live code updates on the right hand side (Not the assistant editor, but when you can get the quick look, etc)
    scene.scaleMode = .aspectFill
    gameScene = scene
    // Present the scene
    sceneView.presentScene(scene)
    
}

guard gameScene != nil else { print("GAME SCENE NOT LOADED PROPERLY"); exit(1)
    
}

let engine = AVAudioEngine()

let inputNode = engine.inputNode

var maxVol: Float = 0.0

// let gate: CGFloat = 15.0 // If volume is less than this, it wont register. This helps with ambient noise.

var paddlePosition: CGFloat = 100

//: Setting up signal proccessing. This will let me grab the amount of decibiels in the mic.
inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.outputFormat(forBus: 0)) { (buffer, time) in

    var vector = [Float](repeatElement(0.0, count: Int(buffer.frameLength)))

    // Calculating absolute values
    vDSP_vabs(buffer.floatChannelData!.pointee, 1, &vector, 1, vDSP_Length(buffer.frameLength))
    // Getting largest vector
    vDSP_maxv(vector, 1, &maxVol, vDSP_Length(buffer.frameLength))

    let volume = CGFloat(maxVol)
    
    // Amplyfing the volume based on the microhpone sensitivity.
    let normalized = volume * gameScene!.micSensitivity.rawValue
    
    // Setting the paddle position to the volume, and ofsetting by -319, so that the paddle rests on the bottom of the screen.
    paddlePosition = normalized - 319.0

    // Telling the GameScene to move the paddle.
    gameScene?.movePaddle(to: paddlePosition)

}

// Preparing the AudioEngine and trying to Start it.
engine.prepare()

do {
    
    try engine.start()
    
} catch {
    
    print("failed")
    
}

// Getting errors
NSSetUncaughtExceptionHandler({ (exception) in
    print(exception)
})

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
