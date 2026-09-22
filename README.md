# InvoicePro

A Flutter invoice manager for creating GST invoices, storing customers/products locally, generating PDFs, and sharing invoices.

## Current features

- Create invoices with automatic subtotal, GST and total calculation
- Select saved customers while creating an invoice
- Select saved products/services while creating an invoice
- Customer management with search, edit and delete
- Product/service management with SKU, unit, rate and GST
- Company profile and GSTIN
- SQLite local storage
- Invoice history
- PDF generation, printing and sharing
- Automated Android release APK build through GitHub Actions

## Run locally

```bash
flutter pub get
flutter run
```

If the Flutter project does not yet contain Android platform files:

```bash
flutter create --platforms=android .
flutter run
```

## Build Android APK

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The release APK is produced at `build/app/outputs/flutter-apk/app-release.apk`.

GitHub Actions also runs analysis/tests and builds the release APK on pushes to `main`.
