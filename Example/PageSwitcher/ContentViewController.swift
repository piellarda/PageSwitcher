
import UIKit

class ContentViewController : PSContentViewController {
    
    @IBOutlet var indexLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
        indexLabel.text = self.pageSwitcherIndex.description
    }
    
}