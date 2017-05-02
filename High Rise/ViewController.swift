import UIKit
import SceneKit
import SpriteKit
import Foundation

class ViewController: UIViewController {
  
  static var num = 0
  static var arrSub = 0
  static var preNum = 2
  static var gameOver = false
  static var collionVioce = true
  
  let PlayerBoxCategory: UInt32 = 0x1 << 1
  let PyramidCategory: UInt32 = 0x1 << 2
  let BulletCategory: UInt32 = 0x1 << 3
  let CapCategory: UInt32 = 0x1 << 4
  
    @IBOutlet weak var endScore: UILabel!

    @IBOutlet weak var change: UILabel!
    @IBOutlet weak var play: UIButton!
  
  var loop = true
  var sumNode = 0
  var firstTouch = true
  var cycleTimer:Timer?
  var scnScene: SCNScene!
  var curTime = NSDate()
  var preTimer = NSDate()
  var previousPosition = SCNVector3(0,0,0)
  public var cameraMove = 1
  
  static var arrayBullet = [SCNNode]()
  var sounds = [String: SCNAudioSource]()

  var arrayPyramid = [SCNNode]()
  var arrayBox = [SCNNode]()
  var arrayPyramidZ = [Int]()
  var arrayPyramidX = [Int]()
  var arrayPositionZ = [SCNVector3]()
  var arrayPositionX = [SCNVector3]()
  
  let excessiveTime: TimeInterval = 1
  let changeStatuTime: TimeInterval = 0.2
  let testTimer:TimeInterval = 0.4
  
  let randomInt:Array = [4,4,4,4,6,6,6,8,8,8,6]

  
  //分数
  @IBOutlet weak var score: UILabel!
  @IBOutlet weak var scnView: SCNView!
  
  
    @IBAction func replay(_ sender: UIButton) {

        load()
    }
  
  //暂停键

  func loadSound(name: String, path: String) {
    if let sound = SCNAudioSource(fileNamed: path) {
      if (name == "playground")
      {
        sound.loops = true
      }
      sound.isPositional = false
      sound.volume = 2
      sound.load()
      sounds[name] = sound
    }
  }
  //重新加载
  private func load()
  {
    score.text = "0"
    endScore.isHidden = true
    play.isHidden = true
    change.isHidden = true
    ViewController.gameOver = false
    ViewController.collionVioce = true
    cameraMove = 1
    firstTouch = true
    deleteAllArray()
    ViewController.num = 0
    ViewController.arrSub = 0
    ViewController.preNum = 2
    setupScene()
    initCap()
    bulletXZ()
    addElementaryPyramid()
    addSecondTimer()
  }
  
