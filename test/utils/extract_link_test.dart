import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/basic_utils.dart';

void main() {
  void expectLink(String input, String? url) =>
      expect(BasicUtils.extractLink(input), url, reason: input);

  test('domain with umlauts', () {
    expectLink('https://www.lecker-küche.de/rezepte/lasagne',
        'https://www.lecker-küche.de/rezepte/lasagne');
  });
  test('German quotation marks are not part of the link', () {
    expectLink('Rezept „https://www.chefkoch.de/r/1“',
        'https://www.chefkoch.de/r/1');
    expectLink('»https://www.chefkoch.de/r/1«', 'https://www.chefkoch.de/r/1');
  });
  test('brackets that belong to the link stay', () {
    expectLink('https://de.wikipedia.org/wiki/Lasagne_(Gericht)',
        'https://de.wikipedia.org/wiki/Lasagne_(Gericht)');
    expectLink('(https://de.wikipedia.org/wiki/Lasagne_(Gericht))',
        'https://de.wikipedia.org/wiki/Lasagne_(Gericht)');
  });
  test('a capitalised word with a slash is not a link', () {
    expectLink('Lasagne nach Oma.Style/vegetarisch', null);
  });
  test('a full link wins over an earlier bare one', () {
    expectLink('linktr.ee/chef https://www.instagram.com/reel/x/',
        'https://www.instagram.com/reel/x/');
  });
  test('tiktok share text', () {
    expectLink(
        'Lemon brownies 🍋 #baking https://vm.tiktok.com/ZGdCqSCL3/ '
            'Shared via TikTok Lite',
        'https://vm.tiktok.com/ZGdCqSCL3/');
  });
  test('bare lowercase links still count', () {
    expectLink('chefkoch.de/rezepte/123', 'https://chefkoch.de/rezepte/123');
    expectLink('www.chefkoch.de', 'https://www.chefkoch.de');
  });
}
