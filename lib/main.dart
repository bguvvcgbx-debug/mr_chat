import 'package:flutter/material.dart';

const kBlue = Color(0xFF2F6BFF);
const kBlack = Color(0xFF000000);
const kPanel = Color(0xFF0E1320);
const kLine = Color(0xFF1F2A44);

void main() => runApp(const MrChatApp());

class MrChatApp extends StatelessWidget {
  const MrChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mr Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBlack,
        colorScheme: const ColorScheme.dark(primary: kBlue, surface: kPanel),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kPanel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBlue, width: 1.5),
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

/// Robot face logo, drawn in code so no image file is needed.
class RobotLogo extends StatelessWidget {
  final double size;
  const RobotLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _RobotPainter());
}

class _RobotPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final blue = Paint()..color = kBlue;
    final black = Paint()..color = kBlack;
    final stroke = Paint()
      ..color = kBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    // antenna
    c.drawLine(Offset(w * .5, w * .2), Offset(w * .5, w * .08), stroke);
    c.drawCircle(Offset(w * .5, w * .07), w * .045, blue);
    // ears
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .06, w * .45, w * .08, w * .2), Radius.circular(w * .03)),
        blue);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .86, w * .45, w * .08, w * .2), Radius.circular(w * .03)),
        blue);
    // head
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .15, w * .2, w * .7, w * .6), Radius.circular(w * .2)),
        blue);
    // eyes
    c.drawCircle(Offset(w * .36, w * .46), w * .075, black);
    c.drawCircle(Offset(w * .64, w * .46), w * .075, black);
    // smile
    final smile = Path()
      ..moveTo(w * .37, w * .62)
      ..quadraticBezierTo(w * .5, w * .72, w * .63, w * .62);
    c.drawPath(
        smile,
        Paint()
          ..color = kBlack
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .045
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _creating = true;
  bool _hide = true;
  String? _error;

  // Stage 1 only: usernames live in memory. A real server comes in the next stage.
  static final Map<String, String> _accounts = {'admin': 'x'};

  void _submit() {
    final u = _user.text.trim().toLowerCase();
    final p = _pass.text;
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(u)) {
      setState(() => _error = 'Username: 3-20 letters, numbers or _');
      return;
    }
    if (_creating) {
      if (p.length < 8) {
        setState(() => _error = 'Password needs at least 8 characters');
        return;
      }
      if (_accounts.containsKey(u)) {
        setState(() => _error = '@$u is already taken. Try another.');
        return;
      }
      _accounts[u] = p;
    } else if (_accounts[u] != p) {
      setState(() => _error = 'Wrong username or password');
      return;
    }
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatsScreen(username: u)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const RobotLogo(size: 110),
                const SizedBox(height: 18),
                const Text('Mr Chat',
                    style: TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text('No phone number. Just your username.',
                    style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 32),
                TextField(
                  controller: _user,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      hintText: 'Username', prefixText: '@ '),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: _hide,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: kBlue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: _submit,
                    child: Text(_creating ? 'Create account' : 'Log in',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _creating = !_creating;
                    _error = null;
                  }),
                  child: Text(_creating
                      ? 'Already have an account? Log in'
                      : 'New here? Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatsScreen extends StatelessWidget {
  final String username;
  const ChatsScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBlack,
        title: Row(children: [
          const RobotLogo(size: 30),
          const SizedBox(width: 10),
          const Text('Mr Chat', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RobotLogo(size: 80),
              const SizedBox(height: 16),
              Text('Welcome, @$username',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                  'No chats yet. Search for a username to start one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kBlue,
        onPressed: () {},
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
