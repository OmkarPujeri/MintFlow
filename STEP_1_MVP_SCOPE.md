# MintFlow Step 1: MVP Scope Breakdown

## Purpose

This document breaks down Step 1 of the MintFlow build plan: freezing the MVP scope.

The goal of Step 1 is to convert the full PRD into a clear, buildable first version. MintFlow has a large long-term vision, but the MVP should prove one core product loop before adding advanced AI, fraud systems, withdrawals, or scale infrastructure.

## Core MVP Hypothesis

MintFlow MVP should prove that:

- Company admins are willing to create campaigns that pay for verified attention.
- Viewers are willing to watch short-form branded videos in exchange for rewards.
- The system can track a basic watch-and-reward flow reliably.
- Company admins can see enough campaign performance data to understand value.

If this loop works, the product has a foundation.

## MVP Core Loop

```text
Company admin creates campaign
↓
Viewer sees campaign in feed
↓
Viewer watches video
↓
Viewer completes quiz, survey, poll, or feedback
↓
System verifies basic completion
↓
Viewer earns reward
↓
Company admin sees campaign analytics
```

## MVP Product Definition

The MVP is not the full Verified Attention Network yet.

The MVP is a simple rewarded advertising platform with two users:

- Company admins can upload short video campaigns from a dashboard.
- Company admins can add quizzes, surveys, polls, and feedback questions.
- Viewers can watch active campaigns in the mobile app.
- Viewers can complete a required interaction.
- Viewers can earn a wallet reward.
- Company admins can view basic campaign results.

## MVP Roles

### Viewer

The viewer is the reward-earning user.

Viewer responsibilities:

- Sign up or log in.
- Watch sponsored videos.
- Complete quiz, survey, poll, or feedback interactions.
- Earn rewards after valid campaign completion.
- View wallet balance and reward history.

### Company Admin

The company admin creates and manages paid campaigns from the web dashboard.

Company admin responsibilities:

- Sign up or log in.
- Create a campaign.
- Upload or attach a video.
- Set campaign budget and reward per valid view.
- Add a quiz, survey, poll, or feedback form.
- Publish or pause campaigns.
- View campaign responses and analytics.

## Must-Have MVP Features

### Authentication

Required:

- Email/password login.
- Role-based access for viewer and company admin.
- Basic session handling.

Not required in MVP:

- Google login.
- Apple login.
- Phone OTP.
- Enterprise SSO.

### Viewer Feed

Required:

- Show active published campaigns.
- Display video, campaign title, company name, and reward amount.
- Allow viewer to start and finish a campaign watch session.
- Track watch progress.

Not required in MVP:

- Infinite scroll optimization.
- AI recommendations.
- Personalized ranking.
- Complex category matching.

### Campaign Watching

Required:

- Track when the viewer starts watching.
- Track watch progress percentage.
- Mark video as completed when minimum watch threshold is reached.
- Prevent reward if the viewer exits too early.

MVP watch threshold:

```text
Minimum watch percentage: 80%
```

### Interactive Campaign Tasks

Required:

- Company admin can attach campaign tasks.
- Viewer must complete the required interaction after watching.
- System stores viewer response.

Quiz MVP:

- Multiple-choice question.
- One correct answer.
- Reward can depend on correct answer.

Survey MVP:

- One or more multiple-choice questions.
- No correct answer.
- Reward depends on completion.

Poll MVP:

- One or more options.
- No correct answer.
- Reward depends on completion.

Feedback MVP:

- Short text or rating response.
- No correct answer.
- Reward depends on completion.

Not required in MVP:

- Mini games.
- Brand recall after delay.
- AI-generated questions.

### Reward Engine

Required:

- Calculate a fixed reward per valid campaign completion.
- Check campaign has enough remaining budget.
- Prevent duplicate reward from the same campaign for the same viewer.
- Create wallet transaction after valid completion.
- Deduct spend from campaign budget.

MVP reward eligibility:

```text
Viewer earns reward only if:
- viewer is logged in
- campaign is active
- campaign has remaining budget
- viewer watched at least 80% of the video
- viewer completed all required campaign tasks
- viewer has not already earned from this campaign
```

Example:

```text
Campaign budget: Rs. 10,000
Reward per valid completion: Rs. 2
Viewer watches 85%
Viewer completes required campaign task
Reward granted: Rs. 2
Remaining campaign budget: Rs. 9,998
```

### Wallet

Required:

- Show current wallet balance.
- Show reward history.
- Store transaction ledger.
- Mark all rewards as internal platform credits.

Not required in MVP:

- Real withdrawals.
- Razorpay integration.
- Cashfree integration.
- KYC.
- Bank account management.

### Company Admin Campaign Creation

Required:

- Campaign name.
- Campaign description.
- Video upload or video URL placeholder.
- Total campaign budget.
- Reward per valid completion.
- Start date.
- End date.
- Campaign status.
- Quiz, survey, poll, or feedback setup.
- Publish campaign to viewer mobile app.

Not required in MVP:

- Advanced targeting.
- Real-time bidding.
- AI campaign optimization.
- Ad quality scoring.
- Complex audience segmentation.

