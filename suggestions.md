# Backend API Suggestions

## 1) Make vignette dimensions orthogonal (`time` vs `region`)

### Current pain point
- County and time information are currently encoded together in `vignetteType` values like `YEAR_12`.
- This couples two independent dimensions:
  - time axis (`DAY`, `WEEK`, `MONTH`, `YEAR`)
  - space axis (national vs county code)

### Suggested model
- Keep `vignetteType` for the time dimension only.
- Introduce a new field for region dimension, e.g. `regionCode`.

Example:

```json
{
  "vignetteType": "YEAR",
  "regionCode": "NATIONAL",
  "vehicleCategory": "CAR",
  "cost": 6660,
  "trxFee": 200,
  "sum": 6860
}
```

and county:

```json
{
  "vignetteType": "YEAR",
  "regionCode": "12",
  "vehicleCategory": "CAR",
  "cost": 6660,
  "trxFee": 200,
  "sum": 6860
}
```

### Benefits
- Clearer data semantics and simpler client parsing.
- Easier filtering/grouping by duration or geography.
- More future-proof for additional region scopes (macro-region, toll segments, etc.).

## 2) Add value recommendation for county selection

### Suggested feature
- During county selection, calculate whether selected county total exceeds equivalent national vignette price.
- If yes, return or enable recommendation metadata so UI can warn user:
  - "Selected county total is higher than national yearly vignette."

### Backend options
- **Option A (client-side only support):** expose a clear national reference item in payload so client compares.
- **Option B (recommended):** backend computes recommendation and returns:
  - `isBetterNationalDeal` (bool)
  - `recommendedProduct` (id/type)
  - `savingAmount` (number)

### Benefits
- Better user value guidance.
- Consistent recommendation logic across platforms.

