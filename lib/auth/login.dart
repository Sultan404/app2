import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:second/copm/button.dart';
import 'package:second/copm/logo.dart';
import 'package:second/copm/textform.dart';

class login extends StatefulWidget {
  const login({Key? key}) : super(key: key);

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  GlobalKey<FormState> formState = GlobalKey<FormState>();

  bool v = false;

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // Show success dialog
      showAwesomeDialog(
        context,
        DialogType.success,
        'Success',
        'Password reset link sent to your email.',
      );
    } catch (e) {
      // Show error dialog
      showAwesomeDialog(
        context,
        DialogType.error,
        'Error',
        'Failed to send password reset email. Please try again later.',
      );
      print('Error: $e');
    }
  }

  void showResetPasswordModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Reset Password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Email Address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    password.text = " ";
                    if (formState.currentState!.validate()) {
                      resetPassword(email.text);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Send Reset Link'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Form(
          key: formState,
          child: Column(children: <Widget>[
            SizedBox(height: 200.0),
            Text(
              'Holek',
              style: TextStyle(
                fontSize: 50.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 172, 78, 212),
                shadows: <Shadow>[
                  Shadow(
                    offset: Offset(5.0, 5.0),
                    blurRadius: 3.0,
                    color: Color.fromARGB(255, 166, 162, 162),
                  ),
                ],
              ),
            ),
            SizedBox(height: 50.0),
            TextFormField(
              controller: email,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 242, 241, 241),
                prefixIcon: Icon(Icons.email),
                prefixIconColor: Color.fromARGB(255, 222, 220, 220),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Email Address';
                }
                return null;
              },
            ),
            SizedBox(height: 10.0),
            TextFormField(
              controller: password,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 242, 241, 241),
                prefixIcon: Icon(Icons.lock),
                prefixIconColor: Color.fromARGB(255, 222, 220, 220),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Not registered yet?'),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed("signup");
                  },
                  child: Text('Register'),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('Forget Password?'),
                TextButton(
                  onPressed: () {
                    showResetPasswordModal(context);
                  },
                  child: Text('Reset Password'),
                ),
              ],
            ),
            MaterialButton(
              height: 50,
              minWidth: 120,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(70)),
              onPressed: () async {
                if (formState.currentState!.validate()) {
                  try {
                    final credential =
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email.text,
                      password: password.text,
                    );
                    if (credential.user!.emailVerified) {
                      // Check if user document exists
                      final userDoc = await FirebaseFirestore.instance
                          .collection('Users')
                          .doc(credential.user!.uid)
                          .get();

                      if (!userDoc.exists) {
                        // Create user document if it doesn't exist
                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(credential.user!.uid)
                            .set({});
                      }

                      Navigator.of(context).pushReplacementNamed("home");
                    } else {
                      // Show email verification error dialog
                      showAwesomeDialog(
                        context,
                        DialogType.error,
                        'Error',
                        'Please verify your email.',
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    // Show login error dialog
                    showAwesomeDialog(
                      context,
                      DialogType.error,
                      'Error',
                      'Incorrect email or password. Please try again.',
                    );
                  } catch (e) {
                    print('Error: $e');
                  }
                } else {
                  print("Enter the email and password");
                }
              },
              color: Colors.purple,
              child: Text(
                'Login',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void showAwesomeDialog(
      BuildContext context, DialogType dialogType, String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: dialogType,
      animType: AnimType.rightSlide,
      title: title,
      desc: desc,
    ).show();
  }
}
