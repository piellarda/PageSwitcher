
import UIKit

protocol PSContentDelegate {
    func pageContentTapped(content: PSContentViewController)
}

class PSContentViewController : UIViewController {
    var pageSwitcherIndex : Int = -1
    var pageSwitcherDelegate : PSContentDelegate?
    
    private let tapGesture = UITapGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()
        tapGesture.addTarget(self, action: "contentTapped")
        view.addGestureRecognizer(tapGesture)
    }
    
    func contentTapped() {
        pageSwitcherDelegate?.pageContentTapped(self)
    }
    
    deinit {
        println("deallocating page at index = \(self.pageSwitcherIndex)")
    }
}

protocol PSDelegate {
    func pageSwitcher(pageSwitcher: PageSwitcherView, viewControllerBeforeViewController viewController: PSContentViewController) -> PSContentViewController?
    func pageSwitcher(pageSwitcher: PageSwitcherView, viewControllerAfterViewController viewController: PSContentViewController) -> PSContentViewController?
}

class PageSwitcherView : UIScrollView, UIScrollViewDelegate, PSContentDelegate, UIPageViewControllerDataSource {

    var scaleFactor : CGFloat!
    var shrinkedContentWidth : CGFloat!
    var shrinkedContentHeight : CGFloat!
    
    let offset : CGFloat = 20
    let animationDuration = 0.3
    
    var pageViewControllerPresented = false
    
    var currentViewControllers = [PSContentViewController]()
    var pageSwitcherDelegate : PSDelegate?
    var pageSwitcherParentVC : UIViewController?
    var pageViewController : UIPageViewController?
    
    var transitionManager = TransisitonManager()
    
