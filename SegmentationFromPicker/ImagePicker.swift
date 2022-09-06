import SwiftUI
import UIKit
import Vision
import AVFoundation

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage
    @Environment(\.presentationMode) private var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
 
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator

        return imagePicker
    }
 
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
 
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
     
        var parent: ImagePicker
        private let requestHandler = VNSequenceRequestHandler()
        private var request = VNGeneratePersonSegmentationRequest()
        
        init(_ parent: ImagePicker) {
            self.parent = parent
            request.qualityLevel = .accurate
            request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        }
     
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
     
            print("aqui")
            if
                let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
                let cgimage = image.cgImage
            {
                try? requestHandler.perform([request], on: cgimage, orientation: .up)
                //try? requestHandler.perform([request], on: CIImage(cgImage: cgimage), orientation: .up)

                print("aqui 2")
                guard let maskPixelBuffer =
                        request.results?.first?.pixelBuffer else {
                            print("return"); return }
                
                print("aqui 3")
                let ciimage = CIImage(cvPixelBuffer: maskPixelBuffer)
                let baseciimage = CIImage(cgImage: cgimage)
                let maskScaleX = baseciimage.extent.width / ciimage.extent.width
                let maskScaleY = baseciimage.extent.height / ciimage.extent.height
                
                let maskScaled = ciimage.transformed(by: __CGAffineTransformMake(maskScaleX, 0, 0, maskScaleY, 0, 0))
                let ciContext = CIContext(options: nil)
                let maskDisplayRef = ciContext.createCGImage(maskScaled, from: maskScaled.extent)
                
                if let maskDisplayRef = maskDisplayRef {
                    UIImageWriteToSavedPhotosAlbum(
                        UIImage(cgImage: maskDisplayRef),
                        nil,
                        nil,
                        nil
                    )
                    print("adicionado")
                    
                    parent.selectedImage = UIImage(cgImage: maskDisplayRef, scale: 1, orientation: .right)
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
