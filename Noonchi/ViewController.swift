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
    //    var eyeTracking: EyeTracking?
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
    
    let imageView: UIImageView = {
        let aImageView = UIImageView()
        aImageView.backgroundColor = .red
        aImageView.image = UIImage(named: "mainImage")
        aImageView.translatesAutoresizingMaskIntoConstraints = false
        return aImageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARSession()
        
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 230),
        ])
        
        //        let configuration = Configuration(appID: "ios-eye-tracking-video", blendShapes: [.eyeBlinkLeft, .eyeBlinkRight])
        //        eyeTracking = EyeTracking(configuration: configuration)
        
        let endButton = UIButton(type: .system)
        endButton.setTitle("End Session", for: .normal)
        endButton.addTarget(self, action: #selector(endSession), for: .touchUpInside)
        endButton.frame = CGRect(x: 20, y: 100, width: 200, height: 50)
        self.view.addSubview(endButton)
        
        //        eyeTracking?.pointer.backgroundColor = .blue
        //        eyeTracking?.displayScanpath(for: "8136AD7E-7262-4F07-A554-2605506B985D", animated: true)
        
        let videoButton = UIButton(type: .system)
        videoButton.setTitle("Watch Video", for: .normal)
        videoButton.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        videoButton.frame = CGRect(x: 20, y: 150, width: 200, height: 50)
        self.view.addSubview(videoButton)
        
        // displayLink = CADisplayLink(target: self, selector: #selector(checkGazePosition))
        // displayLink = CADisplayLink(target: self, selector: #selector(checkBlink))
        displayLink = CADisplayLink(target: self, selector: #selector(checkEyeMotion))
        displayLink?.add(to: .current, forMode: .default)
    }
    
    func setupARSession() {
        session = ARSession()
        session.delegate = self
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [])
    }
    
    @objc func startSession() {
        //        eyeTracking?.startSession()
        //        eyeTracking?.showPointer()
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [])
    }
    
    @objc func endSession() {
        //        eyeTracking?.hidePointer()
        //        eyeTracking?.endSession()
        
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
        
        //        if (eyeTracking?.currentSession) != nil {
        //            endSession()
        //        }
        
        startSession()
    }
    
    @objc func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor else {
            return
        }
        
        leftEyeValue = faceAnchor.blendShapes[.eyeBlinkLeft]?.doubleValue ?? 0.0
        rightEyeValue = faceAnchor.blendShapes[.eyeBlinkRight]?.doubleValue ?? 0.0
        
        //        isBlinkDetected = (leftEyeValue > 0.3 && rightEyeValue > 0.3)
        let currentBlinkDetected = (leftEyeValue > 0.3 && rightEyeValue > 0.3)
        
        if currentBlinkDetected && !isEyesClosed {
            isEyesClosed = true
            blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                self.blinkDuration += 0.1
            }
        } else if !currentBlinkDetected && isEyesClosed {
            isEyesClosed = false
            blinkTimer?.invalidate()
            blinkTimer = nil
            blinkDuration = 0.0
        }
    }
    
    // MARK: - 오른쪽으로 곁눈질할 경우 다음 영상 재생
    //    @objc func checkGazePosition() {
    //        guard let currentSession = eyeTracking?.currentSession, let lastGaze = currentSession.scanPath.last else { return }
    
    //        // MARK: - 화면 오른쪽 밖으로 나갔는지 확인
    //        // 다른 방향으로 설정하고 싶으면 UIScreen.main.bounds.width 활용!
    //        if lastGaze.x < 0 {
    //            print("Gaze exited to the right")
    //            endSession()
    //            playNextVideo()
    //        }
    //    }
    
    //    @objc func checkBlink() {
    //        if isBlinkDetected {
    //            player?.pause()
    //            print("Video paused due to blink detection")
    //        } else {
    //            player?.play()
    //        }
    //    }
    
    @objc func checkEyeMotion() {
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
        
        if isBlinkDetected {
            player?.pause()
            print("Video paused due to blink detection")
        } else {
            player?.play()
        }
    }
}
