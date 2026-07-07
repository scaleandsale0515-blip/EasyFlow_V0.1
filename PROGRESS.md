# EasyFlow — Build Progress Tracker

## STATUS: Full app built + fully audited against the spec (v1.1)

## Audit round — gaps found and fixed
A full line-by-line audit was done against every decision made in planning.
5 real gaps were found and fixed:

1. **Production entry Unit field** — was auto-fill only; now editable per row
   (manual override), and typing a new custom unit here gets remembered for
   future dropdowns, same as Item Catalog. Matches "Unit (auto) is Auto +
   Manual" confirmation.
2. **Worker/Transporter Active/Inactive** — the data field existed and was
   already respected by pickers (inactive ones hidden from new entries), but
   there was no way to actually toggle it. Added a switch in the edit screen
   + "(Inactive)" tag and quick-toggle menu on the list screen, mirroring
   Item Catalog's pattern.
3. **Worker/Transporter List search + filter** — only had name/phone search.
   Added date and amount matching (against that person's ledger lines) plus
   Today/Week/Month/Custom period filter, matching the originally agreed
   design.
4. **Dashboard Worker chart item-wise breakdown** — was only showing date +
   total amount per entry. Now tapping a bar shows the actual items produced
   that day below the chart (category, subcategory, qty, unit).
5. **Low-stock threshold** — exists in data model with a default of 50 bags,
   but had no settings UI. Added a threshold editor (tune icon in the
   Purchase screen's app bar).

**Bonus fix also found and corrected:** the "Custom" option on all date
filters across the app (Production, Transport, Worker/Transporter Ledger,
Purchase, and all 4 Dashboard charts) previously did nothing — selecting
it silently defaulted to "today" with no way to pick an actual range. This
is now a real date-range picker (`DateFilterBar` widget) wired in
consistently everywhere "Custom" appears as an option.

## Full module status (all confirmed present after audit)
- [x] Admin Lock (SHA-256 salted, ID: FactoryFlowRP2026)
- [x] Item Catalog — Category → Subcategory, unit picker w/ custom-unit
      memory, delete-blocked-if-used → Inactive fallback, search
- [x] Production — multi-item entry, worker picker/search/quick-add, cement
      bags used (once per session), Unit auto+manual, By Date/Worker history,
      full CRUD, Today/Week/Month/Custom filter
- [x] Transport — transporter picker w/ auto-fill vehicle (both free text),
      product OR cement rows, independent per-row reduce-stock toggle
      (default ON), flat trip charge, By Date/Transporter history, full CRUD
- [x] Worker — list (search by name/phone/date/amount, period filter,
      balance color-coded, Active/Inactive), Ledger (auto production lines +
      payment CRUD), profile w/ compressed photo
- [x] Transporter — mirrors Worker exactly (no vehicle fields on profile)
- [x] Purchase/Raw Material — qty-only tracker w/ optional rate/supplier,
      live cement ledger, opening-stock popup (~5s delay, first launch only),
      settable low-stock threshold
- [x] Dashboard — welcome line, expandable inventory cards (Category tap →
      Subcategory stock), Today's Summary (tap-to-expand worker/trip detail),
      Cement Stock cards (tap → Purchase), 4 charts all with working
      Month/Quarter/Year/Custom filter (Production by Category, Worker w/
      dropdown + item-wise tap breakdown, Top-3 Trends, Purchase vs Usage),
      Recent Activity (last 5), Pending Dues (totals + individually listed
      negative balances only, color-coded, tap-through to ledgers), low-stock
      banner, 30-day backup reminder banner
- [x] Company Profile — single profile only, logo upload
- [x] Backup & Restore — full zip export/import (all Hive boxes + compressed
      images), shareable to any location (Drive/WhatsApp/Downloads/etc via
      Android share sheet), last-backup-date tracked for the reminder banner
- [x] Terms & Conditions — static info (Developer, Support email w/ mailto,
      Address) at the bottom of the screen
- [x] More menu wired to every real screen
- [x] Native Android project hand-written (no Flutter SDK available in this
      sandbox to run `flutter create`) — Gradle, Manifest, MainActivity.kt
- [x] App icon generated at all 5 mipmap densities from your uploaded icon
- [x] codemagic.yaml — pub get + flutter build apk --debug
- [x] Data-layer sanity-checked by hand: all 14 Hive typeIds unique with no
      gaps, every hand-written adapter's field count matches its model
      exactly (a mismatch here would NOT show as a compile error — it would
      silently corrupt data at runtime, so this was checked field-by-field)
- [x] Every relative import in every file verified to resolve to a real file
- [x] Brace/parenthesis balance verified across every file

## What I still cannot verify (no Flutter/Dart SDK in this sandbox)
- `flutter pub get` actually resolving all package versions without conflict
- The code actually compiling end-to-end (type errors, null-safety edge cases)
- Gradle/AGP/Kotlin version compatibility with whatever Flutter version
  Codemagic has installed

**Your first Codemagic build is the real compile check.** If it fails, paste
the build log back and it'll get fixed immediately — much faster to fix a
real compiler error than to keep guessing blind.

## Key business rules (don't break these in future edits)
- Cement stock = openingStock + purchased minus production-used minus transport-dispatched (if toggle ON)
- Item stock = total produced (that subcategory) minus total transport-dispatched (toggle ON only)
- Worker/Transporter Balance = Earned/Charged minus Paid. Positive = GREEN. Negative = RED/ORANGE (advance).
- Transport per-row "reduce from stock?" toggle — default YES, independent per row.
- Delete blocked (force Inactive) for Category/Subcategory only if used in any Production entry.
- Custom units typed anywhere (Item Catalog OR Production entry) get remembered and suggested next time.
- "Notes" used everywhere, never "Remarks".
- Team/shared production between multiple workers was explicitly deferred (your call) — Production entries are single-worker only for now.