### Company Admin Analytics

Required:

- Total views.
- Completed views.
- Verified rewarded views.
- Quiz, survey, poll, and feedback responses.
- Total amount spent.
- Remaining budget.
- Completion rate.

Not required in MVP:

- ROAS.
- Brand recall rate.
- Sentiment analysis.
- Predictive analytics.
- Audience heatmaps.

## Explicitly Excluded From MVP

These features are part of the larger MintFlow vision but should not be built in Step 1 or the first MVP implementation:

- AI recommendation engine.
- Attention score ML model.
- Fraud detection engine.
- Emulator detection.
- Root detection.
- VPN abuse detection.
- Device fingerprinting.
- AI ad quality scoring.
- AI question generation.
- Dynamic reward optimization.
- Referral program.
- Daily streaks.
- Leaderboards.
- Push notifications.
- Real withdrawals.
- KYC.
- Razorpay or Cashfree payout integration.
- ClickHouse analytics.
- Kubernetes deployment.
- Real-time bidding.
- Enterprise dashboard.
- Agency APIs.
- White-label platform.

## MVP Data Objects

The scope implies these core objects:

- User
- Company Admin Profile
- Campaign
- Campaign Video
- Campaign Interaction
- Watch Session
- Quiz Response
- Survey Response
- Poll Response
- Feedback Response
- Wallet
- Wallet Transaction

## MVP Status Model

### Campaign Status

```text
draft
active
paused
completed
```

### Watch Session Status

```text
started
completed
rewarded
```

### Wallet Transaction Type

```text
reward
adjustment
reversal
```

## MVP Acceptance Criteria

The MVP scope is complete when the following can be demonstrated:

- A viewer can sign up and log in.
- A company admin can sign up and log in.
- A company admin can create a campaign.
- A company admin can attach a video and quiz, survey, poll, or feedback form.
- A company admin can publish the campaign.
- The active campaign appears in the viewer mobile feed.
- The viewer can watch the campaign video.
- The system tracks whether the viewer watched at least 80%.
- The viewer can complete the required campaign tasks.
- The system checks reward eligibility.
- The viewer receives a wallet reward.
- Duplicate rewards for the same campaign are blocked.
- Campaign budget decreases after valid reward.
- Company admin can see basic campaign analytics.
- Company admin can see response data and reward transactions for their campaigns.

## Important Product Decisions To Lock

Before implementation starts, the team should decide:

1. What is the default reward per valid completion?
2. Should quiz correctness be required for reward, or only quiz completion?
3. Should surveys, polls, and feedback always reward after completion?
4. What is the minimum campaign budget?
5. Can one viewer earn from the same campaign more than once?
6. Should videos be uploaded in MVP, or should MVP use video URLs first?
7. Is the first product mobile-only, web-only, or mobile plus dashboard?

Recommended MVP decisions:

- Default reward per valid completion: Rs. 2.
- Quiz reward requires correct answer.
- Survey, poll, and feedback rewards require completion only.
- Minimum campaign budget: Rs. 1,000.
- One viewer can earn from a campaign only once.
- Use video URLs first if upload/storage slows development.
- Build viewer as mobile app and company admin as web dashboard.

## Suggested Step 1 Deliverables

By the end of Step 1, the team should have:

- Final MVP feature list.
- Out-of-scope feature list.
- MVP user roles.
- MVP reward rules.
- MVP acceptance criteria.
- Initial data object list.
- Two-person task ownership.

## Two-Member Team Task Split

### Member 1: Product, Backend, and Data Ownership

Best ownership areas:

- Finalize MVP scope decisions.
- Convert this scope into user stories.
- Define database schema.
- Design backend API endpoints.
- Implement authentication and role permissions.
- Implement campaign creation APIs.
- Implement reward engine logic.
- Implement wallet ledger logic.
- Write backend tests for reward rules.

Suggested first tasks:

1. Lock reward rules.
2. Create user stories for viewer and company admin.
3. Draft database schema.
4. Draft API route list.
5. Implement backend project setup.

### Member 2: Frontend, UX, and Dashboard Ownership

Best ownership areas:

- Design MVP screens.
- Create viewer app flow.
- Create company admin dashboard flow.
- Build campaign creation UI.
- Build feed and watch UI.
- Build quiz, survey, poll, and feedback UI.
- Build wallet UI.
- Build analytics UI.
- Connect frontend to backend APIs.

Suggested first tasks:

1. Create screen list for viewer and company admin.
2. Create low-fidelity wireframes.
3. Define navigation structure.
4. Build frontend project setup.
5. Implement static MVP screens before backend integration.

### Shared Tasks

Both members should collaborate on:

- Final MVP scope review.
- Reward rule decisions.
- Data model review.
- API contract review.
- End-to-end testing.
- Demo preparation.
- Weekly milestone planning.

## Recommended Immediate Next Step

The next step after this document is to convert the MVP scope into user stories.

Start with these epics:

- Viewer onboarding and feed.
- Company admin campaign creation.
- Watch tracking and interaction completion.
- Reward engine and wallet.
- Company admin analytics.
