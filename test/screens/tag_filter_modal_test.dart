import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/tab_navigation/meal_list_view/tag_filter_modal.dart';

void main() {
  test('toggleTag adds a missing tag without mutating the input', () {
    final current = List<String>.unmodifiable(['Vegan']);
    expect(TagFilterModal.toggleTag(current, 'Schnell'), ['Vegan', 'Schnell']);
  });

  test('toggleTag removes a present tag without mutating the input', () {
    final current = List<String>.unmodifiable(['Vegan', 'Schnell']);
    final result = TagFilterModal.toggleTag(current, 'Vegan');
    expect(result, ['Schnell']);
    expect(identical(result, current), isFalse);
  });
}
