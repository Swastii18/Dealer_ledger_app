# Dealer Ledger App (Flutter) – Complete Development Blueprint

## 1. Project Overview

Build a **Flutter mobile + desktop app** for shop owners to maintain dealer-wise credit/debit records.

Core goal:
- Scan paper bills from dealers
- Extract bill details automatically (OCR)
- Save them under the selected dealer ledger
- Track due payments
- Maintain running balance
- Generate reports

---

# 2. Core Concept

Structure:

```text
Dealers
 ├── Dealer A Ledger
 ├── Dealer B Ledger
 ├── Dealer C Ledger
```

Each dealer has their own ledger.

Ledger stores:
- Date
- Bill Number
- Debit Amount
- Credit Amount
- Running Total

Logic:

Bill received = Debit (+)
Payment made = Credit (-)

Formula:

```text
Balance = Previous Balance + Debit - Credit
```

---

# 3. Technology Stack

## Frontend
- Flutter
- GetX

## Database
- SQLite (offline)

## OCR
- Google ML Kit Text Recognition

## File Handling
- File Picker

## Reports
- PDF Export
- Excel Export

## Optional Cloud Sync
- Firebase Firestore

---

# 4. Flutter Packages

```yaml
get:
sqflite:
path:
google_mlkit_text_recognition:
image_picker:
camera:
file_picker:
pdf:
printing:
path_provider:
intl:
```

---

# 5. Project Structure

```text
lib/
├── main.dart
├── models/
│   ├── dealer_model.dart
│   ├── ledger_model.dart
│
├── controllers/
│   ├── dealer_controller.dart
│   ├── ledger_controller.dart
│   ├── ocr_controller.dart
│
├── services/
│   ├── database_service.dart
│   ├── ocr_service.dart
│   ├── report_service.dart
│
├── views/
│   ├── splash_screen.dart
│   ├── dashboard_screen.dart
│   ├── dealer_list_screen.dart
│   ├── add_dealer_screen.dart
│   ├── dealer_ledger_screen.dart
│   ├── scan_bill_screen.dart
│   ├── add_payment_screen.dart
│   ├── reports_screen.dart
│
├── widgets/
│   ├── dealer_card.dart
│   ├── ledger_tile.dart
│   ├── summary_card.dart
```

---

# 6. Database Design

## Dealers Table

```sql
CREATE TABLE dealers (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 name TEXT,
 phone TEXT,
 address TEXT,
 created_at TEXT
);
```

## Ledger Table

```sql
CREATE TABLE ledger (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 dealer_id INTEGER,
 date TEXT,
 bill_no TEXT,
 debit REAL,
 credit REAL,
 running_total REAL,
 payment_type TEXT,
 remarks TEXT
);
```

---

# 7. Data Models

## Dealer Model

Fields:
- id
- name
- phone
- address
- createdAt

## Ledger Model

Fields:
- id
- dealerId
- date
- billNo
- debit
- credit
- runningTotal
- paymentType
- remarks

---

# 8. App Flow

## Step 1: Open App
Dashboard opens.

## Step 2: Add Dealer
Create dealer profile.

## Step 3: Select Dealer
Open dealer ledger.

## Step 4: Scan Bill
Take photo of paper bill.

## Step 5: OCR Reads Data
Extract:
- dealer name
- date
- bill number
- amount

## Step 6: Edit Extracted Data
Allow correction.

## Step 7: Save Bill
Save as debit.

## Step 8: Add Payment
Save as credit.

## Step 9: Generate Reports
Export PDF/Excel.

---

# 9. OCR Workflow

Flow:

```text
Open Camera
↓
Capture Bill
↓
OCR Read Text
↓
Extract Important Fields
↓
Show Editable Form
↓
Save
```

Extraction targets:
- Dealer Name
- Date
- Invoice Number
- Total Amount

---

# 10. Ledger Logic

## New Bill Entry

```text
Debit = Bill Amount
Credit = 0
New Balance = Old Balance + Debit
```

## Payment Entry

```text
Debit = 0
Credit = Paid Amount
New Balance = Old Balance - Credit
```

---

# 11. Screens Required

## Splash Screen
App startup.

## Dashboard
Shows total dealers and dues.

## Dealer List
Shows all dealers.

## Add Dealer
Add new dealer.

## Dealer Ledger Screen
Shows all dealer transactions.

## Scan Bill Screen
OCR bill scanning.

## Add Payment Screen
Record payment.

## Reports Screen
Reports and exports.

---

# 12. Dashboard Features

Show:
- Total Dealers
- Total Due Amount
- Total Paid Amount
- Pending Payments

---

# 13. Dealer Ledger Features

Show:
- All transactions
- Current balance
- Search bills
- Filter by date

Buttons:
- Scan Bill
- Add Payment
- Export Report

---

# 14. Search & Filter

Filter by:
- Date
- Bill Number
- Dealer Name

Search options:
- Invoice number
- Date

---

# 15. Reports Module

Generate:

## Daily Report
Transactions by day.

## Monthly Report
Transactions by month.

## Dealer-wise Report
Single dealer report.

## Due Report
Pending balances.

---

# 16. Export System

Export as:
- PDF
- Excel

PDF contains:
- Dealer details
- Transaction history
- Final due

---

# 17. Notifications (Optional)

Reminder for:
- Pending dues
- Overdue payments

---

# 18. Backup System

Local backup.

Cloud backup (optional).

Firebase sync optional.

---

# 19. Security

Add:
- PIN lock
- Fingerprint lock

Protect financial records.

---

# 20. Future Improvements

Add:
- Barcode scanner
- GST/VAT bill parser
- Multiple shop support
- Staff accounts
- Supplier analytics

---

# 21. Development Order (Important)

## Phase 1
Setup Flutter project.

## Phase 2
Setup database.

## Phase 3
Create models.

## Phase 4
Build CRUD.

## Phase 5
Build dealer screens.

## Phase 6
Build ledger screen.

## Phase 7
Implement OCR.

## Phase 8
Build payment module.

## Phase 9
Build reports.

## Phase 10
Build export module.

## Phase 11
Testing.

## Phase 12
Release.

---

# 22. Testing Checklist

Test:
- Add dealer
- Edit dealer
- Delete dealer
- Scan bill
- OCR extraction
- Save bill
- Add payment
- Balance calculation
- Report generation
- Export PDF
- Search functionality

---

# 23. Deployment

## Mobile
Android APK/AAB
iOS IPA

## Desktop
Windows EXE
macOS App

---

# 24. Final Workflow Example

```text
Add Dealer
↓
Select Dealer
↓
Scan Bill
↓
Save as Debit
↓
Balance Updated
↓
Make Payment
↓
Save as Credit
↓
Balance Reduced
↓
Generate Report
```

---

# 25. Recommended Start Point

Start with:
1. SQLite setup
2. Dealer CRUD
3. Ledger CRUD
4. Balance calculation
5. OCR integration
6. Reports

Build in this exact order for smoother development.