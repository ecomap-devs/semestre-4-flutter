import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mede a interseção com todos os scrollables ancestrais, inclusive grades
/// dentro da página. Não usa timer nem mantém animações rodando fora da tela.
class AnimacaoNaTela extends StatefulWidget {
  const AnimacaoNaTela({
    super.key,
    required this.builder,
    this.child,
    this.duracao = const Duration(milliseconds: 1200),
    this.atraso = Duration.zero,
  });

  final ValueWidgetBuilder<double> builder;
  final Widget? child;
  final Duration duracao;
  final Duration atraso;

  @override
  State<AnimacaoNaTela> createState() => _AnimacaoNaTelaState();
}

class _AnimacaoNaTelaState extends State<AnimacaoNaTela>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final _animacao = AnimationController(vsync: this);
  final _rolagens = <ScrollableState>[];
  bool _agendada = false;
  bool _visivel = false;
  bool _reduzir = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final rolagem in _rolagens) {
      rolagem.position.removeListener(_agendar);
    }
    _rolagens.clear();
    context.visitAncestorElements((elemento) {
      if (elemento is StatefulElement && elemento.state is ScrollableState) {
        final rolagem = elemento.state as ScrollableState;
        _rolagens.add(rolagem);
        rolagem.position.addListener(_agendar);
      }
      return true;
    });
    _reduzir = MediaQuery.disableAnimationsOf(context);
    _animacao.duration = widget.duracao + widget.atraso;
    _animacao.reverseDuration = const Duration(milliseconds: 260);
    if (_reduzir) _animacao.value = 1;
    _agendar();
  }

  @override
  void didChangeMetrics() => _agendar();

  void _agendar() {
    if (_agendada) return;
    _agendada = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _agendada = false;
      if (mounted) _verificar();
    });
  }

  void _verificar() {
    if (_reduzir) return;
    final caixa = context.findRenderObject();
    if (caixa is! RenderBox || !caixa.hasSize || !caixa.attached) return;
    var janela = Offset.zero & MediaQuery.sizeOf(context);
    for (final rolagem in _rolagens) {
      final ancestral = rolagem.context.findRenderObject();
      if (ancestral is RenderBox && ancestral.hasSize && ancestral.attached) {
        janela = janela.intersect(
          ancestral.localToGlobal(Offset.zero) & ancestral.size,
        );
      }
    }
    final retangulo = caixa.localToGlobal(Offset.zero) & caixa.size;
    final intersecao = retangulo.intersect(janela);
    final visivel =
        !intersecao.isEmpty &&
        intersecao.height >= math.min(retangulo.height, janela.height) * .12;
    // Mantém o estado na borda para não piscar com movimentos mínimos.
    if (visivel && !_visivel) {
      _visivel = true;
      _animacao.forward();
    } else if (intersecao.isEmpty && _visivel) {
      _visivel = false;
      _animacao.reverse();
    }
  }

  @override
  void dispose() {
    for (final rolagem in _rolagens) {
      rolagem.position.removeListener(_agendar);
    }
    WidgetsBinding.instance.removeObserver(this);
    _animacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animacao,
    child: widget.child,
    builder: (context, child) {
      final inicio =
          widget.atraso.inMilliseconds /
          (widget.duracao + widget.atraso).inMilliseconds;
      final progresso = _reduzir
          ? 1.0
          : Interval(inicio, 1).transform(_animacao.value);
      return widget.builder(context, progresso, child);
    },
  );
}

class RevelarAoRolar extends StatelessWidget {
  const RevelarAoRolar({
    super.key,
    required this.child,
    this.atraso = Duration.zero,
  });
  final Widget child;
  final Duration atraso;

  @override
  Widget build(BuildContext context) => AnimacaoNaTela(
    duracao: const Duration(milliseconds: 750),
    atraso: atraso,
    child: child,
    builder: (_, progresso, conteudo) {
      final valor = Curves.easeOutCubic.transform(progresso);
      return Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 28 * (1 - valor)),
          child: conteudo,
        ),
      );
    },
  );
}

/// Entrada curta e finita, sem movimento quando o sistema o desabilita.
class EntradaSuave extends StatelessWidget {
  const EntradaSuave({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, valor, conteudo) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - valor)),
          child: conteudo,
        ),
      ),
    );
  }
}

/// O texto de [valor] com o numero dentro dele multiplicado por [progresso],
/// mantendo o resto: "+30%", "1,5 mi ha", "1.173".
///
/// No formato brasileiro: virgula decimal, ponto de milhar. O numero de casas
/// e o agrupamento saem do proprio texto, para "1,5" nao virar "1,50" no meio
/// da contagem nem "1.173" perder o ponto.
String textoContado(String valor, double progresso) {
  final achado = RegExp(r'\d[\d.,]*').firstMatch(valor);
  if (achado == null) return valor;
  final numero = achado[0]!;
  final decimais = numero.contains(',') ? numero.split(',')[1].length : 0;
  final alvo = double.parse(numero.replaceAll('.', '').replaceAll(',', '.'));
  final partes = (alvo * progresso).toStringAsFixed(decimais).split('.');
  final inteiro = numero.contains('.')
      ? partes[0].replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        )
      : partes[0];
  final contado = partes.length > 1 ? '$inteiro,${partes[1]}' : inteiro;
  return valor.replaceRange(achado.start, achado.end, contado);
}

/// Conta de zero ate o numero dentro do texto quando aparece na tela — o
/// `Contador` do site. O leitor de tela recebe o valor final.
class Contador extends StatelessWidget {
  const Contador({super.key, required this.valor, this.estilo});

  final String valor;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) => Semantics(
    label: valor,
    excludeSemantics: true,
    child: AnimacaoNaTela(
      duracao: const Duration(milliseconds: 1600),
      builder: (_, t, _) => Text(
        textoContado(valor, Curves.easeOutCubic.transform(t)),
        maxLines: 1,
        softWrap: false,
        style: estilo,
      ),
    ),
  );
}
