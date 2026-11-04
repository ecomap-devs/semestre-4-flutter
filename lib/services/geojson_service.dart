import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/bioma.dart';

/// O que o arquivo dos alertas traz: os que dao para desenhar, e quantos vieram
/// sem geometria.
typedef AlertasDoArquivo = ({
  List<AlertaDesmatamento> alertas,
  int semGeometria,
});

/// Carrega os alertas de desmatamento do DETER/INPE dos ultimos 12 meses, uma
/// copia do arquivo do site.
///
/// O arquivo tem ~15 MB. Parsear isso na thread da UI trava a tela por
/// segundos — no navegador e no celular. Por isso o decode e o mapeamento
/// rodam num isolate (`compute`), que na web vira uma chamada assincrona
/// comum, mas mantem o codigo igual nos dois alvos.
class GeoJsonService {
  static const _caminho = 'assets/data/alertas-desmatamento.json';

  AlertasDoArquivo? _cache;

  /// Le, parseia e devolve os alertas. Resultado fica em cache: trocar de aba
  /// e voltar nao paga o custo de novo.
  Future<AlertasDoArquivo> carregar() async {
    final emCache = _cache;
    if (emCache != null) return emCache;

    final bruto = await rootBundle.loadString(_caminho);
    final arquivo = await compute(parsear, bruto);
    _cache = arquivo;
    return arquivo;
  }

  /// Roda fora da thread da UI.
  @visibleForTesting
  static AlertasDoArquivo parsear(String bruto) {
    final mapa = jsonDecode(bruto);
    if (mapa is! Map || mapa['features'] is! List) {
      return (alertas: const <AlertaDesmatamento>[], semGeometria: 0);
    }

    final out = <AlertaDesmatamento>[];
    var semGeometria = 0;
    for (final f in (mapa['features'] as List)) {
      if (f is! Map) continue;
      // O INPE publica alguns alertas sem poligono de verdade, e o site os grava
      // com `geometry: null`. Nao ha o que desenhar, mas contam na legenda, como
      // no site. Geometria malformada e outra coisa: e so pulada.
      if (f.containsKey('geometry') && f['geometry'] == null) {
        semGeometria++;
        continue;
      }
      // Uma feature que estoure de um jeito que o parser nao previu perde so
      // ela, nao o mapa inteiro.
      try {
        final alerta = AlertaDesmatamento.doGeoJson(
          Map<String, dynamic>.from(f),
        );
        if (alerta != null) out.add(alerta);
      } catch (_) {
        continue;
      }
    }
    return (alertas: out, semGeometria: semGeometria);
  }
}
