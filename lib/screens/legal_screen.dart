import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/home_data.dart' show enderecoDoSite;
import '../data/legal_data.dart';
import '../models/documento_legal.dart';
import '../theme/app_theme.dart';

/// Abre a politica de privacidade ou os termos de uso por cima da tela atual,
/// ja na secao [secao] se ela for dada.
Future<void> abrirDocumentoLegal(
  BuildContext context,
  DocumentoLegal documento, {
  String? secao,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => LegalScreen(documento: documento, secao: secao),
  ),
);

/// A politica de privacidade e os termos de uso — as paginas `/privacidade` e
/// `/termos` do site, com o mesmo texto (`legal_data.dart`, copiado do site).
///
/// Sem `url_launcher` no app, link para fora copia o endereco; link para outra
/// secao rola ate ela, e para o outro documento abre o outro documento.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.documento, this.secao});

  final DocumentoLegal documento;

  /// O `id` da secao para abrir ja rolado ate ela.
  final String? secao;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  late final Map<String, GlobalKey> _secoes = {
    for (final s in widget.documento.secoes) s.id: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    final secao = widget.secao;
    if (secao != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _irPara(secao));
    }
  }

  void _irPara(String id) {
    final contexto = _secoes[id]?.currentContext;
    if (contexto == null) return;
    Scrollable.ensureVisible(
      contexto,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  /// O que fazer com cada endereco da marcacao `[texto](endereco)`.
  void _seguir(String destino) {
    if (destino.startsWith('#')) {
      _irPara(destino.substring(1));
      return;
    }
    final (caminho, ancora) = switch (destino.split('#')) {
      [final c, final a] => (c, a),
      _ => (destino, null),
    };
    final outro = switch (caminho) {
      '/privacidade' => privacidade,
      '/termos' => termos,
      _ => null,
    };
    if (outro == widget.documento && ancora != null) {
      _irPara(ancora);
    } else if (outro != null) {
      abrirDocumentoLegal(context, outro, secao: ancora);
    } else {
      // Fora daqui: o endereco vai para a area de transferencia.
      final url = destino.startsWith('/') ? '$enderecoDoSite$destino' : destino;
      Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Link copiado. Cole no navegador: $url')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.documento;
    final mobile = Breakpoints.ehMobile(context);

    return Scaffold(
      backgroundColor: AppCores.papel,
      appBar: AppBar(
        title: Text(doc.titulo),
        backgroundColor: AppCores.papel,
        foregroundColor: AppCores.tinta,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          mobile ? 20 : 24,
          mobile ? 16 : 40,
          mobile ? 20 : 24,
          64,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    doc.titulo,
                    style: estiloTitulo(mobile ? 34 : 48, altura: 1.05),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Versão de $atualizadoEm',
                  style: TextStyle(fontSize: 15, color: AppCores.tinta3),
                ),
                const SizedBox(height: 18),
                TextoMarcado(
                  doc.abertura,
                  aoSeguir: _seguir,
                  estilo: const TextStyle(
                    fontSize: 18,
                    height: 1.55,
                    color: AppCores.tinta2,
                  ),
                ),
                const SizedBox(height: 28),
                _Indice(secoes: doc.secoes, aoEscolher: _irPara),
                const SizedBox(height: 36),
                for (final s in doc.secoes) ...[
                  Semantics(
                    key: _secoes[s.id],
                    header: true,
                    child: Text(
                      s.titulo,
                      style: estiloTitulo(mobile ? 24 : 28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final b in s.blocos) ...[
                    _Bloco(bloco: b, aoSeguir: _seguir),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 22),
                ],
                const Divider(color: AppCores.linha, height: 1),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: () => abrirDocumentoLegal(
                        context,
                        doc == privacidade ? termos : privacidade,
                      ),
                      child: Text(
                        doc == privacidade
                            ? 'Termos de uso'
                            : 'Política de privacidade',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Indice extends StatelessWidget {
  const _Indice({required this.secoes, required this.aoEscolher});

  final List<SecaoLegal> secoes;
  final void Function(String id) aoEscolher;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      border: Border.symmetric(horizontal: BorderSide(color: AppCores.linha)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nesta página',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppCores.tinta3,
            ),
          ),
          const SizedBox(height: 4),
          for (final (i, s) in secoes.indexed)
            InkWell(
              onTap: () => aoEscolher(s.id),
              child: Padding(
                // 44 px de altura de toque, como o resto do app.
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Text(
                  '${i + 1}. ${s.titulo}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppCores.mata,
                    decoration: TextDecoration.underline,
                    decorationColor: AppCores.mata,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.bloco, required this.aoSeguir});

  final BlocoLegal bloco;
  final void Function(String destino) aoSeguir;

  static const _corpo = TextStyle(
    fontSize: 16,
    height: 1.55,
    color: AppCores.tinta2,
  );

  @override
  Widget build(BuildContext context) => switch (bloco) {
    ParagrafoLegal(:final texto) => TextoMarcado(
      texto,
      aoSeguir: aoSeguir,
      estilo: _corpo,
    ),
    ListaLegal(:final itens) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: _corpo),
                Expanded(
                  child: TextoMarcado(item, aoSeguir: aoSeguir, estilo: _corpo),
                ),
              ],
            ),
          ),
      ],
    ),
    // No celular a tabela vira um cartao por linha: a primeira coluna e o
    // titulo, e cada outra vem com o nome da coluna.
    TabelaLegal(:final colunas, :final linhas) => Column(
      children: [
        for (final linha in linhas)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppCores.branco,
              border: Border.all(color: AppCores.linha),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextoMarcado(
                  linha.first,
                  aoSeguir: aoSeguir,
                  estilo: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppCores.tinta,
                  ),
                ),
                for (
                  var j = 1;
                  j < linha.length && j < colunas.length;
                  j++
                ) ...[
                  const SizedBox(height: 8),
                  Text(
                    colunas[j],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppCores.tinta3,
                    ),
                  ),
                  TextoMarcado(
                    linha[j],
                    aoSeguir: aoSeguir,
                    estilo: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppCores.tinta2,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    ),
  };
}

/// **negrito**, `codigo` e [texto](endereco), a marcacao de `legal_data.dart`.
final _marcacao = RegExp(r'\*\*[^*]+\*\*|`[^`]+`|\[[^\]]+\]\([^)\s]+\)');
final _link = RegExp(r'^\[([^\]]+)\]\(([^)\s]+)\)$');

/// Um texto com a marcacao minima dos documentos. Os toques nos links vivem
/// num estado proprio para os reconhecedores serem descartados com o widget.
class TextoMarcado extends StatefulWidget {
  const TextoMarcado(
    this.texto, {
    super.key,
    required this.aoSeguir,
    required this.estilo,
  });

  final String texto;
  final void Function(String destino) aoSeguir;
  final TextStyle estilo;

  @override
  State<TextoMarcado> createState() => _TextoMarcadoState();
}

class _TextoMarcadoState extends State<TextoMarcado> {
  final _toques = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final t in _toques) {
      t.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _trechos() {
    for (final t in _toques) {
      t.dispose();
    }
    _toques.clear();

    final trechos = <InlineSpan>[];
    var desde = 0;
    for (final m in _marcacao.allMatches(widget.texto)) {
      if (m.start > desde) {
        trechos.add(TextSpan(text: widget.texto.substring(desde, m.start)));
      }
      final parte = m[0]!;
      if (parte.startsWith('**')) {
        trechos.add(
          TextSpan(
            text: parte.substring(2, parte.length - 2),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppCores.tinta,
            ),
          ),
        );
      } else if (parte.startsWith('`')) {
        trechos.add(
          TextSpan(
            text: parte.substring(1, parte.length - 1),
            style: const TextStyle(
              fontFamily: 'monospace',
              backgroundColor: AppCores.papel2,
            ),
          ),
        );
      } else {
        final link = _link.firstMatch(parte)!;
        final destino = link[2]!;
        final toque = TapGestureRecognizer()
          ..onTap = () => widget.aoSeguir(destino);
        _toques.add(toque);
        trechos.add(
          TextSpan(
            text: link[1],
            recognizer: toque,
            style: const TextStyle(
              color: AppCores.mata,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppCores.mata,
            ),
          ),
        );
      }
      desde = m.end;
    }
    if (desde < widget.texto.length) {
      trechos.add(TextSpan(text: widget.texto.substring(desde)));
    }
    return trechos;
  }

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(style: widget.estilo, children: _trechos()));
}

/// "Política de privacidade · Termos de uso", os atalhos dos rodapes.
class LinksLegais extends StatelessWidget {
  const LinksLegais({super.key, required this.cor, this.tamanho = 13});

  final Color cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    Widget link(String rotulo, DocumentoLegal documento) => InkWell(
      onTap: () => abrirDocumentoLegal(context, documento),
      child: ConstrainedBox(
        // Altura de toque de 44 px num texto de 13.
        constraints: const BoxConstraints(minHeight: 44),
        child: Align(
          widthFactor: 1,
          child: Text(
            rotulo,
            style: TextStyle(
              fontSize: tamanho,
              color: cor,
              decoration: TextDecoration.underline,
              decorationColor: cor,
            ),
          ),
        ),
      ),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        link('Política de privacidade', privacidade),
        Text(
          '  ·  ',
          style: TextStyle(fontSize: tamanho, color: cor),
        ),
        link('Termos de uso', termos),
      ],
    );
  }
}
