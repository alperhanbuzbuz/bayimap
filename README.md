# BayiMap 🗺️

BayiMap is a mobile application designed for field sales representatives and distributors to manage and track their sales points on a map.

It allows users to save shop locations, attach notes and photos, and set visit reminders — all in one place.

---

## 🚀 Problem

Field sales professionals often:
- Forget previous visit details
- Lose track of shop notes
- Miss follow-up visits
- Store information in scattered tools (WhatsApp, notebook, memory)

BayiMap solves this by providing a centralized, map-based visit tracking system.

---

## ✨ Features (MVP v0.1)

- 📍 Add shop locations directly from the map
- 📝 Add notes for each shop
- 📷 Attach photos to shops
- 🔔 Set visit reminders
- 📋 View all shops in list format
- 🔎 Search shops quickly
- 🌙 Dark mode support

---

## 🏗️ Tech Stack

- Flutter
- Google Maps SDK
- Firebase Firestore
- Firebase Storage
- Local Notifications

---

## 📂 Project Structure

lib/
├── screens/
├── models/
├── services/
├── widgets/
└── main.dart

---

## 🧠 Data Model (Initial)

Each shop (place) contains:

- id
- name
- note
- latitude
- longitude
- photoUrls[]
- reminderAt
- createdAt

---

## 📅 Roadmap

### Phase 1 – MVP
- Map integration
- Marker creation
- Shop detail screen
- Photo upload
- Reminder scheduling

### Phase 2 – Improvements
- Offline support
- Visit history
- Phone call integration
- Export data
- Multiple user accounts

---

## 🎯 Target Users

- Field sales representatives
- Distributors
- FMCG sales teams
- Small wholesalers

---

## 📌 Status

🚧 In development (MVP stage)

---

## 📄 License

MIT
