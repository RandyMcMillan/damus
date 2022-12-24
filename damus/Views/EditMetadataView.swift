//
//  EditMetadataView.swift
//  damus
//
//  Created by Thomas Tastet on 23/12/2022.
//

import SwiftUI

let PPM_SIZE: CGFloat = 80.0

func isHttpsUrl(_ string: String) -> Bool {
    let urlRegEx = "^https://.*$"
    let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
    return urlTest.evaluate(with: string)
}

func isImage(_ urlString: String) -> Bool {
    let imageTypes = ["image/jpg", "image/jpeg", "image/png", "image/gif", "image/tiff", "image/bmp", "image/webp"]

    guard let url = URL(string: urlString) else {
        return false
    }

    var result = false
    let semaphore = DispatchSemaphore(value: 0)

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print(error)
            semaphore.signal()
            return
        }

        guard let httpResponse = response as? HTTPURLResponse,
              let contentType = httpResponse.allHeaderFields["Content-Type"] as? String else {
            semaphore.signal()
            return
        }

        if imageTypes.contains(contentType.lowercased()) {
            result = true
        }

        semaphore.signal()
    }

    task.resume()
    semaphore.wait()

    return result
}

struct EditMetadataView: View {
    let damus_state: DamusState
    @State var display_name: String
    @State var about: String
    @State var picture: String
    @State var nip05: String
    @State var name: String
    @State var ln: String
    @State var website: String
    
    @Environment(\.dismiss) var dismiss
    
    init (damus_state: DamusState) {
        self.damus_state = damus_state
        let data = damus_state.profiles.lookup(id: damus_state.pubkey)
        
        _name = State(initialValue: data?.name ?? "")
        _display_name = State(initialValue: data?.display_name ?? "")
        _about = State(initialValue: data?.about ?? "")
        _website = State(initialValue: data?.website ?? "")
        _picture = State(initialValue: data?.picture ?? "")
        _nip05 = State(initialValue: data?.nip05 ?? "")
        _ln = State(initialValue: data?.lud16 ?? data?.lud06 ?? "")
    }
    
    func save() {
        let metadata = NostrMetadata(
            display_name: display_name,
            name: name,
            about: about,
            website: website,
            nip05: nip05.isEmpty ? nil : nip05,
            picture: picture.isEmpty ? nil : picture,
            lud06: ln.contains("@") ? ln : nil,
            lud16: ln.contains("@") ? nil : ln
        );
        
        let m_metadata_ev = make_metadata_event(keypair: damus_state.keypair, metadata: metadata)
        
        if let metadata_ev = m_metadata_ev {
            damus_state.pool.send(.event(metadata_ev))
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                InnerProfilePicView(url: URL(string: picture), pubkey: damus_state.pubkey, size: PPM_SIZE, highlight: .none)
                Spacer()
            }
            Form {
                Section("Your Name") {
                    TextField("Satoshi Nakamoto", text: $display_name)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Username") {
                    TextField("satoshi", text: $name)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)

                }
                
                Section ("Profile Picture") {
                    TextField("https://example.com/pic.jpg", text: $picture)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Website") {
                    TextField("https://jb55.com", text: $website)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }
                
                Section("About Me") {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $about)
                            .textInputAutocapitalization(.sentences)
                        if about.isEmpty {
                            Text("Absolute boss")
                                .offset(x: 0, y: 7)
                                .foregroundColor(Color(uiColor: .placeholderText))
                        }
                    }
                }
                
                Section("Bitcoin Lightning Tips") {
                    TextField("Lightning Address or LNURL", text: $ln)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }
                                
                Section(content: {
                    TextField("example.com", text: $nip05)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }, header: {
                    Text("NIP-05 Verification")
                }, footer: {
                    Text("\(name)@\(nip05) will be used for verification")
                })
                
                Button("Save") {
                    save()
                    dismiss()
                }
            }
        }
        .navigationTitle("Edit Profile")
    }
}

struct EditMetadataView_Previews: PreviewProvider {
    static var previews: some View {
        EditMetadataView(damus_state: test_damus_state())
    }
}
