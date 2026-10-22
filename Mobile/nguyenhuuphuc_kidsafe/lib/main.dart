import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/children_provider.dart';
import 'providers/geofence_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/noise_provider.dart';
import 'providers/sos_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/child/child_device_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KidSafeApp());
}

class KidSafeApp extends StatelessWidget {
  const KidSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChildrenProvider()),
        ChangeNotifierProvider(create: (_) => GeofenceProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => NoiseProvider()),
        ChangeNotifierProvider(create: (_) => SOSProvider()),
      ],
      child: MaterialApp(
        title: 'KidSafe - Giám Sát Điện Thoại Trẻ Em',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppEntryRouter(),
      ),
    );
  }
}

class AppEntryRouter extends StatelessWidget {
  const AppEntryRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Nếu chưa đăng nhập -> hiển thị màn hình đăng nhập
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    final user = auth.currentUser;
    // Phân quyền theo vai trò (Requirement #3)
    if (user?.isAdmin == true) {
      return const AdminDashboardScreen();
    } else if (user?.isStaff == true) {
      return const StaffDashboardScreen();
    } else if (user?.isChild == true) {
      return const ChildDeviceScreen();
    } else {
      return const ParentHomeScreen();

    }
  }
}