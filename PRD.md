```md
# Product Requirements Document (PRD)

**Project Name:** MintFlow – Verified Attention Network  
**Version:** 1.0  
**Document Owner:** Founding Team  
**Status:** Draft

---

# 1. Executive Summary

## Vision

MintFlow is an AI-powered **Verified Attention Network** that rewards users for genuinely engaging with branded short-form videos while giving company admins measurable, fraud-resistant human attention.

Unlike traditional advertising platforms that charge for impressions or clicks, MintFlow creates a transparent two-sided platform where company admins create interactive campaigns, users earn rewards for completing them, and the platform facilitates the exchange through recommendation, verification, fraud detection, and analytics.

---

# 2. Problem Statement

## Company Admin Problems

- Fake impressions
- Bot traffic
- Click fraud
- Poor ROI
- Low engagement
- No proof users actually watched advertisements

## User Problems

- Spend hours scrolling every day
- Generate advertising revenue
- Receive no share of platform profits

## Platform Problems

- Existing platforms optimize for screen time rather than meaningful engagement.
- Companies purchase impressions instead of verified attention.

---

# 3. Product Vision

Build the world's largest **Verified Attention Marketplace** where:

- Companies purchase verified human attention.
- Users monetize their attention.
- AI validates engagement.
- Fraud is minimized.
- Rewards are transparent.

---

# 4. Objectives

## Business Goals

- Build a scalable advertising platform.
- Generate recurring advertising revenue.
- Increase company campaign ROI.
- Share revenue with users.
- Create sustainable attention economics.

## User Goals

- Earn money while watching content.
- Discover useful products.
- Withdraw earnings easily.
- Participate in interactive campaigns.

## Company Admin Goals

- Reach real people.
- Improve conversions.
- Collect consumer insights.
- Measure brand recall.
- Reduce advertising fraud.

---

# 5. Target Audience

## Users

- Age: 18–40
- Social media users
- Students
- Professionals
- Passive income seekers

## Company Admins

- D2C Brands
- Ecommerce Companies
- FMCG
- Gaming Companies
- App Developers
- Automobile Brands
- Fashion Brands
- Consumer Electronics

---

# 6. User Roles

## Viewer

Earn rewards by watching and engaging with advertisements.

## Company Admin

Access the web dashboard to create campaigns, upload reels, add quizzes, surveys, polls, and feedback forms, track campaign performance, and manage campaign spending.

---

# 7. Core Features

## User Features

### Authentication

- Google Login
- Apple Login
- Email Login
- Phone OTP

### Personalized Feed

- Infinite scrolling
- AI recommendations
- Sponsored reels
- Personalized advertisements

### Interactive Engagement

Company admins can attach:

- Quiz
- Poll
- Survey
- Feedback
- Brand Recall Test
- Product Preference Test
- Mini Games

### Rewards

Users earn rewards for:

- Watching videos
- Completing reels
- Correct quiz answers
- Survey participation
- Product feedback
- Referral program
- Daily streaks

### Wallet

- Current Balance
- Pending Rewards
- Withdrawal History
- Transaction Ledger
- Referral Earnings

---

## Company Admin Features

### Campaign Creation

- Upload Reel
- Campaign Budget
- Target Audience
- Campaign Duration
- Campaign Objective

### Interactive Content

Attach

- Quiz
- Survey
- Poll
- Feedback Form
- Product Preference
- Brand Recall Test

### Dashboard

- Views
- Verified Attention
- Completion Rate
- Attention Score
- Survey Results
- Poll Results
- Brand Recall
- Audience Analytics
- ROI

---

# 8. System Workflow

## User Flow

User Opens App

↓

Login

↓

Receive Personalized Feed

↓

Watch Advertisement

↓

System Verifies Watch Completion

↓

Complete Quiz / Survey / Poll / Feedback

↓

Reward Calculated

↓

Wallet Updated

---

## Company Admin Flow

Create Campaign

↓

Upload Reel

↓

Set Budget

↓

Add Quiz / Survey / Poll / Feedback

↓

Publish Campaign

↓

Campaign Pushed To Viewer Mobile App

↓

Campaign Analytics

↓

Campaign Optimization

---

# 9. Interactive Engagement

## Recall Questions

Example:

> What color was the shoe shown?

---

## Brand Quiz

Example:

> Which feature was introduced?

---

## Poll

Example:

> Which packaging do you prefer?

---

## Survey

Example:

> Would you buy this product?

---

## Feedback

Example:

> What did you like or dislike about this product?

---

## Brand Recall

Example:

> Which phone was shown five minutes ago?

---

## Mini Games

- Find Logo
- Spot Product
- Arrange Features
- Match Product with Price

---

# 10. AI Modules

## Recommendation Engine

Purpose

Recommend the best advertisement for every user.

Input

- Watch History
- User Interests
- Completion Rate
- Historical Engagement
- Attention Score
- Campaign Budget
- Freshness

Output

Personalized Feed

---

## Attention Verification Engine

Calculates:

Attention Score (0–100)

Signals

- Watch Time
- Completion Rate
- Replay
- Pause Time
- Interaction
- Quiz Accuracy
- Survey Participation
- Device Authenticity

---

## Fraud Detection Engine

Detects

- Bots
- Emulators
- Rooted Devices
- VPN Abuse
- Auto Scroll
- Fake Accounts
- Click Farms
- Automation

---

## Ad Quality AI

Scores advertisements based on

- Hook Quality
- Audio
- Lighting
- Editing
- Subtitle Quality
- Engagement Prediction

---

## AI Question Generator

Automatically generates

- Quiz
- Poll
- Survey
- Brand Recall Questions

using Large Language Models.

---

# 11. Reward Engine

Reward depends on

- Campaign Budget
- Attention Score
- Completion Rate
- Campaign Priority
- Quiz Accuracy
- Survey Completion

Example

Company Admin Pays ₹100

Platform Commission ₹25

User Rewards ₹65

Operational Cost ₹10

---

# 12. Recommendation Algorithm

Feed Score =

```

