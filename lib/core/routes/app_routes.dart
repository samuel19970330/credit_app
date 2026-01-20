import 'package:flutter/material.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/home/dashboard_page.dart';
import '../../presentation/pages/credits/credits_list_page.dart';
import '../../presentation/pages/credits/credit_detail_page.dart';
import '../../presentation/pages/credits/credit_registration_page.dart';
import '../../presentation/pages/customers/customers_page.dart';
import '../../presentation/pages/customers/customer_form_page.dart';
import '../../presentation/pages/products/products_page.dart';
import '../../presentation/pages/products/product_form_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/settings/settings_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String credits = '/credits';
  static const String creditDetail = '/credit_detail';
  static const String creditRegister = '/credit_register';
  static const String customers = '/customers';
  static const String customerForm = '/customer_form';
  static const String products = '/products';
  static const String productForm = '/product_form';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginPage(),
        home: (context) => const HomePage(),
        dashboard: (context) => const DashboardPage(),
        credits: (context) => const CreditsListPage(),
        creditRegister: (context) => const CreditRegistrationPage(),
        customers: (context) => const CustomersPage(),
        products: (context) => const ProductsPage(),
        profile: (context) => const ProfilePage(),
        settings: (context) => const SettingsPage(),
        customerForm: (context) => const CustomerFormPage(),
        productForm: (context) => const ProductFormPage(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == creditDetail) {
      final credit = settings.arguments as dynamic;
      return MaterialPageRoute(
          builder: (_) => CreditDetailPage(credit: credit));
    }
    return null;
  }
}
