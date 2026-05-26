import 'package:flutter_test/flutter_test.dart';
import 'package:moviecc_flutter/providers/feed_provider.dart';

void main() {
  group('FeedProvider Tests', () {
    test('initial state should be correct', () {
      final provider = FeedProvider();

      expect(provider.posts, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, isNull);
    });

    // Note: To test fetchPosts and other methods that use FirebaseFirestore.instance,
    // we would typically use a package like fake_cloud_firestore.
    // For now, we test the initial state and basic properties.
  });
}
