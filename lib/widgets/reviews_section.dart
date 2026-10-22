import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;

import '../models/avaliacao.dart';
import '../services/reviews_service.dart';
import '../theme/app_theme.dart';
import 'aviso_de_formulario.dart';
import 'estrelas.dart';

/// Secao de avaliacoes da Home — o `Avaliacoes` do site, com as notas como
/// citacoes. Le e grava a mesma colecao que o site.
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
    this.service,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;
  final ReviewsService? service;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  late final ReviewsService _service = widget.service ?? ReviewsService();
  final _comentario = TextEditingController();

  static const _porPagina = 6;

  int _nota = 0;
  bool _enviando = false;
  String _erro = '';
  bool _sucesso = false;

  // A assinatura vive no estado, e não no `build`: antes o stream era criado
  // de novo a cada reconstrução, e o app reassinava a coleção à toa.
  int _limite = _porPagina;
  StreamSubscription<List<Avaliacao>>? _assinatura;
  List<Avaliacao> _lista = const [];
  bool _carregando = true;
  bool _falhou = false;
  ResumoAvaliacoes? _resumo;
  int _pedidoResumo = 0;
  Timer? _relogioResumo;

  @override
  void initState() {
    super.initState();
    _assinar();
    // Agregação não é tempo real: uma edição fora da página visível não
    // dispara a lista. O resumo é refeito também de tempos em tempos.
    _relogioResumo = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _atualizarResumo(),
    );
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    _relogioResumo?.cancel();
    _comentario.dispose();
    super.dispose();
  }

  void _assinar() {
    _assinatura?.cancel();
    _assinatura = _service
        .observar(limite: _limite)
        .listen(
          (lista) {
            if (!mounted) return;
            setState(() {
              _lista = lista;
              _carregando = false;
              _falhou = false;
            });
            _atualizarResumo();
          },
          onError: (Object _) {
            if (mounted) {
              setState(() {
                _carregando = false;
                _falhou = true;
              });
            }
          },
        );
  }

  Future<void> _atualizarResumo() async {
    // Só a resposta do pedido mais recente vale: uma lenta que chegue depois
    // não sobrescreve a nova.
    final pedido = ++_pedidoResumo;
    try {
      final r = await _service.resumo();
      if (mounted && pedido == _pedidoResumo) setState(() => _resumo = r);
    } catch (_) {
      // Mantém o último resumo; a lista continua funcionando.
    }
  }

  void _mudarLimite(int limite) {
    setState(() => _limite = limite);
    _assinar();
  }

  Future<void> _enviar() async {
    setState(() => _erro = '');

    final u = widget.usuario;
    if (u == null) {
      widget.aoPedirLogin();
      return;
    }
    if (_nota == 0) {
      setState(() => _erro = 'Selecione uma nota de 1 a 5 estrelas.');
      return;
    }
    if (_comentario.text.trim().isEmpty) {
      setState(() => _erro = 'Escreva um comentário.');
      return;
    }

    if (_comentario.text.trim().length > maxComentario) {
      setState(
        () => _erro = 'O comentário pode ter até $maxComentario caracteres.',
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await _service.publicar(
        usuario: u,
        nota: _nota,
        comentario: _comentario.text,
      );
      if (!mounted) return;
      unawaited(_atualizarResumo());
      _comentario.clear();
      setState(() {
        _nota = 0;
        _sucesso = true;
      });
      // A versao React nao tratava falha aqui: o `addDoc` sem try/catch
      // deixava o botao travado em "Enviando..." para sempre se a regra do
      // Firestore recusasse a escrita.
      await Future<void>.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _sucesso = false);
    } on FirebaseException catch (e) {
      if (mounted) {
        setState(
          () => _erro = e.code == 'permission-denied'
              ? 'O servidor recusou a avaliação. Confira se o comentário tem '
                    'até $maxComentario caracteres e tente de novo.'
              : 'Não foi possível enviar. Verifique sua conexão e tente de novo.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível enviar. Tente de novo.');
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logado = widget.usuario != null;
    final mobile = Breakpoints.ehMobile(context);
    final media = _resumo?.media;
    final total = _resumo?.total ?? _lista.length;
    final restantes = total - _lista.length;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 20 : 24,
        vertical: mobile ? 64 : 112,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'O que dizem do site',
                          style: estiloTitulo(mobile ? 36 : 52, altura: 1.05),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Opiniões de quem passou por aqui.',
                        style: TextStyle(fontSize: 18, color: AppCores.tinta2),
                      ),
                    ],
                  ),
                  if (media != null && total > 0)
                    _Media(media: media, quantidade: total),
                ],
              ),
              const SizedBox(height: 40),

              if (_carregando)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Carregando avaliações...',
                    style: TextStyle(fontSize: 16, color: AppCores.tinta3),
                  ),
                ),

              if (_falhou)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Não foi possível carregar as avaliações agora.',
                    style: TextStyle(fontSize: 16, color: AppCores.tinta3),
                  ),
                ),

              if (_lista.isNotEmpty)
                LayoutBuilder(
                  builder: (context, c) {
                    final colunas = (c.maxWidth / 320).floor().clamp(1, 3);
                    return Wrap(
                      spacing: 40,
                      runSpacing: 32,
                      children: [
                        for (final a in _lista)
                          SizedBox(
                            width: (c.maxWidth - 40 * (colunas - 1)) / colunas,
                            child: _Citacao(avaliacao: a),
                          ),
                      ],
                    );
                  },
                ),

              if (restantes > 0 || _limite > _porPagina) ...[
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    // De 12 em 12, até acabar: antes "Mostrar mais" baixava
                    // a coleção inteira de uma vez.
                    onPressed: () =>
                        _mudarLimite(restantes > 0 ? _limite + 12 : _porPagina),
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                        fontFamily: AppFontes.texto,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    child: Text(
                      restantes > 0
                          ? 'Mostrar mais ($restantes restantes)'
                          : 'Mostrar menos',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 56),
              Center(
                child: _Formulario(
                  logado: logado,
                  nota: _nota,
                  comentario: _comentario,
                  enviando: _enviando,
                  erro: _erro,
                  sucesso: _sucesso,
                  aoMudarNota: (n) => setState(() => _nota = n),
                  aoEnviar: _enviar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.media, required this.quantidade});

  final double media;
  final int quantidade;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        media.toStringAsFixed(1).replaceAll('.', ','),
        style: estiloTitulo(40, altura: 1),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Estrelas(valor: media.round(), somenteLeitura: true),
          const SizedBox(height: 2),
          Text(
            '$quantidade ${quantidade == 1 ? 'avaliação' : 'avaliações'}',
            style: const TextStyle(fontSize: 14, color: AppCores.tinta3),
          ),
        ],
      ),
    ],
  );
}

