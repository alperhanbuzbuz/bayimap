import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _domainFromEmail(String email) => email.split('@').last.toLowerCase();

  /// Kayıt: şirketi bul ya da oluştur, kullanıcıyı ekle
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String companyName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(name);

    final domain = _domainFromEmail(email);

    // Bu domain'e ait şirket var mı?
    final existing = await _db
        .collection('companies')
        .where('domain', isEqualTo: domain)
        .limit(1)
        .get();

    String companyId;
    if (existing.docs.isNotEmpty) {
      companyId = existing.docs.first.id;
    } else {
      // Yoksa yeni şirket oluştur
      final ref = await _db.collection('companies').add({
        'name': companyName,
        'domain': domain,
        'createdAt': FieldValue.serverTimestamp(),
      });
      companyId = ref.id;
    }

    // Kullanıcıyı kaydet
    await _db.collection('users').doc(credential.user!.uid).set({
      'name': name,
      'email': email,
      'companyId': companyId,
      'role': existing.docs.isEmpty ? 'admin' : 'employee',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Giriş
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Çıkış
  Future<void> signOut() => _auth.signOut();

  /// Giriş yapan kullanıcının verisi (tek seferlik)
  Future<Map<String, dynamic>?> getUserData() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Giriş yapan kullanıcının verisi (realtime stream)
  /// Firestore'da döküman yoksa Firebase Auth'dan oluşturur
  Stream<Map<String, dynamic>?> userDataStream() {
    final user = currentUser;
    if (user == null) return const Stream.empty();
    return _db.collection('users').doc(user.uid).snapshots().asyncMap(
      (snap) async {
        if (!snap.exists) {
          // Auth'da var ama Firestore'da yok — dökümanı oluştur
          final domain = _domainFromEmail(user.email ?? '');
          final existing = await _db
              .collection('companies')
              .where('domain', isEqualTo: domain)
              .limit(1)
              .get();

          String companyId;
          if (existing.docs.isNotEmpty) {
            companyId = existing.docs.first.id;
          } else {
            final ref = await _db.collection('companies').add({
              'name': domain,
              'domain': domain,
              'createdAt': FieldValue.serverTimestamp(),
            });
            companyId = ref.id;
          }

          final data = {
            'name': user.displayName ?? user.email?.split('@').first ?? '—',
            'email': user.email ?? '',
            'companyId': companyId,
            'role': existing.docs.isEmpty ? 'admin' : 'employee',
            'createdAt': FieldValue.serverTimestamp(),
          };
          await _db.collection('users').doc(user.uid).set(data);
          return data;
        }
        return snap.data();
      },
    );
  }

  /// Kullanıcının şirket verisi (realtime stream)
  Stream<Map<String, dynamic>?> companyDataStream() {
    return userDataStream().asyncExpand((userData) {
      final companyId = userData?['companyId'] as String?;
      if (companyId == null) return const Stream.empty();
      return _db
          .collection('companies')
          .doc(companyId)
          .snapshots()
          .map((snap) => snap.data());
    });
  }
}
