import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String username;
  final String review;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    required this.review,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'review': review,
      'timestamp': timestamp,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    // Ensure the timestamp is correctly handled
    var timestamp = map['timestamp'];
    DateTime reviewDate;
    if (timestamp is Timestamp) {
      reviewDate = timestamp.toDate();
    } else {
      reviewDate = DateTime.now(); // Provide a default value if timestamp is not a valid type
    }

    return Review(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      username: map['username'] ?? 'Unknown User',
      review: map['review'] ?? 'No review provided',
      timestamp: reviewDate,
    );
  }
}
