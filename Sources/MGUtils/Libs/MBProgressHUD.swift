//
//  MBProgressHUD.swift
//  Version 1.2.0
//  Swift version of MBProgressHUD
//  Complete implementation in a single file
//

import UIKit
import CoreGraphics

// MARK: - Constants and Types

public let MBProgressMaxOffset: CGFloat = 1000000.0

private let MBDefaultPadding: CGFloat = 4.0
private let MBDefaultLabelFontSize: CGFloat = 16.0
private let MBDefaultDetailsLabelFontSize: CGFloat = 12.0

public enum MBProgressHUDMode: Int {
    case indeterminate
    case determinate
    case determinateHorizontalBar
    case annularDeterminate
    case customView
    case text
}

public enum MBProgressHUDAnimation: Int {
    case fade
    case zoom
    case zoomOut
    case zoomIn
}

public enum MBProgressHUDBackgroundStyle: Int {
    case solidColor
    case blur
}

public typealias MBProgressHUDCompletionBlock = () -> Void

// MARK: - Protocols

@objc public protocol MBProgressHUDDelegate: AnyObject {
    @objc optional func hudWasHidden(_ hud: MBProgressHUD)
}

protocol ProgressViewProtocol: AnyObject {
    var progress: Float { get set }
}

// MARK: - MBProgressHUD Main Class

public class MBProgressHUD: UIView {
    
    // MARK: - Properties
    
    public weak var delegate: MBProgressHUDDelegate?
    public var completionBlock: MBProgressHUDCompletionBlock?
    
    public var graceTime: TimeInterval = 0.0
    public var minShowTime: TimeInterval = 0.0
    public var removeFromSuperViewOnHide: Bool = false
    
    public var mode: MBProgressHUDMode = .indeterminate {
        didSet {
            if mode != oldValue {
                updateIndicators()
            }
        }
    }
    
    public var contentColor: UIColor? {
        didSet {
            if let color = contentColor, label != nil {
                updateViews(for: color)
            }
        }
    }
    
