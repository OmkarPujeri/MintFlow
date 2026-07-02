# MintFlow API Contract
**Version:** 1.0 · **Base URL:** `http://localhost:8000` (dev) · `https://api.mintflow.app` (prod)

> All protected routes require `Authorization: Bearer <access_token>` header.
> Token is returned from `/api/v1/auth/login` and stored by `ApiClient` at key `mintflow.auth.token`.

---

## Authentication

### POST `/api/v1/auth/register`
Create a new company admin account.

**Request:**
```json
{
  "email": "admin@brandco.com",
  "password": "yourpassword",
  "role": "company_admin"
}
```

**Response `201`:**
```json
{
  "id": "uuid",
  "email": "admin@brandco.com",
  "role": "company_admin",
  "message": "Account created successfully"
}
```

---

### POST `/api/v1/auth/login`
Login and receive JWT tokens + CompanyAdmin fields.

**Request:**
```json
{
  "email": "admin@brandco.com",
  "password": "yourpassword"
}
```

**Response `200`:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "id": "uuid",
  "email": "admin@brandco.com",
  "name": "Company Admin",
  "companyName": "My Brand",
  "role": "company_admin"
}
```
> 📌 **Flutter:** Save `access_token` via `ApiClient.saveToken()`. Build `CompanyAdmin` from `id`, `name`, `email`, `companyName`.

---

### POST `/api/v1/auth/refresh`
Get a new access token using a refresh token.

**Request:** `{ "refresh_token": "eyJ..." }`  
**Response `200`:** `{ "access_token": "eyJ...", "token_type": "bearer" }`

---

### POST `/api/v1/auth/logout` 🔒
Invalidate session.

**Response `200`:** `{ "message": "Logged out successfully" }`

---

## Campaigns 🔒
> All campaign routes require `company_admin` role.

### GET `/api/v1/campaigns/`
List all campaigns for the logged-in admin.

**Response `200`:** Array of Campaign objects (see schema below).

---

### POST `/api/v1/campaigns/`
Create a new campaign.

**Request body matches `Campaign.toJson()` exactly:**
```json
{
  "name": "Summer sneaker launch",
  "description": "Introduce cushioned everyday sneakers.",
  "youtubeUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "youtubeVideoId": "dQw4w9WgXcQ",
  "budget": 10000.0,
  "rewardPerCompletion": 2.0,
  "startDate": "2026-07-01T00:00:00.000",
  "endDate": "2026-07-22T00:00:00.000",
  "interactions": [
    {
      "type": "quiz",
      "question": "Which feature was highlighted?",
      "options": ["Cushioned sole", "Leather bag", "Smart watch"],
      "correctAnswer": "Cushioned sole"
    }
  ]
}
```

**Response `201`:** Full Campaign object.

---

### GET `/api/v1/campaigns/{campaign_id}`
Get a single campaign by ID.

**Response `200`:** Full Campaign object.

---

### PATCH `/api/v1/campaigns/{campaign_id}`
Update a campaign (all fields optional).

**Request:** Same shape as POST, all fields optional.  
**Response `200`:** Updated Campaign object.

---

### POST `/api/v1/campaigns/{campaign_id}/publish`
Set campaign status to `active`.

**Response `200`:** Updated Campaign object.

---

### POST `/api/v1/campaigns/{campaign_id}/pause`
Set campaign status to `paused`.

**Response `200`:** Updated Campaign object.

---

### DELETE `/api/v1/campaigns/{campaign_id}`
Permanently delete a campaign.

**Response `204`:** No content.

---

## Campaign Object Schema
This is what the backend returns for every campaign. **Matches `Campaign.fromJson()` exactly.**

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "name": "Summer sneaker launch",
  "description": "Introduce cushioned everyday sneakers.",
  "youtubeUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "youtubeVideoId": "dQw4w9WgXcQ",
  "budget": 10000.0,
  "rewardPerCompletion": 2.0,
  "remainingBudget": 9990.0,
  "startDate": "2026-07-01T00:00:00+00:00",
  "endDate": "2026-07-22T00:00:00+00:00",
  "status": "active",
  "interactions": [
    {
      "type": "quiz",
      "question": "Which feature was highlighted?",
      "options": ["Cushioned sole", "Leather bag", "Smart watch"],
      "correctAnswer": "Cushioned sole"
    }
  ],
  "views": 920,
  "completions": 620,
  "createdAt": "2026-07-01T07:00:00+00:00"
}
```

