# CricHeroes Technology Stack Research

**Date:** 2026-02-19
**Sources:** Job listings, Cutshort profiles, Crunchbase, RocketReach, CricHeroes careers page

## Summary

CricHeroes (40M+ users, by Flavor Systems Pvt Ltd, Ahmedabad) uses **native apps** (NOT Flutter, NOT React Native) with a **Node.js + MongoDB/MySQL + Redis** backend on **AWS**.

---

## Mobile Apps — Native (Not Cross-Platform)

CricHeroes builds **separate native apps** for Android and iOS:

| Platform | Language | Architecture | Tools |
|----------|----------|-------------|-------|
| **Android** | Kotlin + Java | MVVM + Jetpack | Android Studio, Material Design, Git |
| **iOS** | Swift | SwiftUI + UIKit | Xcode, REST APIs, JSON |

**Evidence:**
- Careers page lists separate "Android Developer" (Kotlin, Java, MVVM, Jetpack) and "iOS Developer" (Swift, SwiftUI, UIKit) roles
- No Flutter or React Native mentioned anywhere in any job listing
- iOS Tech Lead listed as Rahul Chandnani (per RocketReach)
- APK package: `com.cricheroes.cricheroes.alpha` — native Android package naming

**Key insight:** CricHeroes chose native over cross-platform despite maintaining two separate codebases. This is the traditional enterprise approach — maximum platform performance at the cost of doubled development effort.

## Backend

| Component | Technology |
|-----------|-----------|
| **Runtime** | Node.js (JavaScript) |
| **Databases** | MySQL (relational) + MongoDB (NoSQL) — dual database |
| **Cache** | Redis |
| **Cloud** | AWS (primary), Google Cloud (secondary/preferred) |
| **Frontend (web)** | React.js, AngularJS, Angular |

**Evidence:**
- Fullstack Developer job listings (Cutshort) list mandatory: Node.js, JavaScript, MySQL, MongoDB, Redis
- AWS listed as preferred skill across multiple listings
- 5-6 years Node.js experience required for senior roles

**Dual database pattern:** MySQL likely handles structured data (users, teams, matches, stats) while MongoDB handles semi-structured/high-write data (deliveries, real-time scoring events, analytics). Redis for caching hot data (live match state, leaderboards).

## Analytics & Observability

| Tool | Purpose |
|------|---------|
| Firebase | Analytics, push notifications, likely auth |
| Mixpanel | Product analytics, user behavior tracking |
| Clarity | Session recording, heatmaps |
| Amazon S3 | File storage (images, media) |
| Ahrefs | SEO monitoring |

## Web Frontend

- React.js and Angular/AngularJS — likely web dashboard for tournament organizers
- Bootstrap — CSS framework for web

## Engineering Team

- ~32 employees in IT/Engineering (per RocketReach)
- Separate Android, iOS, Fullstack, and Hardware teams
- Also building physical products (cricket hardware — embedded systems with STM32, ESP32)

---

## Comparison: CricHeroes vs CricApp Stack

| Layer | CricHeroes | CricApp | Notes |
|-------|-----------|---------|-------|
| **Mobile** | Native (Kotlin + Swift) | Flutter (Dart) | CricApp saves 2x dev effort with cross-platform |
| **State Mgmt** | MVVM + Jetpack (Android) | Riverpod 3.0 | Both use reactive/declarative patterns |
| **Backend** | Node.js | Bun + ElysiaJS | Both JS ecosystem; Bun is faster runtime |
| **Relational DB** | MySQL | PostgreSQL | PostgreSQL has better JSON, UUID, enum support |
| **NoSQL DB** | MongoDB | None (PostgreSQL JSONB) | CricApp uses single DB, simpler ops |
| **Cache** | Redis | None (MVP) | Could add later if needed |
| **Real-time** | Unknown (likely Socket.io on Node) | Bun native WebSockets | Bun WS is faster than Socket.io |
| **Auth** | Firebase (likely) | Firebase Phone OTP | Same approach |
| **Local DB** | SQLite/Room (Android), CoreData (iOS) | Drift/SQLite | Similar offline-first approach |
| **Cloud** | AWS | VPS (planned) | CricHeroes at scale needs AWS |
| **Analytics tools** | Firebase + Mixpanel + Clarity | None (MVP) | Add post-launch |

## Key Takeaways

1. **CricHeroes does NOT use Flutter or any cross-platform framework** — they maintain separate native Android (Kotlin) and iOS (Swift) codebases. This is significant because it means their 32-person team spends roughly double the effort on mobile.

2. **CricHeroes uses a dual-database strategy** (MySQL + MongoDB) — likely MySQL for structured relational data and MongoDB for high-throughput write paths (deliveries, real-time events). CricApp achieves this with PostgreSQL alone (JSONB for semi-structured data).

3. **Redis is essential at CricHeroes scale** (40M users) — for live match state caching, leaderboard reads, and session management. CricApp doesn't need this at MVP scale but should plan for it.

4. **Node.js is the proven backend** for cricket scoring at scale — CricHeroes validates that the JS ecosystem handles real-time cricket scoring well. CricApp's Bun choice is the next evolution of this (faster, built-in WS).

5. **No evidence of BLoC** — CricHeroes Android uses MVVM (the standard Android Jetpack pattern), not BLoC. BLoC is Flutter-specific. Their iOS app uses SwiftUI patterns. The "BLoC vs Riverpod" debate is only relevant within the Flutter ecosystem.

---

*Research conducted via web search of job listings, company profiles, and technology databases. No proprietary or leaked information used.*
