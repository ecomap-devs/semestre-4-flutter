import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/services/sem_metadados.dart';

/// JPEG de 40x20 (metade vermelha, metade azul) com EXIF de orientacao 6 e GPS
/// falso (S 23°33', W 46°38'), gerado pelo System.Drawing do Windows.
Uint8List _fotoComGps() =>
    File('test/fixtures/gps_orientacao6.jpg').readAsBytesSync();

bool _contem(Uint8List bytes, List<int> trecho) {
  for (var i = 0; i + trecho.length <= bytes.length; i++) {
    var igual = true;
    for (var j = 0; j < trecho.length && igual; j++) {
      igual = bytes[i + j] == trecho[j];
    }
    if (igual) return true;
  }
  return false;
}

/// A latitude 23/1, 33/1 como o EXIF grava (RATIONAL), nas duas ordens de byte.
final _latitude = [
  [23, 0, 0, 0, 1, 0, 0, 0, 33, 0, 0, 0, 1, 0, 0, 0],
  [0, 0, 0, 23, 0, 0, 0, 1, 0, 0, 0, 33, 0, 0, 0, 1],
];

/// Os APP1 do JPEG, ate a imagem comprimida.
List<Uint8List> _app1s(Uint8List jpeg) {
  final achados = <Uint8List>[];
  var i = 2;
  while (i + 4 <= jpeg.length && jpeg[i + 1] != 0xDA) {
    final tamanho = (jpeg[i + 2] << 8) | jpeg[i + 3];
    if (jpeg[i + 1] == 0xE1) {
      achados.add(Uint8List.sublistView(jpeg, i + 4, i + 2 + tamanho));
    }
    i += 2 + tamanho;
  }
  return achados;
}

Future<(int, int)> _medidas(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final quadro = await codec.getNextFrame();
  final medidas = (quadro.image.width, quadro.image.height);
  quadro.image.dispose();
  codec.dispose();
  return medidas;
}

void main() {
  group('jpegSemMetadados', () {
    test('o arquivo de teste tem mesmo GPS e orientação 6', () {
      final original = _fotoComGps();
      expect(_latitude.any((l) => _contem(original, l)), isTrue);
      expect(_app1s(original).map(orientacaoDoExif), contains(6));
    });

    test('tira o GPS e deixa só a orientação', () {
      final limpa = jpegSemMetadados(_fotoComGps())!;
      expect(_latitude.any((l) => _contem(limpa, l)), isFalse);
      final app1 = _app1s(limpa);
      // Um APP1 so, com 32 bytes de conteudo: "Exif\0\0", o cabecalho TIFF,
      // uma entrada e o fim do IFD.
      expect(app1, hasLength(1));
      expect(app1.single.length, 32);
      expect(orientacaoDoExif(app1.single), 6);
    });

    testWidgets('a foto limpa abre com as mesmas medidas da original', (
      tester,
    ) async {
      final original = _fotoComGps();
      final limpa = jpegSemMetadados(original)!;
      await tester.runAsync(() async {
        // Os pixels sao 40x20 e a orientacao 6 manda girar: o Flutter aplica a
        // orientacao, e a foto deitada so continua de pe se a limpa a mantiver.
        expect(await _medidas(original), (20, 40));
        expect(await _medidas(limpa), (20, 40));
      });
    });

    test('sem orientação na original, não inventa uma', () {
      final limpa = jpegSemMetadados(_fotoComGps())!;
      final semExif = jpegSemMetadados(
        Uint8List.fromList([
          ...limpa.sublist(0, 2),
          ...limpa.sublist(2 + 36), // pula o APP1 de orientacao
        ]),
      )!;
      expect(_app1s(semExif), isEmpty);
    });

    test('o que não é JPEG, ou JPEG cortado, devolve null', () {
      expect(
        jpegSemMetadados(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])),
        isNull,
      );
      expect(jpegSemMetadados(Uint8List(0)), isNull);
      final original = _fotoComGps();
      expect(jpegSemMetadados(original.sublist(0, 30)), isNull);
    });
  });

  group('semMetadados', () {
    testWidgets('JPEG continua JPEG', (tester) async {
      await tester.runAsync(() async {
        final r = await semMetadados(_fotoComGps(), ladoMaximo: 512);
        expect(r.extensao, 'jpg');
        expect(r.bytes.sublist(0, 2), [0xFF, 0xD8]);
      });
    });

    testWidgets('outro formato é redesenhado em PNG, no tamanho máximo', (
      tester,
    ) async {
      await tester.runAsync(() async {
        // Um PNG de 1200x600 desenhado aqui.
        final gravador = ui.PictureRecorder();
        ui.Canvas(gravador).drawRect(
          const ui.Rect.fromLTWH(0, 0, 1200, 600),
          ui.Paint()..color = const ui.Color(0xFF2F5233),
        );
        final imagem = await gravador.endRecording().toImage(1200, 600);
        final png = (await imagem.toByteData(format: ui.ImageByteFormat.png))!;
        imagem.dispose();

        final r = await semMetadados(png.buffer.asUint8List(), ladoMaximo: 512);
        expect(r.extensao, 'png');
        expect(r.bytes.sublist(1, 4), 'PNG'.codeUnits);
        expect(await _medidas(r.bytes), (512, 256));
      });
    });
  });
}
