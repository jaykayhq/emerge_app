# Affiliate Strategy Integration - End-to-End Testing Checklist

This document provides a comprehensive testing checklist for all affiliate strategy features implemented in the Emerge app.

---

## Phase 1: Sponsored Challenges Testing

### Challenge Display
- [ ] **Sponsored Badge Visibility**
  - [ ] Verify "Sponsored" badge appears on sponsored challenge cards
  - [ ] Badge displays in top-right corner with star icon
  - [ ] Badge color/contrast meets accessibility standards (WCAG AA)

- [ ] **Partner Logo Display**
  - [ ] Partner logo appears correctly below challenge title
  - [ ] "Powered by" label displays with partner logo
  - [ ] Logos load without errors and maintain aspect ratio

- [ ] **Category Tags**
  - [ ] Category pills display correctly (Fitness, Mindfulness, Learning, Nutrition, Productivity, Creative, Faith)
  - [ ] Category filtering works in challenges screen
  - [ ] "All" category shows all challenges

- [ ] **Reward Preview**
  - [ ] Reward preview chip displays (e.g., "🎁 20% off")
  - [ ] Reward description truncates properly if too long
  - [ ] Tapping reward preview shows full description

### Challenge Analytics Tracking
- [ ] **Impression Tracking**
  - [ ] Challenge view logs `challenge_viewed` event to Firebase Analytics
  - [ ] Impressions increment in user's challenge progress
  - [ ] Partner-level impressions tracked when applicable
  - [ ] Verify analytics parameters: `challenge_id`, `partner_id`

- [ ] **Join Tracking**
  - [ ] Joining challenge logs `challenge_joined` event
  - [ ] `has_affiliate` parameter correctly set (true/false)
  - [ ] User's challenge progress document created with correct status

- [ ] **Completion & Redemption**
  - [ ] Challenge completion updates status in Firestore
  - [ ] Redemption button only appears when challenge is completed
  - [ ] Clicking redemption opens affiliate URL with tracking parameters
  - [ ] `reward_redeemed` event logged with correct parameters
  - [ ] Challenge status updated to "redeemed" after successful redemption

### Affiliate Link Functionality
- [ ] **URL Generation**
  - [ ] Affiliate URLs include `ref=emerge_app` parameter
  - [ ] URLs include `uid` parameter for user attribution
  - [ ] URLs include referral code when provided
  - [ ] Special characters in URLs properly encoded

- [ ] **Link Launching**
  - [ ] Affiliate links open in external browser
  - [ ] Deep links work correctly (return to app)
  - [ ] Error handling for invalid URLs
  - [ ] User feedback when link cannot be opened

---

## Phase 2: Club/Tribe System Testing

### Official Clubs Display
- [ ] **Verification Badge**
  - [ ] Blue checkmark badge appears on official clubs
  - [ ] Badge positioned correctly on club cards
  - [ ] "Official" label displays for official club type

