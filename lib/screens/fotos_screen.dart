import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/legal_data.dart';
import '../models/identificacao.dart';
import '../services/declaracao_de_idade.dart';
import '../services/identificacao_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aviso_de_formulario.dart';
import 'legal_screen.dart';

/// Tire uma foto de um animal e veja que animal o Gemini acha que e.
///
/// Exige login: cada consulta gasta a cota do projeto no Gemini, e a Edge
/// Function recusa quem nao manda um ID token do Firebase.
///
/// Exige tambem a autodeclaracao de 18 anos ou mais (11/11/2026), pedida na
/// primeira vez que a pessoa toca em "Tirar foto" ou "Escolher imagem": os
/// termos da Gemini API nao aceitam uso por menores ([DeclaracaoDeIdade]).
class FotosScreen extends StatefulWidget {
  const FotosScreen({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
    this.servico,
    this.declaracao = const DeclaracaoDeIdade(),
    this.escolherImagem,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;
  final IdentificacaoService? servico;
  final DeclaracaoDeIdade declaracao;

  /// Abre a camera ou a galeria e devolve os bytes, ou `null` se a pessoa
  /// desistir. Trocavel nos testes, que nao abrem nenhuma das duas.
  final Future<Uint8List?> Function(ImageSource origem)? escolherImagem;

  @override
  State<FotosScreen> createState() => _FotosScreenState();
}

class _FotosScreenState extends State<FotosScreen> {
  late final _servico = widget.servico ?? IdentificacaoService();

  Uint8List? _foto;
  Identificacao? _resultado;
  bool _carregando = false;
  String _erro = '';

  /// O botao tocado antes de a pessoa dizer a idade: com valor, a pergunta
  /// aparece no lugar dos botoes, e a resposta "sim" abre essa origem.
  ImageSource? _perguntando;

  /// Respondeu que tem menos de 18 nesta visita: os botoes ficam desligados.
  bool _menor = false;

  /// A tela e a mesma quando a conta muda (o `AppShell` a identifica so pela
  /// aba), entao o estado da conta anterior precisa sair: o "nao" dela, a
  /// pergunta pela metade, e a foto e o resultado, que num aparelho
  /// compartilhado ficariam a vista de outra pessoa (revisao do Codex de
  /// 11/11/2026).
  @override
  void didUpdateWidget(covariant FotosScreen antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.usuario?.uid == widget.usuario?.uid) return;
    _foto = null;
    _resultado = null;
    _erro = '';
    _carregando = false;
    _perguntando = null;
    _menor = false;
  }

  /// Se a conta que comecou uma acao ainda e a da tela.
  bool _mesmaConta(String? uid) => mounted && widget.usuario?.uid == uid;

  Future<void> _tentar(ImageSource origem) async {
    final uid = widget.usuario?.uid;
    if (uid == null) return;
    final declarou = await widget.declaracao.declarou(uid);
    if (!_mesmaConta(uid)) return;
    if (declarou) {
      await _escolher(origem);
    } else {
      setState(() => _perguntando = origem);
    }
  }

  Future<void> _responder({required bool maior}) async {
    final origem = _perguntando;
    final uid = widget.usuario?.uid;
    if (origem == null || uid == null) return;
    setState(() {
      _perguntando = null;
      _menor = !maior;
    });
    if (!maior) return;
    try {
      await widget.declaracao.registrar(uid);
    } catch (_) {
      // Sem guardar, a pergunta volta na proxima vez; o uso de agora segue.
    }
    if (_mesmaConta(uid)) await _escolher(origem);
  }

  static Future<Uint8List?> _abrirImagem(ImageSource origem) async {
    // 1024 px basta para o Gemini reconhecer o animal e mantem o envio
    // pequeno em rede movel.
    final img = await ImagePicker().pickImage(
      source: origem,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    return img?.readAsBytes();
  }

  Future<void> _escolher(ImageSource origem) async {
    final uid = widget.usuario?.uid;
    final Uint8List? bytes;
    try {
      bytes = await (widget.escolherImagem ?? _abrirImagem)(origem);
    } catch (_) {
      if (_mesmaConta(uid)) {
        setState(() => _erro = 'Não foi possível abrir a câmera ou a galeria.');
      }
      return;
    }
    if (bytes == null || !_mesmaConta(uid)) return;

    setState(() {
      _foto = bytes;
      _resultado = null;
      _erro = '';
      _carregando = true;
    });

    // A resposta que chega depois de a conta mudar e da conta anterior: some.
    try {
      final r = await _servico.identificar(bytes);
      if (_mesmaConta(uid)) setState(() => _resultado = r);
    } catch (e) {
      // A tela mostra uma mensagem amigavel; o log guarda o erro real, com o
      // status e o corpo da resposta, para dar para diagnosticar pelo adb.
      debugPrint('Identificacao falhou: $e');
      if (_mesmaConta(uid)) {
        setState(() => _erro = IdentificacaoService.mensagemDeErro(e));
      }
    } finally {
      if (_mesmaConta(uid)) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Breakpoints.ehMobile(context);
    return ListView(
      padding: mobile
          ? const EdgeInsets.fromLTRB(16, 36, 16, 56)
          : const EdgeInsets.fromLTRB(24, 64, 24, 80),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Que animal é esse?',
                    style: estiloTitulo(
                      (mobile ? Escala.headlineLarge : Escala.displayLarge),
                      cor: context.cores.tinta,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tire uma foto ou escolha uma imagem, e o Gemini, do '
                  'Google, tenta dizer qual é o animal.',
                  style: Escala.titleMedium.copyWith(
                    height: 1.5,
                    color: context.cores.tinta2,
                  ),
                ),
                const SizedBox(height: 28),
                if (widget.usuario == null)
                  _PedirLogin(aoPedirLogin: widget.aoPedirLogin)
                else
                  ..._conteudo(mobile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _conteudo(bool mobile) {
    final desligado = _carregando || _menor;
    final camera = FilledButton.icon(
      onPressed: desligado ? null : () => _tentar(ImageSource.camera),
      icon: const Icon(Icons.photo_camera_outlined, size: 20),
      label: const Text('Tirar foto'),
    );
    final galeria = OutlinedButton.icon(
      onPressed: desligado ? null : () => _tentar(ImageSource.gallery),
      icon: const Icon(Icons.photo_library_outlined, size: 20),
      label: const Text('Escolher imagem'),
    );

    return [
      // O nivel gratuito do Gemini permite ao Google usar o que e enviado;
      // quem manda a foto precisa saber disso antes. E os termos do Gemini
      // exigem 18 anos (vistos em 02/11/2026).
      Text(
        'Só para maiores de 18 anos. A foto é enviada ao Gemini, do Google, '
        'que pode usá-la para melhorar os serviços dele. Não envie fotos de '
        'pessoas.',
        style: Escala.bodyMedium.copyWith(
          height: 1.5,
          color: context.cores.tinta3,
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => abrirDocumentoLegal(
            context,
            privacidade,
            secao: 'compartilhamento',
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text('Como tratamos a foto'),
        ),
      ),
      const SizedBox(height: 20),
      if (_perguntando != null)
        _PerguntaDeIdade(aoResponder: _responder)
      else ...[
        if (_menor) ...[const _AvisoDeIdade(), const SizedBox(height: 20)],
        if (mobile) ...[
          camera,
          const SizedBox(height: 12),
          galeria,
        ] else
          Row(
            children: [
              Expanded(child: camera),
              const SizedBox(width: 12),
              Expanded(child: galeria),
            ],
          ),
      ],
      if (_foto != null) ...[
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(raioPadrao),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: Image.memory(
              _foto!,
              fit: BoxFit.cover,
              semanticLabel: 'Foto enviada',
            ),
          ),
        ),
      ],
      if (_carregando) ...[
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  backgroundColor: context.cores.linha,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Procurando o animal... pode levar alguns segundos.',
                  style: Escala.bodyLarge.copyWith(color: context.cores.tinta2),
                ),
              ),
            ],
          ),
        ),
      ],
      if (_erro.isNotEmpty) ...[
        const SizedBox(height: 20),
        AvisoDeFormulario(texto: _erro, erro: true),
      ],
      if (_resultado != null) ...[
        const SizedBox(height: 20),
        _Resultado(identificacao: _resultado!),
      ],
    ];
  }
}

