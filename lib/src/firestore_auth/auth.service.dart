import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jam_dart_interfaces/interfaces.dart';
import 'package:jam_dart_models/models.dart';
import 'package:rxdart/rxdart.dart';

class AuthService implements AuthInterface {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Observable<User> user;

  User mapFirebaseUserToUser(FirebaseUser firebaseUser) => firebaseUser == null
      ? null
      : User(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName,
          email: firebaseUser.email,
          phone: firebaseUser.phoneNumber,
          profile: UserProfile(
            name: firebaseUser.displayName,
            photoUrl: firebaseUser.photoUrl,
          ),
        );

  @override
  Future<bool> initialize() {
    this.user = Observable(_auth.onAuthStateChanged).map(mapFirebaseUserToUser);
    return this.user.map((user) => true).first;
  }

  @override
  Observable<User> register(Credential credential) {
    return Observable.fromFuture(_auth.createUserWithEmailAndPassword(
            email: credential.username, password: credential.password))
        .map(mapFirebaseUserToUser);
  }

  @override
  Observable<User> signIn(Credential credential) {
    return Observable.fromFuture(_auth.signInWithEmailAndPassword(
            email: credential.username, password: credential.password))
        .map(mapFirebaseUserToUser);
  }

  @override
  Observable<User> signInWithGoogle() {
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    return Observable.fromFuture(_googleSignIn.signIn())
        .asyncMap((googleUser) => googleUser.authentication)
        .asyncMap((googleAuth) => _auth.signInWithGoogle(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            ))
        .map(mapFirebaseUserToUser);
  }

  @override
  Observable<void> signOut() {
    return Observable.fromFuture(_auth.signOut());
  }
}