- [ ] **Club Categories**
  - [ ] Official clubs display correct archetype alignment
  - [ ] Club tags display correctly (e.g., #fitness, #morning)
  - [ ] Member count displays accurately

- [ ] **Official Clubs List**
  - [ ] All 13 official clubs seeded correctly
  - [ ] Clubs appear in correct order (by rank/popularity)
  - [ ] Each club has complete information (name, description, image)

### Club Creation Workflow
- [ ] **Eligibility Check**
  - [ ] Users below level 10 cannot see "Create Club" option
  - [ ] Users with < 30 day streak cannot create clubs
  - [ ] Eligibility error message displays clearly
  - [ ] Eligible users can access club creation form

- [ ] **Club Submission**
  - [ ] Club creation form validates required fields
  - [ ] Image upload works for club avatar
  - [ ] Tags can be added/removed
  - [ ] Club type selection works (Private/Public)
  - [ ] Submission shows "Pending Approval" message

- [ ] **Club Approval** (Admin Testing)
  - [ ] Pending clubs appear in admin approval queue
  - [ ] Admin can approve/reject clubs
  - [ ] Rejection reason can be provided
  - [ ] Approved clubs appear in public listings
  - [ ] Clubs are created with `user_private` or `user_public` type

### Brand Sponsorship
- [ ] **Brand Club Features**
  - [ ] Brand logo displays separately from club avatar
  - [ ] Sponsorship dates display correctly
  - [ ] "Sponsored" badge appears on brand clubs
  - [ ] Sponsorship expiration hides expired clubs

---

## Phase 3: Referral System Testing

### Referral Code Generation
- [ ] **Code Format**
  - [ ] Generated codes follow format: `EMERGE_XXXXXX`
  - [ ] Codes use only valid characters (no I, O, 0, 1)
  - [ ] Codes are 6 characters long (excluding prefix)
  - [ ] Code uniqueness verified before assignment

- [ ] **Persistence**
  - [ ] Referral code saved to user's stats document
  - [ ] Referral document created in `/referrals` collection
  - [ ] Code remains consistent across app sessions
  - [ ] Existing user keeps their code on subsequent requests

### Referral Sharing
- [ ] **Code Display**
  - [ ] Referral code displays in invite sheet
  - [ ] Stats show correctly (successful, pending, XP earned)
  - [ ] "Tap to copy" hint displays below code

- [ ] **Clipboard Copy**
  - [ ] Tapping code copies to clipboard
  - [ ] SnackBar confirmation displays: "Referral code copied: EMERGE_XXXXXX"
  - [ ] Confirmation displays for 2 seconds
  - [ ] Works on both iOS and Android

- [ ] **Share Functionality**
  - [ ] Share button opens native share sheet
  - [ ] Share link format: `https://emerge.app/referral?code=EMERGE_XXXXXX`
  - [ ] Share includes descriptive message
  - [ ] Share works across platforms (SMS, Email, Social)

### Referral Tracking
- [ ] **Attribution**
  - [ ] New user signup with referral code tracks attribution
  - [ ] `referral_attribution` event logged to analytics
  - [ ] Referred user's stats document includes `referredByCode`
  - [ ] Referral document status updated to "pending"

- [ ] **Completion**
  - [ ] Referred user completing onboarding triggers completion
  - [ ] Referrer awarded 500 XP
  - [ ] Referral status updated to "completed"
  - [ ] `referral_completed` event logged
  - [ ] Referrer's successful referral count increments

- [ ] **Referral Stats**
  - [ ] Referral stats display correctly in Friends screen
  - [ ] Successful referrals count accurate
  - [ ] Pending referrals count accurate
  - [ ] XP earned total accurate
  - [ ] Stats update in real-time

### Milestone Tracking
- [ ] **Milestone Display**
  - [ ] Milestone cards display correctly (3 referrals, 5 referrals, etc.)
  - [ ] Locked milestones show grayed out
  - [ ] Unlocked milestones show active state
  - [ ] Milestone rewards described clearly

---

## Phase 4: Automation Testing

### Weekly Challenge Generation
- [ ] **Cloud Function Testing**
  - [ ] Weekly challenge generates every Monday at 9:00 AM UTC
  - [ ] Challenge created from unused template
  - [ ] Template marked as used after generation
  - [ ] Old templates not reused

- [ ] **Push Notification**
  - [ ] FCM notification sent to `all_users` topic
  - [ ] Notification title: "🔥 New Weekly Challenge!"
  - [ ] Notification body shows challenge name
  - [ ] Notification data includes `challengeId` and `type`
  - [ ] Tapping notification navigates to challenge details

- [ ] **Challenge Data**
  - [ ] Generated challenge has correct start date
  - [ ] End date is 7 days after start date
  - [ ] Challenge type set to "weekly"
  - [ ] Challenge status is "active"
  - [ ] Steps generated correctly (Day 1, 7, 14, etc.)

### Quarterly Challenge Refresh
- [ ] **Quarterly Themes**
  - [ ] Q1 (Jan 1): "New Year Transformation" partners
  - [ ] Q2 (Apr 1): "Spring Energy" partners
  - [ ] Q3 (Jul 1): "Summer Consistency" partners
  - [ ] Q4 (Oct 1): "Year-End Reflection" partners

- [ ] **Sponsored Challenge Creation**
  - [ ] Challenges created for each partner in quarterly theme
  - [ ] Challenge names include quarterly theme
  - [ ] Challenges marked as sponsored
  - [ ] Affiliate partner ID correctly assigned
  - [ ] Sponsorship dates set to quarter end

- [ ] **Notification**
  - [ ] Push notification sent for each quarterly challenge
  - [ ] Notification title: "🎯 New Quarterly Challenge!"
  - [ ] Notifications include challenge details

### Challenge Ending Reminders
- [ ] **Reminder Notifications**
  - [ ] Notification sent 24 hours before challenge ends
  - [ ] Notification title: "⏰ Challenge Ending Soon!"
  - [ ] Body shows time remaining (e.g., "Only 1 day left")
  - [ ] Tapping notification navigates to challenge

### Reward Notifications
- [ ] **Reward Availability**
  - [ ] Notification sent when challenge completed
  - [ ] Notification title: "🎁 Reward Available!"
  - [ ] Body shows reward description
  - [ ] Tapping notification opens challenge details

---

## Phase 5: Analytics & Reporting Testing

### Firebase Analytics Events
- [ ] **Event Logging**
  - [ ] All challenge events logged with correct parameters
  - [ ] All referral events logged with correct parameters
  - [ ] All club events logged with correct parameters
  - [ ] Events appear in Firebase Analytics dashboard

- [ ] **Parameter Validation**
  - [ ] `challenge_id` parameter included in all challenge events
  - [ ] `has_affiliate` parameter is boolean
  - [ ] `partner_id` parameter included when applicable
  - [ ] `xp_awarded` parameter is numeric
  - [ ] User-level parameters (level, archetype) included

### Conversion Funnels
- [ ] **Funnel Accuracy**
  - [ ] Impressions tracked correctly for sponsored challenges
  - [ ] Joins tracked correctly
  - [ ] Completions tracked correctly
  - [ ] Redemptions tracked correctly
  - [ ] Conversion rates calculated accurately

- [ ] **Revenue Tracking**
  - [ ] Partner revenue breakdowns accurate
  - [ ] Commission rates applied correctly
  - [ ] Date range filters work correctly
  - [ ] Revenue totals match individual transactions

### Admin Dashboard (Optional)
- [ ] **Dashboard Access**
  - [ ] Admin users can access affiliate dashboard
  - [ ] Dashboard displays top performing challenges
  - [ ] Revenue charts render correctly
  - [ ] Conversion funnel visualizations accurate

- [ ] **Reports**
  - [ ] Can generate revenue by partner report
  - [ ] Can generate referral metrics report
  - [ ] Can export data (CSV/PDF)
  - [ ] Reports include date range filtering

---

## Phase 6: Integration & Edge Cases

### Error Handling
- [ ] **Network Errors**
  - [ ] App handles offline mode gracefully
  - [ ] Retry logic for failed network requests
  - [ ] User-friendly error messages displayed
  - [ ] Data cached locally when possible

- [ ] **Invalid Data**
  - [ ] Invalid referral codes rejected with clear message
  - [ ] Malformed URLs handled safely
  - [ ] Missing partner data doesn't crash app
  - [ ] Missing challenge images show placeholder

- [ ] **Permission Errors**
  - [ ] Push notification permission requested properly
  - [ ] App functions without notification permission
  - [ ] Clipboard permission handled on iOS
  - [ ] Location permission (if needed) requested appropriately

### Performance
- [ ] **Load Times**
  - [ ] Challenge list loads within 2 seconds
  - [ ] Club list loads within 2 seconds
  - [ ] Referral stats load within 1 second
  - [ ] Images load progressively without blocking UI

- [ ] **Memory**
  - [ ] No memory leaks when navigating screens
  - [ ] Large lists use pagination/lazy loading
  - [ ] Image caching works correctly
  - [ ] Analytics events batched to reduce overhead

### Security
- [ ] **Data Validation**
  - [ ] All user inputs sanitized
  - [ ] Firestore security rules enforced
  - [ ] Referral codes can't be manipulated
  - [ ] XP awards validated server-side

- [ ] **Privacy**
  - [ ] User data not exposed in URLs
  - [ ] Referral codes are anonymous
  - [ ] Analytics data complies with privacy policy
  - [ ] Sensitive data not logged

### Cross-Platform Testing
- [ ] **iOS**
  - [ ] All features work on iOS
  - [ ] Push notifications display correctly
  - [ ] Share sheet works
  - [ ] Clipboard copy works
  - [ ] Deep links work

- [ ] **Android**
  - [ ] All features work on Android
  - [ ] Push notifications display correctly
  - [ ] Share intent works
  - [ ] Clipboard copy works
  - [ ] Deep links work

---

## Test Data Setup

### Required Test Accounts
1. **Admin Account** - For dashboard access and club approvals
2. **Level 1 User** - For testing eligibility restrictions
3. **Level 10+ User** - For testing club creation
4. **Referrer Account** - Has existing referral code
5. **New User** - For testing referral attribution

### Required Firestore Data
- Affiliate partner documents (at least 3)
- Challenge templates (at least 5)
- Official clubs (13 seeded)
- Sample sponsored challenges
- Sample referral codes

### Required Cloud Functions Deployment
- `generateWeeklyChallenge` - Scheduled for Mondays 9:00 AM UTC
- `refreshQuarterlyChallenges` - Scheduled quarterly
- All indexes deployed from `firestore.indexes.json`

---

## Automated Testing Recommendations

### Unit Tests to Add
- [ ] AffiliateService tracking methods
- [ ] ReferralService code generation uniqueness
- [ ] ClubCreationService eligibility validation
- [ ] AffiliateAnalyticsService calculation accuracy
- [ ] URL generation with various parameters

### Integration Tests to Add
- [ ] Complete challenge flow: view → join → complete → redeem
- [ ] Complete referral flow: share → signup → complete → award
- [ ] Complete club creation flow: submit → approve → list
- [ ] Weekly challenge generation from template
- [ ] Quarterly challenge refresh with theme

---

## Sign-Off

**Testing Completed By:** _______________ **Date:** _______________

**Platform:**
- [ ] iOS
- [ ] Android
- [ ] Web (if applicable)

**Build Version:** _______________

**Notes:**
_______________________________________________________________________________
_______________________________________________________________________________
_______________________________________________________________________________

**Issues Found:**
1. ___________________________________________________________________
2. ___________________________________________________________________
3. ___________________________________________________________________

**Overall Status:**
- [ ] Pass - Ready for Production
- [ ] Pass - Minor Issues (documented above)
- [ ] Fail - Critical Issues Found
