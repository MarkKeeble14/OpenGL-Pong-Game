//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update();
        
        p1ScoreText?.text = String(glesRenderer.box2d.getPlayerOneScore());
        p2ScoreText?.text = String(glesRenderer.box2d.getPlayerTwoScore());
    }
}

class ViewController: GLKViewController {
    private var context: EAGLContext?
    private var glesRenderer: Renderer!
    private var p1ScoreText: UITextView?
    private var p2ScoreText: UITextView?

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
        singleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(singleTap);
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.doPan(_:)));
        pan.maximumNumberOfTouches = 1;
        view.addGestureRecognizer(pan);
        
        // a Label displaying text
        p1ScoreText = UITextView();
        p1ScoreText?.isSelectable = false;
        p1ScoreText?.isEditable = false;
        p1ScoreText?.backgroundColor = UIColor.clear;
        p1ScoreText?.textColor = UIColor.white;
        p1ScoreText?.frame = CGRect(x: 50, y: 50, width: 100, height: 100);
        p1ScoreText?.textAlignment = NSTextAlignment.center;
        p1ScoreText?.font = .systemFont(ofSize: 24);
        view.addSubview(p1ScoreText!);
        
        // a Label displaying text
        p2ScoreText = UITextView();
        p2ScoreText?.isSelectable = false;
        p2ScoreText?.isEditable = false;
        p2ScoreText?.backgroundColor = UIColor.clear;
        p2ScoreText?.textColor = UIColor.white;
        p2ScoreText?.frame = CGRect(x: 250, y: 50, width: 100, height: 100);
        p2ScoreText?.textAlignment = NSTextAlignment.center;
        p2ScoreText?.font = .systemFont(ofSize: 24);
        view.addSubview(p2ScoreText!);
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
            if (sender.state == UIGestureRecognizer.State.ended) {
                glesRenderer.box2d.movePaddleLeft(0);
            }
        } else {
            // Move Right Paddle
            glesRenderer.box2d.movePaddleRight(-velocity.y);
            if (sender.state == UIGestureRecognizer.State.ended) {
                glesRenderer.box2d.movePaddleRight(0);
            }
        }
    }
}
