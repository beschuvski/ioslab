import 'package:cupertino_ui/cupertino_ui.dart';

import 'lab_page.dart';

void main() {
  runApp(const IosLabApp());
}

class IosLabApp extends StatelessWidget {
  const IosLabApp({super.key});

  static const Color _accent = Color(0xFF0071E3);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'iOS Lab',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: _accent,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        barBackgroundColor: const Color(0xFFF9F9FB),
        textTheme: const CupertinoTextThemeData(
          navLargeTitleTextStyle: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: CupertinoColors.label,
          ),
        ),
      ),
      home: const LabPage(),
    );
  }
}
