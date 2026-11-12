import 'package:flutter/material.dart';

import 'config/env.dart';
import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/firebase_init.dart';
import 'services/preferencia_de_tema.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sem credenciais o app nao sobe — e diz exatamente o que falta.
  //
  // A versao React falhava calada aqui: `import.meta.env` ausente virava
  // `undefined`, o build passava e o erro so aparecia no login. Uma tela de
  // erro legivel custa 20 linhas e economiza a tarde de quem clonar o repo.
  if (!Env.completo) {
    runApp(TelaDeConfiguracao(faltando: Env.faltando));
    return;
  }

  await inicializarServicos();
  // Lido antes do primeiro quadro, para o app não abrir no tema errado e
  // piscar para o escolhido.
  final tema = await PreferenciaDeTema.carregar();
  runApp(EcoMapApp(tema: tema));
}

class EcoMapApp extends StatelessWidget {
  const EcoMapApp({super.key, required this.tema});

  final PreferenciaDeTema tema;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: tema,
    builder: (context, modo, _) => MaterialApp(
      title: 'EcoMapBrasil',
      debugShowCheckedModeBanner: false,
      // Por padrão o tema segue o do sistema: quem usa o celular no escuro
      // abre o app no escuro (auditoria de responsividade de 11/11/2026). O
      // botão da barra deixa escolher claro ou escuro só no app.
      theme: construirTema(),
      darkTheme: construirTema(escuro: true),
      themeMode: modo,
      home: AppShell(auth: AuthService(), tema: tema),
    ),
  );
}

/// Mostrada quando falta variavel de ambiente.
class TelaDeConfiguracao extends StatelessWidget {
  const TelaDeConfiguracao({super.key, required this.faltando});

  final List<String> faltando;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: AppCores.papel,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.key_off, size: 40, color: AppCores.terra),
                const SizedBox(height: 16),
                Text(
                  'Faltam credenciais',
                  style: Escala.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppCores.tinta,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'O app precisa das chaves do Firebase e do Supabase '
                  'para subir. Copie env.example.json para env.json, '
                  'preencha, e rode com:',
                  style: Escala.bodySmall.copyWith(
                    height: 1.6,
                    color: AppCores.tinta2,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppCores.mataNoite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    'flutter run --dart-define-from-file=env.json',
                    style: Escala.labelMedium.copyWith(
                      color: AppCores.mataClara,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Variáveis ausentes:',
                  style: Escala.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppCores.tinta,
                  ),
                ),
                const SizedBox(height: 8),
                for (final v in faltando)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.close,
                          size: 14,
                          color: AppCores.terra,
                        ),
                        const SizedBox(width: 8),
                        SelectableText(
                          v,
                          style: Escala.labelMedium.copyWith(
                            color: AppCores.terra,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
