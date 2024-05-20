  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:second/copm/button.dart';
  import 'package:second/copm/logo.dart';
  import 'package:second/copm/textform.dart';
  import 'package:awesome_dialog/awesome_dialog.dart';

  class signup extends StatefulWidget {
    const signup({super.key});
    @override
    State<signup> createState() => _signupState();
  }

  class _signupState extends State<signup> {
    TextEditingController username = TextEditingController();
    TextEditingController email = TextEditingController();
    TextEditingController password = TextEditingController();
    TextEditingController repassword = TextEditingController();

    GlobalKey<FormState> formState = GlobalKey<FormState>();

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(),
        body: Form(
          key: formState,
          child: Column(children: <Widget>[
            SizedBox(height: 90.0),
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
            SizedBox(height: 5.0),
            TextFormField(
              controller: username,
              decoration: InputDecoration(
                labelText: 'Username ',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 242, 241, 241),
                prefixIcon: Icon(Icons.person_2),
                prefixIconColor: Color.fromARGB(255, 222, 220, 220),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Username ';
                }
                return null;
              },
            ),
            SizedBox(height: 15.0),
            TextFormField(
              controller: email,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 242, 241, 241),
                prefixIcon: Icon(Icons.email),
                prefixIconColor: Color.fromARGB(255, 222, 220, 220),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            SizedBox(height: 15.0),

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
            SizedBox(height: 15.0),

            TextFormField(
              controller: repassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 242, 241, 241),
                prefixIcon: Icon(Icons.lock),
                
                prefixIconColor: Color.fromARGB(255, 222, 220, 220),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                return null;
              },
            ),
            SizedBox(height: 15.0),
            MaterialButton(
              height: 50,
              minWidth: 120,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(70)),
              onPressed: () async {
                if ((password.text == repassword.text)) {
                  if (formState.currentState!.validate()) {
                    try {
                      final credential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: email.text,
                        password: password.text,
                      );
                      FirebaseAuth.instance.currentUser!.sendEmailVerification();
                      
                      AwesomeDialog(
                          context: context,
                          dialogType: DialogType.success,
                          animType: AnimType.rightSlide,
                          title: 'Success',
                          desc: 'Verification link sent to your email.',
                          btnOkOnPress: () {
                            Navigator.of(context)
                                .pushReplacementNamed("login");
                          },
                        ).show();


                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'weak-password') {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.error,
                          animType: AnimType.rightSlide,
                          title: 'Error',
                          desc: 'The password provided is too weak.',
                        ).show();
                      } else if (e.code == 'email-already-in-use') {
                        AwesomeDialog(
                          context: context,
                          dialogType: DialogType.error,
                          animType: AnimType.rightSlide,
                          title: 'Error',
                          desc: 'The account already exists for that email.',
                        ).show();
                      }
                    } catch (e) {
                      print(e);
                    }
                  }
                } else {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.error,
                    animType: AnimType.rightSlide,
                    title: 'Error',
                    desc: 'The password does not match.',
                  ).show();
                }
              },
              color: Colors.purple,
              child: Text(
                'Signup',
                style: TextStyle(color: Colors.white),
              ),
            ),

            Container(
              height: 20,
            ),

            Container(
              height: 20,
            ),

            Container(
              height: 20,
            ),
            // Text("don't have an account? Rigester", textAlign: TextAlign.center,),
            InkWell(
              onTap: () {
                Navigator.of(context).pushNamed("login");
              },
              child: const Center(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: "Already have an account?  "),
                  TextSpan(
                      text: "Login",
                      style: TextStyle(
                          color: Color.fromARGB(255, 124, 18, 170), fontWeight: FontWeight.bold)),
                ])),
              ),
            )
          ]),
        ),
      );
    }
  }
