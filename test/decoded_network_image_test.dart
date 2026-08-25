import 'package:ability_link/widgets/decoded_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('decodes at the on-screen pixel size', (tester) async {
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(640, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(devicePixelRatio: 2, size: Size(320, 400)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DecodedNetworkImage(
            'https://example.com/photo.jpg',
            width: 72,
            height: 72,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).width, 144);
  });
}
