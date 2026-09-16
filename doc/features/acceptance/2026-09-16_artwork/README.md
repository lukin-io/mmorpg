# September 16 artwork category acceptance

Scope: category-sized Shop Buy/Sell and Inventory images. This verifies the
rendering correction; **asset normalization/redraw integration is not complete**.

## Automated checks

- `bin/verify fast`: **3,109 non-system examples, 0 failures**;622 Ruby files
  linted without offenses;12 feature handbooks and 98 architecture documents
  passed their audits. Existing Partially Implemented warnings remain explicit.
- `bundle exec rspec spec/system/shop_purchase_spec.rb spec/system/inventory_progression_spec.rb`:
  **14 examples, 0 failures**, including the new shared category-size/wear/remove flow.
- The initial fast run found one old Inventory request assertion expecting
  a 60×60 Penknife image. It now expects the measured 62×91; the full fast rerun
  passed. The first new system run used a button-name lookup unsupported by
  the configured Capybara selector; the existing semantic slot-button selector
  fixed the test, followed by the passing complete two-file run.
- `git diff --check` and `bin/verify docs` passed.

## Manual Chrome acceptance

Performed after the required fast check passed, using the dedicated local
`Artwork0916` player. Source Neverlands stayed on the City after read-only
Inventory/Shop capture; no source trade, gear change or fight was performed.

1. Sign in → City Shop → buy one Penknife for 7 NV, confirm the actual browser
   dialog → Shop stock falls by one, balance 1000→993 NV. Chrome's background-tab
   confirmation stalled the automation interface; selecting the local tab and
   clicking its visible **OK** completed it. No direct-request bypass was used.
2. Inventory renders the purchased Penknife plus bounded fixture jewelry/permit.
   Measured display rectangles: weapon 62×91, pendant 62×35, ring 31×31, permit 42×21.
3. Wear Penknife → image appears in Weapon slot and AP 40/armor pierce 1% display.
   Reload restores Shop; reopening Inventory retains the equipped weapon.
   Press Enter on the remove button → item returns to its carried row, AP 45 and
   armor pierce 0% return. Artwork changed no item properties or admission rules.
4. Desktop 1150×819: complete doll visible when main pane is at top; image rows,
   actions and text remain reachable. [Desktop capture](inventory-desktop.png).
   [Equipped capture](inventory-equipped.png) was taken with the pane scrolled;
   the top of that viewport capture is not an image-cropping result.
5. Chrome 125% zoom 920×655,200%575×409 and 300%383×273: no document-wide horizontal
   overflow. At 383 CSS pixels the item properties/requirements stack; keyboard
   Tab reaches Transfer after the Penknife Wear button and scrolls the row into
   view. [200%](inventory-zoom-200.png), [narrow 300%](inventory-narrow-zoom-300.png).
   The advertised 390×844 viewport override did not change this Chrome tab's
   measured viewport; it was reset. These are **actual zoom checks**, not a claim
   of 390×844 device emulation. Zoom was restored to 100%1150×819.
6. City → Shop Jewelry: pendant 62×35 and rings 31×31; [capture](shop-jewelry.png).
   Sell Goods preserves those dimensions and displays the expected missing
   trading-license restriction. No sale bypass or qualification grant occurred.
7. Licenses shows six existing 60×60 images. Relics displays its empty-category
   message. City navigation returns successfully. Test player retains the
   purchased, unequipped Penknife and its initial bounded fixture items.

## Remaining artwork work

The [136-file metadata audit](../../../artwork/2026-09-16/before-audit.json)
is not visual approval of every file. Existing baked pale backgrounds, excess
margins and varied portrait/equipment ratios remain visible. Six horizontal
license redraw candidates are preserved with exact prompts in
[ARTWORK](../../../ARTWORK.md#september-16-category-audit-and-corrections), but
are not installed. User choice of deterministic image normalization versus
imagegen-only correction is pending; no unapproved code-based raster editing
was performed. After assets are packaged, rerun affected asset/rendering checks
and final browser acceptance for the actual replacements, including NPC dolls.