0.30 × Watch History

* 0.25 × Category Match

* 0.15 × Ad Quality

* 0.10 × Attention Score

* 0.10 × Campaign Budget

* 0.10 × Freshness

```

---

# 13. Technology Stack

## Mobile

- React Native
- TypeScript
- Expo
- React Navigation
- React Query
- Zustand

## Web Dashboard

- Next.js
- React
- TailwindCSS
- Chart.js

## Backend

- Python
- FastAPI

## AI / ML

- PyTorch
- TensorFlow
- OpenCV
- Whisper
- LangChain
- OpenAI / Gemini API

## Databases

- PostgreSQL
- Redis
- ClickHouse

## Object Storage

- AWS S3
- Cloudflare R2

## Infrastructure

- Docker
- Kubernetes
- AWS
- Cloudflare CDN
- GitHub Actions
- Prometheus
- Grafana
- Sentry

---

# 14. APIs

- Firebase Authentication
- Razorpay
- Cashfree
- Firebase Cloud Messaging
- OpenAI API
- Gemini API
- Whisper
- FFmpeg
- Google Maps API (Optional)

---

# 15. Security

- HTTPS
- JWT Authentication
- Refresh Tokens
- AES-256 Encryption
- bcrypt Password Hashing
- Redis Rate Limiting
- Device Fingerprinting
- Emulator Detection
- Root Detection
- VPN Detection
- Signed Video URLs
- Fraud Risk Scoring
- KYC for High-Value Withdrawals
- Audit Logs

---

# 16. Non-Functional Requirements

- 99.9% Uptime
- Horizontal Scaling
- API Response < 200 ms
- Millions of Concurrent Users
- Disaster Recovery
- Continuous Monitoring

---

# 17. KPIs

## User

- Daily Active Users
- Monthly Active Users
- Session Duration
- Videos Watched
- Reward Redemption Rate
- Retention Rate

## Company Admin

- Verified Attention Rate
- Cost Per Verified Attention (CPVA)
- Brand Recall Rate
- Survey Completion Rate
- ROI
- ROAS

## Platform

- Revenue
- Fraud Detection Accuracy
- Withdrawal Success Rate
- Campaign Success Rate
- Infrastructure Uptime

---

# 18. Roadmap

## Phase 1 — MVP

- Authentication
- User Feed
- Company Admin Dashboard
- Wallet
- Campaign Upload
- Quiz
- Survey
- Poll
- Feedback
- Basic Recommendation Engine

## Phase 2 — Beta

- Attention Score
- Fraud Detection
- Referrals
- Leaderboards
- Push Notifications
- Advanced Analytics

## Phase 3 — Scale

- AI Question Generation
- Dynamic Rewards
- Real-Time Bidding
- Enterprise Dashboard
- Multi-Country Expansion

## Phase 4 — Ecosystem

- Creator Marketplace
- Agency APIs
- White-Label Platform
- AI Campaign Optimization
- Predictive Analytics

---

# 19. Success Metrics

- 1M+ Registered Users
- 100K Daily Active Users
- 500+ Active Company Admins
- >95% Fraud Detection Accuracy
- >80% Campaign Completion Rate
- Positive User Retention
- Sustainable Reward Economy

---

# 20. Future Vision

MintFlow aims to become the global infrastructure for the **Attention Economy**.

Instead of buying impressions, brands will purchase **Verified Attention**, enriched with engagement, recall, sentiment, and market research. Users will be fairly compensated for their attention, company admins will receive measurable outcomes, and AI will ensure trust, transparency, and fraud resistance across the ecosystem.
```
