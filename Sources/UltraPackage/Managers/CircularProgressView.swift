import UIKit

final class CircularProgressView: UIView {
    
    fileprivate var progressLayer = CAShapeLayer()
    fileprivate var trackLayer = CAShapeLayer()
    fileprivate var didConfigureLabel = false
    var rounded: Bool
    fileprivate var filled: Bool
    fileprivate let lineWidth: CGFloat = 8.0
    
    
    var timeToFill = 3.43
    
    
    var progressColor = UIColor.white {
        willSet {
            if newValue != progressColor {
                progress = 0.0
            }
        }
        
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    
    var trackColor = UIColor.white {
        didSet{
            trackLayer.strokeColor = trackColor.cgColor
        }
    }
    
    
    var progress: Float {
        didSet{
            var pathMoved = progress - oldValue
            if pathMoved < 0 {
                pathMoved = 0 - pathMoved
            }
            
            setProgress(duration: timeToFill * Double(pathMoved), to: progress)
        }
    }
    
    func redraw() {
        self.progressLayer.removeFromSuperlayer()
        self.trackLayer.removeFromSuperlayer()
        self.createProgressView()
    }

    func createProgressView(isRectAnimation: Bool = false, isDahsed: Bool = true){
        let linePath: UIBezierPath?

        if isRectAnimation {
            linePath = UIBezierPath(roundedRect: bounds, cornerRadius: 6)
        } else {
            let centerPoint = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
            let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
            linePath = UIBezierPath(arcCenter: centerPoint, radius: radius, startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        }

        guard let linePath = linePath else { return }

        self.backgroundColor = UIColor.red
        self.layer.cornerRadius = bounds.size.width / 2

        trackLayer.fillColor = UIColor.blue.cgColor
        trackLayer.path = linePath.cgPath
        trackLayer.fillColor = .none
        trackLayer.strokeColor = trackColor.cgColor
        if isDahsed {
            trackLayer.lineDashPattern = [4, 4]
        }

        if filled {
            trackLayer.lineCap = .butt
            trackLayer.lineWidth = bounds.width
        } else {
            trackLayer.lineWidth = lineWidth
        }
        trackLayer.strokeEnd = 1
        layer.addSublayer(trackLayer)

        progressLayer.path = linePath.cgPath
        progressLayer.fillColor = .none
        progressLayer.strokeColor = progressColor.cgColor
        if filled {
            progressLayer.lineCap = .butt
            progressLayer.lineWidth = bounds.width
        } else {
            progressLayer.lineWidth = lineWidth
        }
        progressLayer.strokeEnd = 0
        if rounded {
            progressLayer.lineCap = .round
        }

        layer.addSublayer(progressLayer)
    }
    
    func trackColorToProgressColor() -> Void{
        trackColor = progressColor
        trackColor = UIColor(red: progressColor.cgColor.components![0], green: progressColor.cgColor.components![1], blue: progressColor.cgColor.components![2], alpha: 0.2)
    }
    
    func setProgress(duration: TimeInterval = 3, to newProgress: Float) -> Void {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = newProgress
        
        progressLayer.strokeEnd = CGFloat(newProgress)
        progressLayer.add(animation, forKey: "animationProgress")
    }
    
    override init(frame: CGRect){
        progress = 0
        rounded = true
        filled = false
        
        super.init(frame: frame)
        filled = false
    }
    
    required init?(coder: NSCoder) {
        progress = 0
        rounded = true
        filled = false
        
        super.init(coder: coder)
    }
}
