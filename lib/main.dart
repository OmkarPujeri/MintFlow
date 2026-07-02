import 'package:flutter/material.dart';

import 'models/company_admin.dart';
import 'pages/login_page.dart';
import 'repositories/analytics_repository.dart';
import 'repositories/api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/campaign_repository.dart';
import 'repositories/local_storage.dart';
import 'state/dashboard_controller.dart';
import 'theme.dart';
import 'widgets/dashboard_shell.dart';

void main() {
  runApp(const MintFlowDashboardApp());
}

class MintFlowDashboardApp extends StatefulWidget {
  const MintFlowDashboardApp({super.key});

  @override
  State<MintFlowDashboardApp> createState() => _MintFlowDashboardAppState();
}

class _MintFlowDashboardAppState extends State<MintFlowDashboardApp> {
  late final LocalStorage _storage;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final CampaignRepository _campaignRepository;
  late final AnalyticsRepository _analyticsRepository;

  CompanyAdmin? _admin;
  DashboardController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _storage = LocalStorage();
    _apiClient = ApiClient(_storage);
    _authRepository = AuthRepository(_storage, _apiClient);
    _campaignRepository = CampaignRepository(_apiClient);
    _analyticsRepository = AnalyticsRepository();
    _restoreSession();
  }

  DashboardController _buildController(CompanyAdmin admin) {
    final controller = DashboardController(
      campaignRepository: _campaignRepository,
      analyticsRepository: _analyticsRepository,
      authRepository: _authRepository,
      admin: admin,
    );
    controller.addListener(() {
      if (controller.error != null && controller.error!.contains('ApiException(401)')) {
        _logout();
      }
    });
    return controller..load();
  }

  Future<void> _restoreSession() async {
    final admin = await _authRepository.currentAdmin();
    setState(() {
      _admin = admin;
      _controller = admin == null ? null : _buildController(admin);
      _loading = false;
    });
  }

  Future<void> _login(String email, String password) async {
    final admin = await _authRepository.login(email, password);
    setState(() {
      _admin = admin;
      _controller = _buildController(admin);
    });
  }

  Future<void> _loginWithGoogle() async {
    final admin = await _authRepository.loginWithGoogle();
    setState(() {
      _admin = admin;
      _controller = _buildController(admin);
    });
  }

  Future<void> _logout() async {
    await _authRepository.logout();
    _controller?.dispose();
    setState(() {
      _admin = null;
      _controller = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MintFlow Dashboard',
      theme: buildTheme(),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _admin == null || _controller == null
              ? LoginPage(onLogin: _login, onGoogleLogin: _loginWithGoogle)
              : DashboardShell(
                  controller: _controller!,
                  onLogout: _logout,
                ),
    );
  }
}
