# AvijitSahyog# Avijit Sahyog

A multilingual, platform-independent donation platform designed to make
giving simple, transparent, and repeatable.

## Vision

Avijit Sahyog is being built as a donation platform rather than simply
a donation app.

The platform will allow users to:

- Discover causes and affiliated organisations
- Distribute donations across multiple causes
- Donate using UPI
- View donation history and receipts
- Create recurring donation plans
- Eventually use UPI AutoPay for monthly donations
- Use the platform in multiple Indian languages

See [docs/vision.md](docs/vision.md) for the complete product vision.

## Development Plan

Development is divided into incremental iterations, starting with the
information platform and gradually introducing the donation and payment
systems.

See [docs/iteration-plan.md](docs/iteration-plan.md).

## Technology

### Client
- Flutter
- Dart
- Riverpod
- Flutter localization

### Backend
- Node.js
- TypeScript
- NestJS
- REST API

### Database
- PostgreSQL

### Infrastructure
- Google Cloud Run
- Cloud Storage
- Firebase Authentication
- Firebase Cloud Messaging
- Firebase Crashlytics

### Payments
- UPI Intent for initial one-time donations
- UPI AutoPay for recurring donations

## Current Status

🚧 Early development — Iteration 0

The current focus is establishing the project foundation before implementing
the donation domain.

## Development Principles

- Backend is the source of truth for financial data.
- Historical donations and allocations are immutable.
- Financial amounts are never represented using floating-point values.
- Payment callbacks are never trusted without server-side verification.
- Multilingual support is designed into the platform from the beginning.
- Causes and organisations are data-driven rather than hard-coded.
- Start with a modular monolith; introduce additional infrastructure only
  when scale requires it.