    init(pageSwitcherDelegate: PSDelegate) {
        super.init()
        self.pageSwitcherDelegate = pageSwitcherDelegate
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func initPageSwitch(content: PSContentViewController) {
        scaleFactor = self.bounds.size.height / UIScreen.mainScreen().bounds.size.height
        shrinkedContentWidth = self.bounds.size.width * scaleFactor
        shrinkedContentHeight = self.bounds.size.height
        
        self.delegate = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        
        self.setContentWithStartingIndex(content)
        
        let inset : CGFloat = (self.bounds.size.width - shrinkedContentWidth) / 2 - offset;
        self.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    func setContentWithStartingIndex(content: PSContentViewController) {
        var current = content
        let startingContent = current
        self.addStartingContentView(current, startingIndex: CGFloat(content.pageSwitcherIndex))
        self.currentViewControllers.append(current)
        
        let numberOfContentView = Int(ceil(self.bounds.size.width / shrinkedContentWidth / 2))
        
        var idx = content.pageSwitcherIndex + 1
        while idx < numberOfContentView + content.pageSwitcherIndex {
            if let next = self.pageSwitcherDelegate?.pageSwitcher(self, viewControllerAfterViewController: current)? {
                self.addContentView(next, leftContent: self.currentViewControllers.last, animated: true)
                self.currentViewControllers.append(next)
                current = next
            } else {
                break
            }
            idx++
        }
        
        idx = content.pageSwitcherIndex - 1
        current = startingContent
        while idx >= 0 && idx > content.pageSwitcherIndex - numberOfContentView {
            if let before = self.pageSwitcherDelegate?.pageSwitcher(self, viewControllerBeforeViewController: current)? {
                self.addContentView(before, rightContent: self.currentViewControllers.first, animated: true)
                self.currentViewControllers.insert(before, atIndex: 0)
                current = before
            } else {
                break
            }
            idx--
        }
        
        if let last = self.currentViewControllers.last {
            self.contentSize.width = last.view.frame.origin.x + shrinkedContentWidth + offset
        }
        
        self.setContentOffset(CGPoint(x: content.view.frame.origin.x - (self.bounds.size.width - shrinkedContentWidth) / 2, y: 0), animated: false)
    }
    
    // Recompute contentSize based on last loaded content ViewController
    func reloadContentSize() {
        if let last = self.currentViewControllers.last {
            self.contentSize.width = last.view.frame.origin.x + shrinkedContentWidth + offset
        }
    }
    
    var previousOffset : CGFloat = 0
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.x
        let contentWidth = scrollView.contentSize.width
        
        if let last = self.currentViewControllers.last {
            if previousOffset < currentOffset { // Scrolling right
                let visibleRectRightEdgeOffset = currentOffset + scrollView.bounds.size.width
                let lastRectLeftEdgeOffset = contentWidth - shrinkedContentWidth
                if currentOffset + scrollView.bounds.size.width > contentWidth - shrinkedContentWidth {
                    // Add right content
                    if let after = self.pageSwitcherDelegate?.pageSwitcher(self, viewControllerAfterViewController: last) {
                        self.addContentView(after, leftContent: last)
                        self.currentViewControllers.append(after)
                        self.reloadContentSize()
                    }
                }
            } else { // Scrolling left
                if currentOffset + scrollView.bounds.size.width < last.view.frame.origin.x - (shrinkedContentWidth * 2) {
                    self.removeContentView(last)
                    self.currentViewControllers.removeLast()
                    self.reloadContentSize()
                }
            }
        }
        
        if let first = self.currentViewControllers.first {
            if previousOffset < currentOffset { // Scrolling right
                if first.view.frame.origin.x + (shrinkedContentWidth * 2) < currentOffset  {
                    // Remove left content
                    self.removeContentView(first)
                    self.currentViewControllers.removeAtIndex(0)
                    self.reloadContentSize()
                }
            } else { // Scrolling left
                if currentOffset < first.view.frame.origin.x + shrinkedContentWidth {
                    // Add left content
                    if let before = self.pageSwitcherDelegate?.pageSwitcher(self, viewControllerBeforeViewController: first) {
                        self.addContentView(before, rightContent: first)
                        self.currentViewControllers.insert(before, atIndex: 0)
                        self.reloadContentSize()
                    }
                }
            }
        }
        
        previousOffset = currentOffset
    }
    
    func removeContentView(content: PSContentViewController) {
        content.view.removeFromSuperview()
        content.removeFromParentViewController()
    }
    
    func addStartingContentView(content: PSContentViewController, startingIndex : CGFloat) {
        self.pageSwitcherParentVC?.addChildViewController(content)
        self.addSubview(content.view)
        content.view.setTranslatesAutoresizingMaskIntoConstraints(true)
        var origin : CGFloat = 0 + offset + (startingIndex * (shrinkedContentWidth + offset))
        content.view.layer.setAffineTransform(CGAffineTransformMakeScale(scaleFactor, scaleFactor))
        content.view.frame = CGRectMake(origin, 0, shrinkedContentWidth, shrinkedContentHeight)
        println("Starting page \(content.pageSwitcherIndex) with frame = \(content.view.frame)")
        
        self.contentSize.width = content.view.frame.origin.x + shrinkedContentWidth + offset
        let originX = content.view.frame.origin.x - (self.bounds.size.width - shrinkedContentWidth) / 2
        self.setContentOffset(CGPoint(x: originX, y: 0), animated: false)
    }
    
    // Add a page content on the right side
    func addContentView(content: PSContentViewController, leftContent: PSContentViewController?, animated : Bool = false) {
        self.pageSwitcherParentVC?.addChildViewController(content)
        self.addSubview(content.view)
        content.view.setTranslatesAutoresizingMaskIntoConstraints(true)
        content.view.layer.setAffineTransform(CGAffineTransformMakeScale(scaleFactor, scaleFactor))
        
        var origin : CGFloat = 0 + offset
        origin = leftContent!.view.frame.origin.x + shrinkedContentWidth + offset
        
        if !animated {
            content.view.frame = CGRectMake(origin, 0, shrinkedContentWidth, shrinkedContentHeight)
        } else {
            content.view.frame = CGRectMake(origin + offset + shrinkedContentWidth, 0, shrinkedContentWidth, shrinkedContentHeight)
            UIView.animateWithDuration(animationDuration, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.2, options: nil, animations: { () -> Void in
                content.view.frame = CGRectMake(origin, 0, self.shrinkedContentWidth, self.shrinkedContentHeight)
                }, completion: nil)
        }
        
        println("New right page \(content.pageSwitcherIndex) with frame = \(content.view.frame)")
    }
    
    // Add a page content on the left side
    func addContentView(content: PSContentViewController, rightContent: PSContentViewController?, animated: Bool = false) {
        self.pageSwitcherParentVC?.addChildViewController(content)
        self.addSubview(content.view)
        content.view.setTranslatesAutoresizingMaskIntoConstraints(true)
        content.view.layer.setAffineTransform(CGAffineTransformMakeScale(scaleFactor, scaleFactor))
        
        var origin : CGFloat = 0 + offset
        origin = rightContent!.view.frame.origin.x - shrinkedContentWidth - offset
        
        if !animated {
            content.view.frame = CGRectMake(origin, 0, shrinkedContentWidth, shrinkedContentHeight)
        } else {
            content.view.frame = CGRectMake(origin - offset - shrinkedContentWidth, 0, shrinkedContentWidth, shrinkedContentHeight)
            UIView.animateWithDuration(animationDuration, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.2, options: nil, animations: { () -> Void in
                content.view.frame = CGRectMake(origin, 0, self.shrinkedContentWidth, self.shrinkedContentHeight)
            }, completion: nil)
        }
        println("New left page \(content.pageSwitcherIndex) with frame = \(content.view.frame)")
    }
    
    // MARK: UIPageViewController DataSource
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let content = viewController as PSContentViewController
        if let index = find(currentViewControllers, content) {
            if index > 0 {
                return currentViewControllers[index - 1]
            }
        }
        return self.pageSwitcherDelegate?.pageSwitcher(self, viewControllerBeforeViewController: content)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let content = viewController as PSContentViewController
        if let index = find(currentViewControllers, content) {
            if index < currentViewControllers.count - 1 {
                return currentViewControllers[index + 1]
            }
        }
        return self.pageSwitcherDelegate?.pageSwitcher(self, viewControllerAfterViewController: content)
    }
    
