import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/shared/widgets/price_tag.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('muestra solo el precio final sin descuento', (tester) async {
    await tester.pumpWidget(
      _wrap(const PriceTag(price: 1000, finalPrice: 1000)),
    );
    expect(find.textContaining('1.000'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('muestra precio tachado, descuento y precio final', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const PriceTag(price: 1000, finalPrice: 800, discountPercentage: 20),
      ),
    );
    expect(find.textContaining('800'), findsOneWidget);
    expect(find.textContaining('1.000'), findsOneWidget);
    expect(find.textContaining('-20%'), findsOneWidget);
  });
}
