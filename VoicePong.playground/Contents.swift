import PlaygroundSupport
import SpriteKit
import Accelerate
import AVFoundation

// Can't have audio inside if let, because it wont run for some reason... Works fine with this workaround.
var gameScene: GameScene?

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))

if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    
    // Errors may be thrown for line 16 and 17, this is an Xcode bug, everything is working fine.
    scene.scaleMode = .aspectFill
    gameScene = scene
    // Present the scene
    sceneView.presentScene(scene)
    
}

guard gameScene != nil else { print("GAME SCENE NOT LOADED PROPERLY"); exit(1)
    
}

var frameCount = 0

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
    
    let normalized = volume * gameScene!.micSensitivity.rawValue
    
    paddlePosition = normalized - 319.0
    

    gameScene?.movePaddle(to: paddlePosition)

}

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
