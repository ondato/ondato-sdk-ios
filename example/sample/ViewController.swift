import UIKit
import OndatoSDK

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        Ondato.sdk.setIdentityVerificationId("<Your identification id here>")
        Ondato.sdk.delegate = self
        
        let viewController = Ondato.sdk.instantiateOndatoViewController()
        viewController.modalPresentationStyle = .fullScreen
        present(viewController, animated: true, completion: nil)
    }
}

extension ViewController: OndatoFlowDelegate {
    func flowDidFail(identificationId: String?, error: OndatoServiceError) {
        print("Failure \(identificationId) reason: \(error)")
    }
    
    func flowDidSucceed(identificationId: String?) {
        print("Success \(identificationId)")
    }
}
