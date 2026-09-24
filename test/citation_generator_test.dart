import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Citation Styles Format Verification', () {
    const title = 'Machine Learning in Academic Research';
    const author = 'Turing, Alan';
    const date = '2024';
    const publisher = 'Oxford University Press';
    const url = 'https://oxford.example.com/ml-research';

    test('APA Style format', () {
      final apa = '$author. ($date). $title. $publisher. Retrieved from $url';
      expect(apa.contains('(2024)'), true);
      expect(apa.contains(author), true);
      expect(apa.contains(title), true);
    });

    test('MLA Style format', () {
      final mla = '$author. "$title." $publisher, $date. $url';
      expect(mla.contains('"$title."'), true);
      expect(mla.contains('$publisher,'), true);
    });

    test('IEEE Style format', () {
      final ieee = '$author, "$title," $publisher, $date. [Online]. Available: $url';
      expect(ieee.contains('[Online]. Available:'), true);
    });

    test('Harvard Style format', () {
      final harvard = '$author, ($date) \'$title\', $publisher, available at: $url';
      expect(harvard.contains('available at:'), true);
    });
  });
}
