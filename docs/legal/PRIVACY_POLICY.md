# Privacy Policy — Emerge

**Effective Date: March 17, 2026**

This Privacy Policy describes how Emerge ("we", "us", or "our") collects, uses, and shares your personal information when you use the Emerge mobile application ("App").

## 1. Information We Collect

### 1.1 Account Data
- **Registration**: Email address and display name (via Firebase Authentication).
- **Authentication Provider**: Google Sign-In or email/password.

### 1.2 Profile & Usage Data
- Habit creation, completion, and streak data.
- Gamification progress (XP, levels, archetype, world state).
- Onboarding selections (archetype, identity attributes, anchors).
- AI coaching interactions and reflections.
- Community interactions (club memberships, accountability partnerships).

### 1.3 Health & Activity Data (Optional)
- **Fitness Data**: Steps, activities from Google Fit / Health Connect (only if you grant permission).
- **Screen Time**: App usage statistics (only if you grant permission via Android's Usage Access setting).
- This data is used solely to auto-verify habit completions. It is stored on your device and in your private Firestore profile.

### 1.4 Device & Analytics Data
- Device type, operating system version, and app version.
- Firebase Analytics events (anonymized usage patterns).
- Crash reports and diagnostics via Firebase Crashlytics.
- Advertising ID (AAID) for ad personalization via Google AdMob.

### 1.5 Subscription Data
- Purchase status and entitlements (managed by RevenueCat).
- We do **NOT** store payment card details or billing information.

## 2. How We Use Your Information

| Purpose | Data Used |
|---------|-----------|
| Provide core habit tracking | Account, profile, habit data |
| Gamification (XP, levels, world) | Usage data, streak data |
| AI coaching & reflections | Habit data, archetype, interactions |
| Push notifications & reminders | FCM token, notification preferences |
| Display advertisements (free tier) | Advertising ID |
| Process subscriptions | Purchase status via RevenueCat |
| App performance & stability | Crash logs, analytics |
| Community features | Profile data, club membership |

## 3. Data Storage & Security

- All user data is stored in **Google Cloud Firestore** (Firebase), with servers in the United States.
- Data is encrypted in transit (TLS 1.2+) and at rest.
- API keys and secrets are stored server-side in **Google Cloud Secret Manager**.
- Firebase App Check is enabled to prevent unauthorized API access.
- We follow Firebase and Google Cloud security best practices.

## 4. Data Sharing

We do **not** sell your personal data. We share data only with the following service providers to operate the App:

| Provider | Purpose | Data Shared |
|----------|---------|-------------|
| Google Firebase / Cloud | Infrastructure, auth, database, analytics | Account data, usage data, crash logs |
| Google AdMob | Advertising (free tier only) | Advertising ID, anonymized identifiers |
| RevenueCat | Subscription management | User ID, purchase status |
| Groq AI (via Cloud Functions) | AI coaching responses | Anonymized habit context (no PII) |

## 5. Data Retention

- We retain your data for as long as your account is active.
- Upon account deletion, your personal data is permanently removed from our systems within 30 days.
- Anonymized, aggregated analytics data may be retained indefinitely.

## 6. Your Rights & Choices

You have the right to:
- **Access** your personal data through the App's profile and settings.
- **Delete** your account and all associated data via Settings → Delete Account.
- **Export** your data by contacting support.
- **Opt out** of analytics collection in your device settings.
- **Revoke** health and app usage permissions at any time in your device's system settings.
- **Manage** notification preferences within the App's settings.
- **Opt out** of personalized advertising via your device's ad settings.

### For EU/EEA Users (GDPR)
You have additional rights including data portability, the right to restrict processing, and the right to lodge a complaint with a supervisory authority.

## 7. Children's Privacy

The App is not intended for users under 13 years of age. We do not knowingly collect personal information from children under 13. If we learn that we have inadvertently collected such data, we will promptly delete it.

## 8. International Data Transfers

Your data may be processed in the United States (where Google Cloud infrastructure is located). By using the App, you consent to the transfer of your data to the United States.

## 9. Changes to This Policy

We will notify users of material changes via in-app notification or email. The "Effective Date" at the top of this policy indicates when it was last updated.

## 10. Contact Us

For privacy questions, data requests, or concerns, please contact us at: **joeukpai55@gmail.com**
