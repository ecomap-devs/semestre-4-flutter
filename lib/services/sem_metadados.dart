import 'dart:typed_data';
import 'dart:ui' as ui;

/// Tira os metadados de uma foto antes de ela sair do aparelho: a localizacao
/// GPS, o modelo da camera, a data, o nome do dono.
///
/// O `image_picker` do Android, ao reduzir a foto, copia o EXIF da original
/// para a reduzida, inclusive 32 campos de GPS (`ExifDataCopier`, conferido no
/// image_picker_android 0.8.13+22). Ate 02/11/2026 o avatar ia assim para o
/// bucket publico `avatars`, e a foto de identificacao assim para o Gemini. O
/// site ja redesenhava as duas no canvas (`src/lib/avatar.ts` e
/// `src/lib/identificacao.ts`), e a politica de privacidade promete o mesmo
/// para os dois.
///
/// JPEG (o que a camera e o picker devolvem) e limpo sem reencodar: saem os
/// segmentos de metadados e fica so a orientacao, num EXIF minimo, para a foto
/// nao aparecer deitada. Qualquer outro formato e redesenhado em PNG.
Future<({Uint8List bytes, String extensao})> semMetadados(
  Uint8List bytes, {
  required int ladoMaximo,
}) async {
  final jpeg = jpegSemMetadados(bytes);
  if (jpeg != null) return (bytes: jpeg, extensao: 'jpg');
  return (
    bytes: await redesenharEmPng(bytes, ladoMaximo: ladoMaximo),
    extensao: 'png',
  );
}

/// O JPEG sem APP1 (EXIF, onde mora o GPS, e XMP), APP13 (IPTC) e COM
/// (comentario). APP0, APP2 (perfil de cor), APP14, as tabelas e a imagem
/// ficam como estao. Se a original tinha orientacao diferente de 1, ela volta
/// num APP1 com essa marcacao e mais nada.
///
/// Devolve `null` se nao for JPEG ou se a estrutura nao for a esperada: quem
/// chama redesenha em PNG em vez de mandar a foto sem limpar.
Uint8List? jpegSemMetadados(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;

  final segmentos = <Uint8List>[];
  int? orientacao;
  var i = 2;
  while (i + 1 < bytes.length) {
    if (bytes[i] != 0xFF) return null;
    final marcador = bytes[i + 1];
    // FF repetido e so preenchimento antes do marcador.
    if (marcador == 0xFF) {
      i++;
      continue;
    }
    // SOS: dali em diante e a imagem comprimida, copiada inteira.
    if (marcador == 0xDA) {
      final saida = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
      final o = orientacao;
      if (o != null && o >= 2 && o <= 8) saida.add(_app1SoComOrientacao(o));
      for (final s in segmentos) {
        saida.add(s);
      }
      saida.add(Uint8List.sublistView(bytes, i));
      return saida.takeBytes();
    }
    // Marcadores sem tamanho nao aparecem antes do SOS num arquivo normal.
    if (marcador == 0x01 ||
        marcador == 0xD9 ||
        (marcador >= 0xD0 && marcador <= 0xD7)) {
      return null;
    }
    if (i + 3 >= bytes.length) return null;
    final tamanho = (bytes[i + 2] << 8) | bytes[i + 3];
    final fim = i + 2 + tamanho;
    if (tamanho < 2 || fim > bytes.length) return null;
    final segmento = Uint8List.sublistView(bytes, i, fim);
    if (marcador == 0xE1) {
      orientacao ??= orientacaoDoExif(Uint8List.sublistView(bytes, i + 4, fim));
    } else if (marcador != 0xED && marcador != 0xFE) {
      segmentos.add(segmento);
    }
    i = fim;
  }
  return null;
}

/// A orientacao (tag 0x0112) do conteudo de um APP1 EXIF, ou `null`.
int? orientacaoDoExif(Uint8List app1) {
  // "Exif\0\0" e depois o cabecalho TIFF.
  const assinatura = [0x45, 0x78, 0x69, 0x66, 0x00, 0x00];
  if (app1.length < 14) return null;
  for (var k = 0; k < assinatura.length; k++) {
    if (app1[k] != assinatura[k]) return null;
  }
  final tiff = ByteData.sublistView(app1, 6);
  final Endian ordem;
  if (tiff.getUint16(0) == 0x4949) {
    ordem = Endian.little;
  } else if (tiff.getUint16(0) == 0x4D4D) {
    ordem = Endian.big;
  } else {
    return null;
  }
  final ifd0 = tiff.getUint32(4, ordem);
  if (ifd0 + 2 > tiff.lengthInBytes) return null;
  final entradas = tiff.getUint16(ifd0, ordem);
  for (var e = 0; e < entradas; e++) {
    final p = ifd0 + 2 + e * 12;
    if (p + 12 > tiff.lengthInBytes) return null;
    if (tiff.getUint16(p, ordem) == 0x0112) return tiff.getUint16(p + 8, ordem);
  }
  return null;
}

/// Um APP1 com um EXIF de uma entrada so: a orientacao.
Uint8List _app1SoComOrientacao(int orientacao) {
  final d = ByteData(36);
  d
    ..setUint16(0, 0xFFE1) // APP1
    ..setUint16(2, 34) // tamanho, sem o marcador
    ..setUint32(4, 0x45786966) // "Exif"
    ..setUint16(8, 0) // "\0\0"
    ..setUint16(10, 0x4D4D) // TIFF big-endian
    ..setUint16(12, 42)
    ..setUint32(14, 8) // IFD0 logo depois do cabecalho
    ..setUint16(18, 1) // uma entrada
    ..setUint16(20, 0x0112) // Orientation
    ..setUint16(22, 3) // SHORT
    ..setUint32(24, 1) // um valor
    ..setUint16(28, orientacao)
    ..setUint16(30, 0)
    ..setUint32(32, 0); // sem proximo IFD
  return d.buffer.asUint8List();
}

/// Redesenha a imagem em PNG, com o lado maior em [ladoMaximo] no maximo. O
/// PNG gerado aqui nao leva metadado nenhum.
Future<Uint8List> redesenharEmPng(
  Uint8List bytes, {
  required int ladoMaximo,
}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final codec = await ui.instantiateImageCodecWithSize(
    buffer,
    getTargetSize: (largura, altura) {
      final maior = largura > altura ? largura : altura;
      if (maior <= ladoMaximo) {
        return ui.TargetImageSize(width: largura, height: altura);
      }
      final escala = ladoMaximo / maior;
      return ui.TargetImageSize(
        width: (largura * escala).round(),
        height: (altura * escala).round(),
      );
    },
  );
  final quadro = await codec.getNextFrame();
  final png = await quadro.image.toByteData(format: ui.ImageByteFormat.png);
  quadro.image.dispose();
  codec.dispose();
  if (png == null) throw StateError('Não foi possível redesenhar a imagem');
  return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
}
