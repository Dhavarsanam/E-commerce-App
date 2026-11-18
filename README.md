# Lumière — Premium E-commerce (Flutter frontend)

A frontend-only shopping app for Android and iOS. All data is mocked in `lib/data/mock_data.dart`, so you can replace it with API calls later.

Product photos are free-licence images from [Unsplash](https://unsplash.com/license), loaded over the network. Each product stores photo ids in `images`. To use your own catalogue, change `Product.imageUrl` in `lib/data/models.dart` to point at your CDN. If a photo fails to load, the app falls back to a code-drawn product render.

## Run

```bash
flutter pub get
flutter run
```

Sign in with any email and a password of 6+ characters. Choose **Vendor / Admin** on the sign-in screen to open the admin panel.

## Structure

| Path | What's inside |
| --- | --- |
| `lib/core/theme.dart` | Design tokens (colours, motion curves, radii), light and dark themes |
| `lib/state/app_state.dart` | Cart, wishlist, orders, notifications, recommendations |
| `lib/widgets/effects.dart` | Aurora background, glass, 3D `TiltCard`, `Reveal` stagger, shimmer, animated counters, page transition |
| `lib/widgets/product_visual.dart` | `ProductPhoto` (progressive loading, shimmer, fade-in, Ken Burns drift) and the code-drawn fallback render |
| `lib/widgets/components.dart` | Gradient CTA, heart burst, product card, quantity stepper and more |
| `lib/widgets/charts.dart` | Animated area, bar, donut and sparkline charts |
| `lib/widgets/nav_bar.dart` | Floating glass dock with a sliding liquid indicator |
| `lib/screens/` | Splash, onboarding, auth, home, explore, detail, bag, checkout, success, orders/tracking, wishlist, profile, notifications |
| `lib/screens/admin/` | Vendor dashboard, inventory and order management |

## Tests

```bash
flutter test
```

`test/screens_smoke_test.dart` renders every screen at phone size in both themes and fails on any layout overflow or exception.
