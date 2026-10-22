import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../animacao_na_tela.dart';

/// Linha de tendencia populacional — o `MiniGrafico` do site.
///
/// Serve ao cartao e a ficha da tela de Animais; a diferenca e so a altura.
/// Linha fina, area clara por baixo, um ponto no fim e so o primeiro e o
/// ultimo ano no eixo.
class LinhaChart extends StatelessWidget {
  const LinhaChart({
    super.key,
    required this.valores,
    required this.rotulos,
    this.cor = AppCores.mata,
    this.mostrarEixo = true,
    this.altura = 56,
  });

  final List<int> valores;
  final List<String> rotulos;
  final Color cor;
  final bool mostrarEixo;
  final double altura;

  @override
  Widget build(BuildContext context) {
    if (valores.length < 2) return SizedBox(height: altura);

    return Semantics(
      label:
          'População de ${rotulos.first} a ${rotulos.last}: '
          '${valores.join(', ')}',
      excludeSemantics: true,
      child: AnimacaoNaTela(
        duracao: const Duration(milliseconds: 600),
        builder: (_, t, _) => SizedBox(
          height: altura,
          child: CustomPaint(
            painter: _LinhaPainter(
              valores: valores,
              rotulos: rotulos,
              cor: cor,
              opacidade: Curves.easeOut.transform(t),
              mostrarEixo: mostrarEixo,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _LinhaPainter extends CustomPainter {
  _LinhaPainter({
    required this.valores,
    required this.rotulos,
    required this.cor,
    required this.opacidade,
    required this.mostrarEixo,
  });

  final List<int> valores;
  final List<String> rotulos;
  final Color cor;
  final double opacidade;
  final bool mostrarEixo;

  @override
  void paint(Canvas canvas, Size size) {
    const margemX = 4.0;
    const margemTopo = 6.0;
    final margemBaixo = mostrarEixo ? 18.0 : 4.0;
    final largura = size.width - margemX * 2;
    final base = size.height - margemBaixo;
    final alturaGrafico = base - margemTopo;

    // Como no site, o eixo comeca em zero (ou abaixo, se houver negativo), e
    // a faixa nunca e zero: serie constante desenharia divisao por zero.
    final maximo = valores.reduce((a, b) => a > b ? a : b).toDouble();
    final menor = valores.reduce((a, b) => a < b ? a : b).toDouble();
    final minimo = menor < 0 ? menor : 0.0;
    final faixa = maximo - minimo == 0 ? 1.0 : maximo - minimo;

    Offset pontoEm(int i) => Offset(
      margemX + (i / (valores.length - 1)) * largura,
      margemTopo + (1 - (valores[i] - minimo) / faixa) * alturaGrafico,
    );

    canvas.drawLine(
      Offset(margemX, base),
      Offset(margemX + largura, base),
      Paint()
        ..color = AppCores.linha
        ..strokeWidth = 1,
    );

    final linha = Path()..moveTo(pontoEm(0).dx, pontoEm(0).dy);
    for (var i = 1; i < valores.length; i++) {
      linha.lineTo(pontoEm(i).dx, pontoEm(i).dy);
    }
    final ultimo = pontoEm(valores.length - 1);
    final area = Path.from(linha)
      ..lineTo(ultimo.dx, base)
      ..lineTo(pontoEm(0).dx, base)
      ..close();

    canvas.drawPath(
      area,
      Paint()..color = cor.withValues(alpha: 0.1 * opacidade),
    );
    canvas.drawPath(
      linha,
      Paint()
        ..color = cor.withValues(alpha: opacidade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      ultimo,
      3,
      Paint()..color = cor.withValues(alpha: opacidade),
    );

    if (!mostrarEixo) return;
    for (final (i, noFim) in [(0, false), (rotulos.length - 1, true)]) {
      final tp = TextPainter(
        text: TextSpan(
          text: rotulos[i],
          style: const TextStyle(
            fontFamily: AppFontes.texto,
            fontSize: 11,
            color: AppCores.tinta3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = noFim ? margemX + largura - tp.width : margemX;
      tp.paint(canvas, Offset(x, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(_LinhaPainter old) =>
      old.opacidade != opacidade || old.valores != valores || old.cor != cor;
}
