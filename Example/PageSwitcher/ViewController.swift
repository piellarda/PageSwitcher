
import UIKit

class ViewController: UIViewController, PSDelegate {

    @IBOutlet var pageSwitcher: PageSwitcherView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pageSwitcher.pageSwitcherParentVC = self
        self.pageSwitcher.pageSwitcherDelegate = self
        let startingContent = self.createDummyContent(0)
        self.pageSwitcher.initPageSwitch(startingContent)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createDummyContent(index: Int) -> PSContentViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let content = storyboard.instantiateViewControllerWithIdentifier("Content") as PSContentViewController
        content.pageSwitcherIndex = index
        content.pageSwitcherDelegate = self.pageSwitcher
        return content
    }
    
    // MARK: PageSwitcherDelegate
    
    let numberOfPageMax = 25
    
    func pageSwitcher(pageSwitcher: PageSwitcherView, viewControllerBeforeViewController viewController: PSContentViewController) -> PSContentViewController? {
        let index = viewController.pageSwitcherIndex
        if index > 0 {
            return self.createDummyContent(index - 1)
        }
        return nil
    }
    
    func pageSwitcher(pageSwitcher: PageSwitcherView, viewControllerAfterViewController viewController: PSContentViewController) -> PSContentViewController? {
        let index = viewController.pageSwitcherIndex
        if index < numberOfPageMax {
            return self.createDummyContent(index + 1)
        }
        return nil
    }
}