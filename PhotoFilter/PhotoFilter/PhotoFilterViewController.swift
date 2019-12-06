import UIKit
import CoreImage
import Photos


class PhotoFilterViewController: UIViewController {
    
    //Properties
    
    private let context = CIContext(options: nil)
    private let filter = CIFilter(name: "CIColorControls")! //Can crash
    
    private var originalImage: UIImage? {
        didSet{
            
            guard let originalImage = originalImage else {return}
            
            var scaledSize = imageView.bounds.size
            
         // 1x 2x 3x (400 points * 3x = 1,200pixels)
            let scale = UIScreen.main.scale
            
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.width * scale)
            
            scaledImage = originalImage.imageByScaling(toSize: scaledSize)
            
        }
    }
    
    private var scaledImage: UIImage? {
        didSet{
            updateView()
        }
    }

	@IBOutlet var brightnessSlider: UISlider!
	@IBOutlet var contrastSlider: UISlider!
	@IBOutlet var saturationSlider: UISlider!
	@IBOutlet var imageView: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
        //FIXME: fake it for now
        originalImage = imageView.image
	}
	
	// MARK: Actions
	
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
		// TODO: show the photo picker so we can choose on-device photos
		// UIImagePickerController + Delegate
        presentImagePicker()
	}
	
    private func presentImagePicker(){
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("Error with image picker")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {

		// TODO: Save to photo library
        savePhoto()
	}
	
    
    private func savePhoto(){
        
        guard let originalImage = originalImage else {
            return
            
        } //Warn user when there is no image
        
        let processedImage = filterImage(originalImage)
        
        //Save to photo library
        PHPhotoLibrary.requestAuthorization { (status) in
            guard status == .authorized else{
                return //TODO Display to the user how to enable photos
            }
            
            //Make a photo library change
            PHPhotoLibrary.shared().performChanges({
                
                PHAssetCreationRequest.creationRequestForAsset(from: processedImage)
                
            }) { (success, error) in
                if let error = error {
                    print("Error saving photo \(error)")
                    return
                }
                
                //Display alert
                print("Saved photo successfully")
                
            }
            
        }
        
        
        
    }

	// MARK: Slider events
	
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateView()

	}
	
	@IBAction func contrastChanged(_ sender: Any) {
        updateView()

	}
	
	@IBAction func saturationChanged(_ sender: Any) {
        updateView()

	}
    
    
    // Private Functions
    
    private func filterImage(_ image:UIImage) -> UIImage {
        
        guard let cgImage = image.cgImage else {return image}
        
        let ciImage = CIImage(cgImage: cgImage)
        
        //Set the filter values
        filter.setValue(ciImage, forKey: "inputImage")
        filter.setValue(saturationSlider.value, forKey: "inputSaturation")
        filter.setValue(brightnessSlider.value, forKey: "inputBrightness")
        filter.setValue(contrastSlider.value, forKey: "inputContrast")
        
        guard let outputCIImage = filter.outputImage else {return image}
        
        let bounds = CGRect(origin: CGPoint.zero, size: image.size)
        guard let outputCGImage = context.createCGImage(outputCIImage, from: bounds) else {return image}
        
        
        return UIImage(cgImage: outputCGImage) //FIXME: return filtered image
    }
    
    private func updateView(){
        // Filter image
        
        if let originalImage = originalImage {
            imageView.image = filterImage(originalImage)
        } else {
            imageView.image = nil
        }
    }
    
    
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        //Set the image and update the display
        
        if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
}
