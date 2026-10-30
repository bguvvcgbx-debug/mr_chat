import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const kBlue = Color(0xFF2F6BFF);
const kBlack = Color(0xFF000000);
const kPanel = Color(0xFF0E1320);
const kLine = Color(0xFF1F2A44);

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

class MrChatApp extends StatelessWidget {
  const MrChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
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
      setState(() => _error = 'Username: 3-20 letters, numbers or _');
      return;
    }
    if (_creating && p.length < 8) {
      setState(() => _error = 'Password needs at least 8 characters');
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
          msg = '@$u is already taken. Try another.';
          break;
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          msg = 'Wrong username or password';
          break;
        case 'network-request-failed':
          msg = 'No internet connection';
          break;
        case 'operation-not-allowed':
          msg = 'Email/Password sign-in is not enabled in Firebase yet';
          break;
        default:
          msg = 'Error: ${e.code}';
      }
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = 'Something went wrong: $e');
    }
    if (mounted) setState(() => _busy = false);
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
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
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
                      icon: Icon(
                          _hide ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: Color(0xFFFF6B6B))),
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
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Text(_creating ? 'Create account' : 'Log in',
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

  Future<void> _newChat() async {
    final ctl = TextEditingController();
    final other = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kPanel,
        title: const Text('New chat'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          autocorrect: false,
          decoration:
              const InputDecoration(hintText: 'Username', prefixText: '@ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, ctl.text.trim().toLowerCase()),
              child: const Text('Start')),
        ],
      ),
    );
    if (other == null || other.isEmpty) return;
    if (other == me) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("That's you!")));
      }
      return;
    }
    try {
      final doc = await fs.collection('users').doc(other).get();
      if (!mounted) return;
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user named @$other')));
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(me: me, other: other)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
        backgroundColor: kBlack,
        title: Row(children: [
          const RobotLogo(size: 30),
          const SizedBox(width: 10),
          Text('@$me', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
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
                    RobotLogo(size: 80),
                    SizedBox(height: 16),
                    Text('No chats yet. Tap the pencil to start one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data();
              final members = List<String>.from(d['members'] ?? []);
              final other =
                  members.firstWhere((m) => m != me, orElse: () => me);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: kBlue,
                  child: Text(other.isEmpty ? '?' : other[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text('@$other'),
                subtitle: Text('${d['last'] ?? ''}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(me: me, other: other))),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kBlue,
        onPressed: _newChat,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String me;
  final String other;
  const ChatScreen({super.key, required this.me, required this.other});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctl = TextEditingController();
  late final String _id = ([widget.me, widget.other]..sort()).join('~');

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty) return;
    _ctl.clear();
    try {
      final chat = fs.collection('chats').doc(_id);
      final batch = fs.batch();
      batch.set(
          chat,
          {
            'members': _id.split('~'),
            'last': text,
            'updated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
      batch.set(chat.collection('messages').doc(), {
        'from': widget.me,
        'text': text,
        'ts': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Not sent: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = fs
        .collection('chats')
        .doc(_id)
        .collection('messages')
        .orderBy('ts', descending: true)
        .limit(100)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBlack,
        title: Text('@${widget.other}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data!.docs;
                if (msgs.isEmpty) {
                  return Center(
                      child: Text('Say hi to @${widget.other}',
                          style: const TextStyle(color: Colors.white60)));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i].data();
                    final mine = m['from'] == widget.me;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: mine ? kBlue : kPanel,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('${m['text'] ?? ''}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'Message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: kBlue),
                    onPressed: _send,
                    icon: const Icon(Icons.send),
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
