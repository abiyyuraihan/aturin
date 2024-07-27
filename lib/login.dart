import 'package:aturin/register.dart';
import 'package:aturin/screens/users/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  String emailOrPhone = '';
  String password = '';
  String errorMessage = '';

  Future<void> loginUser(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        await Provider.of<AuthProvider>(context, listen: false)
            .login(emailOrPhone, password);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } catch (error) {
        setState(() {
          errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 40),
                Image.asset('assets/images/logo512.png', width: 120),
                SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Email atau nomor telepon',
                          fillColor: Colors.grey[800],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        onSaved: (value) => emailOrPhone = value!,
                        validator: (value) => value!.isEmpty
                            ? 'Field ini tidak boleh kosong'
                            : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          fillColor: Colors.grey[800],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        obscureText: true,
                        onSaved: (value) => password = value!,
                        validator: (value) => value!.isEmpty
                            ? 'Password tidak boleh kosong'
                            : null,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => loginUser(context),
                        child: Text('Masuk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Text(
                            errorMessage,
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Belum punya akun?',
                              style: TextStyle(color: Colors.white)),
                          TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Register())),
                            child: Text('Registrasi',
                                style: TextStyle(color: Colors.indigo[300])),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
