//
//  ContentView.swift
//  Custom Camera
//
//  Created by Phat Vuong Vinh on 7/10/24.
//

import SwiftUI
import AVFoundation
struct ContentView: View {
    var body: some View {
        CameraView()
    }
}

#Preview {
    ContentView()
}


struct CameraView: View {
    
    @StateObject var camera = CameraModel()
    
    var body: some View {
        
        ZStack {
            // Going to Be Camera preview
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack {
                
                if camera.isTaken {
                    HStack {
                        Spacer()
                        Button(action: {
                            camera.retakePicture()

                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .foregroundStyle(Color.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(Circle())
                    
                        }
                        .padding(.leading)
                    }
                    .padding(.trailing, 10)
                    
                }
                Spacer()
                
                HStack {
                    // is taken showing "Save" else show "Take" button
                    
                    if camera.isTaken {
                        Button(action: {
                            if !camera.isSaved {
                                camera.savePhoto()
                            }
                        }) {
                            Text(camera.isSaved ? "Saved" : "Save")
                                .foregroundStyle(Color.black)
                                .fontWeight(.semibold)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .padding(.leading)
                        
                        Spacer()
                    } else {
                        
                        Button(action: {
                            camera.takePicture()
                        }) {
                            ZStack{
                                Circle()
                                    .fill(.white)
                                    .frame(width: 65, height: 65)
                                
                                Circle()
                                    
                                    .stroke(.white, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            }
                        }
                    }
                    
                    
                    
                }
                .frame(height: 75)
            }
        }
        .onAppear {
            camera.checkPermission()
        }
    }
}

// Camera Model
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    // since were going to read pic data...
    @Published var output: AVCapturePhotoOutput?
    
    // preview
    @Published var previewLayer: AVCaptureVideoPreviewLayer!
    
    @Published var isSaved = false
    
    @Published var photoData = Data(count: 0)
    
    
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInWideAngleCamera, .builtInDualWideCamera], mediaType: .video, position: .unspecified).devices
    }
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setup()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setup()
                }
            }
        case .denied:
            self.alert.toggle()
        default:
            return
        }
    }
    
    func setup() {
        // setting up the Camera
        
        do {
            
            // setting configs...
            self.session.beginConfiguration()
            
            // change for your own..
            let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            //checking and adding to session ...
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            // add output
            self.output = AVCapturePhotoOutput()
            
            if self.session.canAddOutput(self.output!) {
                self.session.addOutput(self.output!)
            }
            
            self.session.commitConfiguration()
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    // take and retake functions..
    func takePicture() {
        DispatchQueue.global(qos: .background).async  {
            
            self.output?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            
            
        }
    }
    
    func retakePicture() {
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
                
                self.isSaved = false
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let error {
            print("Error: \(error.localizedDescription)")
        }
        
        print("Photo taken")
        
        guard let imagedata = photo.fileDataRepresentation() else { return }
        
        
        self.photoData = imagedata
        
        DispatchQueue.main.async {
            withAnimation {
                self.isTaken.toggle()
                
                self.session.stopRunning()

            }
        }
    }
        
        
    func savePhoto() {
        
        let image = UIImage(data: photoData)!
        
        // Saving Image...
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        self.isSaved = true
        
        print("Photo saved")
    }
}


// Setting view for Preview

struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.previewLayer.frame = view.frame
        
        // your own properties...
        
        camera.previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.previewLayer)
        
        
        camera.session.startRunning()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
