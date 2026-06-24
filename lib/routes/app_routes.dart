import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/courses/courses_screen.dart';

import '../screens/attendance/attendance_screen.dart';
import '../screens/placements/placements_screen.dart';
import '../screens/fees/fees_screen.dart';
import '../screens/announcements/announcements_screen.dart';
import '../screens/support/doubt_support_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/exams/exams_screen.dart';

import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/certificate_verification_screen.dart';

import '../screens/premium/premium_features_screen.dart';

import '../screens/notes/notes_screen.dart';
import '../screens/lectures/lectures_screen.dart';
import '../screens/live_sessions/live_sessions_screen.dart';
import '../screens/ai_assistant/ai_assistant_screen.dart';
import '../screens/trainer/trainer_dashboard.dart';
import '../screens/trainer/upload_notes_screen.dart';
import '../screens/trainer/live_hub_screen.dart';
import '../screens/trainer/lectures_hub_screen.dart';
import '../screens/trainer/announcements_hub_screen.dart';
import '../screens/trainer/performance_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String trainerDashboard = '/trainer-dashboard';
  static const String courses = '/courses';
  static const String placements = '/placements';
  static const String attendance = '/attendance';
  static const String fees = '/fees';
  static const String announcements = '/announcements';
  static const String doubtSupport = '/doubt-support';
  static const String profile = '/profile';
  static const String exams = '/exams';
  static const String notifications = '/notifications';
  static const String verifyCertificate = '/verify-certificate';
  static const String premium = '/premium';
  static const String notes = '/notes';
  static const String lectures = '/lectures';
  static const String liveSessions = '/live-sessions';
  static const String aiAssistant = '/ai-assistant';
  static const String uploadNotes = '/upload-notes';
  static const String liveHub = '/live-hub';
  static const String lecturesHub = '/lectures-hub';
  static const String announcementsHub = '/announcements-hub';
  static const String performance = '/performance';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) => const DashboardScreen(),
    trainerDashboard: (context) => const TrainerDashboard(),
    courses: (context) => const CoursesScreen(),
    placements: (context) => const PlacementsScreen(),
    attendance: (context) => const AttendanceScreen(),
    fees: (context) => const FeesScreen(),
    announcements: (context) => const AnnouncementsScreen(),
    doubtSupport: (context) => const DoubtSupportScreen(),
    profile: (context) => const ProfileScreen(),
    exams: (context) => const ExamsScreen(),
    notifications: (context) => const NotificationsScreen(),
    verifyCertificate: (context) => const CertificateVerificationScreen(),
    premium: (context) => const PremiumFeaturesScreen(),
    notes: (context) => const NotesScreen(),
    lectures: (context) => const LecturesScreen(),
    liveSessions: (context) => const LiveSessionsScreen(),
    aiAssistant: (context) => const AiAssistantScreen(),
    uploadNotes: (context) => const UploadNotesScreen(),
    liveHub: (context) => const LiveHubScreen(),
    lecturesHub: (context) => const LecturesHubScreen(),
    announcementsHub: (context) => const AnnouncementsHubScreen(),
    performance: (context) => const PerformanceScreen(),
  };
}
