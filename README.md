# AstroField UI

A complete Flutter UI prototype for an offline-first astrophotography planning app.

## Included screens

1. Splash
2. Onboarding
3. Home dashboard
4. Current sky / best targets now
5. Object catalog
6. Object search
7. Object details
8. Tonight planner
9. Sky chart
10. Sun & twilight
11. Moon conditions
12. Weather cache
13. Location / GPS
14. Offline trip pack
15. Sync center
16. Equipment profiles
17. Equipment form
18. Favorites
19. Settings
20. About / data sources

## Design goals

- Dark astronomical UI
- Works as a UI-only prototype with mocked offline data
- GetX navigation
- No paid SDKs or map services
- Custom Flutter painters for score rings, altitude curves and sky chart visuals
- Responsive enough for phone and tablet layouts

## Run

```bash
# If this zip is extracted as a standalone source bundle, first create
# the standard Flutter platform folders without replacing lib/:
flutter create .

flutter pub get
flutter run
```

## Next implementation steps

Replace mocked UI data with:
- GNSS/GPS location
- Local SQLite/Drift catalog
- Offline astronomy calculations
- Cached weather sync
- Equipment/FOV calculations
- Optional offline sky-map rendering