    public var animationType: MBProgressHUDAnimation = .fade
    public var offset: CGPoint = .zero {
        didSet {
            if !CGPointEqualToPoint(offset, oldValue) {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var margin: CGFloat = 20.0 {
        didSet {
            if margin != oldValue {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var minSize: CGSize = .zero {
        didSet {
            if !CGSizeEqualToSize(minSize, oldValue) {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var isSquare: Bool = false {
        didSet {
            if isSquare != oldValue {
                setNeedsUpdateConstraints()
            }
        }
    }
    
    public var areDefaultMotionEffectsEnabled: Bool = false {
        didSet {
            if areDefaultMotionEffectsEnabled != oldValue {
                updateBezelMotionEffects()
            }
        }
    }
    
    public var progress: Float = 0.0 {
        didSet {
            if progress != oldValue {
                updateProgressValue()
            }
        }
    }
    
    public var progressObject: Progress? {
        didSet {
            if progressObject != oldValue {
                setNSProgressDisplayLinkEnabled(true)
            }
        }
    }
    
    public private(set) var bezelView: MBBackgroundView!
    public private(set) var backgroundView: MBBackgroundView!
    public var customView: UIView? {
        didSet {
            if customView != oldValue && mode == .customView {
                updateIndicators()
            }
        }
    }
    
    public private(set) var label: UILabel!
    public private(set) var detailsLabel: UILabel!
    public private(set) var button: UIButton!
    
    // MARK: - Private Properties
    
    private var useAnimation: Bool = false
    private var hasFinished: Bool = false
    private var indicator: UIView?
    private var showStarted: Date?
    private var paddingConstraints: [NSLayoutConstraint] = []
    private var bezelConstraints: [NSLayoutConstraint] = []
    private var topSpacer: UIView!
    private var bottomSpacer: UIView!
    private var bezelMotionEffects: UIMotionEffectGroup?
    
    private weak var graceTimer: Timer?
    private weak var minShowTimer: Timer?
    private weak var hideDelayTimer: Timer?
    private var progressObjectDisplayLink: CADisplayLink? {
        didSet {
            oldValue?.invalidate()
            progressObjectDisplayLink?.add(to: .main, forMode: .default)
        }
    }
    
    // MARK: - Class Methods
    
    @discardableResult
    public class func showHUDAddedTo(_ view: UIView, animated: Bool) -> MBProgressHUD {
        let hud = MBProgressHUD(view: view)
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(animated: animated)
        return hud
    }
    
    @discardableResult
    public class func hideHUDForView(_ view: UIView, animated: Bool) -> Bool {
        if let hud = HUDForView(view) {
            hud.removeFromSuperViewOnHide = true
            hud.hide(animated: animated)
            return true
        }
        return false
    }
    
    public class func HUDForView(_ view: UIView) -> MBProgressHUD? {
        for subview in view.subviews.reversed() {
            if let hud = subview as? MBProgressHUD, !hud.hasFinished {
                return hud
            }
        }
        return nil
    }
    
    // MARK: - Lifecycle
    
    public convenience init(view: UIView) {
        self.init(frame: view.bounds)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        animationType = .fade
        mode = .indeterminate
        margin = 20.0
        areDefaultMotionEffectsEnabled = false
        
        if #available(iOS 13.0, *) {
            contentColor = UIColor.label.withAlphaComponent(0.7)
        } else {
            contentColor = UIColor(white: 0.0, alpha: 0.7)
        }
        
        isOpaque = false
        backgroundColor = .clear
        alpha = 0.0
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layer.allowsGroupOpacity = false
        
        setupViews()
        registerForNotifications()
        updateIndicators()
    }
    
    deinit {
        unregisterFromNotifications()
    }
    
    // MARK: - Show & Hide
    
    public func show(animated: Bool) {
        assert(Thread.isMainThread, "MBProgressHUD needs to be accessed on the main thread.")
        
        minShowTimer?.invalidate()
        useAnimation = animated
        hasFinished = false
        
        if graceTime > 0.0 {
            graceTimer = Timer.scheduledTimer(withTimeInterval: graceTime, repeats: false) { [weak self] _ in
                self?.handleGraceTimer()
            }
        } else {
            showUsingAnimation(useAnimation)
        }
    }
    
    public func hide(animated: Bool) {
        assert(Thread.isMainThread, "MBProgressHUD needs to be accessed on the main thread.")
        
        graceTimer?.invalidate()
        useAnimation = animated
        hasFinished = true
        
        if minShowTime > 0.0, let showStarted = showStarted {
            let interval = Date().timeIntervalSince(showStarted)
            if interval < minShowTime {
                minShowTimer = Timer.scheduledTimer(withTimeInterval: minShowTime - interval, repeats: false) { [weak self] _ in
                    self?.handleMinShowTimer()
                }
                return
            }
        }
        
        hideUsingAnimation(useAnimation)
    }
    
    public func hide(animated: Bool, afterDelay delay: TimeInterval) {
        hideDelayTimer?.invalidate()
        hideDelayTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.hide(animated: animated)
        }
    }
    
    // MARK: - Timer Callbacks
    
    private func handleGraceTimer() {
        if !hasFinished {
            showUsingAnimation(useAnimation)
        }
    }
    
    private func handleMinShowTimer() {
        hideUsingAnimation(useAnimation)
    }
    
    // MARK: - Internal Show & Hide Operations
    
    private func showUsingAnimation(_ animated: Bool) {
        bezelView.layer.removeAllAnimations()
        backgroundView.layer.removeAllAnimations()
        
        hideDelayTimer?.invalidate()
        
        showStarted = Date()
        alpha = 1.0
        
        setNSProgressDisplayLinkEnabled(true)
        updateBezelMotionEffects()
        
        if animated {
            animateIn(true, withType: animationType, completion: nil)
        } else {
            bezelView.alpha = 1.0
            backgroundView.alpha = 1.0
        }
    }
    
    private func hideUsingAnimation(_ animated: Bool) {
        hideDelayTimer?.invalidate()
        
        if animated && showStarted != nil {
            showStarted = nil
            animateIn(false, withType: animationType) { [weak self] _ in
                self?.done()
            }
        } else {
            showStarted = nil
            bezelView.alpha = 0.0
            backgroundView.alpha = 1.0
            done()
        }
    }
    
    private func animateIn(_ animatingIn: Bool, withType type: MBProgressHUDAnimation, completion: ((Bool) -> Void)?) {
        var animationType = type
        
        if type == .zoom {
            animationType = animatingIn ? .zoomIn : .zoomOut
        }
        
        let small = CGAffineTransform(scaleX: 0.5, y: 0.5)
        let large = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        if animatingIn && bezelView.alpha == 0.0 && animationType == .zoomIn {
            bezelView.transform = small
        } else if animatingIn && bezelView.alpha == 0.0 && animationType == .zoomOut {
            bezelView.transform = large
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .beginFromCurrentState, animations: {
            if animatingIn {
                self.bezelView.transform = .identity
            } else if !animatingIn && animationType == .zoomIn {
                self.bezelView.transform = large
            } else if !animatingIn && animationType == .zoomOut {
                self.bezelView.transform = small
            }
            
            let alpha: CGFloat = animatingIn ? 1.0 : 0.0
            self.bezelView.alpha = alpha
            self.backgroundView.alpha = alpha
        }, completion: completion)
    }
    
    private func done() {
        setNSProgressDisplayLinkEnabled(false)
        
        if hasFinished {
            alpha = 0.0
            if removeFromSuperViewOnHide {
                removeFromSuperview()
            }
        }
        
        completionBlock?()
        delegate?.hudWasHidden?(self)
    }
    
    // MARK: - UI Setup
    
    private func setupViews() {
        let defaultColor = contentColor ?? UIColor.white
        
        // Background view
        backgroundView = MBBackgroundView(frame: bounds)
        backgroundView.style = .solidColor
        backgroundView.backgroundColor = .clear
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundView.alpha = 0.0
        addSubview(backgroundView)
        
        // Bezel view
        bezelView = MBBackgroundView()
        bezelView.translatesAutoresizingMaskIntoConstraints = false
        bezelView.layer.cornerRadius = 5.0
        bezelView.alpha = 0.0
        addSubview(bezelView)
        
        // Label
        label = UILabel()
        label.adjustsFontSizeToFitWidth = false
        label.textAlignment = .center
        label.textColor = defaultColor
        label.font = UIFont.boldSystemFont(ofSize: MBDefaultLabelFontSize)
        label.isOpaque = false
        label.backgroundColor = .clear
        
        // Details label
        detailsLabel = UILabel()
        detailsLabel.adjustsFontSizeToFitWidth = false
        detailsLabel.textAlignment = .center
        detailsLabel.textColor = defaultColor
        detailsLabel.numberOfLines = 0
        detailsLabel.font = UIFont.boldSystemFont(ofSize: MBDefaultDetailsLabelFontSize)
        detailsLabel.isOpaque = false
        detailsLabel.backgroundColor = .clear
        
        // Button
        button = MBProgressHUDRoundedButton(type: .custom)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: MBDefaultDetailsLabelFontSize)
        button.setTitleColor(defaultColor, for: .normal)
        
        let views = [label!, detailsLabel!, button!]
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(.init(998), for: .horizontal)
            view.setContentCompressionResistancePriority(.init(998), for: .vertical)
            bezelView.addSubview(view)
        }
        
        // Spacers
        topSpacer = UIView()
        topSpacer.translatesAutoresizingMaskIntoConstraints = false
        topSpacer.isHidden = true
        bezelView.addSubview(topSpacer)
        
        bottomSpacer = UIView()
        bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
        bottomSpacer.isHidden = true
        bezelView.addSubview(bottomSpacer)
    }
    
    private func updateIndicators() {
        indicator?.removeFromSuperview()
        
        let isActivityIndicator = indicator is UIActivityIndicatorView
        let isRoundIndicator = indicator is MBRoundProgressView
        
        switch mode {
        case .indeterminate:
            if !isActivityIndicator {
                let activityIndicator: UIActivityIndicatorView
                if #available(iOS 13.0, *) {
                    activityIndicator = UIActivityIndicatorView(style: .large)
                    activityIndicator.color = .white
                } else {
                    activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
                }
                activityIndicator.startAnimating()
                indicator = activityIndicator
                bezelView.addSubview(activityIndicator)
            }
            
        case .determinateHorizontalBar:
            indicator = MBBarProgressView()
            bezelView.addSubview(indicator!)
            
        case .determinate, .annularDeterminate:
            if !isRoundIndicator {
                let roundProgressView = MBRoundProgressView()
                indicator = roundProgressView
                bezelView.addSubview(roundProgressView)
            }
            if mode == .annularDeterminate {
                (indicator as? MBRoundProgressView)?.isAnnular = true
            }
            
        case .customView:
            if let customView = customView, customView != indicator {
                indicator = customView
                bezelView.addSubview(customView)
            }
            
        case .text:
            indicator = nil
        }
        
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        
        updateProgressValue()
        
        indicator?.setContentCompressionResistancePriority(.init(998), for: .horizontal)
        indicator?.setContentCompressionResistancePriority(.init(998), for: .vertical)
        
        if label != nil {
            updateViews(for: contentColor ?? UIColor.white)
        }
        setNeedsUpdateConstraints()
    }
    
    private func updateViews(for color: UIColor) {
        label?.textColor = color
        detailsLabel?.textColor = color
        button?.setTitleColor(color, for: .normal)
        
        if let activityIndicator = indicator as? UIActivityIndicatorView {
            activityIndicator.color = color
        } else if let roundProgressView = indicator as? MBRoundProgressView {
            roundProgressView.progressTintColor = color
            roundProgressView.backgroundTintColor = color.withAlphaComponent(0.1)
        } else if let barProgressView = indicator as? MBBarProgressView {
            barProgressView.progressColor = color
            barProgressView.lineColor = color
        } else {
            indicator?.tintColor = color
        }
    }
    
    private func updateBezelMotionEffects() {
        if let motionEffects = bezelMotionEffects {
            bezelView.removeMotionEffect(motionEffects)
            bezelMotionEffects = nil
        }
        
        if areDefaultMotionEffectsEnabled {
            let effectOffset: CGFloat = 10.0
            
            let effectX = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
            effectX.maximumRelativeValue = effectOffset
            effectX.minimumRelativeValue = -effectOffset
            
            let effectY = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
            effectY.maximumRelativeValue = effectOffset
            effectY.minimumRelativeValue = -effectOffset
            
            let group = UIMotionEffectGroup()
            group.motionEffects = [effectX, effectY]
            
            bezelMotionEffects = group
            bezelView.addMotionEffect(group)
        }
    }
    
    // MARK: - Progress Update
    
    private func updateProgressValue() {
        if let roundProgressView = indicator as? MBRoundProgressView {
            roundProgressView.progress = progress
        } else if let barProgressView = indicator as? MBBarProgressView {
            barProgressView.progress = progress
        }
    }
    
    // MARK: - NSProgress
    
    private func setNSProgressDisplayLinkEnabled(_ enabled: Bool) {
        if enabled && progressObject != nil {
            if progressObjectDisplayLink == nil {
                progressObjectDisplayLink = CADisplayLink(target: self, selector: #selector(updateProgressFromProgressObject))
            }
        } else {
            progressObjectDisplayLink = nil
        }
    }
    
    @objc private func updateProgressFromProgressObject() {
        progress = Float(progressObject?.fractionCompleted ?? 0.0)
    }
    
    // MARK: - Notifications
    
    private func registerForNotifications() {
        #if !os(tvOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(statusBarOrientationDidChange),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil
        )
        #endif
    }
    
    private func unregisterFromNotifications() {
        #if !os(tvOS)
        NotificationCenter.default.removeObserver(self)
        #endif
    }
    
    #if !os(tvOS)
    @objc private func statusBarOrientationDidChange(_ notification: Notification) {
        if superview != nil {
            updateForCurrentOrientation(animated: true)
        }
    }
    #endif
    
    private func updateForCurrentOrientation(animated: Bool) {
        if let superview = superview {
            frame = superview.bounds
        }
    }
    
    // MARK: - Layout
    
    public override func updateConstraints() {
        let bezel = bezelView!
        let topSpacer = self.topSpacer!
        let bottomSpacer = self.bottomSpacer!
        let margin = self.margin
        var bezelConstraints: [NSLayoutConstraint] = []
        
        var subviews = [topSpacer, label!, detailsLabel!, button!, bottomSpacer]
        if let indicator = indicator {
            subviews.insert(indicator, at: 1)
        }
        
        // Remove existing constraints
        removeConstraints(constraints)
        topSpacer.removeConstraints(topSpacer.constraints)
        bottomSpacer.removeConstraints(bottomSpacer.constraints)
        if !self.bezelConstraints.isEmpty {
            bezel.removeConstraints(self.bezelConstraints)
            self.bezelConstraints.removeAll()
        }
        
        // Center bezel in container
        let centeringConstraints = [
            bezel.centerXAnchor.constraint(equalTo: centerXAnchor, constant: offset.x),
            bezel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: offset.y)
        ]
        centeringConstraints.forEach { $0.priority = UILayoutPriority(998) }
        addConstraints(centeringConstraints)
        
        // Ensure minimum side margin
        let sideConstraints = [
            bezel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: margin),
            trailingAnchor.constraint(greaterThanOrEqualTo: bezel.trailingAnchor, constant: margin),
            bezel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: margin),
            bottomAnchor.constraint(greaterThanOrEqualTo: bezel.bottomAnchor, constant: margin)
        ]
        sideConstraints.forEach { $0.priority = UILayoutPriority(999) }
        addConstraints(sideConstraints)
        
        // Minimum bezel size
        if !CGSizeEqualToSize(minSize, .zero) {
            let minSizeConstraints = [
                bezel.widthAnchor.constraint(greaterThanOrEqualToConstant: minSize.width),
                bezel.heightAnchor.constraint(greaterThanOrEqualToConstant: minSize.height)
            ]
            minSizeConstraints.forEach { $0.priority = UILayoutPriority(997) }
            bezelConstraints.append(contentsOf: minSizeConstraints)
        }
        
        // Square aspect ratio
        if isSquare {
            let square = bezel.heightAnchor.constraint(equalTo: bezel.widthAnchor)
            square.priority = UILayoutPriority(997)
            bezelConstraints.append(square)
        }
        
        // Top and bottom spacing
        topSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: margin).isActive = true
        bottomSpacer.heightAnchor.constraint(greaterThanOrEqualToConstant: margin).isActive = true
        bezelConstraints.append(topSpacer.heightAnchor.constraint(equalTo: bottomSpacer.heightAnchor))
        
        // Layout subviews in bezel
        var paddingConstraints: [NSLayoutConstraint] = []
        for (index, view) in subviews.enumerated() {
            // Center in bezel
            bezelConstraints.append(view.centerXAnchor.constraint(equalTo: bezel.centerXAnchor))
            
            // Ensure minimum edge margin
            bezelConstraints.append(view.leadingAnchor.constraint(greaterThanOrEqualTo: bezel.leadingAnchor, constant: margin))
            bezelConstraints.append(bezel.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor, constant: margin))
            
            // Element spacing
            if index == 0 {
                bezelConstraints.append(view.topAnchor.constraint(equalTo: bezel.topAnchor))
            } else if index == subviews.count - 1 {
                bezelConstraints.append(view.bottomAnchor.constraint(equalTo: bezel.bottomAnchor))
            }
            
            if index > 0 {
                let padding = view.topAnchor.constraint(equalTo: subviews[index - 1].bottomAnchor)
                bezelConstraints.append(padding)
                paddingConstraints.append(padding)
            }
        }
        
