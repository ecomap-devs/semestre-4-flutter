import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/preferencia_de_tema.dart';
import '../theme/app_theme.dart';
import '../widgets/apagar_conta_dialog.dart';
import '../widgets/auth_modal.dart';
import '../widgets/botao_de_tema.dart';
import 'animais_screen.dart';
import 'fotos_screen.dart';
import 'home_screen.dart';
import 'mapa_screen.dart';

/// Casca de navegacao das quatro telas.
///
/// Na versao React isso era React Router com um fade escrito a mao. Aqui e
/// `NavigationBar` no mobile e `NavigationRail` no desktop — o padrao que o
/// usuario de cada plataforma ja espera —, com o mesmo fade entre telas.
class AppShell extends StatefulWidget {
  AppShell({super.key, required this.auth, PreferenciaDeTema? tema})
    : tema = tema ?? PreferenciaDeTema();

  final AuthService auth;

  /// A escolha de tema do botão da barra. O `EcoMapApp` passa a mesma que o
  /// `MaterialApp` escuta; sem ela (nos testes), o botão troca só o ícone.
  final PreferenciaDeTema tema;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indice = 0;

  static const _destinos = <({IconData icone, IconData ativo, String rotulo})>[
    (icone: Icons.home_outlined, ativo: Icons.home, rotulo: 'Início'),
    (icone: Icons.map_outlined, ativo: Icons.map, rotulo: 'Mapa'),
    (icone: Icons.pets_outlined, ativo: Icons.pets, rotulo: 'Animais'),
    (
      icone: Icons.photo_camera_outlined,
      ativo: Icons.photo_camera,
      rotulo: 'Fotos',
    ),
  ];

  void _pedirLogin() => AuthModal.abrir(context, widget.auth);

  Future<void> _apagarConta() async {
    final apagou = await ApagarContaDialog.abrir(context, widget.auth);
    if (!apagou || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Sua conta foi apagada.')));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.auth.mudancasDeAutenticacao,
      builder: (context, snap) {
        // Enquanto o Firebase nao responde, a versao React renderizava `null`.
        // Aqui vale mostrar que algo esta acontecendo.
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final usuario = snap.data;
        final telas = [
          HomeScreen(
            usuario: usuario,
            aoPedirLogin: _pedirLogin,
            aoAbrirMapa: () => setState(() => _indice = 1),
            aoAbrirAnimais: () => setState(() => _indice = 2),
            aoAbrirFotos: () => setState(() => _indice = 3),
          ),
          const MapaScreen(),
          const AnimaisScreen(),
          FotosScreen(usuario: usuario, aoPedirLogin: _pedirLogin),
        ];

        final ehMobile = Breakpoints.ehMobile(context);

        final corpo = AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 550),
          reverseDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animacao) => FadeTransition(
            opacity: animacao,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .025),
                end: Offset.zero,
              ).animate(animacao),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_indice), child: telas[_indice]),
        );

        // O Voltar do sistema fechava o app de qualquer aba. Agora, fora do
        // Inicio, ele volta para o Inicio; so dali o app fecha, como nos apps
        // do proprio Android (auditoria de 11/11/2026).
        return PopScope(
          canPop: _indice == 0,
          onPopInvokedWithResult: (saiu, _) {
            if (!saiu) setState(() => _indice = 0);
          },
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: ehMobile ? 56 : 64,
              titleSpacing: ehMobile ? 16 : 24,
              title: Row(
                children: [
                  Image.asset('assets/img/logo.png', height: 30),
                  const SizedBox(width: 10),
                  Text(
                    'EcoMapBrasil',
                    style: estiloTitulo(
                      Escala.titleLarge,
                      cor: context.cores.tinta,
                    ),
                  ),
                ],
              ),
              actions: [
                BotaoDeTema(tema: widget.tema),
                const SizedBox(width: 4),
                if (usuario == null)
                  OutlinedButton(
                    onPressed: _pedirLogin,
                    style: OutlinedButton.styleFrom(
                      // O desenho fica com 40 dp para caber na barra; o toque
                      // tem 48, pela margem que o Material poe em volta.
                      minimumSize: const Size(48, 40),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: Escala.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Entrar'),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: usuario.displayName ?? 'Conta',
                    onSelected: (v) {
                      if (v == 'sair') widget.auth.sair();
                      if (v == 'apagar') _apagarConta();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        enabled: false,
                        child: Text(
                          usuario.displayName ?? usuario.email ?? 'Usuário',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.cores.tinta,
                          ),
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'sair', child: Text('Sair')),
                      PopupMenuItem(
                        value: 'apagar',
                        child: Text(
                          'Apagar conta',
                          style: TextStyle(color: context.cores.terra),
                        ),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: context.cores.mataClara,
                        foregroundImage: (usuario.photoURL ?? '').isEmpty
                            ? null
                            : NetworkImage(usuario.photoURL!),
                        child: Text(
                          (usuario.displayName ?? 'U').characters.first
                              .toUpperCase(),
                          style: Escala.bodySmall.copyWith(
                            color: context.cores.mata,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                SizedBox(width: ehMobile ? 12 : 20),
              ],
            ),
            body: ehMobile
                ? corpo
                : Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _indice,
                        onDestinationSelected: (i) =>
                            setState(() => _indice = i),
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (final d in _destinos)
                            NavigationRailDestination(
                              icon: Icon(d.icone),
                              selectedIcon: Icon(d.ativo),
                              label: Text(d.rotulo),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: corpo),
                    ],
                  ),
            bottomNavigationBar: ehMobile
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.cores.linha),
                      ),
                    ),
                    child: NavigationBar(
                      selectedIndex: _indice,
                      onDestinationSelected: (i) => setState(() => _indice = i),
                      destinations: [
                        for (final d in _destinos)
                          NavigationDestination(
                            icon: Icon(d.icone),
                            selectedIcon: Icon(d.ativo),
                            label: d.rotulo,
                          ),
                      ],
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