/// Cartao branco sobre o papel, com a borda fina do site.
class _Cartao extends StatelessWidget {
  const _Cartao({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: context.cores.cartao,
      border: Border.all(color: context.cores.linha),
      borderRadius: BorderRadius.circular(raioPadrao),
    ),
    child: child,
  );
}

/// A trava por autodeclaracao, no lugar dos botoes, na primeira tentativa.
class _PerguntaDeIdade extends StatelessWidget {
  const _PerguntaDeIdade({required this.aoResponder});

  final Future<void> Function({required bool maior}) aoResponder;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: _Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Você tem 18 anos ou mais?',
              style: estiloTitulo(
                Escala.headlineSmall,
                cor: context.cores.tinta,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A identificação por foto usa o Gemini, do Google, e os termos '
            'dele só permitem o uso por quem tem 18 anos ou mais.',
            style: Escala.bodyLarge.copyWith(
              height: 1.5,
              color: context.cores.tinta2,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => aoResponder(maior: true),
            child: const Text('Tenho 18 anos ou mais'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => aoResponder(maior: false),
            child: const Text('Tenho menos de 18'),
          ),
        ],
      ),
    ),
  );
}

/// O que aparece para quem respondeu que tem menos de 18.
class _AvisoDeIdade extends StatelessWidget {
  const _AvisoDeIdade();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: _Cartao(
      child: Text(
        'A identificação por foto é só para quem tem 18 anos ou mais, por '
        'exigência do Google. O mapa, as espécies e o resto do EcoMapBrasil '
        'continuam abertos para você.',
        style: Escala.bodyLarge.copyWith(
          height: 1.5,
          color: context.cores.tinta2,
        ),
      ),
    ),
  );
}