| Frontend Field | Backend DB Column | Notes |
|---------------|-------------------|-------|
| `id` | `campaigns.id` | UUID as string |
| `youtubeUrl` | `campaigns.youtube_url` | Any YouTube URL format |
| `youtubeVideoId` | `campaigns.youtube_video_id` | 11-char extracted ID |
| `budget` | `campaigns.total_budget` | Total allocated budget |
| `rewardPerCompletion` | `campaigns.reward_per_view` | Rs. per rewarded view |
| `remainingBudget` | `campaigns.remaining_budget` | Budget - rewards paid |
| `views` | Computed from `watch_sessions` | Sessions started |
| `completions` | Computed from `watch_sessions` | Sessions rewarded |
| `createdAt` | `campaigns.created_at` | ISO8601 |

---

## Analytics 🔒

### GET `/api/v1/analytics/campaigns/{campaign_id}`
Get stats for a single campaign.

**Response `200`:**
```json
{
  "campaign_id": "uuid",
  "campaign_name": "Summer sneaker launch",
  "status": "active",
  "total_budget": 10000.0,
  "remaining_budget": 9990.0,
  "total_spent": 10.0,
  "total_views": 920,
  "completed_views": 847,
  "rewarded_views": 620,
  "completion_rate": 84.7
}
```

### GET `/api/v1/analytics/campaigns/{campaign_id}/responses`
Get all viewer responses for a campaign.

**Response `200`:**
```json
{
  "campaign_id": "uuid",
  "total_responses": 124,
  "responses": [
    {
      "question_id": "uuid",
      "response_value": "Cushioned sole",
      "is_correct": true,
      "responded_at": "2026-07-01T08:30:00+00:00"
    }
  ]
}
```

---

## Feed & Watch (Viewer-only) 🔒

### GET `/api/v1/feed/`
Get all active campaigns for the viewer feed.

### POST `/api/v1/watch/start`
Start a watch session.
```json
{ "campaign_id": "uuid" }
```

### PATCH `/api/v1/watch/{session_id}/progress`
Update watch percentage (call every 5 seconds from YouTube IFrame API).
```json
{ "watch_percentage": 73.5 }
```

### POST `/api/v1/watch/{session_id}/complete`
Mark video as fully watched.

### POST `/api/v1/rewards/claim/{session_id}`
Claim reward after completing video + interactions.

### POST `/api/v1/interactions/{session_id}/submit`
Submit quiz/survey/poll/feedback answers.

---

## Wallet (Viewer-only) 🔒

### GET `/api/v1/wallet/`
Get viewer wallet balance.

### GET `/api/v1/wallet/transactions`
Get transaction history.

---

## Status Codes

| Code | Meaning |
|------|---------|
| `200` | Success |
| `201` | Created |
| `204` | Deleted |
| `400` | Bad request / business rule violation |
| `401` | Not authenticated / invalid token |
| `403` | Wrong role |
| `404` | Not found |
| `409` | Conflict (e.g. email already exists) |
| `422` | Validation error (check request body) |
| `500` | Server error |

---

## Flutter Integration Checklist

- [ ] `AppConfig.useBackend = true` OR run with `--dart-define=USE_BACKEND=true`
- [ ] `AppConfig.apiBaseUrl` = your backend URL (default: `http://localhost:8000`)
- [ ] `AuthRepository` now calls real login API ✅
- [ ] `CampaignRepository` now calls real campaign APIs ✅
- [ ] `ApiClient.saveToken()` called after login ✅
- [ ] YouTube IFrame API needed for watch tracking (not yet implemented)
- [ ] `DashboardController` needs `ApiClient` injected alongside `LocalStorage`

---

## CORS Allowed Origins (Backend)
```
http://localhost:3000
http://localhost:8080
https://omkarpujeri.github.io
```
