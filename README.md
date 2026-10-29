# Smart Fashion Assistant

<p align="center">
  <img width="800" alt="Smart Fashion Assistant Preview" src="https://github.com/user-attachments/assets/7f5c6721-eacc-4ed8-acf1-fff431b33cc9" />
</p>

> A Flutter mobile application designed to combat overconsumption in fashion. Before making a new purchase, the app analyzes your existing wardrobe to help you decide whether you truly need the item.

Built as an undergraduate thesis at **FERIT Osijek**.

---

##  Features

- **Digital Wardrobe:** Easily digitize and manage the clothes you already own.
- **Wishlist / Potential Buys:** Add new clothing items you are considering purchasing.
- **AI-Powered Comparison:** Automatically compares the prospective item against your current wardrobe using advanced vision models.
- **Smart Recommendations:** Receive a clear verdict on whether the purchase is worth it.

---

## How It Works

Unlike traditional approaches that require training and hosting custom computer vision models, **Smart Fashion Assistant** leverages multimodal Large Language Models (**Claude**). Images of your existing clothes and the new item are sent directly within the prompt alongside contextual data for accurate and cost-effective analysis.

---

## UI/UX Design

The user interface was fully conceptualized and designed in **Figma** before implementation.

---

## Built With

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **Backend & Database:** [Supabase](https://supabase.com/)
- **AI Model:** Claude Haiku 4.5
- **Design:** [Figma](https://www.figma.com/)

---

## Getting Started
### Prerequisites

- Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- A Supabase account and a Claude API key.

### Installation
**Clone the repository:**
   ```bash
   git clone [https://github.com/ljurlina/fashion_assistant.git](https://github.com/ljurlina/fashion_assistant.git)
   cd fashion_assistant