class _PedirLogin extends StatelessWidget {
  const _PedirLogin({required this.aoPedirLogin});

  final VoidCallback aoPedirLogin;

  @override
  Widget build(BuildContext context) => _Cartao(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Para identificar animais por foto é preciso entrar na sua conta. '
          'Cada consulta tem custo, e o login evita abuso.',
          style: Escala.bodyLarge.copyWith(
            height: 1.5,
            color: context.cores.tinta2,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: aoPedirLogin, child: const Text('Entrar')),
      ],
    ),
  );
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.identificacao});

  final Identificacao identificacao;

  @override
  Widget build(BuildContext context) {
    final r = identificacao;
    if (r.vazia) {
      return _Cartao(
        child: Text(
          r.ehAnimal
              ? 'Parece haver um animal, mas não deu para dizer qual. '
                    'Tente uma imagem mais nítida, com o animal em destaque.'
              : 'Não encontramos nenhum animal nesta foto.',
          style: Escala.bodyLarge.copyWith(color: context.cores.tinta2),
        ),
      );
    }

    return _Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parece ser',
            style: Escala.bodyMedium.copyWith(color: context.cores.tinta3),
          ),
          const SizedBox(height: 2),
          Text(
            r.nomePopular!,
            style: estiloTitulo(Escala.headlineLarge, cor: context.cores.tinta),
          ),
          if (r.nomeCientifico != null) ...[
            const SizedBox(height: 2),
            Text(
              r.nomeCientifico!,
              style: Escala.titleMedium.copyWith(
                fontStyle: FontStyle.italic,
                color: context.cores.tinta2,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            r.confianca.rotulo,
            style: Escala.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: context.cores.mata,
            ),
          ),
          if (r.descricao != null) ...[
            const SizedBox(height: 20),
            Text(
              'Por quê',
              style: estiloTitulo(Escala.titleLarge, cor: context.cores.tinta),
            ),
            const SizedBox(height: 4),
            Text(
              r.descricao!,
              style: Escala.bodyLarge.copyWith(
                height: 1.5,
                color: context.cores.tinta2,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.cores.linha)),
            ),
            child: Text(
              'Identificação feita por inteligência artificial: pode errar.',
              style: Escala.bodySmall.copyWith(color: context.cores.tinta3),
            ),
          ),
        ],
      ),
    );
  }
}
