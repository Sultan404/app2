import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:second/real/home.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _currentPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();

  // Function to handle password reset
  Future<void> resetPassword() async {
    try {
      String email = FirebaseAuth.instance.currentUser!.email!;
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to your email.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send password reset email. Please try again later.')),
      );
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Color.fromARGB(255, 136, 37, 186),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            SizedBox(height: 40.0),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Enter your Email',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(255, 242, 241, 241),
                prefixIcon: Icon(Icons.person),
                prefixIconColor: Color.fromARGB(255, 222, 220, 220),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your Email';
                }
                return null;
              },
            ),
            
            
            SizedBox(height: 15.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      
                      
                      resetPassword;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Link send')),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Container(
                            color: const Color.fromARGB(255, 185, 72, 72),
                            child: MyHomePage(),
                          ),
                        ),
                      );
                    }
                  },
                  child:  Text('Send Reset Password Link'),
                ),
                
              ],
            ),
          ],
        ),
      ),
    );
  }
}
