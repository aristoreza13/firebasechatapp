import 'package:firebasechatapp/common/entities/entities.dart';
import 'package:firebasechatapp/common/routes/names.dart';
import 'package:firebasechatapp/common/store/store.dart';
import 'package:firebasechatapp/common/widgets/toast.dart';

import 'index.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>['openid']);

class SignInController extends GetxController {
  final state = SignInState();
  SignInController();
  final db = FirebaseFirestore.instance;

  Future<void> hanldeSignIn() async {
    try {
      var user = await _googleSignIn.signIn();
      if (user != null) {
        // save credential to firebase Authentication with OAuthCredential
        final _gAuthentication = await user.authentication;
        final _credentials = GoogleAuthProvider.credential(
          idToken: _gAuthentication.idToken,
          accessToken: _gAuthentication.accessToken,
        );

        await FirebaseAuth.instance.signInWithCredential(_credentials);

        String displayName = user.displayName ?? user.email;
        String email = user.email;
        String id = user.id;
        String photoUrl = user.photoUrl ?? "";

        UserLoginResponseEntity userProfile = UserLoginResponseEntity();
        userProfile.email = email;
        userProfile.displayName = displayName;
        userProfile.accessToken = id;
        userProfile.photoUrl = photoUrl;

        UserStore.to.saveProfile(userProfile); //Save locally

        var userbase = await db
            .collection("users")
            .withConverter(
              fromFirestore: UserData.fromFirestore,
              toFirestore: (UserData userData, options) => userData.toFirestore(),
            )
            .where("id", isEqualTo: id)
            .get(); //Check if user is exist or not

        if (userbase.docs.isEmpty) {
          final data = UserData(
            id: id,
            name: displayName,
            email: email,
            photourl: photoUrl,
            location: "",
            fcmtoken: "",
            addtime: Timestamp.now(),
          ); // Assign data to map and prepare to send

          await db
              .collection("users")
              .withConverter(
                fromFirestore: UserData.fromFirestore,
                toFirestore: (UserData userData, options) => userData.toFirestore(),
              )
              .add(data); // Add the data to Firebase
        }

        toastInfo(msg: "Login success");
        Get.offAndToNamed(AppRoutes.Application);
      }
    } catch (e) {
      toastInfo(msg: "Login error");
      print(e);
    }
  }

  // If the user already logged in
  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print("User is currently logged out");
      } else {
        print("User is logged in");
      }
    });
  }
}
