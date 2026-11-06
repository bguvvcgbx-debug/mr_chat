import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

const kBlue = Color(0xFF2F6BFF);
const kBlue2 = Color(0xFF6C8CFF);
const kBlack = Color(0xFF000000);
const kBg = Color(0xFF05070D);
const kPanel = Color(0xFF0E1320);
const kPanel2 = Color(0xFF172036);
const kLine = Color(0xFF1F2A44);
const kMuted = Color(0xFF8A94AB);
const kRed = Color(0xFFFF6B6B);
const kGrad = LinearGradient(
  colors: [kBlue, kBlue2],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Firestore database named "default" (not "(default)").
late final FirebaseFirestore fs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBX3Te99JOmn8Qy0W-BYf5fH0g1QuQFpOM',
      appId: '1:159709567103:android:9297797f7ba9e1e16c474a',
      messagingSenderId: '159709567103',
      projectId: 'mr-chat-a083b',
      storageBucket: 'mr-chat-a083b.firebasestorage.app',
    ),
  );
  fs = FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'default');
  runApp(const MrChatApp());
}

String fmtTime(Timestamp? t) {
  if (t == null) return '';
  final d = t.toDate().toLocal();
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return '${two(d.hour)}:${two(d.minute)}';
  }
  return '${d.day}/${d.month}';
}

String fmtDur(int secs) =>
    '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';

String dispName(Map<String, dynamic> u, String username) {
  final n = (u['name'] ?? '').toString().trim();
  return n.isEmpty ? username : n;
}

class MrChatApp extends StatelessWidget {
  const MrChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return MaterialApp(
      title: 'Mr Chat',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(primary: kBlue, surface: kPanel),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
        snackBarTheme:
            const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kPanel,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintStyle: const TextStyle(color: kMuted),
          border: border(kLine),
          enabledBorder: border(kLine),
          focusedBorder: border(kBlue, 1.5),
        ),
      ),
      home: const AuthGate(),
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

    c.drawLine(Offset(w * .5, w * .2), Offset(w * .5, w * .08), stroke);
    c.drawCircle(Offset(w * .5, w * .07), w * .045, blue);
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .06, w * .45, w * .08, w * .2),
            Radius.circular(w * .03)),
        blue);
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .86, w * .45, w * .08, w * .2),
            Radius.circular(w * .03)),
        blue);
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .15, w * .2, w * .7, w * .6),
            Radius.circular(w * .2)),
        blue);
    c.drawCircle(Offset(w * .36, w * .46), w * .075, black);
    c.drawCircle(Offset(w * .64, w * .46), w * .075, black);
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

/// Round avatar: photo if there is one, otherwise a gradient with the initial.
class Avatar extends StatelessWidget {
  final String name;
  final String? photo;
  final double size;
  final bool group;
  const Avatar({
    super.key,
    required this.name,
    this.photo,
    this.size = 48,
    this.group = false,
  });

  Widget _initial() => Container(
        decoration: const BoxDecoration(gradient: kGrad),
        alignment: Alignment.center,
        child: group
            ? Icon(Icons.groups_rounded, color: Colors.white, size: size * 0.55)
            : Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w800),
              ),
      );

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (photo != null && photo!.isNotEmpty) {
      try {
        child = Image.memory(
          base64Decode(photo!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _initial(),
        );
      } catch (_) {
        child = _initial();
      }
    } else {
      child = _initial();
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: child));
  }
}

/// Listens to one user's profile (name + photo).
class UserBuilder extends StatelessWidget {
  final String username;
  final Widget Function(BuildContext, Map<String, dynamic>) builder;
  const UserBuilder({super.key, required this.username, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: fs.collection('users').doc(username).snapshots(),
      builder: (context, snap) =>
          builder(context, snap.data?.data() ?? <String, dynamic>{}),
    );
  }
}

class GradButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool busy;
  const GradButton(
      {super.key, required this.text, this.onPressed, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
              gradient: kGrad, borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: SizedBox(
              height: 54,
              width: double.infinity,
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(text,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the login screen or the chats, depending on whether you are signed in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: RobotLogo(size: 90)));
        }
        final user = snap.data;
        if (user == null) return const AuthScreen();
        final name = (user.email ?? '').split('@').first;
        return ChatsScreen(key: ValueKey(user.uid), me: name, uid: user.uid);
      },
    );
  }
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
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final u = _user.text.trim().toLowerCase();
    final p = _pass.text;
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(u)) {
      setState(() =>
          _error = 'اسم المستخدم: من 3 إلى 20 حرف إنجليزي أو رقم أو _');
      return;
    }
    if (_creating && p.length < 8) {
      setState(() => _error = 'كلمة المرور لازم تكون 8 خانات على الأقل');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = '$u@mrchat.app';
      if (_creating) {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: p);
      } else {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: p);
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = '@$u مأخوذ، جرّب اسم تاني';
          break;
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          msg = 'اسم المستخدم أو كلمة المرور غلط';
          break;
        case 'network-request-failed':
          msg = 'ما في اتصال بالإنترنت';
          break;
        case 'operation-not-allowed':
          msg = 'تسجيل الدخول بالإيميل مش مفعّل بـ Firebase';
          break;
        default:
          msg = 'خطأ: ${e.code}';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'صار خطأ: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1330), kBg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: kPanel,
                      boxShadow: [
                        BoxShadow(color: Color(0x592F6BFF), blurRadius: 44)
                      ],
                    ),
                    child: const RobotLogo(size: 84),
                  ),
                  const SizedBox(height: 22),
                  const Text('Mr Chat',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  const Text('بدون رقم هاتف. بس اسم المستخدم.',
                      style: TextStyle(color: kMuted)),
                  const SizedBox(height: 34),
                  TextField(
                    controller: _user,
                    autocorrect: false,
                    enableSuggestions: false,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: 'اسم المستخدم',
                      prefixIcon: Icon(Icons.alternate_email, color: kMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: _hide,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: kMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _hide ? Icons.visibility_off : Icons.visibility,
                            color: kMuted),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kRed)),
                  ],
                  const SizedBox(height: 22),
                  GradButton(
                    text: _creating ? 'إنشاء حساب' : 'تسجيل الدخول',
                    busy: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => setState(() {
                      _creating = !_creating;
                      _error = null;
                    }),
                    child: Text(_creating
                        ? 'عندك حساب؟ سجّل دخول'
                        : 'جديد هون؟ أنشئ حساب'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatsScreen extends StatefulWidget {
  final String me;
  final String uid;
  const ChatsScreen({super.key, required this.me, required this.uid});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String get me => widget.me;

  @override
  void initState() {
    super.initState();
    _saveProfile();
  }

  /// Makes sure this username is listed so other people can find it.
  Future<void> _saveProfile() async {
    try {
      await fs.collection('users').doc(me).set(
          {'username': me, 'uid': widget.uid}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _showNewMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: kPanel,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_rounded,
                  color: kBlue2),
              title: const Text('محادثة جديدة'),
              onTap: () {
                Navigator.pop(ctx);
                _newChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add_rounded, color: kBlue2),
              title: const Text('مجموعة جديدة'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GroupCreateScreen(me: me)));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _newChat() async {
    final ctl = TextEditingController();
    final other = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text('محادثة جديدة'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          autocorrect: false,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            hintText: 'اسم المستخدم',
            prefixIcon: Icon(Icons.alternate_email, color: kMuted),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, ctl.text.trim().toLowerCase()),
              child: const Text('ابدأ')),
        ],
      ),
    );
    if (other == null || other.isEmpty) return;
    if (other == me) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('هاد إنت!')));
      }
      return;
    }
    try {
      final doc = await fs.collection('users').doc(other).get();
      if (!mounted) return;
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ما في مستخدم باسم @$other')));
        return;
      }
      final members = [me, other]..sort();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
                me: me,
                chatId: members.join('~'),
                members: members,
                isGroup: false,
                title: other,
                other: other,
              )));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = fs
        .collection('chats')
        .where('members', arrayContains: me)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: const [
          RobotLogo(size: 34),
          SizedBox(width: 10),
          Text('Mr Chat',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProfileScreen(me: me))),
              child: UserBuilder(
                username: me,
                builder: (c, u) => Avatar(
                    name: me, photo: u['photo'] as String?, size: 38),
              ),
            ),
          ),
        ]
