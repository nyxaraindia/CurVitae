<img width="1366" height="768" alt="CurVitae app preview" src="https://github.com/user-attachments/assets/0a725ccb-9401-47f1-8df0-6b0f2ccd3e5b" />

<div align="center">

# 📄 CurVitae

**Your Career, AI-Crafted.**

An intelligent, cross-platform CV builder powered by Flutter and Nyxara AI. CurVitae helps users turn resumes, notes, and career details into polished, recruiter-ready PDF CVs with AI-assisted rewriting, formatting, and export.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Gemini](https://img.shields.io/badge/Google_Gemini-AI-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://ai.google.dev)
[![Web](https://img.shields.io/badge/Web-Ready-4CAF50?style=for-the-badge)](https://github.com/nyxaraindia/CurVitae)

</div>

## ✨ What CurVitae does

CurVitae is designed for people who want a professional CV without spending hours rewriting bullet points and formatting layouts.

- 🧠 AI-powered resume improvement using Gemini-based generation
- 📄 Resume-to-CV conversion from uploaded PDF files
- 📝 Build-from-details mode for freshers and career switchers
- 🎨 Multiple CV color themes and export-ready layouts
- 🔐 Google sign-in and Firebase-backed app flow
- 📱 Cross-platform Flutter app for mobile and web
- 🧾 Clean PDF generation for sharing, printing, and job applications

---

## 🏗️ Tech stack

- Frontend: Flutter + Dart
- UI: Material 3
- AI: Google Generative AI (Gemini)
- Authentication: Firebase Authentication + Google Sign-In
- Storage / platform services: Firebase Core
- Export: PDF generation with `pdf` and `printing`
- File handling: `file_picker`

---

## 📁 Project structure

```text
CurVitae/
├── android/              # Android project files
├── assets/              # App assets and branding images
├── lib/                 # Flutter application source
│   ├── core.dart        # Shared config and app constants
│   ├── cv_pdf.dart      # CV PDF generation logic
│   ├── firebase_options.dart
│   ├── main.dart        # App entry point and screens
│   ├── nyxara_ai.dart   # AI resume generation flow
│   ├── widgets.dart     # Reusable UI widgets
│   └── ...
├── web/                 # Web app configuration
├── .gitignore
├── analysis_options.yaml
├── firebase.json
├── index.html
├── pubspec.yaml
├── pubspec.lock
├── README.md
└── ...
```

---

## 🚀 Getting started

### Prerequisites

- Flutter SDK 3.13.5 or newer
- Dart SDK
- Firebase project configured for the app
- Gemini API access for the AI generation workflow

### 1) Clone the repository

```bash
git clone https://github.com/nyxaraindia/CurVitae.git
cd CurVitae
```

### 2) Install dependencies

```bash
flutter pub get
```

### 3) Configure Firebase and AI keys

Before running the app, ensure your Firebase project is connected and add the required environment or config files for your local setup.

For Gemini-based AI generation, the app expects a configured API key in the local environment flow used by the project.

### 4) Run the app

```bash
flutter run
```

For web:

```bash
flutter run -d chrome
```

---

## 🧠 How it works

1. User signs in with Google or enters the app flow.
2. They either:
   - upload a resume PDF, or
   - fill out their profile and career details manually
3. CurVitae sends the content to the Nyxara AI generation engine.
4. The app rewrites the content into a polished CV structure.
5. A formatted PDF is generated and previewed for export.

---

## 🔒 Privacy and data handling

CurVitae is built with a privacy-conscious approach:

- personal profile data is managed within the app flow
- resume content is used for CV generation and formatting
- AI processing is designed to help rewrite and structure user content responsibly

---

## 📌 Features in detail

### Resume enhancement
Upload an existing resume and generate a refined version tailored to a target role and professional tone.

### Manual CV builder
Use the “From Details” workflow to create a CV from scratch with experience, education, projects, certifications, and language skills.

### Profile management
Store and update personal information such as name, title, location, email, phone, and professional links.

### PDF export
Generate a clean PDF your users can share, print, or send to recruiters.

---

## 🛠️ Contribution

Contributions are welcome.

If you want to improve the app:

```bash
git checkout -b feature/your-feature-name
# make changes
flutter test
```

---

## 📬 Contact

- GitHub: https://github.com/nyxaraindia
- Project: https://github.com/nyxaraindia/CurVitae

---

## ⚠️ Notes

This project is actively evolving and may require project-specific setup for Firebase and AI credentials depending on your environment.

If you are running the code locally, make sure the required credentials and generated Firebase configuration files are in place before launching the app.

---

## 📜 License

**Proprietary License — not MIT.**

Copyright © NYXARA_IN. All rights reserved.

This repository and its contents are proprietary to NYXARA_IN. No license or permission is granted to use, copy, modify, distribute, sublicense, or create derivative works from this project, in whole or in part, without prior written permission from NYXARA_IN, except where applicable law requires otherwise. Third-party components remain subject to their respective licenses.