    // MARK: PageSwitcher Delegate
    func pageContentTapped(content: PSContentViewController) {
        let page = content as PSContentViewController
        
        if self.pageViewControllerPresented {
            self.currentViewControllers.removeAll(keepCapacity: true)
            self.pageViewController?.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.setContentWithStartingIndex(content)
            })
            self.pageViewControllerPresented = false
        } else {
            self.transitionManager.childViewControllerTapped = content
            self.transitionManager.transform = content.view.layer.affineTransform()
            self.transitionManager.pageCenter = self.convertPoint(page.view.center, toView: self.pageSwitcherParentVC?.view)
            self.transitionManager.pageSwitcher = self
            pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
            pageViewController?.dataSource = self
            pageViewController?.setViewControllers([page], direction: .Forward, animated: true, completion: nil)
            pageViewController?.transitioningDelegate = self.transitionManager
            
            let snapshot = page.view.snapshotViewAfterScreenUpdates(true)
            snapshot.frame = page.view.frame
            self.addSubview(snapshot)
            
            page.view.layer.setAffineTransform(CGAffineTransformIdentity)
            
            self.pageSwitcherParentVC?.presentViewController(pageViewController!, animated: true) { () -> Void in
                snapshot.removeFromSuperview()
                for contentPage in self.currentViewControllers {
                    if contentPage != page {
                        contentPage.view.removeFromSuperview()
                    }
                    contentPage.view.layer.setAffineTransform(CGAffineTransformIdentity)
                }
                println("Pager displayed")
            }
            self.pageViewControllerPresented = true
        }
    }
}
