// Bateria de testes de navegação do Portal Administrador (GEOPRAG-36):
// garante que o guard de autenticação, o guard de cargo Administrador, e
// cada rota do menu lateral abrem sem erro (provider ausente, id não
// encontrado, etc.).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_administrador/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  // Viewport padrão de teste (800x600) é menor que o layout desktop-only
  // do portal (login com painéis lado a lado, sidebar fixa) e causa
  // overflow + botões fora da área de hit-test. Usa um tamanho realista de
  // desktop web.
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const AppAdministrador());
  // Deixa o guard de tenant (AdminTenantCubit.load) resolver.
  await tester.pumpAndSettle();

  // O GoRouter e o AdminSessionCubit usados por `AppAdministrador` são
  // singletons de nível de biblioteca (`main.dart`), não recriados a cada
  // `pumpWidget` — sobrevivem entre os `testWidgets` deste arquivo. Força
  // a volta para a tela de login a cada novo teste para garantir
  // isolamento, independente do que o teste anterior deixou navegado.
  final context = tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go('/');
  await tester.pumpAndSettle();
}

Future<void> _login(
  WidgetTester tester, {
  required String identifier,
  String senha = '123456',
}) async {
  // O rótulo de InputDecoration não vira um match direto de
  // `widgetWithText` sobre o TextFormField — usa a ordem dos campos no
  // formulário (identificador, depois senha).
  final campos = find.byType(TextFormField);
  await tester.enterText(campos.at(0), identifier);
  await tester.enterText(campos.at(1), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar no Portal'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guard geral redireciona para o login quando não autenticado', (
    tester,
  ) async {
    await _pumpApp(tester);

    // Tenta ir direto para uma rota protegida sem estar autenticado —
    // simula o cenário de hot restart em Flutter web, onde a URL do
    // navegador sobrevive mas a sessão em memória é perdida.
    // `MaterialApp` cria o Router — seu próprio context fica ACIMA do
    // InheritedGoRouter, então `GoRouter.of` só funciona a partir de um
    // widget renderizado dentro da rota atual (ex.: o `Scaffold` da tela).
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).go('/dashboard');
    await tester.pumpAndSettle();

    expect(find.text('Acesso Restrito'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets(
    'login como Administrador leva ao dashboard e mostra o item de Administradores',
    (tester) async {
      await _pumpApp(tester);

      await _login(tester, identifier: 'admin@gaspar.sc.gov.br');

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Gerenciamento de Administradores'), findsOneWidget);
    },
  );

  testWidgets(
    'login como Sub-Administrador esconde o item de Administradores e bloqueia a rota',
    (tester) async {
      await _pumpApp(tester);

      await _login(tester, identifier: 'celia.ramos@gaspar.sc.gov.br');

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Gerenciamento de Administradores'), findsNothing);

      // Mesmo tentando ir direto pela URL, o guard de cargo redireciona de
      // volta ao dashboard geral.
      // `MaterialApp` cria o Router — seu próprio context fica ACIMA do
      // InheritedGoRouter, então `GoRouter.of` só funciona a partir de um
      // widget renderizado dentro da rota atual (ex.: o `Scaffold` da tela).
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go('/administradores');
      await tester.pumpAndSettle();
      expect(find.text('Administradores Cadastrados'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
    },
  );

  group('rotas do menu abrem sem erro (provider presente)', () {
    Future<void> verificaRota(
      WidgetTester tester,
      String rota,
      String tituloEsperado,
    ) async {
      // `MaterialApp` cria o Router — seu próprio context fica ACIMA do
      // InheritedGoRouter, então `GoRouter.of` só funciona a partir de um
      // widget renderizado dentro da rota atual (ex.: o `Scaffold` da tela).
      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go(rota);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'rota $rota lançou uma exceção',
      );
      // Busca só dentro da AppBar: alguns títulos (ex.: "Visão Geral")
      // coincidem com o rótulo do item correspondente na sidebar.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(tituloEsperado),
        ),
        findsOneWidget,
        reason: 'rota $rota não mostrou o título esperado na AppBar',
      );
    }

    testWidgets(
      'dashboard, mapa, aplicadores, estoque, distribuições, denúncias e administradores',
      (tester) async {
        await _pumpApp(tester);
        await _login(tester, identifier: 'admin@gaspar.sc.gov.br');

        await verificaRota(tester, '/dashboard', 'Visão Geral');
        await verificaRota(tester, '/mapa', 'Mapa Hidrológico e Monitoramento');
        await verificaRota(tester, '/aplicadores', 'Gestão de Aplicadores');
        await verificaRota(tester, '/estoque', 'Controle de Estoque e Compras');
        await verificaRota(
          tester,
          '/distribuicoes',
          'Gestão de Distribuições (Saídas)',
        );
        await verificaRota(tester, '/denuncias_admin', 'Gestão de Denúncias');
        await verificaRota(
          tester,
          '/administradores',
          'Gerenciamento de Administradores',
        );
        await verificaRota(
          tester,
          '/administradores/solicitacoes',
          'Solicitações de Promoção',
        );
      },
    );
  });

  testWidgets(
    'clicar na linha do usuário abre o dialog de detalhes com as ações, e desativar/reativar funciona',
    (tester) async {
      await _pumpApp(tester);
      await _login(tester, identifier: 'admin@gaspar.sc.gov.br');

      final context = tester.element(find.byType(Scaffold).first);
      GoRouter.of(context).go('/administradores');
      await tester.pumpAndSettle();

      // Clica na linha da Célia Ramos (Sub-Administrador ativa por padrão).
      await tester.tap(find.text('Célia Ramos'));
      await tester.pumpAndSettle();

      expect(
        find.byType(Dialog),
        findsOneWidget,
        reason: 'o dialog deveria ter aberto',
      );
      expect(find.text('Sub-Administrador'), findsWidgets);
      // ElevatedButton.icon/OutlinedButton.icon retornam uma subclasse
      // privada (não `ElevatedButton`/`OutlinedButton` em runtimeType), por
      // isso os asserts usam o texto do rótulo em vez de
      // `widgetWithText(ElevatedButton, ...)`.
      expect(find.text('Desativar'), findsOneWidget);
      expect(find.text('Promover a Administrador'), findsOneWidget);
      expect(find.text('Reativar'), findsNothing);
      expect(find.textContaining('desativado desde'), findsNothing);

      // Desativa pelo dialog.
      await tester.tap(find.text('Desativar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Desativar'));
      await tester.pumpAndSettle();

      expect(find.text('Cadastro desativado com sucesso.'), findsOneWidget);

      // Reabre a linha: agora deve mostrar o indicador e o botão de
      // reativar no lugar do de desativar.
      await tester.tap(find.text('Célia Ramos'));
      await tester.pumpAndSettle();

      expect(find.text('Reativar'), findsOneWidget);
      expect(find.text('Desativar'), findsNothing);
      expect(find.text('Promover a Administrador'), findsNothing);
      expect(find.textContaining('desativado desde'), findsOneWidget);

      // `mockAdminAccounts` é um singleton compartilhado entre os testes
      // deste arquivo — reativa a Célia de volta para não vazar estado
      // para os testes seguintes.
      await tester.tap(find.text('Reativar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Reativar'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('sidebar não fica coberta por uma AppBar de largura total', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _login(tester, identifier: 'admin@gaspar.sc.gov.br');

    // AdminScaffold: o Scaffold externo (sidebar) não tem AppBar própria —
    // só o Scaffold interno (painel de conteúdo) tem. Duas AppBars
    // indicaria a estrutura antiga (uma cobrindo a largura toda).
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsNWidgets(2));
  });
}
