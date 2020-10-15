import UIKit
import UIKit.UIGestureRecognizerSubclass

protocol Point {
    var x:CGFloat {get set}
    var y:CGFloat {get set}
}

class GraphGestureRecognizer: UIGestureRecognizer {
    
    
    //MARK: - Public Vars
    
    private(set) var activeTouches = Set<UITouch>()
    var singleTouchDelay: TimeInterval = 0.2 // as seconds
    var singleTouchMovementThreshold: CGFloat = 5.0 // as points
    
    
    //MARK: - Private Vars
    
    private var graphSelectionIsActive = false
    private var dispatchItem: DispatchWorkItem?
    
    
    //MARK: - Override Methods
    
    override func reset() {
        super.reset()
        activeTouches = []
        dispatchItem?.cancel()
        graphSelectionIsActive = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            if !activeTouches.contains(touch) {
                activeTouches.insert(touch)
            }
        }
        
        let start:() -> Void = { [unowned self] in
            if self.graphSelectionIsActive == false {
                self.graphSelectionIsActive = true
                self.state = .began
            }
        }
        
        if touches.count > 1 {
            start()
        } else if touches.count == 1 {
            let item = DispatchWorkItem(block: start)
            dispatchItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + singleTouchDelay, execute: item)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        if graphSelectionIsActive {
            state = .changed
        } else {
            // if one touch is detected and we are not in active mode
            // check if touch should cancel the start timeout if outside of movement threshold
            
            if touches.count == 1 {
                guard let touch = touches.first else { return }
                
                let p1 = touch.previousLocation(in: view)
                let p2 = touch.location(in: view)
                
                if abs(p1.distance(to: p2)) > singleTouchMovementThreshold {
                    state = .cancelled
                    dispatchItem?.cancel()
                    activeTouches.removeAll()
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        activeTouches.subtract(touches)
        
        if activeTouches.isEmpty {
            graphSelectionIsActive = false
            state = .ended
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        activeTouches.subtract(touches)
        
        if activeTouches.isEmpty {
            graphSelectionIsActive = false
            state = .cancelled
        }
    }
    
}
