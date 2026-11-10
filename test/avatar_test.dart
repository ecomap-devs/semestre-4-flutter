import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/services/auth_service.dart';

void main() {
  // Desde 10/11/2026 a foto de perfil sobe pela funcao `enviar-avatar`, e a URL
  // publica e montada a partir do caminho que ela devolve. Resposta estranha
  // nao pode virar foto de perfil.
  group('caminhoDoAvatar', () {
    const uid = 'AbC123xyz';

    test('aceita o que a função grava, nas três extensões', () {
      for (final ext in ['jpg', 'png', 'webp']) {
        final caminho = '$uid/3f2a9c1e-7b4d-4e8a-9f10-2c3d4e5f6a7b.$ext';
        expect(caminhoDoAvatar({'caminho': caminho}, uid), caminho);
      }
    });

    test('recusa a pasta de outra pessoa', () {
      expect(
        caminhoDoAvatar({
          'caminho': 'OutraPessoa/3f2a9c1e-7b4d-4e8a-9f10-2c3d4e5f6a7b.png',
        }, uid),
        isNull,
      );
    });

    test('recusa formato que a função não grava', () {
      for (final caminho in [
        '$uid/../OutraPessoa/x.png',
        '$uid/foto.png',
        '$uid/3f2a9c1e-7b4d-4e8a-9f10-2c3d4e5f6a7b.svg',
        '$uid/3f2a9c1e-7b4d-4e8a-9f10-2c3d4e5f6a7b.png?x=1',
        'https://outro.site/$uid/3f2a9c1e-7b4d-4e8a-9f10-2c3d4e5f6a7b.png',
      ]) {
        expect(
          caminhoDoAvatar({'caminho': caminho}, uid),
          isNull,
          reason: caminho,
        );
      }
    });

    test('recusa resposta sem caminho', () {
      for (final resposta in [
        null,
        'texto',
        <String, Object>{},
        {'erro': 'limite-dia'},
        {'caminho': 42},
      ]) {
        expect(caminhoDoAvatar(resposta, uid), isNull, reason: '$resposta');
      }
    });
  });
}
