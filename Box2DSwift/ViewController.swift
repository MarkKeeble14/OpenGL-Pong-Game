//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update()
    }
}

class ViewController: GLKViewController {
    
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    
    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
            glesRenderer.loadModels()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGL();
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(self.doSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        view.addGestureRecognizer(singleTap);
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.doPan(_:)));
        pan.maximumNumberOfTouches = 1;
        view.addGestureRecognizer(pan);
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glesRenderer.draw(rect);
    }
    
    @objc func doSingleTap(_ sender: UITapGestureRecognizer) {
        glesRenderer.box2d.launchBall();
    }

    @objc func doPan(_ sender: UIPanGestureRecognizer) {
        let position = GLKVector2Make(Float(sender.location(in: view).x), Float(sender.location(in: view).y));
        let velocity = GLKVector2Make(Float(sender.velocity(in: view).y/2000), Float(sender.velocity(in: view).y)/2000);
        if (position.x < 200) {
            glesRenderer.box2d.movePaddleLeft(-velocity.y);
            // Move Left Paddle
        } else {
            glesRenderer.box2d.movePaddleRight(-velocity.y);
            // Move Right Paddle
        }
    }
}