/// Uma avaliacao como citacao: nota, comentario e quem escreveu. Antes era um
/// cartao com sombra, avatar grande e o texto cortado em quatro linhas.
class _Citacao extends StatelessWidget {
  const _Citacao({required this.avaliacao});

  final Avaliacao avaliacao;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(top: 20),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppCores.linha)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Estrelas(valor: avaliacao.nota, somenteLeitura: true, tamanho: 15),
        const SizedBox(height: 10),
        Text(
          avaliacao.comentario,
          style: const TextStyle(
            fontSize: 17,
            height: 1.55,
            color: AppCores.tinta,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _Avatar(nome: avaliacao.nome, url: avaliacao.fotoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: avaliacao.nome),
                    TextSpan(
                      text: ' · ${avaliacao.tempoRelativo}',
                      style: const TextStyle(color: AppCores.tinta3),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, color: AppCores.tinta2),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.nome, required this.url});

  final String nome;
  final String url;

  @override
  Widget build(BuildContext context) {
    final inicial = Center(
      child: Text(
        nome.isEmpty ? '?' : nome.characters.first.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppCores.mata,
        ),
      ),
    );

    return Container(
      width: 32,
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppCores.mataClara,
      ),
      child: url.isEmpty
          ? inicial
          : Image.network(
              url,
              fit: BoxFit.cover,
              // Avatar quebrado nao pode virar caixa cinza: cai na inicial.
              errorBuilder: (_, _, _) => inicial,
            ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.logado,
    required this.nota,
    required this.comentario,
    required this.enviando,
    required this.erro,
    required this.sucesso,
    required this.aoMudarNota,
    required this.aoEnviar,
  });

  final bool logado;
  final int nota;
  final TextEditingController comentario;
  final bool enviando;
  final String erro;
  final bool sucesso;
  final ValueChanged<int> aoMudarNota;
  final VoidCallback aoEnviar;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppCores.branco,
        border: Border.all(color: AppCores.linha),
        borderRadius: BorderRadius.circular(raioPadrao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            logado ? 'Deixe sua avaliação' : 'Faça login para avaliar',
            style: estiloTitulo(22),
          ),
          const SizedBox(height: 20),

          if (sucesso) ...[
            const AvisoDeFormulario(
              texto: 'Obrigado! Sua avaliação foi publicada.',
              erro: false,
            ),
            const SizedBox(height: 16),
          ],
          if (erro.isNotEmpty) ...[
            AvisoDeFormulario(texto: erro, erro: true),
            const SizedBox(height: 16),
          ],

          const Text(
            'Sua nota',
            style: TextStyle(fontSize: 15, color: AppCores.tinta2),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Estrelas(
              valor: nota,
              aoMudar: logado ? aoMudarNota : null,
              somenteLeitura: !logado,
              tamanho: 28,
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: comentario,
            enabled: logado,
            maxLines: 4,
            // O mesmo limite das Firestore Rules: antes o campo aceitava
            // qualquer tamanho e o servidor recusava sem dizer por quê.
            maxLength: maxComentario,
            inputFormatters: [LengthLimitingTextInputFormatter(maxComentario)],
            style: const TextStyle(fontSize: 16, color: AppCores.tinta),
            decoration: InputDecoration(
              hintText: logado
                  ? 'Escreva seu comentário sobre o site...'
                  : 'Faça login para deixar um comentário...',
              fillColor: logado ? AppCores.branco : AppCores.papel2,
            ),
          ),
          const SizedBox(height: 14),

          FilledButton(
            onPressed: enviando ? null : aoEnviar,
            child: Text(
              !logado
                  ? 'Entrar para avaliar'
                  : enviando
                  ? 'Enviando...'
                  : 'Enviar avaliação',
            ),
          ),
        ],
      ),
    ),
  );
}