  private func deleteAllArray() {
    arrayBox.removeAll()
    arrayPyramid.removeAll()
    arrayPyramidX.removeAll()
    arrayPyramidZ.removeAll()
    arrayPositionZ.removeAll()
    arrayPositionX.removeAll()
    sounds.removeAll()
    ViewController.arrayBullet.removeAll()
  }
  public func playSound(sound: String, node: SCNNode) {
    node.runAction(SCNAction.playAudio(sounds[sound]!, waitForCompletion: false))
  }
//定时器函数
  private func addCycleTimer() {
    cycleTimer = Timer.scheduledTimer(timeInterval: 1.1, target: self, selector: #selector(flashFuncOne), userInfo: nil, repeats: true)
    RunLoop.main.add(cycleTimer!, forMode: RunLoopMode.commonModes)
  }
  private func addOtherTimer() {
    cycleTimer = Timer.scheduledTimer(timeInterval: 1.4, target: self, selector: #selector(flashFuncTwo), userInfo: nil, repeats: true)
    RunLoop.main.add(cycleTimer!, forMode: RunLoopMode.commonModes)
  }
  private func addSecondTimer() {
    cycleTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(flashPyramidStatue), userInfo: nil, repeats: true)
    RunLoop.main.add(cycleTimer!, forMode: RunLoopMode.commonModes)
  }
  //关闭定时函数
  private func removeCycleTimer() {
    cycleTimer?.invalidate()
    cycleTimer = nil
  }
  //初始化box
  private func initPlayerBox()
  {
    let box = SCNNode(geometry: SCNBox(width: 0.11, height: 0.11, length: 0.11, chamferRadius: 0))
    box.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 1, green: 1, blue: 1, alpha: 1)
    box.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    box.position = SCNVector3(0,2,-0.11)
    box.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 140/255, green: 140/255, blue: 140/255, alpha: 1)
    box.geometry?.firstMaterial?.selfIllumination.contents = UIColor(colorLiteralRed: 245/255, green: 173/255, blue: 105/255, alpha: 1)
    box.physicsBody?.categoryBitMask = Int(PlayerBoxCategory)
    box.physicsBody?.collisionBitMask = Int(BulletCategory) | Int(CapCategory)
    box.physicsBody?.contactTestBitMask = Int(BulletCategory)
    box.name = "box_box"
    scnScene.rootNode.addChildNode(box)

  }
  //初始化场景,音效
  private func setupScene() {
    scnScene = SCNScene(named: "Box.scnassets/Scenes/GameScene.scn")
    scnView.scene = scnScene
    scnView.delegate = self
    scnScene.physicsWorld.contactDelegate = self
    loadSound(name: "playground", path: "Box.scnassets/Audio/playground.mp3")
    loadSound(name: "playing", path: "Box.scnassets/Audio/playing.wav")
    loadSound(name: "collision", path: "Box.scnassets/Audio/collision.wav")
    initPlayerBox()
    let node = scnScene.rootNode.childNode(withName: "box_box", recursively: false)
    playSound(sound: "playground", node: node!)
    endScore.isHidden = true
    play.isHidden = true
    change.isHidden = true
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupScene()
    initCap()
    addOtherTimer()
    addCycleTimer()
    addSecondTimer()
    bulletXZ()
    addElementaryPyramid()
  }
  //添加随机boxCap
  private func addRandomBox()
  {
    var position:SCNVector3
    var sumNode = 0
    let num = Int(arc4random()%10) + 1
    let realNum = randomInt[num]
    
    //1表示没有间隔，2表示有间隔
    let solidHollow = Int(arc4random()%2) + 1
    if (solidHollow == 1)
    {
      sumNode = getBoxArrayLength()
      position = arrayBox[sumNode - 2].position
      position.x = position.x - 0.35
      for _ in 1...realNum+1 {
        let boxNum = Int(arc4random()%6) + 1
        position.x = position.x - 0.35
        addVerticalBox(position: position, num: boxNum)
        sumNode = sumNode + 1
      }
      position = arrayBox[sumNode - 1].position
      for _ in 1...realNum+1 {
        let boxNum = Int(arc4random()%6) + 1
        position.z = position.z - 0.35
        addVerticalBox(position: position, num: boxNum)
      }
    }
    else
    {
      sumNode = getBoxArrayLength()
      position = arrayBox[sumNode - 2].position
      position.x = position.x - 0.35
      for _ in 1...realNum {
        let boxNum = Int(arc4random()%6) + 1
        position.x = position.x - 0.35
        addVerticalBox(position: position, num: boxNum)
        sumNode = sumNode + 1
      }
      position = arrayBox[sumNode - 2].position
      position.z = position.z - 0.35
      for _ in 1...realNum {
        let boxNum = Int(arc4random()%6) + 1
        position.z = position.z - 0.35
        addVerticalBox(position: position, num: boxNum)
      }
    }
  }
  //获取当前arraybox的长度
  private func getBoxArrayLength() -> Int
  {
    var length = 0
    for _ in arrayBox {
      length = length + 1
    }
    return length
  }
  //当box坐标比发射器高，让发射器下落
  @objc private func flashPyramidStatue()
  {
    if (!ViewController.gameOver)
    {
      let box = getBoxNode()
      for node in arrayPyramid
      {
        if box.position.x < node.position.x && box.position.z < node.position.z
        {
          node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
          node.removeFromParentNode()
        }
      }
      for node in arrayPositionX
      {
        if box.position.x+0.1 < node.x && box.position.z+0.1 < node.z
        {
          arrayPositionX.remove(at: getSubOfArray(arr: arrayPositionX, vPosition: node))
        }
      }
      for node in arrayPositionZ
      {
        if box.position.x+0.1 < node.x && box.position.z+0.1 < node.z
        {
          arrayPositionZ.remove(at: getSubOfArray(arr: arrayPositionZ, vPosition: node))
        }
      }
    }
    else
    {
      removeCycleTimer()
    }
  }
  //刷新子弹
  @objc private func flashFuncOne()
  {
    for position in arrayPositionZ {
      addXBullet(position: position)
    }
    if (ViewController.gameOver)
    {
      loadgameover()
    }
  }
  @objc private func flashFuncTwo()
  {
    for position in arrayPositionX {
      addZBullet(position: position)
    }
  }
  private func getSubOfArray(arr:Array<SCNVector3>,vPosition:SCNVector3) -> Int
  {
    var num = 0
    for p in arr
    {
      if p.x == vPosition.x && p.y == vPosition.y && p.z == vPosition.z
      {
        return num
      }
      num = num + 1
    }
    return 0
  }
  //让脚下的box下落，并在arraybox数组去除
  private func changeStatue(num:Int){
    let funBox1 = arrayBox[num - 2]
    
    for childnode in scnScene.rootNode.childNodes {
      if (testPosition(one: funBox1.position, two: childnode.position))
      {
        childnode.physicsBody? = SCNPhysicsBody(type: .dynamic, shape: nil)
      }
    }
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + changeStatuTime ,execute: {() in
      let funBox2 = self.arrayBox[num - 1]
      self.arrayBox.removeFirst()
      self.arrayBox.removeFirst()///////////////////
      for childnode in self.scnScene.rootNode.childNodes {
        if (self.testPosition(one: funBox2.position, two: childnode.position))
        {
          childnode.physicsBody? = SCNPhysicsBody(type: .dynamic, shape: nil)
        }
      }
      })
    
  }
  //判断两个空间向量是在x轴或z轴
  private func testPosition(one:SCNVector3,two:SCNVector3) -> Bool
  {
    
    if (one.x == two.x && one.z == two.z)
    {
      return true
    }
    else
    {
      return false
      
    }
  }
  //添加发射器
  private func addEnemyPyramid(position:SCNVector3)
  {
    let Pyramid = SCNNode(geometry: SCNPyramid(width: 0.22, height: 0.3, length: 0.22))
    Pyramid.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 150/255, green: 150/255, blue: 150/255, alpha: 1)
    Pyramid.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
    Pyramid.name = "cone_\(ViewController.num)"
    Pyramid.position = position
    Pyramid.physicsBody?.categoryBitMask = Int(PyramidCategory)
    Pyramid.physicsBody?.collisionBitMask = 0
    Pyramid.geometry?.firstMaterial?.selfIllumination.contents = UIColor(colorLiteralRed: 120/255, green: 244/255, blue: 255/255, alpha: 1)
    arrayPyramid.append(Pyramid)
    scnScene.rootNode.addChildNode(Pyramid)
  }
  //添加x轴的子弹，旋转角度不一样
  private func addXBullet(position:SCNVector3)
  {
    let testbox = SCNNode(geometry: SCNCapsule(capRadius: 0.03, height: 0.14))
    testbox.position = position
    testbox.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    testbox.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 160/255, green: 160/255, blue: 160/255, alpha: 1)
    testbox.geometry?.firstMaterial?.selfIllumination.contents = UIColor(colorLiteralRed: 250/255, green: 67/255, blue: 101/255, alpha: 0.9)
    testbox.rotation = SCNVector4(1,1,0,Double.pi)
    testbox.physicsBody?.damping = 0.05
    testbox.physicsBody?.isAffectedByGravity = false
    testbox.physicsBody?.categoryBitMask = Int(BulletCategory)
    testbox.physicsBody?.collisionBitMask = Int(PlayerBoxCategory)
    testbox.physicsBody?.contactTestBitMask = Int(PlayerBoxCategory)
    testbox.physicsBody?.applyForce(SCNVector3(8,0,0), asImpulse: false)
    scnScene.rootNode.addChildNode(testbox)
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: { () in
    testbox.removeFromParentNode()})
  }
  //添加z轴的子弹，旋转角度不一样
  private func addZBullet(position:SCNVector3)
  {
    let testbox = SCNNode(geometry: SCNCapsule(capRadius: 0.03, height: 0.14))
    testbox.position = position
    testbox.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
    testbox.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 160/255, green: 160/255, blue: 160/255, alpha: 1)
        testbox.geometry?.firstMaterial?.selfIllumination.contents = UIColor(colorLiteralRed: 0, green: 191/255, blue: 1, alpha: 1)
    testbox.rotation = SCNVector4(0,1,1,Double.pi)
    testbox.physicsBody?.damping = 0.05
    testbox.physicsBody?.isAffectedByGravity = false
    testbox.physicsBody?.categoryBitMask = Int(BulletCategory)
    testbox.physicsBody?.collisionBitMask = Int(PlayerBoxCategory)
    testbox.physicsBody?.contactTestBitMask = Int(PlayerBoxCategory)
    testbox.physicsBody?.applyForce(SCNVector3(0,0,-8), asImpulse: false)
    scnScene.rootNode.addChildNode(testbox)
    
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: { () in
      testbox.removeFromParentNode()})
  }
  //初始化脚下的box,并让type设为static
  private func initBox(box: SCNNode, position: SCNVector3) {
    
    ViewController.num = ViewController.num + 1
    box.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 150/255, green: 150/255, blue: 150/255, alpha: 1)
    box.geometry?.firstMaterial?.selfIllumination.contents = UIColor(colorLiteralRed: 245/255, green: 173/255, blue: 105/255, alpha: 1)
    box.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
    box.name = "box_\(ViewController.num)"
    box.position = position
    box.physicsBody?.categoryBitMask = Int(CapCategory)
    box.physicsBody?.collisionBitMask = Int(PlayerBoxCategory)
    scnScene.rootNode.addChildNode(box)
  }
  //添加垂直方向盒子,num为数量
  private func addVerticalBox(position: SCNVector3,num: Int) {
    var mark = 0
    var flag = num
    var begin = position
    if (flag < 0)
    {
      while (flag < 0)
      {
        flag = flag + 1
        let boxfun = SCNNode(geometry: SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0))
        initBox(box: boxfun, position: begin)
        begin.y = begin.y + 0.35
        if (mark == 0)
        {
          arrayBox.append(boxfun)
          mark = 1
        }
      }
    }
    else {
    while(flag > 0)
    {
      flag = flag - 1
      let boxfun = SCNNode(geometry: SCNBox(width: 0.3, height: 0.3, length: 0.3, chamferRadius: 0))
      initBox(box: boxfun, position: begin)
      begin.y = begin.y - 0.35
      if (mark == 0)
      {
        arrayBox.append(boxfun)
        mark = 1
      }
    }
    }
  }
  //移动相机跟随playerbox
  private func moveCamera() {
    let moveUpAction = SCNAction.move(by: SCNVector3(-0.35,0,-0.35), duration: 0.75)
    let mainCamera = scnScene.rootNode.childNode(withName: "Main Camera", recursively: false)
    mainCamera?.runAction(moveUpAction)
  }
  //点击屏幕移动方块，移动完，脚下的方块下落
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    if (!ViewController.gameOver)
    {
    var previousPosition:SCNVector3
    var flag:Bool                   //判断playerbox起跳是在x轴还是y轴，在空中有0.5s的停顿
    let box = getBoxNode()
    if (firstTouch)
    {
      preTimer = NSDate(timeIntervalSinceNow: 0)
      firstTouch = false
      firstTouchPlayer()
    }
    else
    {
      curTime = NSDate(timeIntervalSinceNow: 0)
    }
    if (curTime.timeIntervalSince(preTimer as Date) >= 0.9)
    {
      previousPosition = arrayBox[0].position
      ViewController.arrSub = ViewController.arrSub + 2
      let position = arrayBox[2].position
      flag = flagPosition(p1: previousPosition, p2: position)
      if (flag)
      {
        secondTouchPlayerOne(vPosition:position)
      }
      else
      {
        secondTouchPlayerTwo(vPosition:position)
      }
      playSound(sound: "playing", node: box)
      changeStatue(num: 2)
      preTimer = NSDate(timeIntervalSinceNow: 0)
      cameraMove = cameraMove + 1
      if (cameraMove >= 2)
      {
        moveCamera()
      }
      if (cameraMove >= 14)
      {
        if (cameraMove%7 == 0)
        {
          for node in arrayPyramid
          {
            node.removeFromParentNode()
          }
          addRandomBox()
          arrayPositionZ.removeAll()
          arrayPositionX.removeAll()
          arrayPyramidX.removeAll()
          arrayPyramidZ.removeAll()
          bulletXZ()
          if (cameraMove >= 35)
          {
            if (cameraMove != 35)
            {
              change.text = "变换轨道"
              change.isHidden = false
              DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: { () in
                self.change.isHidden = true})
              addAdvancedPyramid()
              addElementaryPyramid()
            }
            else
            {
              change.text = "难度升级"
              change.isHidden = false
              DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: { () in
                self.change.isHidden = true})
              addAdvancedPyramid()
            }
          }
          else
          {
            change.text = "变换轨道"
            change.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: { () in
              self.change.isHidden = true})
            addElementaryPyramid()
          }
        }
      }
    }
      score.text = "\(cameraMove)"
    }
    else
    {
      
    }
    }
  private func secondTouchPlayerOne(vPosition:SCNVector3)
  {
    var position = vPosition
    let box = getBoxNode()
    position.y = 1.5
    position.z = position.z + 0.35
    let moveBoxOne = SCNAction.move(to: position, duration: 0.4)
    box.runAction(moveBoxOne)
    position.y = 1.2
    position.z = position.z - 0.36
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + testTimer, execute: {() in
      let moveBoxTwo = SCNAction.move(to: position, duration: 0.4)
      box.runAction(moveBoxTwo)
    })
  }
  private func secondTouchPlayerTwo(vPosition:SCNVector3)
  {
    let box = getBoxNode()
    var position = vPosition
    position.y = 1.5
    position.x = position.x + 0.35
    let one = SCNAction.move(to: position, duration: 0.4)
    box.runAction(one)
    position.y = 1.2
    position.x = position.x - 0.36
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + testTimer, execute: {() in
      let two = SCNAction.move(to: position, duration: 0.5)
      box.runAction(two)
    })

  }
  //第一次点击屏幕
  private func firstTouchPlayer()
  {
    let box = getBoxNode()
    let move = SCNAction.move(to: SCNVector3(0,1.2,-0.11), duration: 0.1)
    box.runAction(move)
    var position = arrayBox[2].position
    position.y = position.y + 0.5
    position.z = position.z + 0.35
    let moveBoxOne = SCNAction.move(to: position, duration: 0.4)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1, execute: { () in
      box.runAction(moveBoxOne)
    })
    position.y = position.y - 0.3
    position.z = position.z - 0.36
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + testTimer, execute: {() in
      let moveBoxTwo = SCNAction.move(to: position, duration: 0.4)
      box.runAction(moveBoxTwo)
    })
    playSound(sound: "playing", node: box)
    changeStatue(num: 2)
  }
  //判断是在x轴还是在z轴移动,true为z轴
  private func flagPosition(p1:SCNVector3,p2:SCNVector3) -> Bool {
    if (p1.x == p2.x)
    {
      return true
    }
    else
    {
      return false
    }
  }
  //获取box节点
  private func getBoxNode() -> SCNNode {
    let box = self.scnScene.rootNode.childNode(withName: "box_box", recursively: false)
    return box!
  }
  override var prefersStatusBarHidden: Bool {
    return true
  }

  //添加初级难度的子弹,获取发射器的位置放入两个数组里面
  private func addElementaryPyramid()
  {
    var position:SCNVector3
    //z轴
    for num in arrayPyramidX {
      if (num%3 == 0)
      {
        position = arrayBox[num].position
        position.x = position.x - 1.2
        position.y = position.y + 0.1
        
        addEnemyPyramid(position: position)
        position.y = position.y + 0.1
        arrayPositionZ.append(position)
      }
    }
    for num in arrayPyramidZ {
      if (num%3 == 0)
      {
        position = arrayBox[num].position
        position.z = position.z + 1.2
        position.y = position.y + 0.1
        addEnemyPyramid(position: position)
        position.y = position.y + 0.1
        arrayPositionX.append(position)
      }
    }
  }
  private func addAdvancedPyramid()
  {
    var position:SCNVector3
    //z轴
    for num in arrayPyramidX {
      if (num%2 == 0)
      {
        position = arrayBox[num].position
        position.x = position.x - 1.2
        position.y = position.y + 0.1
        
        addEnemyPyramid(position: position)
        position.y = position.y + 0.1
        arrayPositionZ.append(position)
      }
    }
    for num in arrayPyramidZ {
      if (num%2 == 0)
      {
        position = arrayBox[num].position
        position.z = position.z + 1.2
        position.y = position.y + 0.1
        addEnemyPyramid(position: position)
        position.y = position.y + 0.1
        arrayPositionX.append(position)
      }
    }

  }
  //子弹的相对位置是在X轴，Z轴，X轴为true，Z轴为false
  private func bulletXZ()
  {
    let length = getBoxArrayLength() - 3
    var position:SCNVector3
    var nextOnePosition:SCNVector3
    var nextTwoPosition:SCNVector3
    for num in 3...length {//error
      position = arrayBox[num].position
      nextOnePosition = arrayBox[num + 1].position
      nextTwoPosition = arrayBox[num + 2].position
      if (position.x == nextOnePosition.x && position.x == nextTwoPosition.x) {
        //z轴
        arrayPyramidX.append(num)
      }
      else if (position.z == nextOnePosition.z && position.z == nextTwoPosition.z) {
        //x轴
        arrayPyramidZ.append(num)
      }
    }
  }
  private func initCap()
  {
    //地图
    //第一行
    addVerticalBox(position: SCNVector3(0,1,-0.1), num: 3)
    addVerticalBox(position: SCNVector3(0,1,-0.45), num: 4)
    addVerticalBox(position: SCNVector3(0,1,-0.8), num: 1)
    addVerticalBox(position: SCNVector3(0,1,-1.15), num: 2)
    addVerticalBox(position: SCNVector3(0,1,-1.5), num: 1)
    addVerticalBox(position: SCNVector3(0,1,-1.85), num: -2)
    //第二行
    addVerticalBox(position: SCNVector3(-0.7,1,-1.5), num: 1)
    addVerticalBox(position: SCNVector3(-1.05,1,-1.5), num: 2)
    addVerticalBox(position: SCNVector3(-1.4,1,-1.5), num: 2)
    addVerticalBox(position: SCNVector3(-1.75,1,-1.5), num: 2)
    addVerticalBox(position: SCNVector3(-2.1,1,-1.5), num: 1)
    addVerticalBox(position: SCNVector3(-2.45,1,-1.5), num: 1)
    addVerticalBox(position: SCNVector3(-2.8,1,-1.5), num: 1)
    addVerticalBox(position: SCNVector3(-3.15,1,-1.5), num: -3)
    //第三行
    addVerticalBox(position: SCNVector3(-2.8,1,-2.2), num: 3)
    addVerticalBox(position: SCNVector3(-2.8,1,-2.55), num: 1)
    addVerticalBox(position: SCNVector3(-2.8,1,-2.9), num: 1)
    addVerticalBox(position: SCNVector3(-2.8,1,-3.25), num: 3)
    addVerticalBox(position: SCNVector3(-2.8,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-2.8,1,-3.95), num: -3)
    //第四行
    
    addVerticalBox(position: SCNVector3(-3.5,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-3.85,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-4.2,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-4.55,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-4.9,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-5.25,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-5.6,1,-3.6), num: 1)
    addVerticalBox(position: SCNVector3(-5.95,1,-3.6), num: 1)
    //第五行
    addVerticalBox(position: SCNVector3(-5.6,1,-4.3), num: 2)
    addVerticalBox(position: SCNVector3(-5.6,1,-4.65), num: 3)
    addVerticalBox(position: SCNVector3(-5.6,1,-5.0), num: 4)
    addVerticalBox(position: SCNVector3(-5.6,1,-5.35), num: 5)
    addVerticalBox(position: SCNVector3(-5.6,1,-5.7), num: 2)
    addVerticalBox(position: SCNVector3(-5.6,1,-6.05), num: 7)
    addVerticalBox(position: SCNVector3(-5.6,1,-6.4), num: 2)
    addVerticalBox(position: SCNVector3(-5.6,1,-6.75), num: 7)
    //第六行
    addVerticalBox(position: SCNVector3(-6.3,1,-6.4), num: 1)
    addVerticalBox(position: SCNVector3(-6.65,1,-6.4), num: 1)
    addVerticalBox(position: SCNVector3(-7,1,-6.4), num: 1)
    addVerticalBox(position: SCNVector3(-7.35,1,-6.4), num: 1)
    addVerticalBox(position: SCNVector3(-7.7,1,-6.4), num: 1)
    addVerticalBox(position: SCNVector3(-8.05,1,-6.4), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-6.4), num: 1)
    addVerticalBox(position: SCNVector3(-8.75,1,-6.4), num: -2)
    //第七行
    addVerticalBox(position: SCNVector3(-8.4,1,-7.1), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-7.45), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-7.8), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-8.15), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-8.5), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-8.85), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-9.2), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-9.55), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-9.9), num: 1)
    addVerticalBox(position: SCNVector3(-8.4,1,-10.25), num: 1)
  }
  public func loadgameover()
  {
    endScore.isHidden = false
    endScore.text = "得分:\(cameraMove)"
    play.isHidden = false
  }
}

