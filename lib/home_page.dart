import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'main_home_page.dart';
import 'review.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _reviewController = TextEditingController();
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Unknown User';
    });
  }

  Future<void> _submitReview() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      String userId = user.uid;
      String? reviewText = _reviewController.text;

      if (userId.isEmpty || reviewText == null || reviewText.isEmpty) {
        return;
      }

      Review review = Review(
        id: '',
        userId: userId,
        username: _username,
        review: reviewText,
        timestamp: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('reviews').add(review.toMap());
      setState(() {
        _reviewController.clear();
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Thank You!'),
            content: Text('Thank you for your review!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error in _submitReview: $e");
    }
  }

  Future<void> _confirmLogout() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('email');
                await prefs.remove('password');
                await prefs.remove('username');
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        automaticallyImplyLeading: false, // Remove back button
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _confirmLogout(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Logged in as $_username', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey),
              ),
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  border: InputBorder.none,
                ),
                maxLines: 3,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitReview,
              child: Text('Submit Review'),
            ),
            Expanded(
              child: MainHomePage(),
            ),
          ],
        ),
      ),
    );
  }
}
