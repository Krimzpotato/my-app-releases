import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review.dart';

class MainHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews and Thoughts'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reviews').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var reviews = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>?; // Cast to Map<String, dynamic> safely
            // Ensure the data is not null and handle null values
            String userId = data?['userId'] ?? 'Unknown User ID';
            String username = data?['username'] ?? 'Unknown User';
            String review = data?['review'] ?? 'No review provided';
            var timestamp = data?['timestamp'];

            DateTime reviewDate;
            if (timestamp is Timestamp) {
              reviewDate = timestamp.toDate();
            } else {
              reviewDate = DateTime.now(); // Provide a default value if timestamp is not a valid type
            }

            String formattedDate = "${reviewDate.day}/${reviewDate.month}/${reviewDate.year} ${reviewDate.hour}:${reviewDate.minute}";

            return Review(
              id: doc.id,
              userId: userId,
              username: username,
              review: review,
              timestamp: reviewDate,
            );
          }).toList();

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              var review = reviews[index];
              String formattedDate = "${review.timestamp.day}/${review.timestamp.month}/${review.timestamp.year} ${review.timestamp.hour}:${review.timestamp.minute}";
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
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
                child: ListTile(
                  title: Text(review.review),
                  subtitle: Text('Username: ${review.username}\nTimestamp: ${formattedDate}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
