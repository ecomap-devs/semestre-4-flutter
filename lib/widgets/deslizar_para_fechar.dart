import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Deslizar para fechar (11/11/2026): o cartão acompanha o dedo, para os lados
/// ou para baixo, e fecha se passar do limite ou for jogado com força; senão,
/// volta ao lugar.
///
/// O gesto é atalho, não o único caminho: todo cartão que usa isto tem também
/// um botão de fechar, para leitor de tela e para quem não arrasta.
///
/// Para baixo só vale onde nada rola na vertical. Um scroll por dentro, com
/// conteúdo maior que a caixa, fica com o arrasto vertical, e o cartão ainda
/// fecha deslizando para o lado.
class DeslizarParaFechar extends StatefulWidget {
  const DeslizarParaFechar({
    super.key,
    required this.aoFechar,
    required this.child,
    this.paraOsLados = true,
    this.paraBaixo = true,
  });

  final VoidCallback aoFechar;
  final Widget child;
  final bool paraOsLados;
  final bool paraBaixo;

  /// Fração da largura (para os lados) ou da altura (para baixo) que fecha
  /// ao soltar.
  static const limite = .35;

  /// Velocidade, em pixels por segundo, de um gesto rápido: fecha mesmo curto.
  static const velocidadeQueFecha = 700.0;

  @override
  State<DeslizarParaFechar> createState() => _DeslizarParaFecharState();
}

class _DeslizarParaFecharState extends State<DeslizarParaFechar>
    with SingleTickerProviderStateMixin {
  late final _animacao = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_acompanharAnimacao);

  Offset _deslocamento = Offset.zero;
  Animation<Offset>? _trajeto;

  @override
  void dispose() {
    _animacao.dispose();
    super.dispose();
  }

  void _acompanharAnimacao() {
    final trajeto = _trajeto;
    if (trajeto != null) setState(() => _deslocamento = trajeto.value);
  }

  void _mover(Offset delta) {
    _animacao.stop();
    setState(() {
      _deslocamento = Offset(
        widget.paraOsLados ? _deslocamento.dx + delta.dx : 0,
        widget.paraBaixo ? math.max(0, _deslocamento.dy + delta.dy) : 0,
      );
    });
  }

  void _soltar(Velocity velocidade) {
    final tamanho = context.size ?? Size.zero;
    final v = velocidade.pixelsPerSecond;
    final dx = _deslocamento.dx;
    final dy = _deslocamento.dy;

    final fechaDeLado =
        widget.paraOsLados &&
        dx != 0 &&
        (dx.abs() > tamanho.width * DeslizarParaFechar.limite ||
            (v.dx.abs() > DeslizarParaFechar.velocidadeQueFecha &&
                v.dx.sign == dx.sign));
    final fechaPraBaixo =
        widget.paraBaixo &&
        dy > 0 &&
        (dy > tamanho.height * DeslizarParaFechar.limite ||
            v.dy > DeslizarParaFechar.velocidadeQueFecha);

    if (fechaDeLado) {
      _animarAte(Offset(dx.sign * (tamanho.width + 24), 0), fechar: true);
    } else if (fechaPraBaixo) {
      _animarAte(Offset(0, tamanho.height + 24), fechar: true);
    } else {
      _animarAte(Offset.zero);
    }
  }

  void _animarAte(Offset destino, {bool fechar = false}) {
    void depois() {
      if (!mounted || !fechar) return;
      widget.aoFechar();
      // Quem chamou costuma tirar o cartão da tela; se não tirar, ele volta.
      if (mounted) setState(() => _deslocamento = Offset.zero);
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _deslocamento = fechar ? destino : Offset.zero);
      depois();
      return;
    }
    _trajeto = Tween(
      begin: _deslocamento,
      end: destino,
    ).animate(CurvedAnimation(parent: _animacao, curve: Curves.easeOut));
    _animacao.forward(from: 0).whenCompleteOrCancel(depois);
  }

  @override
  Widget build(BuildContext context) {
    // Esmaece enquanto se afasta: diz que soltar ali fecha.
    final afastamento = (_deslocamento.distance / 300).clamp(0.0, 1.0);
    return GestureDetector(
      onHorizontalDragUpdate: widget.paraOsLados
          ? (d) => _mover(d.delta)
          : null,
      onHorizontalDragEnd: widget.paraOsLados
          ? (d) => _soltar(d.velocity)
          : null,
      onVerticalDragUpdate: widget.paraBaixo ? (d) => _mover(d.delta) : null,
      onVerticalDragEnd: widget.paraBaixo ? (d) => _soltar(d.velocity) : null,
      child: Transform.translate(
        offset: _deslocamento,
        child: Opacity(opacity: 1 - afastamento * .6, child: widget.child),
      ),
    );
  }
}
