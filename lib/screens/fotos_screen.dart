import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/identificacao.dart';
import '../services/identificacao_service.dart';
import '../theme/app_theme.dart';
import '../widgets/aviso_de_formulario.dart';

/// Tire uma foto de um animal e veja que animal o Gemini acha que e.
///
/// Exige login: cada consulta gasta a cota do projeto no Gemini, e a Edge
/// Function recusa quem nao manda um ID token do Firebase.
class FotosScreen extends StatefulWidget {
  const FotosScreen({
    super.key,
    required this.usuario,
    required this.aoPedirLogin,
    this.servico,
  });

  final User? usuario;
  final VoidCallback aoPedirLogin;
  final IdentificacaoService? servico;

  @override
  State<FotosScreen> createState() => _FotosScreenState();
}

class _FotosScreenState extends State<FotosScreen> {
  late final _servico = widget.servico ?? IdentificacaoService();

  Uint8List? _foto;
  Identificacao? _resultado;
  bool _carregando = false;
  String _erro = '';

  Future<void> _escolher(ImageSource origem) async {
    final XFile? img;
    try {
      // 1024 px basta para o Gemini reconhecer o animal e mantem o envio
      // pequeno em rede movel.
      img = await ImagePicker().pickImage(
        source: origem,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (_) {
      setState(() => _erro = 'Não foi possível abrir a câmera ou a galeria.');
      return;
    }
    if (img == null) return;
    final bytes = await img.readAsBytes();
    if (!mounted) return;

    setState(() {
      _foto = bytes;
      _resultado = null;
      _erro = '';
      _carregando = true;
    });

    try {
      final r = await _servico.identificar(bytes);
      if (mounted) setState(() => _resultado = r);
    } catch (e) {
      // A tela mostra uma mensagem amigavel; o log guarda o erro real, com o
      // status e o corpo da resposta, para dar para diagnosticar pelo adb.
      debugPrint('Identificacao falhou: $e');
      if (mounted) {
        setState(() => _erro = IdentificacaoService.mensagemDeErro(e));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
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
                    style: estiloTitulo(mobile ? 32 : 48),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tire uma foto ou escolha uma imagem, e o Gemini, do '
                  'Google, tenta dizer qual é o animal.',
                  style: TextStyle(
                    fontSize: mobile ? 17 : 19,
                    height: 1.5,
                    color: AppCores.tinta2,
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
    final camera = FilledButton.icon(
      onPressed: _carregando ? null : () => _escolher(ImageSource.camera),
      icon: const Icon(Icons.photo_camera_outlined, size: 20),
      label: const Text('Tirar foto'),
    );
    final galeria = OutlinedButton.icon(
      onPressed: _carregando ? null : () => _escolher(ImageSource.gallery),
      icon: const Icon(Icons.photo_library_outlined, size: 20),
      label: const Text('Escolher imagem'),
    );

    return [
      // O nivel gratuito do Gemini permite ao Google usar o que e enviado;
      // quem manda a foto precisa saber disso antes.
      const Text(
        'A foto é enviada ao Gemini, do Google, que pode usá-la para melhorar '
        'os serviços dele. Não envie fotos de pessoas.',
        style: TextStyle(fontSize: 15, height: 1.5, color: AppCores.tinta3),
      ),
      const SizedBox(height: 20),
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
          child: const Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  backgroundColor: AppCores.linha,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Procurando o animal... pode levar alguns segundos.',
                  style: TextStyle(fontSize: 16, color: AppCores.tinta2),
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
      color: AppCores.branco,
      border: Border.all(color: AppCores.linha),
      borderRadius: BorderRadius.circular(raioPadrao),
    ),
    child: child,
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
        const Text(
          'Para identificar animais por foto é preciso entrar na sua conta. '
          'Cada consulta tem custo, e o login evita abuso.',
          style: TextStyle(fontSize: 16, height: 1.5, color: AppCores.tinta2),
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
          style: const TextStyle(fontSize: 16, color: AppCores.tinta2),
        ),
      );
    }

    return _Cartao(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Parece ser',
            style: TextStyle(fontSize: 15, color: AppCores.tinta3),
          ),
          const SizedBox(height: 2),
          Text(r.nomePopular!, style: estiloTitulo(32)),
          if (r.nomeCientifico != null) ...[
            const SizedBox(height: 2),
            Text(
              r.nomeCientifico!,
              style: const TextStyle(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                color: AppCores.tinta2,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            r.confianca.rotulo,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppCores.mata,
            ),
          ),
          if (r.descricao != null) ...[
            const SizedBox(height: 20),
            Text('Por quê', style: estiloTitulo(18)),
            const SizedBox(height: 4),
            Text(
              r.descricao!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppCores.tinta2,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppCores.linha)),
            ),
            child: const Text(
              'Identificação feita por inteligência artificial: pode errar.',
              style: TextStyle(fontSize: 14, color: AppCores.tinta3),
            ),
          ),
        ],
      ),
    );
  }
}
