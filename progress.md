# Dealer Ledger App – Development Progress

## Status: Phase 1–10 Complete

---

## Completed

### Phase 1 – Flutter Project Setup
- [x] Flutter project initialized
- [x] iOS deployment target set to 15.5 (required by google_mlkit_commons)
- [x] pubspec.yaml configured with all dependencies

### Phase 2 – Database (SQLite)
- [x] `DatabaseService` with singleton pattern
- [x] `dealers` table (id, name, phone, address, created_at)
- [x] `ledger` table (id, dealer_id, date, bill_no, debit, credit, running_total, payment_type, remarks)
- [x] Full CRUD for dealers and ledger entries
- [x] Dashboard aggregate queries (total debit, credit, balance per dealer)
- [x] Running total recalculation after entry deletion

### Phase 3 – Models
- [x] `DealerModel` with `toMap` / `fromMap` / `copyWith`
- [x] `LedgerModel` with `toMap` / `fromMap` / `copyWith`

### Phase 4 – State Management (GetX)
- [x] `DealerController` – reactive dealer list, search filter, CRUD actions
- [x] `LedgerController` – reactive entry list, bill/payment entry, balance calc
- [x] `OcrController` – camera/gallery picker, reactive OCR state, auto-fill
- [x] `AppBindings` – permanent dependency injection of all controllers
- [x] Named routes via `AppRoutes` + `AppPages`

### Phase 5 – Dealer Screens
- [x] Dealer list with search bar and balance badge
- [x] Add / Edit dealer form with validation
- [x] Delete dealer with confirmation dialog (cascades ledger entries)

### Phase 6 – Ledger Screen
- [x] Per-dealer ledger with running balance header (debit / credit / net)
- [x] Search by bill no, date, remarks
- [x] Delete entry (recalculates all running totals)
- [x] Bottom bar: Scan Bill + Add Payment buttons

### Phase 7 – OCR (Google ML Kit)
- [x] `google_mlkit_text_recognition ^0.14.0` added to pubspec
- [x] `OcrService` – Latin script text recognition via ML Kit
- [x] Regex extraction: invoice number (bill/inv/receipt patterns), date (dd/mm/yyyy, yyyy-mm-dd, text month), amount (Grand Total / largest number fallback)
- [x] `OcrController` – runs OCR after image pick, exposes `extractedBillNo`, `extractedDate`, `extractedAmount` as reactive observables
- [x] Scan screen auto-fills form fields via `ever()` workers; processing overlay shown during OCR; success banner shown after extraction; all fields remain editable

### Phase 8 – Payment Module
- [x] Add Payment screen with amount, date, mode (cash/bank/UPI/cheque/other), remarks
- [x] Saves as credit entry; running total updated immediately

### Phase 9 – Reports & Export
- [x] Reports screen: summary table + full transaction DataTable
- [x] PDF generation via `pdf` + `printing` packages
- [x] Share as PDF (cross-platform share sheet)
- [x] Print PDF

### Theme & UI
- [x] `AppTheme` – Material 3, custom color scheme, consistent card/button styles
- [x] Reusable widgets: `SummaryCard`, `DealerCard`, `LedgerTile`
- [x] Splash screen with fade animation

---

## Pending

### Phase 10 – Android & iOS Permissions
- [x] Add camera permission to `AndroidManifest.xml`
- [x] Add `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` to `Info.plist`

### Phase 11 – Testing
- [ ] Add dealer, edit dealer, delete dealer
- [ ] Scan bill, OCR extraction accuracy
- [ ] Save bill as debit, verify balance calculation
- [ ] Add payment as credit, verify balance reduction
- [ ] Delete entry and confirm running totals recalculate
- [ ] PDF generation and share
- [ ] Search functionality

### Phase 12 – Future Improvements (Optional)
- [ ] PIN / fingerprint lock
- [ ] Local backup / restore
- [ ] Firebase cloud sync
- [ ] Daily / monthly / dealer-wise report filters
- [ ] Excel export
- [ ] Due payment notifications
- [ ] Barcode scanner
- [ ] GST/VAT bill parser

---

## Tech Stack

| Layer | Package |
|---|---|
| State management | `get ^4.7.2` |
| Database | `sqflite ^2.4.2` |
| OCR | `google_mlkit_text_recognition ^0.14.0` |
| Camera / Gallery | `image_picker ^1.1.2`, `camera ^0.11.1` |
| PDF | `pdf ^3.11.3`, `printing ^5.14.2` |
| Date formatting | `intl ^0.20.2` |
| Path / Storage | `path ^1.9.0`, `path_provider ^2.1.5` |

---

## Known Issues / Notes

- iOS minimum deployment target raised to **15.5** (from 13.0) due to `google_mlkit_commons` requirement.
- Running total recalculation after entry deletion is sequential (O(n)) — acceptable for typical ledger sizes.
- OCR extraction uses regex heuristics; accuracy depends on bill image quality.