        bezel.addConstraints(bezelConstraints)
        self.bezelConstraints = bezelConstraints
        self.paddingConstraints = paddingConstraints
        
        updatePaddingConstraints()
        super.updateConstraints()
    }
    
    public override func layoutSubviews() {
        if !needsUpdateConstraints() {
            updatePaddingConstraints()
        }
        super.layoutSubviews()
    }
    
    private func updatePaddingConstraints() {
        var hasVisibleAncestors = false
        for padding in paddingConstraints {
            guard let firstView = padding.firstItem as? UIView,
                  let secondView = padding.secondItem as? UIView else { continue }
            
            let firstVisible = !firstView.isHidden && !CGSizeEqualToSize(firstView.intrinsicContentSize, .zero)
            let secondVisible = !secondView.isHidden && !CGSizeEqualToSize(secondView.intrinsicContentSize, .zero)
            
            padding.constant = (firstVisible && (secondVisible || hasVisibleAncestors)) ? MBDefaultPadding : 0.0
            hasVisibleAncestors = hasVisibleAncestors || secondVisible
        }
    }
    
    public override func didMoveToSuperview() {
        updateForCurrentOrientation(animated: false)
    }
}

// MARK: - MBRoundProgressView

public class MBRoundProgressView: UIView, ProgressViewProtocol {
    
