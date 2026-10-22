import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_modal.dart';
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
  const AppShell({super.key, required this.auth});

  final AuthService auth;

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

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: ehMobile ? 56 : 64,
            titleSpacing: ehMobile ? 16 : 24,
            title: Row(
              children: [
                Image.asset('assets/img/logo.png', height: 30),
                const SizedBox(width: 10),
                Text('EcoMapBrasil', style: estiloTitulo(20)),
              ],
            ),
            actions: [
              if (usuario == null)
                OutlinedButton(
                  onPressed: _pedirLogin,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontFamily: AppFontes.texto,
                      fontSize: 15,
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
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Text(
                        usuario.displayName ?? usuario.email ?? 'Usuário',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppCores.tinta,
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'sair', child: Text('Sair')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppCores.mataClara,
                      foregroundImage: (usuario.photoURL ?? '').isEmpty
                          ? null
                          : NetworkImage(usuario.photoURL!),
                      child: Text(
                        (usuario.displayName ?? 'U').characters.first
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppCores.mata,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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
                      onDestinationSelected: (i) => setState(() => _indice = i),
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
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppCores.linha)),
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
        );
      },
    );
  }
}
