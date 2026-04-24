import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/foodly_change.dart';
import 'package:foodly/widgets/new_version_modal.dart';

void main() {
  test('#checkVersionNotesForVariables replaces {appName}', () {
    const translations = [
      ChangeTranslation(
        title: 'test {appName}',
        description: 'test {appName}',
        language: 'en',
      ),
    ];

    final result = NewVersionModal.checkVersionNotesForVariables(translations);

    expect(result[0].title, 'test $kAppName');
    expect(result[0].description, 'test $kAppName');
  });

  test('#checkVersionNotesForVariables returns same instance when no replacement needed', () {
    const translation = ChangeTranslation(
      title: 'no variables here',
      description: 'none here either',
      language: 'en',
    );

    final result = NewVersionModal.checkVersionNotesForVariables([translation]);

    expect(identical(result[0], translation), isTrue);
  });
}
