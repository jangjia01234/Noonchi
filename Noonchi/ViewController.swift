//
//  ViewController.swift
//  Noonchi
//
//  Created by Jia Jang on 6/20/24.
//

import UIKit
import ARKit
import EyeTracking
import AVKit

class ViewController: UIViewController, ARSessionDelegate {
    var eyeTracking: EyeTracking?
    var session: ARSession!
    var isBlinkDetected: Bool = false
    var leftEyeValue: Double = 0
    var rightEyeValue: Double = 0
    
    var player: AVPlayer?
    var playerController: AVPlayerViewController?
    var currentVideoIndex = 0
    
    let videos: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
    var displayLink: CADisplayLink?
    
    var blinkTimer: Timer?
    var isEyesClosed: Bool = false
    var blinkDuration: TimeInterval = 0.0
    let blinkThreshold: TimeInterval = 0.2
    
    lazy var label: UILabel = {
        let label: UILabel = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.text = "오른쪽으로\n곁눈질 👀 해서\n영상을 넘겨보세요!"
        label.numberOfLines = 3
        label.layer.masksToBounds = true
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        let myImage: UIImage = UIImage(named: "mainImage.png")!
        imageView.image = myImage
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    lazy var videoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("시작하기", for: .normal)
        button.backgroundColor = UIColor(red: 0/255, green: 114/255, blue: 190/255, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARSession()
        setupConstraints()
        
        let configuration = Configuration(appID: "ios-eye-tracking-video")
        eyeTracking = EyeTracking(configuration: configuration)
        
        eyeTracking?.pointer.backgroundColor = .blue
        
        // MARK: - 타겟 설정
        displayLink = CADisplayLink(target: self, selector: #selector(checkGazePosition))
        // displayLink = CADisplayLink(target: self, selector: #selector(checkBlink))
        //        displayLink = CADisplayLink(target: self, selector: #selector(checkEyeMotion))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    func setupARSession() {
        session = ARSession()
        session.delegate = self
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [])
    }
    
    func setupConstraints() {
        self.view.backgroundColor = UIColor.white
        
        self.view.addSubview(label)
        self.view.addSubview(imageView)
        self.view.addSubview(videoButton)
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // MARK: - 상단 텍스트
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0),
            label.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: -150),
            label.bottomAnchor.constraint(equalTo: imageView.topAnchor),
            label.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            
            // MARK: - 중앙 이미지
            imageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0),
            imageView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0),
            imageView.bottomAnchor.constraint(equalTo: videoButton.topAnchor, constant: -200),
            
            // MARK: - 하단 버튼
            videoButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0),
            videoButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 0),
            videoButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            videoButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 20),
            videoButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
            videoButton.heightAnchor.constraint(equalToConstant: 60)
        ])
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
    
    @objc func playVideo() {
        guard currentVideoIndex < videos.count else {
            // MARK: - Watch Video 버튼 누르면 다시 처음부터 재생
            currentVideoIndex = 0
            return
        }
        
        let videoName = videos[currentVideoIndex]
        guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else { debugPrint("MP4 Not Found"); return }
        
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
    
    @objc func videoDidEnd(notification: Notification) {
        playNextVideo()
        
        // 🔥 FIX: - 전체 영상 다 보면 처음부터 다시 재생 (print 안찍힘)
        if currentVideoIndex >= videos.count {
            currentVideoIndex = 0
            playVideo()
        } else {
            playNextVideo()
        }
    }
    
    @objc func playNextVideo() {
        currentVideoIndex += 1
        
        guard currentVideoIndex < videos.count else { return }
        
        let videoName = videos[currentVideoIndex]
        guard let path = Bundle.main.path(forResource: videoName, ofType: "mp4") else {
            debugPrint("MP4 Not Found")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: url)
        
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        
        if (eyeTracking?.currentSession) != nil {
            endSession()
        }
        
        startSession()
    }
    
    @objc func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor else {
            return
        }
        
        //        leftEyeValue = faceAnchor.blendShapes[.eyeBlinkLeft]?.doubleValue ?? 0.0
        //        rightEyeValue = faceAnchor.blendShapes[.eyeBlinkRight]?.doubleValue ?? 0.0
        
        //        isBlinkDetected = (leftEyeValue > 0.3 && rightEyeValue > 0.3)
        //        let currentBlinkDetected = (leftEyeValue > 0.3 && rightEyeValue > 0.3)
        //
        //        if currentBlinkDetected && !isEyesClosed {
        //            isEyesClosed = true
        //            blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
        //                self.blinkDuration += 0.1
        //            }
        //        } else if !currentBlinkDetected && isEyesClosed {
        //            isEyesClosed = false
        //            blinkTimer?.invalidate()
        //            blinkTimer = nil
        //            blinkDuration = 0.0
        //        }
    }
    
    // MARK: - 오른쪽으로 곁눈질할 경우 다음 영상 재생
    @objc func checkGazePosition() {
        guard let currentSession = eyeTracking?.currentSession, let lastGaze = currentSession.scanPath.last else { return }
        
        // MARK: - 화면 오른쪽 밖으로 나갔는지 확인
        // 다른 방향으로 설정하고 싶으면 UIScreen.main.bounds.width 활용!
        if lastGaze.x < 0 {
            print("Gaze exited to the right")
            endSession()
            playNextVideo()
        }
    }
    
    //    @objc func checkBlink() {
    //        if isBlinkDetected {
    //            player?.pause()
    //            print("Video paused due to blink detection")
    //        } else {
    //            player?.play()
    //        }
    //    }
    
    //    @objc func checkEyeMotion() {
    //        guard let currentSession = eyeTracking?.currentSession, let lastGaze = currentSession.scanPath.last else { return }
    
    //        DispatchQueue.main.async {
    // Check gaze position
    //            if lastGaze.x < 0 {
    //                print("Gaze exited to the right")
    //                self.endSession()
    //                self.playNextVideo()
    //            }
    
    // Check blink
    //            if self.isBlinkDetected {
    //                self.player?.pause()
    //                print("Video paused due to blink detection")
    //            } else {
    //                self.player?.play()
    //            }
    //        }
    
    //        if isBlinkDetected {
    //            player?.pause()
    //            print("Video paused due to blink detection")
    //        } else {
    //            player?.play()
    //        }
    //    }
}
