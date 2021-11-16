import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'auth_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';


class LoginForm extends StatefulWidget {
  Set<WordPair> saved;

  LoginForm(this.saved);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool enable = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(
      builder: (context, authentication, child) {
        return Container(
            child: Column(children: <Widget>[
          const Text(
            "Welcome to Startup Names Generator, please log in below",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Colors.deepPurple,
                child: MaterialButton(
                  minWidth: MediaQuery.of(context).size.width,
                  onPressed: () {
                    setState(() {
                      enable = false;
                    });
                    loginButton(context, authentication);
                  },
                  child: buttonOrProgressBar(),
                )),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(30.0),
                color: Colors.lightBlue,
                child: MaterialButton(
                  minWidth: MediaQuery.of(context).size.width,
                  onPressed: () {
                    signUpButton(context, authentication);
                  },
                  child: const Text(
                    "New user? Click to sign up",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                )),
          )
        ]));
      },
    );
  }

  void loginButton(BuildContext context, AuthRepository authentication) async {
    bool res = await authentication.signIn(
        emailController.text, passwordController.text);
    if (res == false) {
      final snackBar =
          SnackBar(content: Text('There was an error logging into the app'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      updateUserData(authentication);
      Navigator.of(context).pop();
    }
    setState(() {
      enable = true;
    });
  }

  Widget buttonOrProgressBar() {
    if (enable) {
      return const Text(
        "Log in",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white),
      );
    } else {
      return CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    }
  }

  void updateUserData(AuthRepository authentication) async {
    /// we take the suggestions save by the user while logout and merge to the suggestions
    /// saved while login to display all
    for (int i = 0; i < widget.saved.length; i++) {
      var pair = widget.saved.elementAt(i);
      _firestore
          .collection('users')
          .doc(authentication.user?.uid)
          .collection('SavedSuggestions')
          .doc(pair.asPascalCase)
          .set({'name': pair.asPascalCase});
    }
  }

  void signUpButton(BuildContext context, AuthRepository authentication) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Container(
                  height: 250,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Center(child: const Text('Please confirm yout password below:',
                          style: TextStyle(fontSize: 16))),
                      TextFormField(
                        obscureText: true,
                        controller: confirmPasswordController,
                        decoration: const InputDecoration(labelText: 'Password'),
                      ),
                      TextButton(
                          child: Text(
                            "Confirm",
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () {checkPasswordAndSignUp(authentication);},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                          )),
                    ],
                  ),
                ),
              ));
        });


  }

  checkPasswordAndSignUp(AuthRepository authentication) async {
    if(passwordController.text == confirmPasswordController.text){
      await authentication.signUp(
          emailController.text, passwordController.text);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }else{
      confirmPasswordController.clear();
      Navigator.of(context).pop();
      final snackBar =
      SnackBar(content: Text('Passwords must match'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

class GrabbingWidget extends StatefulWidget {
  String? email;
  SnappingSheetController snappingSheetController;
  double sigmaX ;
  double sigmaY  ;

  GrabbingWidget(this.email, this.snappingSheetController, this.sigmaX, this.sigmaY);

  @override
  _GrabbingWidgetState createState() => _GrabbingWidgetState();
}

class _GrabbingWidgetState extends State<GrabbingWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: BackdropFilter(
          filter:  ImageFilter.blur(sigmaX:widget.sigmaX, sigmaY: widget.sigmaY),
          child: Material(
            color: Colors.grey.shade400,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(
                    'Welcome back, ${widget.email}',
                    style: TextStyle(
                      fontFamily: "Arial",
                      fontSize: 15.0,
                    ),
                    overflow: TextOverflow.fade,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 90.0),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                  ),
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          if (widget.snappingSheetController.currentPosition == 30) {
            widget.snappingSheetController.setSnappingSheetPosition(140);
          } else {
            widget.snappingSheetController.setSnappingSheetPosition(30);
          }
        },

       );
  }
}

class SheetContent extends StatefulWidget {
  String? email;
  String? uid;

  SheetContent(this.email, this.uid);

  @override
  _SheetContentState createState() => _SheetContentState();
}

class _SheetContentState extends State<SheetContent> {
  String imagePath = "";

  @override
  void initState() {
    super.initState();
    String storagePath = 'avatars/ ${widget.uid}' ;
    upload(storagePath);
  }

  void upload(String storagePath) async{
    FirebaseStorage storage = FirebaseStorage.instance;
    Reference ref = storage.ref().child(storagePath);
    try{
      var res =  await ref.getDownloadURL();
      imagePath = res;
      setState(() {

      });
    }catch(e){

    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15.0, top: 15.0),
            child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 38,
                  backgroundImage: imagePath.isNotEmpty ? NetworkImage(imagePath)
                       : null,
                  backgroundColor: Colors.white,
                )
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0, top: 15.0),
                  child: Text(
                    '${widget.email}',
                    style: TextStyle(
                      fontFamily: "Arial",
                      fontSize: 21.0,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0, top: 8.0),
                  child: SizedBox(
                    height: 35,
                    width: 140,
                    child: TextButton(
                        child: Text(
                          "Change avatar",
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          changeAvatar();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                        )),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  changeAvatar() async {
    ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      uploadImageToFirebase(image.path);
    } else {
      final snackBar =
      SnackBar(content: Text('No image selected'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future uploadImageToFirebase(String localPath) async {
    FirebaseStorage storage = FirebaseStorage.instance;
    String storagePath = 'avatars/ ${widget.uid}' ;
    Reference ref = storage.ref().child(storagePath);
    var uploadTask = await ref.putFile(File(localPath));
    imagePath = await uploadTask.ref.getDownloadURL();
    setState(() {});
  }
}
