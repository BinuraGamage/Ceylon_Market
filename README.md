<table>
	<tr>
		<td valign="top">
			<img src="assets/icon.png" alt="Ceylon Marketplace Logo" width="180"/>
		</td>
		<td valign="top">
			<h1>Ceylon Marketplace</h1>
			<p>A Flutter marketplace for Sri Lankan local products, built by Group 57 for PUSL2023.</p>
			<p>Designed to help artisans and local sellers reach customers with a modern mobile shopping experience.</p>
			<ul>
				<li>Advanced product visualization with AR preview for furniture and decor</li>
				<li>Engagement-first flow with push notifications for order updates and custom requests</li>
			</ul>
			<p>
				<a href="https://drive.google.com/file/d/1fSbHsoQyXi069C58Im7k2L04MA6TM7V5/view?usp=sharing">
					<img src="https://img.shields.io/badge/Download_APK-00C853?style=for-the-badge&logo=android&logoColor=white" alt="Download APK"/>
				</a>
				<a href="#quick-start">
					<img src="https://img.shields.io/badge/Quick_Start-Open-2563eb?style=for-the-badge" alt="Quick Start"/>
				</a>
			</p>
		</td>
	</tr>
</table>

<p align="center">
  <img src="https://img.shields.io/badge/Module-PUSL2023-d97706?style=flat-square" alt="Module"/>
  <img src="https://img.shields.io/badge/Team-Group%2057-0f766e?style=flat-square" alt="Team"/>
  <img src="https://img.shields.io/badge/Platform-Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Platform"/>
  <img src="https://img.shields.io/badge/Backend-Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black" alt="Backend"/>
</p>

---

## Table of Contents

