//
//  CALayer+Heartbeat.swift
//  MGUtils
//
//  Created by 董振山 on 2025/7/29.
//

import QuartzCore

extension CALayer {
    
    // MARK: - 呼吸动画
    func beginBreathingAnimation() {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.5
        opacityAnimation.duration = 1.0
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        opacityAnimation.fillMode = .both
        opacityAnimation.isRemovedOnCompletion = false
        
        self.add(opacityAnimation, forKey: "breathingAnimation")
    }
    
    func removeBreathAnimation() {
        self.removeAnimation(forKey: "breathingAnimation")
    }
    
    // MARK: - 心跳动画
    func beginHeartbeatAnimation() {
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.03
        scaleAnimation.duration = 0.4
        scaleAnimation.autoreverses = true
        scaleAnimation.repeatCount = 2
        scaleAnimation.fillMode = .both
        scaleAnimation.isRemovedOnCompletion = false
        
        self.add(scaleAnimation, forKey: "heartbeatAnimation")
    }
    
    func removeHeartbeatAnimation() {
        self.removeAnimation(forKey: "heartbeatAnimation")
    }
    
    // MARK: - 弹跳动画
    func beginBounceAnimation(positionY: CGFloat, range: CGFloat) {
        let positionAnimation = CABasicAnimation(keyPath: "position.y")
        positionAnimation.fromValue = positionY - range
        positionAnimation.toValue = positionY + range
        positionAnimation.duration = 1.0
        positionAnimation.autoreverses = true
        positionAnimation.repeatCount = .infinity
        positionAnimation.fillMode = .both
        positionAnimation.isRemovedOnCompletion = false
        
        self.add(positionAnimation, forKey: "bounceAnimation")
    }
    
    func removeBounceAnimation() {
        self.removeAnimation(forKey: "bounceAnimation")
    }
}
