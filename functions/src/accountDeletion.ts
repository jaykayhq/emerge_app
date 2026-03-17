/**
 * Cloud Function: Account Deletion Page
 *
 * Serves a static HTML page with instructions for deleting
 * your Emerge account and all associated data.
 *
 * URL: https://us-central1-tradeflash-l2966.cloudfunctions.net/accountDeletion
 */

import * as functionsV1 from "firebase-functions/v1";

export const accountDeletion = functionsV1.https.onRequest((_req, res) => {
  res.status(200).send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Delete Your Account — Emerge</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #0D0F14;
      color: #e0e0e0;
      line-height: 1.6;
      min-height: 100vh;
      display: flex;
      justify-content: center;
      padding: 40px 20px;
    }
    .container {
      max-width: 640px;
      width: 100%;
    }
    .logo {
      font-size: 28px;
      font-weight: 800;
      color: #4DD0C8;
      margin-bottom: 8px;
    }
    h1 {
      font-size: 24px;
      color: #ffffff;
      margin-bottom: 8px;
    }
    .subtitle {
      color: #999;
      font-size: 15px;
      margin-bottom: 32px;
    }
    .card {
      background: rgba(255,255,255,0.06);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 16px;
      padding: 28px;
      margin-bottom: 24px;
    }
    h2 {
      font-size: 18px;
      color: #4DD0C8;
      margin-bottom: 16px;
    }
    .step {
      display: flex;
      gap: 14px;
      margin-bottom: 16px;
    }
    .step-num {
      flex-shrink: 0;
      width: 28px;
      height: 28px;
      background: #4DD0C8;
      color: #0D0F14;
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 700;
      font-size: 14px;
    }
    .step-text { font-size: 15px; padding-top: 3px; }
    .warning {
      background: rgba(239, 83, 80, 0.1);
      border: 1px solid rgba(239, 83, 80, 0.3);
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 24px;
    }
    .warning h3 {
      color: #EF5350;
      font-size: 16px;
      margin-bottom: 10px;
    }
    .warning ul { padding-left: 20px; }
    .warning li {
      color: #ccc;
      font-size: 14px;
      margin-bottom: 4px;
    }
    .alt-card {
      background: rgba(77, 208, 200, 0.06);
      border: 1px solid rgba(77, 208, 200, 0.2);
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 24px;
    }
    .alt-card h3 {
      color: #4DD0C8;
      font-size: 16px;
      margin-bottom: 8px;
    }
    .alt-card a {
      color: #4DD0C8;
      text-decoration: underline;
    }
    .footer {
      color: #666;
      font-size: 13px;
      text-align: center;
      margin-top: 16px;
    }
    .footer a { color: #4DD0C8; text-decoration: none; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">Emerge</div>
    <h1>Delete Your Account</h1>
    <p class="subtitle">We're sorry to see you go. Here's how to delete your account and all associated data.</p>

    <div class="card">
      <h2>How to Delete Your Account (In-App)</h2>
      <div class="step">
        <div class="step-num">1</div>
        <div class="step-text">Open the <strong>Emerge</strong> app and log in to your account.</div>
      </div>
      <div class="step">
        <div class="step-num">2</div>
        <div class="step-text">Tap your <strong>profile icon</strong> or go to <strong>Settings</strong>.</div>
      </div>
      <div class="step">
        <div class="step-num">3</div>
        <div class="step-text">Scroll down to <strong>Support &amp; Legal</strong>.</div>
      </div>
      <div class="step">
        <div class="step-num">4</div>
        <div class="step-text">Tap <strong>Delete Account</strong>.</div>
      </div>
      <div class="step">
        <div class="step-num">5</div>
        <div class="step-text">Type <strong>DELETE</strong> to confirm, then tap <strong>Delete Forever</strong>.</div>
      </div>
    </div>

    <div class="warning">
      <h3>⚠ What Gets Deleted</h3>
      <ul>
        <li>Your profile and account credentials</li>
        <li>All habits, streaks, and completion history</li>
        <li>XP, levels, and world progress</li>
        <li>Club and tribe memberships</li>
        <li>AI coaching history and reflections</li>
      </ul>
      <p style="margin-top: 12px; font-size: 14px; color: #EF5350;">
        This action is <strong>permanent</strong> and cannot be undone. Your data will be removed within 30 days.
      </p>
    </div>

    <div class="alt-card">
      <h3>Can't Access the App?</h3>
      <p style="font-size: 14px; color: #ccc;">
        If you're unable to delete your account through the app, you can request deletion by emailing us at
        <a href="mailto:joeukpai55@gmail.com">joeukpai55@gmail.com</a>.
        Please include the email address associated with your account. We will process your request within 30 days.
      </p>
    </div>

    <div class="footer">
      <p>&copy; 2026 Emerge — 
        <a href="https://docs.google.com/document/d/e/2PACX-1vRt5cCpFS7PLmh_nwhxq3ec9YtRWQZk7mrOqbVN7aThrclpjgYL3q5r-nAqlftQJVkOSWzxnG_FDfjo/pub">Privacy Policy</a> · 
        <a href="https://docs.google.com/document/d/e/2PACX-1vQX-5ydyuD3ZYp_-8b_2rVyyuKW9zF2NaMm1CBxxwE5s1LXASy1P7Plxf8axNGc_TFJw-OnZrULmjgP/pub">Terms of Service</a>
      </p>
    </div>
  </div>
</body>
</html>`);
});
