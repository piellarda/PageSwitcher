//
//  TransitionManager.swift
//  PageSwitcher
//
//  Created by Antoine Piellard on 06/02/15.
//
//

import UIKit

extension UIView {
    
    func pb_takeSnapshot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale);
        
        self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates: true)
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}

class TransisitonManager : NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    var isPresenting = true
    var transform : CGAffineTransform?
    var pageCenter : CGPoint?
    var childViewControllerTapped : PSContentViewController?
    var pageSwitcher : PageSwitcherView?
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.8
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView()
        let fromViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        let fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)!
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let fromViewChild = childViewControllerTapped!.view
        
        let snapshot = fromViewChild.snapshotViewAfterScreenUpdates(true)
        

        if isPresenting {
            toView.center = self.pageCenter!
            toView.layer.setAffineTransform(self.transform!)
            containerView.addSubview(toView)
        } else {
            containerView.addSubview(toView)
            containerView.addSubview(fromView)
        }
        
        let duration = self.transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, delay: 0.0, options: nil, animations: {
            
            if self.isPresenting {
                toView.center = containerView.center
                toView.layer.setAffineTransform(CGAffineTransformIdentity)
            } else {
                fromView.layer.setAffineTransform(self.transform!)
                fromView.center = self.pageSwitcher!.center
            }
            
            }, completion: { finished in
                transitionContext.completeTransition(true)
                println("transition complete")
        })
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = true
        return self
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isPresenting = false
        return self
    }
    
}
