import SwiftUI
import Toasts
import CoreData

struct DetailsScreenView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentToast) var presentToast
    
    let photoPath: String
    @State private var isImageFullscreen = false
    
    @State private var date = Date()
    @State private var amount: Double = 0.0
    @State private var vendorText: String = ""
    @State private var notesText: String = ""
    
    var currenciesArray = ["Euro (€)", "Dollar ($)"]
    @State private var selectedCurrency: String = "Euro (€)"
    
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isVendorFocused: Bool
    @FocusState private var isNotesFocused: Bool
    
    @State private var showBackConfirmation = false
    
    @StateObject private var viewModel = DetailsScreenViewModel()
    
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
                        
                        if amount <= 0 {
                            Text("Amount must be greater than 0.")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
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
                        .padding(.vertical)
                        
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
                        Task {
                            do {
                                try await viewModel.saveOnCoreData(
                                    context: viewContext,
                                    imagePath: photoPath,
                                    date: date, amount: amount,
                                    currency: selectedCurrency,
                                    vendor: vendorText.isEmpty ? nil : vendorText,
                                    notes: notesText.isEmpty ? nil : notesText)
                                
                                presentToast(ToastValue(message: "Receipt/Invoice saved!"))
                                
                                if viewModel.existingReceipt == nil {
                                    dismiss()
                                }
                            } catch {
                                print("Failed to save: \(error)")
                            }
                        }
                    }
                    .disabled(viewModel.existingReceipt == nil ? amount <= 0 : !existingDataHasChanges())
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
                    .padding()
                }
            }
            .accessibilityIdentifier("DetailsScreenView")
            
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
        .onAppear {
            Task {
                let receipt = await viewModel.fetchReceipt(context: viewContext, imagePath: photoPath)
                
                if let receipt = receipt {
                    date = receipt.date ?? Date()
                    amount = receipt.amount
                    selectedCurrency = receipt.currency ?? "Euro (€)"
                    vendorText = receipt.vendor ?? ""
                    notesText = receipt.notes ?? ""
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !isImageFullscreen {
                    Button(action: {
                        if viewModel.existingReceipt == nil {
                            showBackConfirmation = true
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .keyboard) {
                if isAmountFocused {
                    Button("Done") {
                        isAmountFocused = false
                    }
                }
            }
        }
        .animation(.easeInOut, value: isImageFullscreen)
        .navigationBarBackButtonHidden(true)
        .alert("Do you want to discard this receipt/invoice?", isPresented: $showBackConfirmation) {
            Button("Confirm", role: .destructive) {
                viewModel.deleteImageFromDisk(imagePath: photoPath)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    private func existingDataHasChanges() -> Bool {
        if let existingReceipt = viewModel.existingReceipt {
            let vendorChanges = existingReceipt.vendor == nil ? vendorText != "" : existingReceipt.vendor != vendorText
            let notesChanges = existingReceipt.notes == nil ? notesText != "" : existingReceipt.notes != notesText
            
            return existingReceipt.date != date ||
                   existingReceipt.amount != amount ||
                   existingReceipt.currency != selectedCurrency ||
                   vendorChanges ||
                   notesChanges
        }
        return false
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
