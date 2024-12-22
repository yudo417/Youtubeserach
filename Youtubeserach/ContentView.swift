//
//  test10.swift
//  testIos
//
//  Created by 林　一貴 on 2024/12/21.
//

import SwiftUI
import WebKit

struct APIResult:Codable {
    var  items:[Items]
    struct Items:Codable,Identifiable{
        var vid: VID
        var id: String
        var snippet: Snippet
        enum CodingKeys: String, CodingKey {
            case id = "etag"
            case vid = "id"
            case snippet
        }
    }
    struct VID: Codable{
        var videoId: String
    }
    struct Snippet:Codable{
        var title: String
        var description: String
        var thumbnails: Thumbnails
    }
    struct Thumbnails:Codable{
        var `default`: Default
    }
    struct Default:Codable{
        var url: String
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }


    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: -ViewContent
struct ContentView: View {
    @State var sresult : APIResult?
    @State var text : String = ""
    var keyword : String = ""
    var apikey : String?
    var body: some View {
        NavigationStack {
            VStack{
                HStack{
                    TextField("検索", text: $text)
                        .padding(7)
                        .background{ Capsule().foregroundStyle(.gray.opacity(0.4))}
                    Button {
                        fetchPosts(keyword: text)
                    } label: {
                        Text("検索")
                            .frame(width: 60, height: 30)
                            .background{ Capsule().foregroundStyle(.gray.opacity(0.2))}

                    }
                }
                Spacer()
//                ScrollView(showsIndicators: false){
                    if let items = sresult?.items {
                        List{
                                ForEach(items) { item in
                                    viewRow(videoURL: item.vid.videoId,urlImage: item.snippet.thumbnails.default.url, title: item.snippet.title, description: item.snippet.description)
                            }
                        }
                        .listStyle(.plain)
                    }
            }
            .padding()
            .navigationTitle("検索ページ")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    func fetchPosts(keyword : String) {
            // APIのURL
            guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
             let plistData = NSDictionary(contentsOfFile: path),
             let apikey = plistData["apikey"] as? String
            else {
                print("Failed to load API key from con.plist")
                return
            }
            print("取得APIKey:\(apikey)")
            guard let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(keyword)&type=video&maxResults=20&key=\(apikey)") else {
                print("無効なURL")
                return
            }

            // URLSessionを使って通信
            URLSession.shared.dataTask(with: url) { data, response, error in
                // エラーの確認
                if let error = error {
                    print("通信エラー: \(error.localizedDescription)")
                    return
                }

                // レスポンスのデータ確認
                guard let data = data else {
                    print("データがありません")
                    return
                }

                // JSONデータをデコード
                do {
                    let decodedData = try JSONDecoder().decode(APIResult.self, from: data)
                    DispatchQueue.main.async {
                        self.sresult = decodedData
                    }
                } catch {
                    print("デコードエラー: \(error.localizedDescription)")
                }
            }
            .resume() // リクエストを開始
        }
}

// MARK: - ROW
struct viewRow: View{
    let videoURL: String
    let urlImage: String
    let title: String
    let description: String
    var body: some View {
        NavigationStack{
            NavigationLink {
                WebView(url: URL(string: "https://youtube.com/watch?v="+videoURL)!)
            } label: {
                HStack{
                    AsyncImage(url: URL(string: urlImage)!){ image in
                        image.image?.scaledToFill()
                    }
                    VStack{
                        Text(title)
                            .lineLimit(1)
                            .fontWeight(.bold)
                        Text(description)
                            .font(.caption)
                            .lineLimit(3)
                    }
                }
            }

        }
        .padding(.vertical,5)
//        .border(.black.opacity(0.2))
    }
}

#Preview {
    ContentView()
}