    public var progress: Float = 0.0 {
        didSet {
            if progress != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var progressTintColor: UIColor = UIColor(white: 1.0, alpha: 1.0) {
        didSet {
            if progressTintColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var backgroundTintColor: UIColor = UIColor(white: 1.0, alpha: 0.1) {
        didSet {
            if backgroundTintColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var isAnnular: Bool = false {
        didSet {
            if isAnnular != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 37, height: 37))
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
    }
    
    // MARK: - Layout
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 37, height: 37)
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if isAnnular {
            // Draw background
            let lineWidth: CGFloat = 2.0
            let processBackgroundPath = UIBezierPath()
            processBackgroundPath.lineWidth = lineWidth
            processBackgroundPath.lineCapStyle = .butt
            
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = (bounds.width - lineWidth) / 2
            let startAngle = -CGFloat.pi / 2 // 90 degrees
            let endAngle = (2 * CGFloat.pi) + startAngle
            
            processBackgroundPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            backgroundTintColor.set()
            processBackgroundPath.stroke()
            
            // Draw progress
            let processPath = UIBezierPath()
            processPath.lineCapStyle = .square
            processPath.lineWidth = lineWidth
            let progressEndAngle = (CGFloat(progress) * 2 * CGFloat.pi) + startAngle
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: progressEndAngle, clockwise: true)
            progressTintColor.set()
            processPath.stroke()
            
        } else {
            // Draw background
            let lineWidth: CGFloat = 2.0
            let allRect = bounds
            let circleRect = allRect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            
            progressTintColor.setStroke()
            backgroundTintColor.setFill()
            context.setLineWidth(lineWidth)
            context.strokeEllipse(in: circleRect)
            
            // 90 degrees
            let startAngle = -CGFloat.pi / 2
            
            // Draw progress
            let processPath = UIBezierPath()
            processPath.lineCapStyle = .butt
            processPath.lineWidth = lineWidth * 2
            let radius = (bounds.width / 2) - (processPath.lineWidth / 2)
            let endAngle = (CGFloat(progress) * 2 * CGFloat.pi) + startAngle
            processPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            // Ensure that we don't get color overlapping when progressTintColor alpha < 1.0
            context.setBlendMode(.copy)
            progressTintColor.set()
            processPath.stroke()
        }
    }
}

// MARK: - MBBarProgressView

public class MBBarProgressView: UIView, ProgressViewProtocol {
    
    public var progress: Float = 0.0 {
        didSet {
            if progress != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var lineColor: UIColor = .white {
        didSet {
            if lineColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var progressRemainingColor: UIColor = .clear {
        didSet {
            if progressRemainingColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    public var progressColor: UIColor = .white {
        didSet {
            if progressColor != oldValue {
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 120, height: 20))
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
    }
    
    // MARK: - Layout
    
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 120, height: 10)
    }
    
    // MARK: - Drawing
    
    public override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineWidth(2)
        context.setStrokeColor(lineColor.cgColor)
        context.setFillColor(progressRemainingColor.cgColor)
        
        // Draw background and Border
        let radius = (rect.height / 2) - 2
        context.move(to: CGPoint(x: 2, y: rect.height / 2))
        context.addArc(tangent1End: CGPoint(x: 2, y: 2), tangent2End: CGPoint(x: radius + 2, y: 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.width - 2, y: 2), tangent2End: CGPoint(x: rect.width - 2, y: rect.height / 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x: rect.width - 2, y: rect.height - 2), tangent2End: CGPoint(x: rect.width - radius - 2, y: rect.height - 2), radius: radius)
        context.addArc(tangent1End: CGPoint(x: 2, y: rect.height - 2), tangent2End: CGPoint(x: 2, y: rect.height / 2), radius: radius)
        context.drawPath(using: .fillStroke)
        
        context.setFillColor(progressColor.cgColor)
        let progressRadius = radius - 2
        let amount = CGFloat(progress) * rect.width
        
        // Progress in the middle area
        if amount >= progressRadius + 4 && amount <= (rect.width - progressRadius - 4) {
            context.move(to: CGPoint(x: 4, y: rect.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: progressRadius + 4, y: 4), radius: progressRadius)
            context.addLine(to: CGPoint(x: amount, y: 4))
            context.addLine(to: CGPoint(x: amount, y: progressRadius + 4))
            
            context.move(to: CGPoint(x: 4, y: rect.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.height - 4), tangent2End: CGPoint(x: progressRadius + 4, y: rect.height - 4), radius: progressRadius)
            context.addLine(to: CGPoint(x: amount, y: rect.height - 4))
            context.addLine(to: CGPoint(x: amount, y: progressRadius + 4))
            
            context.fillPath()
        }
        // Progress in the right arc
        else if amount > progressRadius + 4 {
            let x = amount - (rect.width - progressRadius - 4)
            
            context.move(to: CGPoint(x: 4, y: rect.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: progressRadius + 4, y: 4), radius: progressRadius)
            context.addLine(to: CGPoint(x: rect.width - progressRadius - 4, y: 4))
            var angle = -acos(x / progressRadius)
            if angle.isNaN { angle = 0 }
            context.addArc(center: CGPoint(x: rect.width - progressRadius - 4, y: rect.height / 2), radius: progressRadius, startAngle: .pi, endAngle: angle, clockwise: false)
            context.addLine(to: CGPoint(x: amount, y: rect.height / 2))
            
            context.move(to: CGPoint(x: 4, y: rect.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.height - 4), tangent2End: CGPoint(x: progressRadius + 4, y: rect.height - 4), radius: progressRadius)
            context.addLine(to: CGPoint(x: rect.width - progressRadius - 4, y: rect.height - 4))
            angle = acos(x / progressRadius)
            if angle.isNaN { angle = 0 }
            context.addArc(center: CGPoint(x: rect.width - progressRadius - 4, y: rect.height / 2), radius: progressRadius, startAngle: -.pi, endAngle: angle, clockwise: true)
            context.addLine(to: CGPoint(x: amount, y: rect.height / 2))
            
            context.fillPath()
        }
        // Progress is in the left arc
        else if amount < progressRadius + 4 && amount > 0 {
            context.move(to: CGPoint(x: 4, y: rect.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: 4), tangent2End: CGPoint(x: progressRadius + 4, y: 4), radius: progressRadius)
            context.addLine(to: CGPoint(x: progressRadius + 4, y: rect.height / 2))
            
            context.move(to: CGPoint(x: 4, y: rect.height / 2))
            context.addArc(tangent1End: CGPoint(x: 4, y: rect.height - 4), tangent2End: CGPoint(x: progressRadius + 4, y: rect.height - 4), radius: progressRadius)
            context.addLine(to: CGPoint(x: progressRadius + 4, y: rect.height / 2))
            
            context.fillPath()
        }
    }
}

// MARK: - MBBackgroundView

public class MBBackgroundView: UIView {
    
    public var style: MBProgressHUDBackgroundStyle = .blur {
        didSet {
            if style != oldValue {
                updateForBackgroundStyle()
            }
        }
    }
    
    public var blurEffectStyle: UIBlurEffect.Style = {
        if #available(iOS 13.0, *) {
            #if os(tvOS)
            return .regular
            #else
            return .systemThickMaterial
            #endif
        } else {
            return .light
        }
    }() {
        didSet {
            if blurEffectStyle != oldValue {
                updateForBackgroundStyle()
            }
        }
    }
    
    public var color: UIColor? {
        didSet {
            if let color = color {
                updateViews(for: color)
            }
        }
    }
    
    private var effectView: UIVisualEffectView?
    
    // MARK: - Lifecycle
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        if #available(iOS 13.0, *) {
            // Leaving the color unassigned yields best results on iOS 13+
        } else {
            color = UIColor(white: 0.8, alpha: 0.6)
        }
        
        clipsToBounds = true
        updateForBackgroundStyle()
    }
    
    // MARK: - Layout
    
    public override var intrinsicContentSize: CGSize {
        return .zero // Smallest size possible. Content pushes against this.
    }
    
    // MARK: - Appearance
    
    private func updateForBackgroundStyle() {
        effectView?.removeFromSuperview()
        effectView = nil
        
        if style == .blur {
            let effect = UIBlurEffect(style: blurEffectStyle)
            let newEffectView = UIVisualEffectView(effect: effect)
            insertSubview(newEffectView, at: 0)
            newEffectView.frame = bounds
            newEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            backgroundColor = color
            layer.allowsGroupOpacity = false
            effectView = newEffectView
        } else {
            backgroundColor = color
        }
    }
    
    private func updateViews(for color: UIColor) {
        backgroundColor = color
    }
}

// MARK: - MBProgressHUDRoundedButton

class MBProgressHUDRoundedButton: UIButton {
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        layer.borderWidth = 1.0
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Fully rounded corners
        let height = bounds.height
        layer.cornerRadius = ceil(height / 2)
    }
    
    override var intrinsicContentSize: CGSize {
        // Only show if we have associated control events and a title
        if allControlEvents.isEmpty || (title(for: .normal)?.isEmpty ?? true) {
            return .zero
        }
        var size = super.intrinsicContentSize
        // Add some side padding
        size.width += 20
        return size
    }
    
    // MARK: - Color
    
    override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        super.setTitleColor(color, for: state)
        // Update related colors
        isHighlighted = isHighlighted
        layer.borderColor = color?.cgColor
    }
    
