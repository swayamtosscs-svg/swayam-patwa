# DivineConnect 🌟

A spiritual social media platform that connects people through faith and spirituality. DivineConnect allows users to share their spiritual journey, connect with like-minded individuals, and explore content from various religions and faiths.

## ✨ Features

### 🔑 Authentication & Onboarding
- **Phone Number Authentication**: Secure OTP-based login using Firebase Auth
- **Religion Selection**: Choose from major world religions during onboarding
- **Profile Creation**: Complete your spiritual profile with bio and preferences

### 🏠 Main Feed
- **Personalized Content**: Feed curated based on your selected religion
- **Multiple Content Types**: Images, videos, stories, and text posts
- **Stories**: 24-hour ephemeral content with spiritual themes
- **Religion Filtering**: Filter content by religion and media type

### 📤 Content Creation
- **Multi-media Upload**: Share photos, videos, and stories
- **Location Tagging**: Add spiritual locations to your posts
- **Religious Context**: Auto-tag content with your religion
- **Hashtags**: Use spiritual and religious hashtags

### 🌍 Explore & Discover
- **Cross-religion Discovery**: Explore content from other faiths
- **Trending Posts**: Discover popular spiritual content
- **Location-based**: Find content from sacred places worldwide

### 🧑‍🤝‍🧑 Social Features
- **Follow/Unfollow**: Connect with spiritual leaders and seekers
- **Like & Comment**: Engage with spiritual content
- **Share**: Spread positive spiritual messages
- **Notifications**: Stay updated on spiritual activities

### ✔️ Profile & Verification
- **Spiritual Profile**: Showcase your faith journey
- **Verification Badge**: Apply for verified spiritual leader status
- **Religion Badge**: Display your faith with pride
- **Activity Stats**: Track your spiritual engagement

## 🛠️ Technical Stack

- **Framework**: Flutter 3.8+
- **State Management**: Provider
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Navigation**: Go Router
- **UI Components**: Custom religious-themed widgets
- **Image Handling**: Cached Network Image
- **Location Services**: Geolocator & Geocoding

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Firebase project setup
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/divineconnect.git
   cd divineconnect
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project
   - Enable Authentication (Phone provider)
   - Enable Firestore Database
   - Enable Storage
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── models/
│   ├── user_model.dart          # User data model
│   └── post_model.dart          # Post content model
├── providers/
│   └── auth_provider.dart       # Authentication state management
├── services/
│   └── auth_service.dart        # Firebase authentication service
├── screens/
│   ├── login_screen.dart        # Phone authentication
│   ├── onboarding_screen.dart   # Religion selection & profile setup
│   └── home_screen.dart         # Main feed
├── widgets/
│   ├── story_widget.dart        # Story display component
│   └── post_widget.dart         # Post display component
└── main.dart                    # App entry point
```

## 🎨 Design Philosophy

DivineConnect features a modern, spiritual design with:
- **Sacred Color Palette**: Indigo, purple, and gold accents
- **Religious Symbols**: Integration of faith symbols throughout the UI
- **Peaceful Typography**: Clean, readable fonts for spiritual content
- **Meditative Animations**: Smooth, calming transitions
- **Inclusive Design**: Respectful representation of all faiths

## 🌟 Supported Religions

- **Hinduism** (ॐ) - Orange theme
- **Islam** (☪) - Green theme  
- **Christianity** (✝) - Blue theme
- **Buddhism** (☸) - Purple theme
- **Sikhism** (☬) - Amber theme
- **Judaism** (✡) - Indigo theme
- **Other Faiths** (🕉) - Grey theme

## 🔒 Privacy & Security

- **Secure Authentication**: Firebase Auth with phone verification
- **Data Privacy**: User data stored securely in Firestore
- **Content Moderation**: Community guidelines for respectful content
- **Location Privacy**: Optional location sharing with user control

## 🤝 Contributing

We welcome contributions from the spiritual community! Please read our contributing guidelines and ensure all content respects diverse faiths and beliefs.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Spiritual leaders and communities for inspiration
- Open source contributors
- Firebase team for robust backend services
- Flutter team for the amazing framework

## 📞 Support

For support, email us at support@divineconnect.app or join our spiritual community discussions.

---

**DivineConnect** - Connecting hearts through faith and spirituality 🌟
