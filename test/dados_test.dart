import 'package:flutter_test/flutter_test.dart';

import 'package:ecomapbrasil/data/biomas_data.dart';
import 'package:ecomapbrasil/data/home_data.dart';
import 'package:ecomapbrasil/data/linha_do_tempo.dart';
import 'package:ecomapbrasil/data/prodes_data.dart';

// Os numeros esperados aqui sao os que o site mostra com o mesmo prodes.ts
// (atualizado em 16/10/2026). Se a copia do site mudar, eles mudam junto.
void main() {
  group('PRODES', () {
    test('os seis biomas têm dado', () {
      for (final b in biomas) {
        expect(prodes[b.nome], isNotNull, reason: b.nome);
      }
    });

    test('o acumulado termina no total do bioma e nunca diminui', () {
      for (final MapEntry(key: nome, value: b) in prodes.entries) {
        expect(b.acumulado.last.km2, b.acumuladoKm2, reason: nome);
        for (var i = 1; i < b.acumulado.length; i++) {
          expect(b.acumulado[i].fim, greaterThan(b.acumulado[i - 1].fim));
          expect(
            b.acumulado[i].km2,
            greaterThanOrEqualTo(b.acumulado[i - 1].km2),
            reason: '$nome em ${b.acumulado[i].fim}',
          );
        }
        expect(b.acumuladoKm2, lessThan(b.areaKm2), reason: nome);
      }
    });

    test('cada período vai de agosto a julho: um ano só', () {
      for (final b in prodes.values) {
        for (final p in b.anos) {
          expect(p.fim, p.inicio + 1);
        }
      }
    });

    test('período preliminar fica fora do que é consolidado', () {
      final cerrado = prodes['Cerrado']!;
      expect(cerrado.anos.last.preliminar, isTrue);
      expect(cerrado.noPeriodo(cerrado.anos.last.fim), isNull);
      expect(cerrado.noPeriodo(2025), 7235.3);
    });
  });

  test('percentual desmatado de cada bioma, como no site', () {
    final pct = {for (final b in biomas) b.nome: b.percentualDesmatado};
    // A Amazonia aparecia 78% ate 28/10/2026.
    expect(pct, {
      'Amazônia': 20,
      'Cerrado': 53,
      'Caatinga': 44,
      'Mata Atlântica': 72,
      'Pantanal': 21,
      'Pampa': 60,
    });
  });

  group('Home', () {
    test('os quatro números saem do PRODES e da lista do MMA', () {
      expect(numeros.map((n) => n.valor), [
        '16.089',
        '−20%',
        '1.259',
        '6 biomas',
      ]);
      expect(numeros.first.rotulo, contains('ago/2024 a jul/2025'));
      expect(numeros[1].rotulo, contains('ago/2023 a jul/2024'));
    });

    test('área desmatada por bioma vem da maior para a menor', () {
      expect(areaPorBioma.first.nome, 'Cerrado');
      expect(areaPorBioma.first.valor, 1041);
      for (var i = 1; i < areaPorBioma.length; i++) {
        expect(
          areaPorBioma[i].valor,
          lessThanOrEqualTo(areaPorBioma[i - 1].valor),
        );
      }
    });

    test('último período soma os seis biomas no mesmo ano', () {
      expect(ultimoPeriodo.rotulo, 'ago/2024 a jul/2025');
      expect(ultimoPeriodo.biomas, hasLength(6));
      expect(ultimoPeriodo.biomas.first.nome, 'Cerrado');
      expect(ultimoPeriodo.biomas.last.nome, 'Pantanal');
    });

    test('destaques são as seis primeiras ameaçadas do catálogo', () {
      expect(animaisDestaque, hasLength(6));
      expect(animaisDestaque.first.nome, 'Onça-pintada');
      expect(animaisDestaque.every((a) => a.ehAmeacada), isTrue);
    });

    test('data da atualização por extenso', () {
      expect(dadosAtualizadosEm, '16 de outubro de 2026');
    });
  });

  group('Linha do tempo', () {
    test('marcos calculados, do mais antigo ao mais recente', () {
      expect(
        [for (final m in linhaDoTempo) '${m.ano} ${m.titulo}'],
        [
          '1995 Pior ano da série',
          '2004 Começa o PPCDAm',
          '2006 Moratória da Soja',
          '2008 Pampa passa da metade',
          // Mesmo ano: a lei antes do numero.
          '2012 Novo Código Florestal',
          '2012 Menor taxa da série',
          '2021 O desmatamento volta a subir',
          '2021 Cerrado passa da metade',
          '2025 Último dado consolidado',
          '2026 Estimativa do INPE',
        ],
      );
    });

    test('textos com os números do INPE', () {
      String texto(String titulo) =>
          linhaDoTempo.firstWhere((m) => m.titulo == titulo).texto;
      expect(texto('Pior ano da série'), contains('29.059 km²'));
      expect(texto('Começa o PPCDAm'), contains('27.772 km²'));
      expect(texto('Menor taxa da série'), contains('4.571 km²'));
      expect(
        texto('O desmatamento volta a subir'),
        'A Amazônia Legal perde 13.038 km², o maior valor desde 2006.',
      );
      expect(
        texto('Último dado consolidado'),
        'A Amazônia Legal perde 5.731 km², 12% a menos que no ano anterior.',
      );
      expect(texto('Cerrado passa da metade'), contains('do Cerrado'));
    });

    test('o mapa mostra os cinco mais recentes, do mais novo', () {
      expect(
        [for (final m in linhaDoTempoMapa) m.ano],
        [2026, 2025, 2021, 2021, 2012],
      );
    });

    test('série curta demais é erro, não linha do tempo vazia', () {
      expect(
        () => calcularLinhaDoTempo(const [
          TaxaAnual(2020, 1),
          TaxaAnual(2021, 2),
        ]),
        throwsStateError,
      );
    });

    test('sem estimativa preliminar, não inventa uma', () {
      final marcos = calcularLinhaDoTempo([
        for (final t in taxasAmazoniaLegal)
          if (!t.preliminar) t,
      ]);
      expect(
        marcos.map((m) => m.titulo),
        isNot(contains('Estimativa do INPE')),
      );
    });
  });

  test('formatarMilhar', () {
    expect(formatarMilhar(0), '0');
    expect(formatarMilhar(999), '999');
    expect(formatarMilhar(16088.7), '16.089');
    expect(formatarMilhar(1041097.3), '1.041.097');
  });
}
