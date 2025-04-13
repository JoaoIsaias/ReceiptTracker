import SwiftUI
import CoreData

struct DetailsScreenView: View {
    let photoPath: String
    @State private var isImageFullscreen = false
    
    @State private var date = Date.now
    @State private var amount: Double = 0.0
    @State private var vendorText: String = ""
    @State private var notesText: String = ""
    
    var currenciesArray = ["Euro (€)", "Dollar ($)"]
    @State private var selectedCurrency: String = "Euro (€)"
    
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isVendorFocused: Bool
    @FocusState private var isNotesFocused: Bool
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    if let image = UIImage(contentsOfFile: photoPath) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: UIScreen.main.bounds.height * 0.3)
                            .onTapGesture {
                                isAmountFocused = false
                                isVendorFocused = false
                                isNotesFocused = false
                                
                                isImageFullscreen = true
                            }
                            .padding()
                    }
                    
                    Text("Details:")
                        .font(.title2)
                        .padding()
                    
                    VStack(alignment: .leading) {
                        DatePicker(selection: $date, in: ...Date.now, displayedComponents: .date) {
                            Text("Receipt/Invoice Date:")
                        }
                        .padding(.bottom)
                        
                        Text("Amount")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .transition(.opacity)
                        
                        HStack {
                            TextField("Amount", value: $amount, formatter: NumberFormatter.currency)
                                .frame(width: UIScreen.main.bounds.width * 0.3)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .fixedSize(horizontal: true, vertical: false)
                                .keyboardType(.decimalPad)
                                .focused($isAmountFocused)
                            
                            
                            Spacer()
                            
                            Text("Currency:")
                            
                            Picker("Choose the currency", selection: $selectedCurrency) {
                                ForEach(currenciesArray, id: \.self) {
                                    Text($0)
                                }
                            }
                            
                        }
                        .padding(.bottom)
                        
                        VStack(alignment: .leading) {
                            Text("Vendor")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .transition(.opacity)
                            
                            TextField("Vendor (Optional)", text: $vendorText)
                                .frame(maxWidth: .infinity)
                                .focused($isVendorFocused)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                        }
                        .padding(.bottom)
                        
                        VStack(alignment: .leading) {
                            Text("Extra notes")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .transition(.opacity)
                            
                            TextField("Extra notes (Optional)", text: $notesText)
                                .frame(maxWidth: .infinity)
                                .focused($isNotesFocused)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    Spacer()
                    
                    Button("Save") {
                        print("Save Details")
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
                    .padding()
                }
            }
            
            // Fullscreen image overlay
            if isImageFullscreen {
                Color.black
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isImageFullscreen = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }
                
                if let image = UIImage(contentsOfFile: photoPath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .transition(.scale)
                }
            }
        }
        .toolbar {
            if isAmountFocused {
                Button("Done") {
                    isAmountFocused = false
                }
            }
        }
        .animation(.easeInOut, value: isImageFullscreen)
        .navigationBarBackButtonHidden(isImageFullscreen)
    }
}

extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}


#Preview {
    DetailsScreenView(photoPath: "").environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
