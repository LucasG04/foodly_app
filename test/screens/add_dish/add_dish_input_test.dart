import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/add_dish/add_dish_input.dart';

void main() {
  void expectInput(String input, AddDishKind kind, [String? url]) {
    final result = classifyAddDishInput(input);
    expect(result.kind, kind);
    expect(result.url, url);
    expect(result.text, input.trim());
  }

  test('empty input', () => expectInput('', AddDishKind.empty));
  test('whitespace only', () => expectInput('   ', AddDishKind.empty));
  test('dish description',
      () => expectInput('Spaghetti bolognese', AddDishKind.ai));
  test('decimal number is not a link',
      () => expectInput('Kartoffeln 1.5 kg', AddDishKind.ai));
  test('sentence dots are not a link',
      () => expectInput('Pasta. Schnell.', AddDishKind.ai));
  test('recipe website link', () {
    const url = 'https://www.chefkoch.de/rezepte/123/x.html';
    expectInput(url, AddDishKind.website, url);
  });
  test('link without scheme gets https', () {
    expectInput('chefkoch.de/rezepte/123', AddDishKind.website,
        'https://chefkoch.de/rezepte/123');
  });
  test('instagram link', () {
    const url = 'https://www.instagram.com/reel/abc/';
    expectInput(url, AddDishKind.instagram, url);
  });
  test('instagram link inside shared caption', () {
    expectInput('Look at this! https://www.instagram.com/reel/abc/ 😍',
        AddDishKind.instagram, 'https://www.instagram.com/reel/abc/');
  });
  test('link after a decimal number', () {
    expectInput('Für 2.5 Personen https://www.instagram.com/reel/abc/',
        AddDishKind.instagram, 'https://www.instagram.com/reel/abc/');
  });
  test('foodly meal link', () {
    const url = 'https://foodly.golenia.dev/meal/xyz';
    expectInput(url, AddDishKind.website, url);
  });
  test('http link is upgraded to https', () {
    expectInput('http://www.example.com/rezept', AddDishKind.website,
        'https://www.example.com/rezept');
  });
  test('auto-capitalized scheme still is a link', () {
    expectInput('Https://www.chefkoch.de/rezepte/1/x.html', AddDishKind.website,
        'https://www.chefkoch.de/rezepte/1/x.html');
  });
  test('upper-case instagram link', () {
    final result = classifyAddDishInput('HTTPS://WWW.INSTAGRAM.COM/reel/abc/');
    expect(result.kind, AddDishKind.instagram);
    expect(result.url, startsWith('https://'));
  });
  test('missing space after a dot is not a link',
      () => expectInput('Lasagne mit Spinat.Schnell gemacht', AddDishKind.ai));
  test('domain name in a description is not a link',
      () => expectInput('Pizza wie bei chefkoch.de', AddDishKind.ai));
  test('umlauts around a dot are not a link',
      () => expectInput('Käse.Spätzle', AddDishKind.ai));
  test('www host without path is a link', () {
    expectInput(
        'www.chefkoch.de', AddDishKind.website, 'https://www.chefkoch.de');
  });
  test('link in brackets drops the bracket', () {
    expectInput('Rezept (https://www.chefkoch.de/rezepte/123/x.html)',
        AddDishKind.website, 'https://www.chefkoch.de/rezepte/123/x.html');
  });
  test('link at the end of a sentence drops the full stop', () {
    expectInput('Schau mal: https://www.chefkoch.de/rezepte/123/x.html.',
        AddDishKind.website, 'https://www.chefkoch.de/rezepte/123/x.html');
  });
  test('link with a port keeps the port and path', () {
    expectInput('https://example.com:8080/rezept', AddDishKind.website,
        'https://example.com:8080/rezept');
  });
  test('half-typed link offers nothing yet', () {
    expectInput('https://www.i', AddDishKind.empty);
    expectInput('www.', AddDishKind.empty);
    expectInput('Https:/', AddDishKind.empty);
  });
}
