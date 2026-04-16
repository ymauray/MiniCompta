import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            Image("LaunchImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        }
        .background(Color.black)
    }
}
