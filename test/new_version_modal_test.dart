import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/foodly_version.dart';
import 'package:foodly/widgets/new_version_modal.dart';

void main() {
  test('#checkVersionNotesForVariables replaces {appName}', () {
    final versionNotes = [
      FoodlyVersionNote(
        title: 'test {appName}',
        description: 'test {appName}',
        language: 'en',
      ),
    ];

    final result = NewVersionModal.checkVersionNotesForVariables(versionNotes);

    expect(result[0].title, 'test $kAppName');
    expect(result[0].description, 'test $kAppName');
  });
}
