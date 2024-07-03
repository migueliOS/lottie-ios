//
//  File.swift
//  
//
//  Created by Miguel Lorenzo on 3/7/2024.
//

import Foundation

import QuartzCore

/**
 The base animation container.

 This layer holds a single composition container and allows for animation of
 the currentFrame property.
 */
public final class AnimationContainer: CALayer {

  /// The animatable Current Frame Property
  @NSManaged public var currentFrame: CGFloat

  var imageProvider: AnimationImageProvider {
    get {
      return coreAnimationLayer.imageProvider
    }
    set {
      coreAnimationLayer.imageProvider = newValue
    }
  }

  func reloadImages() {
    coreAnimationLayer.reloadImages()
  }

  var renderScale: CGFloat = 1 {
    didSet {
      coreAnimationLayer.renderScale = renderScale
    }
  }

  public var respectAnimationFrameRate: Bool {
    get { return coreAnimationLayer.respectAnimationFrameRate }
    set { coreAnimationLayer.respectAnimationFrameRate = newValue }
  }

  /// Forces the view to update its drawing.
  public func forceDisplayUpdate() {
    coreAnimationLayer.forceDisplayUpdate()
  }

  func logHierarchyKeypaths() {
    coreAnimationLayer.logHierarchyKeypaths()
  }

  func setValueProvider(_ valueProvider: AnyValueProvider, keypath: AnimationKeypath) {
    coreAnimationLayer.setValueProvider(valueProvider, keypath: keypath)
  }

  func getValue(for keypath: AnimationKeypath, atFrame: CGFloat?) -> Any? {
    return coreAnimationLayer.getValue(for: keypath, atFrame: atFrame)
  }

  func layer(for keypath: AnimationKeypath) -> CALayer? {
    return coreAnimationLayer.layer(for: keypath)
  }

  func animatorNodes(for keypath: AnimationKeypath) -> [AnimatorNode]? {
    return coreAnimationLayer.animatorNodes(for: keypath)
  }

  var textProvider: AnimationKeypathTextProvider {
    get { return coreAnimationLayer.textProvider }
    set { coreAnimationLayer.textProvider = newValue }
  }

  var fontProvider: AnimationFontProvider {
    get { return coreAnimationLayer.fontProvider }
    set { coreAnimationLayer.fontProvider = newValue }
  }

  var coreAnimationLayer: CoreAnimationLayer

  public init(animation: LottieAnimation, imageProvider: AnimationImageProvider, textProvider: AnimationKeypathTextProvider, fontProvider: AnimationFontProvider) {
    do {
      self.coreAnimationLayer = try CoreAnimationLayer(
        animation: animation,
        imageProvider: imageProvider,
        textProvider: textProvider,
        fontProvider: fontProvider,
        maskAnimationToBounds: false,
        compatibilityTrackerMode: .track,
        logger: .shared)
    } catch {
      fatalError("Failed to initialize CoreAnimationLayer: \(error)")
    }
    super.init()
    bounds = animation.bounds
    coreAnimationLayer.bounds = bounds
    addSublayer(coreAnimationLayer)
    setNeedsDisplay()
  }

  /// For CAAnimation Use
  public override init(layer: Any) {
    if let animationLayer = layer as? AnimationContainer {
      self.coreAnimationLayer = animationLayer.coreAnimationLayer
    } else {
      self.coreAnimationLayer = try! CoreAnimationLayer(
        animation: LottieAnimation.init(dictionary: [:]),
        imageProvider: BlankImageProvider(),
        textProvider: DefaultTextProvider(),
        fontProvider: DefaultFontProvider(),
        maskAnimationToBounds: false,
        compatibilityTrackerMode: .track,
        logger: .shared)
    }
    super.init(layer: layer)
    currentFrame = coreAnimationLayer.currentFrame
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: CALayer Animations

  override public class func needsDisplay(forKey key: String) -> Bool {
    if key == "currentFrame" {
      return true
    }
    return super.needsDisplay(forKey: key)
  }

  override public func action(forKey event: String) -> CAAction? {
    if event == "currentFrame" {
      let animation = CABasicAnimation(keyPath: event)
      animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
      animation.fromValue = self.presentation()?.currentFrame
      return animation
    }
    return super.action(forKey: event)
  }

  public override func display() {
    guard Thread.isMainThread else { return }
    var newFrame: CGFloat
    if let animationKeys = self.animationKeys(), !animationKeys.isEmpty {
      newFrame = self.presentation()?.currentFrame ?? self.currentFrame
    } else {
      newFrame = self.currentFrame
    }
    if respectAnimationFrameRate {
      newFrame = floor(newFrame)
    }
    coreAnimationLayer.currentFrame = newFrame
  }
}

private class BlankImageProvider: AnimationImageProvider {
  func imageForAsset(asset: ImageAsset) -> CGImage? {
    return nil
  }
}
