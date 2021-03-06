//
//  ViewController.swift
//  CoinCounter
//
//  Created by PointerFLY on 17/07/2018.
//  Copyright © 2018 PointerFLY. All rights reserved.
//

import AVFoundation
import UIKit
import SnapKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEvents()
        setupAVCapture();
    }
    
    // MARK: - AVCapture
    
    private let _session =  AVCaptureSession()
    private let _videoDataOuput = AVCaptureVideoDataOutput()
    private var _videoDataOutputQueue = DispatchQueue(label: "ViewController._videoDataOutputQueue")
    private let _interpreter = Interpreter()
    
    private func setupAVCapture() {
        let device = AVCaptureDevice.default(for: .video)!
        let deviceInput = try! AVCaptureDeviceInput(device: device)
        _session.addInput(deviceInput)
    
        _videoDataOuput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCMPixelFormat_32BGRA]
        _videoDataOuput.alwaysDiscardsLateVideoFrames = true
        _videoDataOuput.setSampleBufferDelegate(self, queue: _videoDataOutputQueue);
        _session.addOutput(_videoDataOuput)
        
        _session.sessionPreset = .vga640x480
        _session.startRunning()
    }
    
    // MARK: - Events
    
    private func setupEvents() {
        _freezeButton.addTarget(self, action: #selector(freezeButtonClicked(_:)), for: .touchUpInside)
    }
    
    @objc
    private func freezeButtonClicked(_ sender: UIButton) {
        if _session.isRunning {
            _session.stopRunning()
            sender.setTitle("Continue", for: .normal)
            let flashView = UIView(frame: _previewView.frame)
            flashView.backgroundColor = UIColor.white
            flashView.alpha = 0.0
            self.view.window?.addSubview(flashView);
            
            UIView.animate(withDuration: 0.2, animations: {
                flashView.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    flashView.alpha = 0.0
                }) { _ in
                    flashView.removeFromSuperview()
                }
            }
        } else {
            self._session.startRunning()
            sender.setTitle("Freeze Frame", for: .normal)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let result = _interpreter.run(onFrame: buffer)

        var text = "";
        result.coinInfo.forEach { key, value in
            text += "[\(value)]\(key)\n"
        }
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self._infoTextView.text = text
            self._previewView.image = result.image
        }
    }
    
    // MARK: - UI
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func setupUI() {
        self.view.backgroundColor = UIColor.black
        self.view.addSubview(_previewView)
        self.view.addSubview(_infoTextView)
        self.view.addSubview(_freezeButton)
        _previewView.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.bottom.equalTo(_infoTextView.snp.top)
        }
        _infoTextView.snp.makeConstraints { make in
            make.left.equalTo(self.view)
            make.right.equalTo(_freezeButton.snp.left)
            make.bottom.equalTo(self.view)
            make.height.equalTo(164)
            make.width.equalTo(140)
        }
        _freezeButton.snp.makeConstraints { make in
            make.top.equalTo(_previewView.snp.bottom)
            make.right.equalTo(self.view)
            make.height.equalTo(_infoTextView)
        }
    }
    
    private let _infoTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor.black
        textView.font = UIFont(name: "Menlo-Regular", size: 14)
        textView.textColor = UIColor.white
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.isSelectable = false
        return textView
    }()
    
    private let _previewView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.black
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let _freezeButton: UIButton = {
        let button = UIButton()
        button.setTitle("Freeze Frame", for: .normal)
        button.titleLabel?.font = UIFont(name: "Menlo-Regular", size: 24)
        button.backgroundColor = UIColor.black
        button.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .highlighted)
        button.setTitleColor(UIColor.white, for: .normal)
        return button
    }()
}

