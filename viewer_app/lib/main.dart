import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'pages/login_page.dart';
import 'repositories/api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/feed_repository.dart';
import 'repositories/local_storage.dart';
import 'state/viewer_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // storage → ApiClient → AuthRepository → ViewerController
  final storage = await LocalStorage.create();
  final api = ApiClient(storage);
  final auth = AuthRepository(api);
  final feed = FeedRepository(api);
  final controller = ViewerController(auth, feed);
  await controller.bootstrap(); // restore session if a token is persisted

  runApp(MintFlowViewerApp(controller: controller));
}

class MintFlowViewerApp extends StatelessWidget {
  const MintFlowViewerApp({super.key, required this.controller});

  final ViewerController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MintFlow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => controller.isAuthenticated
            ? HomeShell(controller: controller)
            : LoginPage(controller: controller),
      ),
    );
  }
}