- [At a Glance](#at-a-glance)
- [Technologies Used](#technologies-used)
- [Feature Highlights](#feature-highlights)
- [Architecture Overview](#architecture-overview)
- [User Roles](#user-roles)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Download APK](#download-apk)
- [Configuration](#configuration)
- [Firebase Setup](#firebase-setup)
- [Data Model Overview](#data-model-overview)
- [Scripts](#scripts)
- [Testing and Quality](#testing-and-quality)
- [Roadmap](#roadmap)
- [Development Notes](#development-notes)
- [Resources](#resources)
- [License](#license)

<p align="center">
	<a href="#feature-highlights"><img src="https://img.shields.io/badge/Explore_Features-1f2937?style=for-the-badge" alt="Explore Features"/></a>
	<a href="#project-structure"><img src="https://img.shields.io/badge/View_Architecture-7c3aed?style=for-the-badge" alt="View Architecture"/></a>
	<a href="#testing-and-quality"><img src="https://img.shields.io/badge/Testing_&_Quality-15803d?style=for-the-badge" alt="Testing and Quality"/></a>
</p>

---

## At a Glance

| Area | Details |
| --- | --- |
| Platform | Flutter (Android primary, iOS secondary) |
| State Management | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Key Features | Product catalog, shops, cart, checkout, customization, AR preview, notifications |

## Technologies Used

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-0F9D58?style=flat-square&logo=riverpod&logoColor=white)
![GoRouter](https://img.shields.io/badge/GoRouter-3D5AFE?style=flat-square&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=flat-square&logo=firebase&logoColor=black)
![Cloudinary](https://img.shields.io/badge/Cloudinary-3448C5?style=flat-square&logo=cloudinary&logoColor=white)
![Stripe](https://img.shields.io/badge/Stripe-635BFF?style=flat-square&logo=stripe&logoColor=white)

---

## Feature Highlights

- Curated local products with rich media, tags, and categories
- Shop profiles with stories and ratings
- Customization requests with messages and attachments
- Order lifecycle tracking with clear status updates
- AR preview for furniture and decor
- Push notifications for orders and custom requests

<table>
	<tr>
		<td valign="top" width="33%">
			<h3>Immersive Shopping</h3>
			<p>AR preview helps users visualize furniture and decor in real space before purchasing.</p>
		</td>
		<td valign="top" width="33%">
			<h3>Smart Engagement</h3>
			<p>Real-time notifications keep customers, sellers, and designers updated at each key action.</p>
		</td>
		<td valign="top" width="33%">
			<h3>Local Commerce</h3>
			<p>Built to spotlight Sri Lankan creators with storytelling, quality listings, and secure checkout flow.</p>
		</td>
	</tr>
</table>

---

## Architecture Overview

The app follows a feature-first Flutter architecture with clear separation of concerns:

- UI Layer: screens and widgets under `lib/features/` and `lib/shared/widgets/`
- State Layer: Riverpod providers under `lib/providers/`
- Domain/Data Layer: models under `lib/models/`
- Service Layer: Firebase and integrations under `lib/services/`
- Core Layer: router, constants, validators, and app-wide utilities under `lib/core/`

Data flow is designed as:
`Widget -> Provider -> Service -> Firebase`

This keeps business logic out of widgets and makes screens easier to maintain and test.

---

## User Roles

- Customer: browse products, place orders, submit customization requests, track order updates
- Seller: manage shops/products, process orders, respond to marketplace demand
- Designer: receive and handle custom requests
- Admin: monitor and manage platform-level operations (including ad management)

---

## Project Structure

```
lib/
	core/            # constants, router, validators, utilities
	features/        # feature modules (auth, home, shop, products, checkout, ...)
	models/          # pure data models
	providers/       # Riverpod providers
	services/        # Firebase services
	shared/          # shared widgets and themes
```

---

## Quick Start

Prerequisites:

- Flutter SDK (stable channel)
- Dart SDK (as required by `pubspec.yaml`)
- Android Studio or VS Code with Flutter extension
- Firebase project access for backend features

1) Install dependencies

```bash
flutter pub get
```

2) Run the app

```bash
flutter run
```

For the prepared debug launch configuration in VS Code, use the launch option:

- `Flutter (Gemini 3 Flash)` from `.vscode/launch.json`

<details>
	<summary><strong>Need a full clean rebuild?</strong></summary>

```bash
flutter clean
flutter pub get
flutter run
```

</details>

---

## Download APK

To generate a release APK for Android, run:

```bash
flutter build apk --release
```

The APK will be created at:

```bash
build/app/outputs/flutter-apk/app-release.apk
```

If you publish builds later, you can replace this section link with your release page URL.

---

## Configuration

The project supports runtime configuration through `--dart-define` values.

Current launch setup includes:

- `GEMINI_API_KEY_B64`
- `GEMINI_MODEL`

Example:

```bash
flutter run \
	--dart-define=GEMINI_API_KEY_B64=your_base64_key \
	--dart-define=GEMINI_MODEL=gemini-3-flash-preview
```

---

## Firebase Setup

- Firebase is configured via `firebase.json` and `lib/firebase_options.dart`.
- Android config lives in `android/app/google-services.json`.
- Ensure you have Firebase CLI set up if you need local emulators or functions.

Firebase project currently linked:

- Project ID: `ceylonmarketplace-38df8`

Cloud Functions source:

- `functions/index.js`

---

## Data Model Overview

Main Firestore collections used by the app:

- `users`
- `shops`
- `products`
- `orders`
- `customRequests`

Nested collections:

- `users/{userId}/cart`
- `products/{productId}/reviews`
- `customRequests/{requestId}/messages`

---

## Scripts

- Seed Firestore data: `scripts/seed_firestore.dart`
- Resize launcher icon: `scripts/resize_launcher_icon.sh`

---

## Testing and Quality

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Current test folder:

- `test/widget_test.dart`

---

## Roadmap

- Expand production-ready CI for lint, test, and build validation
- Improve seller analytics and campaign insights
- Strengthen search and recommendations
- Enhance AR coverage across more product categories
- Add formal release channel for APK distribution

---

## Development Notes

- Use constants for Firestore paths and colors.
- Always handle loading, empty, and error states in screens.

---

## Resources

- Flutter docs: https://docs.flutter.dev/
- Firebase docs: https://firebase.google.com/docs

---

## License

Academic project for PUSL2023. All rights reserved by Group 57.
