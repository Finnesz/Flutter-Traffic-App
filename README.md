# C4 Road Traffic Prediction App

A comprehensive Flutter application for real-time traffic prediction and analysis on C4 Road, Malabon City. This app provides live traffic forecasts, intelligent recommendations, and interactive visualizations to help users navigate traffic efficiently.

## Screenshot

<div align="center">
  <img src="screenshots/screenshot_001.jpeg" alt="C4 Road Traffic App" width="300">
</div>

## Features

### 🚗 **Real-Time Traffic Analytics**
- **Live Prediction Summary**: Today's traffic overview with peak/low hours and vehicle counts
- **Weekly Analytics**: Current week traffic patterns and averages
- **Quarterly Insights**: Three-month traffic trends and projections

### 📊 **Interactive Data Visualization**
- **Scrollable Charts**: Navigate through 24-hour daily patterns and 12-month yearly trends
- **Responsive Design**: Enhanced chart sizing for landscape mode viewing
- **Time Formats**: User-friendly AM/PM time display instead of 24-hour format
- **Actual Dates**: Weekly view shows real dates instead of generic week numbers

### 🎯 **Smart Traffic Recommendations**
- **Period-Specific Advice**: Tailored recommendations for hourly, daily, weekly, and monthly patterns
- **Dynamic Suggestions**: Real-time alternative routes and optimal travel times
- **Condition-Based Tips**: Traffic strategies based on current congestion levels

### 🎨 **Enhanced User Experience**
- **Professional UI**: Dark theme with consistent color scheme
- **Touch-Optimized**: Properly sized buttons that adapt to device orientation
- **Smooth Interactions**: Pull-to-refresh functionality for live data updates
- **Error Handling**: Graceful fallbacks and loading states

## Technology Stack

- **Frontend**: Flutter with Material Design
- **Backend**: FastAPI deployed on Railway
- **Data Sources**: 
  - Live traffic prediction API
  - Real-time analytics endpoint
  - Dynamic recommendation system
- **Visualization**: Custom `CustomPainter` with scrollable charts
- **Architecture**: REST API integration with Future-based state management

## API Endpoints

- **Traffic Predictions**: `/api/dashboard/user/end-user-prediction-detail`
- **Analytics Summary**: `/api/dashboard/user/end-user-prediction-summary`  
- **Recommendations**: `/api/dashboard/user/end-user-traffic-recommendations`

## Development

This project showcases modern mobile development practices:
- **AI-Assisted Development**: Built with **Claude Sonnet 4** in VS Code
- **Educational Tools**: Leveraged **GitHub Education** benefits
- **Real-World Integration**: Live API consumption and data visualization
- **Responsive Design**: Adaptive UI for multiple orientations and screen sizes

## Getting Started

1. **Prerequisites**: Flutter SDK, Android Studio/VS Code
2. **Dependencies**: All required packages are listed in `pubspec.yaml`
3. **API Access**: The app connects to live FastAPI endpoints on Railway
4. **Build**: Standard Flutter build process for Android/iOS

For Flutter development help, visit the [official documentation](https://docs.flutter.dev/).

## Color Scheme

- **Background**: `#192A31` (Dark blue-green)
- **Cards**: `#293949` (Medium gray-blue)
- **Highlights**: `#00C8FA` (Bright cyan)
- **Secondary**: `#586A80` (Muted gray-blue)

---

**Live Traffic Intelligence for Smart Navigation** 🚦📱