    override var isHighlighted: Bool {
        didSet {
            let baseColor = titleColor(for: .selected) ?? .clear
            backgroundColor = isHighlighted ? baseColor.withAlphaComponent(0.1) : .clear
        }
    }
}

// MARK: - Extensions

extension MBProgressHUD {
    
    /// 显示加载中提示
    /// - Parameters:
    ///   - view: 父视图
    ///   - text: 提示文字
    /// - Returns: MBProgressHUD实例
    @discardableResult
    public static func showLoading(in view: UIView, text: String = "加载中...") -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = .indeterminate
        hud.label.text = text
        return hud
    }
    
    /// 显示成功提示
    /// - Parameters:
    ///   - view: 父视图
    ///   - text: 提示文字
    ///   - delay: 延迟隐藏时间
    @discardableResult
    public static func showSuccess(in view: UIView, text: String, delay: TimeInterval = 2.0) -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = .customView
        hud.customView = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        hud.label.text = text
        hud.hide(animated: true, afterDelay: delay)
        return hud
    }
    
    /// 显示错误提示
    /// - Parameters:
    ///   - view: 父视图
    ///   - text: 提示文字
    ///   - delay: 延迟隐藏时间
    @discardableResult
    public static func showError(in view: UIView, text: String, delay: TimeInterval = 2.0) -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = .customView
        hud.customView = UIImageView(image: UIImage(systemName: "xmark.circle.fill"))
        hud.label.text = text
        hud.hide(animated: true, afterDelay: delay)
        return hud
    }
    
    /// 显示纯文字提示
    /// - Parameters:
    ///   - view: 父视图
    ///   - text: 提示文字
    ///   - delay: 延迟隐藏时间
    @discardableResult
    public static func showText(in view: UIView, text: String, delay: TimeInterval = 2.0) -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = .text
        hud.label.text = text
        hud.hide(animated: true, afterDelay: delay)
        return hud
    }
    
    /// 显示进度条
    /// - Parameters:
    ///   - view: 父视图
    ///   - text: 提示文字
    ///   - progress: 进度值 (0.0 - 1.0)
    /// - Returns: MBProgressHUD实例
    @discardableResult
    public static func showProgress(in view: UIView, text: String = "进度", progress: Float = 0.0) -> MBProgressHUD {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = .determinate
        hud.label.text = text
        hud.progress = progress
        return hud
    }
    
    /// 隐藏指定视图中的所有HUD
    /// - Parameter view: 父视图
    public static func hideAll(in view: UIView) {
        MBProgressHUD.hideHUDForView(view, animated: true)
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    
    /// 在当前视图控制器中显示加载HUD
    @discardableResult
    public func showLoadingHUD(text: String = "加载中...") -> MBProgressHUD {
        return MBProgressHUD.showLoading(in: view, text: text)
    }
    
    /// 在当前视图控制器中显示成功HUD
    @discardableResult
    public func showSuccessHUD(text: String, delay: TimeInterval = 2.0) -> MBProgressHUD {
        return MBProgressHUD.showSuccess(in: view, text: text, delay: delay)
    }
    
    /// 在当前视图控制器中显示错误HUD
    @discardableResult
    public func showErrorHUD(text: String, delay: TimeInterval = 2.0) -> MBProgressHUD {
        return MBProgressHUD.showError(in: view, text: text, delay: delay)
    }
    
    /// 在当前视图控制器中显示文字HUD
    @discardableResult
    public func showTextHUD(text: String, delay: TimeInterval = 2.0) -> MBProgressHUD {
        return MBProgressHUD.showText(in: view, text: text, delay: delay)
    }
    
    /// 隐藏当前视图控制器中的所有HUD
    public func hideAllHUDs() {
        MBProgressHUD.hideAll(in: view)
    }
}

