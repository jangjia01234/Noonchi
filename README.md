
<div align=center> 
  <img src="https://github.com/user-attachments/assets/2d687a21-20e1-4b78-b0df-e57e575b1637" width="550"/><br/>
</div>
<br><br>


## ✨ 눈치 👀 를 소개합니다!

### 소개
눈치 보듯이 오른쪽으로 곁눈질하면 다음 영상으로 넘어갈 수 있습니다. 손 안대고 편하게 영상을 넘겨볼 수 있어요!

### 사용법

- 메인 화면에서 간단한 온보딩 문구를 확인할 수 있습니다.
- **시작하기** 버튼을 눌러 영상 시청을 시작합니다.
- 영상의 시간이 다 되면 다음 영상으로 자동으로 넘어갑니다.
- 다만 중간에 다음 영상으로 이동하고 싶을 경우, **눈치를 보듯** 👀 **오른쪽 끝으로 시선을 두었다 돌아오면** 다음으로 넘길 수 있습니다.

### 언제 사용할까?
 
- 요리를 하거나, 홈트를 한다거나, 필기하면서 영상을 볼 때 요긴하게 쓸 수 있을 것 같습니다. 손이 불편하신 분들도 터치 없이 사용할 수 있습니다.
- AVKit을 활용해서 영상이 아니라 음악 플레이리스트로도 만들 수 있습니다. 음악 앱일 경우 다른 활용 사례가 생길 것 같습니다.

<br><br>

## 🧑‍💻 코드 설명

AVKit과 ARKit을 활용하여 사용자의 눈 움직임과 깜박임으로 영상을 제어하는 기능을 구현했습니다.

<br>

> **AVKit을 활용한 동영상 플레이어 구현**

**AVPlayer와 AVPlayerViewController 설정**

```swift
var player: AVPlayer?
var playerController: AVPlayerViewController?

@objc func playVideo() {
    guard currentVideoIndex < videos.count else {
        currentVideoIndex = 0
        return
    }

    let videoName = videos[currentVideoIndex]
    guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
        debugPrint("MP4 Not Found")
        return
    }

    let url = URL(fileURLWithPath: path)
    let playerItem = AVPlayerItem(url: url)

    NotificationCenter.default.addObserver(self, selector: #selector(videoDidEnd), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

    player = AVPlayer(playerItem: playerItem)
    playerController = AVPlayerViewController()
    playerController?.player = player

    present(playerController!, animated: true) {
        self.player?.play()
    }

    startSession()
}
```

<br>

> **ARKit과 EyeTracking을 통한 눈 움직임 감지**

**세션 설정 및 시작**

```swift
func setupARSession() {
    session = ARSession()
    session.delegate = self

    let configuration = ARFaceTrackingConfiguration()
    configuration.isLightEstimationEnabled = true
    session.run(configuration, options: [])
}

@objc func startSession() {
    eyeTracking?.startSession()
    eyeTracking?.showPointer()

    let configuration = ARFaceTrackingConfiguration()
    configuration.isLightEstimationEnabled = true
    session.run(configuration, options: [])
}

@objc func endSession() {
    eyeTracking?.hidePointer()
    eyeTracking?.endSession()

    session.pause()
}
```

<br>

**눈 움직임을 통한 동영상 제어**

```swift
@objc func checkGazePosition() {
    guard let currentSession = eyeTracking?.currentSession, let lastGaze = currentSession.scanPath.last else { return }
    
    if lastGaze.x < 0 {
        print("Gaze exited to the right")
        endSession()
        playNextVideo()
    }
}
```

<br><br>

## 📝 정보

- 개발 기간: 2024.06.20~21 (1일)
- 기여도: 100%
