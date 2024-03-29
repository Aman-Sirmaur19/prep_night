import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:fluttermoji/fluttermojiCircleAvatar.dart';
import 'package:prep_night/screens/avatar_screen.dart';

import '../main.dart';
import '../models/main_user.dart';

import '../api/apis.dart';
import '../helper/dialogs.dart';

// profile screen -- to show signed in user info
class ProfileScreen extends StatefulWidget {
  final MainUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // for hiding keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(width: mq.width, height: mq.height * .03),
                  InkWell(
                    borderRadius: BorderRadius.circular(mq.height * .075),
                    onTap: () {
                      // _showBottomSheet();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AvatarScreen()));
                    },
                    child: FluttermojiCircleAvatar(
                      backgroundColor: Colors.grey[200],
                      radius: mq.height * .075,
                    ),
                  ),
                  SizedBox(height: mq.height * .02),
                  Text(APIs.user.phoneNumber!),
                  SizedBox(height: mq.height * .05),
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        CupertinoIcons.person,
                        color: Colors.lightBlue,
                      ),
                      labelText: 'Name',
                      hintText: 'eg. Aman Sirmaur',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  SizedBox(height: mq.height * .02),
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        CupertinoIcons.pencil_ellipsis_rectangle,
                        color: Colors.lightBlue,
                      ),
                      labelText: 'About',
                      hintText: 'eg. Feeling Happy!',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  SizedBox(height: mq.height * .02),
                  TextFormField(
                    initialValue: widget.user.branch,
                    onSaved: (val) => APIs.me.branch = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.school,
                        color: Colors.lightBlue,
                      ),
                      labelText: 'Branch',
                      hintText: 'eg. Mechanical Engineering',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  SizedBox(height: mq.height * .02),
                  TextFormField(
                    initialValue: widget.user.college,
                    onSaved: (val) => APIs.me.college = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.apartment,
                        color: Colors.lightBlue,
                      ),
                      labelText: 'College',
                      hintText: 'eg. NIT Agartala',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                  SizedBox(height: mq.height * .02),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.lightBlue.shade50,
                      fixedSize: Size(mq.width * .35, mq.height * .05),
                    ),
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('Update'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackBar(
                              context, 'Profile Updated Successfully!');
                        });
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
