<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../../../assets/logo/wordmark-dark.svg">
    <img src="../../../assets/logo/wordmark.svg" alt="Lottorito Brand Identity" width="260">
  </picture>
</p>

# Lottorito Brand &amp; Visual Identity Specification

**Document ID:** `LOT-BRAND-001` | **Version:** 1.0.0 | **Status:** Implemented Base Asset Specification

---

## 1. Executive Summary &amp; Positioning
Lottorito is independent, API-first B2B infrastructure for partner programs, multi-level affiliate/agent networks, attribution, commissions, wallets, and operational reporting. 

Unlike consumer-facing lottery games (which rely on sparkling numbers, crossed fingers, or jackpot celebration iconography), Lottorito’s brand identity reflects enterprise reliability, cryptographic ledger accuracy, and seamless partner federation.

## 2. Logo Mark &amp; Construction Geometry

The official logomark consists of two interlocking, facing **L** glyphs:
1. **Left Stem (Primary Platform):** Grounded vertical column with a horizontal return and a 45-degree chamfer.
2. **Right Stem (Federated Partner):** Inverted reciprocal column interlocking with the platform stem across an active diagonal negative space.
3. **Letterform Harmony:** The 45° cut of the logomark directly defines the angled crossbars and terminal strokes of the custom lowercase `t` in the wordmark (`Lottorito`).

### Vector Asset Directory
- Master Light Wordmark: [`assets/logo/wordmark.svg`](../../../assets/logo/wordmark.svg)
- Master Dark Wordmark: [`assets/logo/wordmark-dark.svg`](../../../assets/logo/wordmark-dark.svg)
- Isolated Mark: [`assets/logo/mark.svg`](../../../assets/logo/mark.svg)
- Browser Favicon: [`assets/logo/favicon.svg`](../../../assets/logo/favicon.svg)

## 3. Verified Color Palette &amp; Accessibility (WCAG 2.2 AA / AAA)

| Swatch Name | Hex | RGB | Light Background Contrast | Dark Background Contrast | Usage Scope |
|:---|:---|:---|:---|:---|:---|
| **Deep Teal** | `#00786C` | `0, 120, 108` | **5.38:1** (Pass AA) | 3.02:1 | Primary mark, interactive CTAs, verified badges |
| **Mint Glow** | `#2BB3A4` | `43, 179, 164` | 2.05:1 | **7.92:1** (Pass AAA) | Dark-mode mark, illuminated indicators |
| **Deep Ink** | `#161A29` | `22, 26, 41` | **16.24:1** (Pass AAA) | — | Wordmark typography, high-contrast headings |
| **Mist White** | `#F3F5F4` | `243, 245, 244` | — | **14.88:1** (Pass AAA) | Neutral card surfaces, dark-mode body copy |

## 4. UI/UX Multi-Tenant &amp; White-Labeling Guidelines

Per `LOT-ARCH-001`, `LOT-DATA-001`, and `LOT-DASH-001`:
1. **White-Label Boundary:** Operators and tenants may inject custom CSS variables, custom tenant favicons, and localized logos for player-facing and affiliate portals.
2. **Platform Attribution:** Technical ledger receipts, cryptographic audit logs, administrative system interfaces, and core platform API headers must maintain strict Lottorito brand provenance.
3. **Bidirectional Script Support (RTL/LTR):**
   - English documentation and interfaces render LTR with the mark preceding the wordmark on the left.
   - Persian documentation and interfaces render RTL (`dir="rtl"`). The mark does not flip horizontally (preserving directional geometry), but component placement aligns with natural Persian reading order.

## 5. Bilingual Document Synchronization
- Persian counterpart: [`docs/fa/product/brand-and-visual-identity.md`](../../fa/product/brand-and-visual-identity.md)
