import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Quem entrega o endereco ao sistema. Os testes trocam por um falso, porque
/// no `flutter test` nao ha navegador nem discador do outro lado.
@visibleForTesting
Future<bool> Function(Uri endereco) abrirNoSistema = _abrirNoSistema;

/// Site abre no navegador do celular, e nao num navegador dentro do app: quem
/// toca num link de fonte quer a pagina inteira, com os favoritos e a conta
/// gov.br que ja tem la. `tel:` abre o discador com o numero, sem ligar.
Future<bool> _abrirNoSistema(Uri endereco) =>
    launchUrl(endereco, mode: LaunchMode.externalApplication);

/// So estes esquemas saem do app. Os enderecos sao todos nossos (dados copiados
/// do site e textos legais), mas um `javascript:` ou `intent:` que entrasse por
/// engano num deles nao deve chegar ao sistema.
const _esquemasAceitos = {'https', 'http', 'tel'};

/// Abre [endereco] no navegador (`https:`) ou no discador (`tel:`).
///
/// Ate 10/11/2026 o app nao tinha `url_launcher` e mostrava os links por
/// extenso para copiar. Se o aparelho nao tiver quem abra o endereco, ou o
/// sistema recusar, volta a ser assim: o endereco (ou o numero) vai para a area
/// de transferencia, com um aviso.
Future<void> abrirLink(BuildContext context, String endereco) async {
  final uri = Uri.tryParse(endereco);

  var abriu = false;
  if (uri != null && _esquemasAceitos.contains(uri.scheme)) {
    try {
      abriu = await abrirNoSistema(uri);
    } on PlatformException {
      abriu = false;
    }
  }
  if (abriu || !context.mounted) return;

  final telefone = uri != null && uri.scheme == 'tel';
  final texto = telefone ? uri.path : endereco;
  await Clipboard.setData(ClipboardData(text: texto));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          telefone
              ? 'Não deu para abrir o discador. Número copiado: $texto'
              : 'Não deu para abrir o navegador. Link copiado: $texto',
        ),
      ),
    );
}

/// Copia [texto] e avisa. E o toque longo nos links, que antes eram texto
/// selecionavel: quem queria copiar o numero continua podendo.
Future<void> copiarComAviso(BuildContext context, String texto) async {
  await Clipboard.setData(ClipboardData(text: texto));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('Copiado: $texto')));
}