/*
 使用示例：
 
 // 1. 显示加载中
 let hud = MBProgressHUD.showLoading(in: self.view, text: "正在加载...")
 
 // 2. 显示成功提示
 MBProgressHUD.showSuccess(in: self.view, text: "操作成功")
 
 // 3. 显示错误提示
 MBProgressHUD.showError(in: self.view, text: "操作失败")
 
 // 4. 显示纯文字
 MBProgressHUD.showText(in: self.view, text: "这是一条提示信息")
 
 // 5. 显示进度条
 let progressHUD = MBProgressHUD.showProgress(in: self.view, text: "下载中", progress: 0.5)
 
 // 6. 手动隐藏
 hud.hide(animated: true)
 
 // 7. 隐藏所有HUD
 MBProgressHUD.hideAll(in: self.view)
 
 // 8. 使用UIViewController扩展
 self.showLoadingHUD(text: "加载中...")
 self.showSuccessHUD(text: "成功")
 self.hideAllHUDs()
 
 // 9. 自定义配置
 let customHUD = MBProgressHUD(view: self.view)
 customHUD.mode = .indeterminate
 customHUD.label.text = "自定义HUD"
 customHUD.detailsLabel.text = "详细信息"
 customHUD.margin = 10.0
 customHUD.offset = CGPoint(x: 0, y: -50)
 customHUD.removeFromSuperViewOnHide = true
 self.view.addSubview(customHUD)
 customHUD.show(animated: true)
 
 // 10. 使用代理
 class MyViewController: UIViewController, MBProgressHUDDelegate {
     func showHUDWithDelegate() {
         let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
         hud.delegate = self
         hud.label.text = "处理中..."
     }
     
     func hudWasHidden(_ hud: MBProgressHUD) {
         print("HUD已隐藏")
     }
 }
 
 // 11. 使用完成回调
 let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
 hud.completionBlock = {
     print("HUD隐藏完成")
 }
 hud.hide(animated: true, afterDelay: 2.0)
 
 */
