# 📦 Smart Inventory & Expiry Tracker

A **Flutter + Firebase** mobile application to manage inventory items, track expiry dates, and reduce waste using **smart reminders and barcode scanning**.

---

## 🚀 Features

- 🔐 **Firebase Authentication**
  - Email & Password Login / Signup
- 🗂️ **Category-based Inventory**
  - Create and manage categories (Kitchen, Fridge, Warehouse, etc.)
- 📦 **Item Management**
  - Add items manually
  - Add items using barcode scanning (Google ML Kit)
- 📅 **Expiry Tracking**
  - Store and display expiry dates clearly
- 🔔 **Smart Notifications**
  - Local notifications before expiry (1 day & 2 days)
- 🧾 **Item Details**
  - View item name, barcode/manual entry, expiry date, created time
  - Delete items securely
- 🎨 **Premium UI**
  - Glassmorphism design
  - Gradient backgrounds
  - Fully responsive & keyboard-safe layouts

---

## 🧠 App Flow

1. User opens the app
2. Login / Signup using Firebase Auth
3. View Categories
4. Select a Category
5. Add Items (Manual or Barcode Scan)
6. Receive notifications before expiry

---

## 🗄️ Firestore Data Structure

```text
users (collection)
 └── userId (document)
     ├── username
     ├── email
     ├── createdAt
     └── categories (subcollection)
          └── categoryId
              ├── name
              ├── createdAt
              └── items (subcollection)
                   └── itemId
                       ├── name
                       ├── barcode
                       ├── expiryDate
                       ├── createdAt
````

---

## 🛠️ Tech Stack

* Flutter (Dart)
* Firebase Authentication
* Cloud Firestore
* Google ML Kit (Barcode Scanning)
* Flutter Local Notifications

---

## 📱 Screens

* Login / Signup
* Categories Grid
* Items List
* Add Item (Manual)
* Add Item (Scan)
* Item Details Bottom Sheet

---

## ⚙️ Run Locally

```bash
flutter pub get
flutter run
```

---

## 📦 Build APK

```bash
flutter build apk --release
```

📍 APK Location:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔒 Security

* Firebase credentials are excluded from version control
* `google-services.json` is ignored via `.gitignore`

---

## 📌 Future Enhancements

* Cloud push notifications
* Analytics dashboard
* Consumption tracking

---

## 👨‍💻 Author

**Alish Sahdev**
GitHub: [https://github.com/Alishron](https://github.com/Alishron)



---

## ✅ 2️⃣ WHERE TO FIND APK (DIRECT ANSWER)

After running:

```bash
flutter build apk --release
```

👉 **Your APK file will be here:**

```
project_flutter/build/app/outputs/flutter-apk/app-release.apk
```

That **`app-release.apk`** is what you:

* Send to friends
* Upload to Google Drive
* Share for demo/interview

---

## 🔁 Rebuild APK Anytime

```bash
flutter clean
flutter build apk --release
```

---

## 🎉 DONE
