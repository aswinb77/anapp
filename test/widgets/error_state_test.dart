import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviecc_flutter/widgets/media_carousel.dart';
import 'package:moviecc_flutter/models/movie.dart';

void main() {
  testWidgets('MediaCarouselSection shows error UI when fetchFunc throws', (WidgetTester tester) async {
    // Arrange
    Future<List<Movie>> mockFetchFunc() async {
      throw Exception('Failed to load movies');
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaCarouselSection(
            title: 'Trending',
            fetchFunc: mockFetchFunc,
            onMovieClick: (m) {},
            isTv: false,
            tag: 'Trending',
          ),
        ),
      ),
    );

    // Initial state is loading
    expect(find.byType(CircularProgressIndicator), findsNothing); // It actually uses Shimmer for loading, so this is just to wait.
    
    // Act
    await tester.pumpAndSettle(); // Wait for fetchFunc to throw and setState

    // Assert
    expect(find.text('Failed to load'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
