import SwiftUI

struct ThumbnailImageView: View {
    let path: String
    let width: CGFloat
    let height: CGFloat
    
    @State private var thumbnail: UIImage?
    
    init(path: String, width: CGFloat = 100, height: CGFloat = 100) {
        self.path = path
        self.width = width
        self.height = height
    }

    var body: some View {
        Group {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView() //Placeholder
            }
        }
        .frame(width: width, height: width)
        .clipped()
        .cornerRadius(8)
        .task {
            guard let image = UIImage(contentsOfFile: path),
                  let imageThumbnail = await image.byPreparingThumbnail(ofSize: CGSize(width: width, height: width)) else {
                return
            }
            thumbnail = imageThumbnail
        }
    }
}
