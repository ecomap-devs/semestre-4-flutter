import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../data/biomas_data.dart';
import '../../models/bioma.dart';
import '../../theme/app_theme.dart';
import '../animacao_na_tela.dart';

/// Os seis biomas desenhados com o mesmo contorno do IBGE do mapa
/// interativo — o `MapaBiomas` da Home do site.
///
/// Nao carrega o `flutter_map` nem o GeoJSON dos alertas. Tocar num bioma (ou
/// passar o mouse, ou escolher na legenda) destaca ele e mostra quanto ja foi
/// desmatado.
class MapaBiomas extends StatefulWidget {
  const MapaBiomas({super.key});

  @override
  State<MapaBiomas> createState() => _MapaBiomasState();
}

/// Projecao equirretangular com a longitude encolhida pelo cosseno da
/// latitude media do Brasil (~15° S), para o pais nao sair achatado.
final _escalaX = math.cos(15 * math.pi / 180);

Offset _projetar(LatLng p) => Offset(p.longitude * _escalaX, -p.latitude);

/// Limites da projecao, calculados uma vez: sao milhares de pontos.
final Rect _limites = () {
  var esq = double.infinity, dir = -double.infinity;
  var topo = double.infinity, base = -double.infinity;
  for (final b in biomas) {
    for (final anel in b.poligonos) {
      for (final p in anel) {
        final o = _projetar(p);
        esq = math.min(esq, o.dx);
        dir = math.max(dir, o.dx);
        topo = math.min(topo, o.dy);
        base = math.max(base, o.dy);
      }
    }
  }
  return Rect.fromLTRB(esq, topo, dir, base);
}();

/// Um caminho por bioma, em coordenadas da projecao. `evenOdd` deixa os
/// buracos (massas d'agua) vazados.
final List<Path> _caminhos = [
  for (final b in biomas)
    () {
      final caminho = Path()..fillType = PathFillType.evenOdd;
      for (final contorno in b.poligonos) {
        for (final anel in [contorno, ...b.buracosDe(contorno)]) {
          caminho.addPolygon(anel.map(_projetar).toList(), true);
        }
      }
      return caminho;
    }(),
];

class _MapaBiomasState extends State<MapaBiomas> {
  Bioma? _ativo;

  void _ativar(Bioma? b) {
    if (b != _ativo) setState(() => _ativo = b);
  }

  /// O bioma sob o ponto tocado, desfazendo a projecao.
  Bioma? _biomaEm(Offset local, Size tamanho) {
    final escala = tamanho.width / _limites.width;
    final x = local.dx / escala + _limites.left;
    final y = local.dy / escala + _limites.top;
    return Bioma.maisEspecificoEm(biomas, LatLng(-y, x / _escalaX));
  }

  @override
  Widget build(BuildContext context) {
    final ativo = _ativo;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Mapa dos seis biomas brasileiros',
            image: true,
            child: AspectRatio(
              aspectRatio: _limites.width / _limites.height,
              child: LayoutBuilder(
                builder: (context, c) => MouseRegion(
                  onHover: (e) => _ativar(_biomaEm(e.localPosition, c.biggest)),
                  onExit: (_) => _ativar(null),
                  child: GestureDetector(
                    onTapDown: (e) =>
                        _ativar(_biomaEm(e.localPosition, c.biggest)),
                    child: AnimacaoNaTela(
                      duracao: const Duration(milliseconds: 1100),
                      builder: (_, t, _) => CustomPaint(
                        size: c.biggest,
                        painter: _BiomasPainter(entrada: t, ativo: ativo),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Altura minima: o texto trocar nao pode empurrar a legenda.
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Semantics(
              liveRegion: true,
              child: ativo == null
                  ? const Text(
                      'Toque num bioma para ver quanto dele já foi desmatado.',
                      style: TextStyle(fontSize: 16, color: AppCores.tinta3),
                    )
                  : Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 12,
                      children: [
                        Text(
                          '${ativo.percentualDesmatado}%',
                          style: estiloTitulo(44, cor: AppCores.terra),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '${ativo.preposicao} '),
                                TextSpan(
                                  text: ativo.nome,
                                  style: const TextStyle(
                                    color: AppCores.tinta,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' já foi desmatado'),
                              ],
                            ),
                            style: const TextStyle(
                              fontSize: 17,
                              color: AppCores.tinta2,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final b in biomas)
                _ItemLegenda(
                  bioma: b,
                  ativo: b == ativo,
                  aoEscolher: () => _ativar(b),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemLegenda extends StatelessWidget {
  const _ItemLegenda({
    required this.bioma,
    required this.ativo,
    required this.aoEscolher,
  });

  final Bioma bioma;
  final bool ativo;
  final VoidCallback aoEscolher;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: ativo,
    child: InkWell(
      onTap: aoEscolher,
      onHover: (dentro) {
        if (dentro) aoEscolher();
      },
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: ativo ? AppCores.branco : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: ativo ? AppCores.linha : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: bioma.cor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              bioma.nome,
              style: TextStyle(
                fontSize: 14,
                color: ativo ? AppCores.tinta : AppCores.tinta2,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BiomasPainter extends CustomPainter {
  _BiomasPainter({required this.entrada, required this.ativo});

  /// Progresso da entrada: os biomas aparecem um depois do outro.
  final double entrada;
  final Bioma? ativo;

  @override
  void paint(Canvas canvas, Size size) {
    final escala = size.width / _limites.width;
    canvas
      ..save()
      ..scale(escala)
      ..translate(-_limites.left, -_limites.top);

    final contorno = Paint()
      ..color = AppCores.papel
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / escala
      ..strokeJoin = StrokeJoin.round;

    for (final (i, b) in biomas.indexed) {
      final aparecer = Interval(
        i * .1,
        .5 + i * .1,
        curve: Curves.easeOut,
      ).transform(entrada);
      final opacidade = aparecer * (ativo != null && ativo != b ? 0.3 : 1);
      if (opacidade == 0) continue;
      canvas
        ..drawPath(
          _caminhos[i],
          Paint()..color = b.cor.withValues(alpha: opacidade),
        )
        ..drawPath(_caminhos[i], contorno);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BiomasPainter old) =>
      old.entrada != entrada || old.ativo != ativo;
}
