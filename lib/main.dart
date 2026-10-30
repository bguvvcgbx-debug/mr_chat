import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:image_picker/image_picker.dart';

const kBlue = Color(0xFF2F6BFF);
const kBlue2 = Color(0xFF6C8CFF);
const kBlack = Color(0xFF000000);
const kBg = Color(0xFF05070D);
const kPanel = Color(0xFF0E1320);
const kPanel2 = Color(0xFF172036);
const kLine = Color(0xFF1F2A44);
const kMuted = Color(0xFF8A94AB);
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
                        style: const TextStyle(color: Color(0xFFFF6B6B))),
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
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('خطأ: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs.toList();
          int when(QueryDocumentSnapshot<Map<String, dynamic>> d) =>
              (d.data()['updated'] as Timestamp?)?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;
          docs.sort((a, b) => when(b).compareTo(when(a)));
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RobotLogo(size: 90),
                    SizedBox(height: 18),
                    Text('ما في محادثات بعد',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('اضغط «جديد» وابدأ محادثة أو مجموعة',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kMuted)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final id = docs[i].id;
              final d = docs[i].data();
              final members = List<String>.from(d['members'] ?? []);
              final isGroup = d['isGroup'] == true;
              final last = '${d['last'] ?? ''}';
              final time = fmtTime(d['updated'] as Timestamp?);
              if (isGroup) {
                final title = '${d['name'] ?? 'مجموعة'}';
                return _ChatTile(
                  title: title,
                  group: true,
                  last: last,
                  time: time,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(
                            me: me,
                            chatId: id,
                            members: members,
                            isGroup: true,
                            title: title,
                          ))),
                );
              }
              final other =
                  members.firstWhere((m) => m != me, orElse: () => me);
              return UserBuilder(
                username: other,
                builder: (c, u) => _ChatTile(
                  title: dispName(u, other),
                  photo: u['photo'] as String?,
                  last: last,
                  time: time,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(
                            me: me,
                            chatId: id,
                            members: members,
                            isGroup: false,
                            title: other,
                            other: other,
                          ))),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        onPressed: _showNewMenu,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('جديد',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String title;
  final String? photo;
  final bool group;
  final String last;
  final String time;
  final VoidCallback onTap;
  const _ChatTile({
    required this.title,
    this.photo,
    this.group = false,
    required this.last,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Avatar(name: title, photo: photo, size: 54, group: group),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16.5, fontWeight: FontWeight.w700)),
                      ),
                      Text(time,
                          style:
                              const TextStyle(color: kMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kMuted, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GroupCreateScreen extends StatefulWidget {
  final String me;
  const GroupCreateScreen({super.key, required this.me});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _name = TextEditingController();
  final _member = TextEditingController();
  final List<String> _members = [];
  bool _busy = false;
  String? _error;

  Future<void> _addMember() async {
    final u = _member.text.trim().toLowerCase();
    if (u.isEmpty) return;
    if (u == widget.me || _members.contains(u)) {
      _member.clear();
      return;
    }
    try {
      final doc = await fs.collection('users').doc(u).get();
      if (!doc.exists) {
        setState(() => _error = 'ما في مستخدم باسم @$u');
        return;
      }
      setState(() {
        _members.add(u);
        _error = null;
      });
      _member.clear();
    } catch (e) {
      setState(() => _error = 'خطأ: $e');
    }
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اكتب اسم المجموعة');
      return;
    }
    if (_members.isEmpty) {
      setState(() => _error = 'ضيف عضو واحد على الأقل');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final id = 'grp-${DateTime.now().millisecondsSinceEpoch}-${widget.me}';
      final members = [widget.me, ..._members];
      await fs.collection('chats').doc(id).set({
        'members': members,
        'isGroup': true,
        'name': name,
        'admin': widget.me,
        'last': 'تم إنشاء المجموعة',
        'updated': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ChatScreen(
                me: widget.me,
                chatId: id,
                members: members,
                isGroup: true,
                title: name,
              )));
    } catch (e) {
      setState(() {
        _error = 'ما انعملت المجموعة: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مجموعة جديدة')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              hintText: 'اسم المجموعة',
              prefixIcon: Icon(Icons.groups_rounded, color: kMuted),
            ),
          ),
          const SizedBox(height: 18),
          const Text('الأعضاء',
              style: TextStyle(fontWeight: FontWeight.w700, color: kMuted)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _member,
                  autocorrect: false,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => _addMember(),
                  decoration: const InputDecoration(
                    hintText: 'اسم مستخدم',
                    prefixIcon: Icon(Icons.alternate_email, color: kMuted),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: kBlue),
                onPressed: _addMember,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in _members)
                Chip(
                  label: Text('@$m'),
                  backgroundColor: kPanel2,
                  onDeleted: () => setState(() => _members.remove(m)),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B))),
          ],
          const SizedBox(height: 24),
          GradButton(
            text: 'إنشاء المجموعة',
            busy: _busy,
            onPressed: _busy ? null : _create,
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String me;
  final String chatId;
  final List<String> members;
  final bool isGroup;
  final String title;
  final String? other;
  const ChatScreen({
    super.key,
    required this.me,
    required this.chatId,
    required this.members,
    required this.isGroup,
    required this.title,
    this.other,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctl = TextEditingController();

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    _ctl.clear();
    try {
      final chat = fs.collection('chats').doc(widget.chatId);
      final batch = fs.batch();
      final data = <String, dynamic>{
        'last': widget.isGroup ? '${widget.me}: $text' : text,
        'updated': FieldValue.serverTimestamp(),
      };
      if (!widget.isGroup) data['members'] = widget.members;
      batch.set(chat, data, SetOptions(merge: true));
      batch.set(chat.collection('messages').doc(), {
        'from': widget.me,
        'text': text,
        'ts': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ما انبعتت: $e')));
      }
    }
  }

  Widget _titleBar() {
    if (widget.isGroup) {
      return Row(
        children: [
          Avatar(name: widget.title, size: 38, group: true),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                Text('${widget.members.length} أعضاء',
                    style: const TextStyle(color: kMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      );
    }
    final other = widget.other ?? widget.title;
    return UserBuilder(
      username: other,
      builder: (c, u) => Row(
        children: [
          Avatar(name: other, photo: u['photo'] as String?, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dispName(u, other),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                Text('@$other',
                    style: const TextStyle(color: kMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = fs
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('ts', descending: true)
        .limit(100)
        .snapshots();
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: _titleBar()),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('خطأ: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data!.docs;
                if (msgs.isEmpty) {
                  return Center(
                      child: Text('ابدأ المحادثة مع ${widget.title}',
                          style: const TextStyle(color: kMuted)));
                }
                return ListView.builder(
                  reverse: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i].data();
                    final mine = m['from'] == widget.me;
                    return Align(
                      alignment: mine
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.centerEnd,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          gradient: mine ? kGrad : null,
                          color: mine ? null : kPanel2,
                          borderRadius: BorderRadiusDirectional.only(
                            topStart: const Radius.circular(18),
                            topEnd: const Radius.circular(18),
                            bottomStart: Radius.circular(mine ? 4 : 18),
                            bottomEnd: Radius.circular(mine ? 18 : 4),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isGroup && !mine)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text('${m['from'] ?? ''}',
                                    style: const TextStyle(
                                        color: kBlue2,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ),
                            Text('${m['text'] ?? ''}',
                                style: const TextStyle(
                                    fontSize: 15.5, height: 1.35)),
                            const SizedBox(height: 3),
                            Text(fmtTime(m['ts'] as Timestamp?),
                                style: TextStyle(
                                    fontSize: 10.5,
                                    color: mine
                                        ? Colors.white70
                                        : kMuted)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: kBg,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      minLines: 1,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(hintText: 'اكتب رسالة...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                          gradient: kGrad, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final String me;
  const ProfileScreen({super.key, required this.me});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  String? _photo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _load() async {
    try {
      final d = await fs.collection('users').doc(widget.me).get();
      final u = d.data() ?? <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _name.text = (u['name'] ?? '').toString();
        _photo = u['photo'] as String?;
      });
    } catch (_) {}
  }

  Future<void> _pick() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 70,
      );
      if (x == null) return;
      final b64 = base64Encode(await x.readAsBytes());
      await fs
          .collection('users')
          .doc(widget.me)
          .set({'photo': b64}, SetOptions(merge: true));
      if (mounted) setState(() => _photo = b64);
    } catch (e) {
      if (mounted) _snack('ما انحفظت الصورة: $e');
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await fs.collection('users').doc(widget.me).set(
          {'name': _name.text.trim()}, SetOptions(merge: true));
      if (mounted) _snack('تم الحفظ');
    } catch (e) {
      if (mounted) _snack('ما انحفظ: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text('تسجيل الخروج'),
        content: const Text('بدك تسجّل خروج؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('خروج')),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pick,
              child: Stack(
                children: [
                  Avatar(name: widget.me, photo: _photo, size: 120),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: kBlue, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text('@${widget.me}',
                style: const TextStyle(color: kMuted, fontSize: 15)),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              hintText: 'الاسم الظاهر',
              prefixIcon: Icon(Icons.badge_outlined, color: kMuted),
            ),
          ),
          const SizedBox(height: 16),
          GradButton(
            text: 'حفظ',
            busy: _saving,
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B6B),
              side: const BorderSide(color: Color(0xFF5A2A2A)),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
