import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Run with `dart run scripts/seed_firestore.dart` from project root.
  // Ensure Firebase emulator or credentials are configured.

  final firestore = FirebaseFirestore.instance;

  final now = DateTime.now();
  final customRequests = [
    {
      'customerId': 'customer1',
      'shopId': 'shopA',
      'designerId': null,
      'type': 'customization',
      'productId': 'prod1',
      'selectedColor': 'Blue',
      'selectedSize': 'M',
      'selectedMaterial': 'Cotton',
      'description': 'Make this dress in blue cotton with embroidered pocket.',
      'imageUrl': null,
      'status': 'pending',
    },
    {
      'customerId': 'customer2',
      'shopId': null,
      'designerId': null,
      'type': 'inquiry',
      'productId': null,
      'selectedColor': null,
      'selectedSize': null,
      'selectedMaterial': null,
      'description': 'Need a custom wooden coffee table 120x60cm for living room.',
      'imageUrl': 'https://example.com/sample-custom-inquiry.jpg',
      'status': 'assigned',
    },
    {
      'customerId': 'customer3',
      'shopId': 'shopB',
      'designerId': 'designer1',
      'type': 'customization',
      'productId': 'prod3',
      'selectedColor': 'Green',
      'selectedSize': 'L',
      'selectedMaterial': 'Silk',
      'description': 'Add a matching belt and make the sleeves longer.',
      'imageUrl': null,
      'status': 'in_progress',
    },
  ];

  for (final data in customRequests) {
    final doc = firestore.collection('customRequests').doc();
    await doc.set({
      'requestId': doc.id,
      ...data,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    print('Seeded custom request: ${doc.id}');
  }

  print('Seed complete.');
}
