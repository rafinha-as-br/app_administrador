import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geoprag_modules/geoprag_modules.dart';
import 'package:geoprag_modules/portal_administrador/bootstrap.dart';
import 'package:geoprag_modules/portal_administrador/tenant/tenant.dart';
import 'package:go_router/go_router.dart';

import 'navigation/admin_go_router_navigator.dart';
import 'navigation/go_router_refresh_stream.dart';

void main() {
  runApp(const AppAdministrador());
}

const AdminBootstrap _bootstrap = AdminBootstrap();

// TODO(GEOPRAG-24): tenant_id real vem do login (Fase 4/contrato de
// endpoints); mockado aqui até o contrato ser fechado com o backend.
final TenantCubit _tenantCubit = _bootstrap.buildTenantCubit()
  ..load('gaspar-sc');

const _publicPaths = {
  '/',
  '/senha/esqueci',
  '/senha/aguardando',
  '/senha/autorizar',
  '/senha/codigo-subadmin',
  '/senha/codigo-admin',
  '/senha/recriar',
  '/tenant/carregando',
};

final GoRouter _router = GoRouter(
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(_tenantCubit.stream),
  // TODO(GEOPRAG-24): guard de auth real vem da Fase 3/4 (AuthBloc); por ora
  // considera sempre autenticado. Guard de tenant abaixo já é real (Fase 2).
  redirect: (context, state) {
    if (_publicPaths.contains(state.matchedLocation)) return null;
    if (_tenantCubit.state is! TenantReady) return '/tenant/carregando';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildAdminLoginCubit(),
        child: const LoginScreenWeb(),
      ),
    ),
    GoRoute(
      path: '/senha/esqueci',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildAdminEsqueciSenhaCubit(),
        child: const EsqueciSenhaWebScreen(),
      ),
    ),
    GoRoute(
      path: '/senha/aguardando',
      builder: (context, state) => const AguardandoAutorizacaoScreen(),
    ),
    GoRoute(
      path: '/senha/autorizar',
      builder: (context, state) => const AutorizacaoRedefinicaoScreen(),
    ),
    GoRoute(
      path: '/senha/codigo-subadmin',
      builder: (context, state) => const VerificarCodigoSubAdminScreen(),
    ),
    GoRoute(
      path: '/senha/codigo-admin',
      builder: (context, state) => const VerificarCodigoAdminScreen(),
    ),
    GoRoute(
      path: '/senha/recriar',
      builder: (context, state) => BlocProvider(
        create: (_) => _bootstrap.buildAdminRecriarSenhaCubit(),
        child: const RecriarSenhaWebScreen(),
      ),
    ),
    GoRoute(
      path: '/tenant/carregando',
      builder: (context, state) => const TenantLoadingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardGeralScreen(),
    ),
    GoRoute(
      path: '/mapa',
      builder: (context, state) => const MapMonitoringScreen(),
    ),
    GoRoute(
      path: '/mapa/bairro',
      builder: (context, state) => const DetalheDoBairroScreen(),
    ),
    GoRoute(
      path: '/aplicadores',
      builder: (context, state) => const DashboardAplicadoresScreen(),
    ),
    GoRoute(
      path: '/aplicadores/detalhes',
      builder: (context, state) => const VisualizacaoIndividualScreen(),
    ),
    GoRoute(
      path: '/aplicacoes',
      builder: (context, state) => const DashboardDeAplicacoesScreen(),
    ),
    GoRoute(
      path: '/aplicacoes/bairro',
      builder: (context, state) => const VisualizacaoDeBairroScreen(),
    ),
    GoRoute(
      path: '/aplicacoes/detalhes',
      builder: (context, state) => const VisualizacaoDePontoDeAplicacaoScreen(),
    ),
    GoRoute(
      path: '/aplicacoes/criar',
      builder: (context, state) => const CriacaoDePontoScreen(),
    ),
    GoRoute(
      path: '/estoque',
      builder: (context, state) => const DashboardEstoqueScreen(),
    ),
    GoRoute(
      path: '/estoque/formula',
      builder: (context, state) => const CadastroFormulaScreen(),
    ),
    GoRoute(
      path: '/estoque/licitacao',
      builder: (context, state) => const CadastroLicitacaoScreen(),
    ),
    GoRoute(
      path: '/estoque/produto',
      builder: (context, state) => const CadastroProdutoScreen(),
    ),
    GoRoute(
      path: '/estoque/visualizacao',
      builder: (context, state) => const VisualizacaoProdutoScreen(),
    ),
    GoRoute(
      path: '/distribuicoes',
      builder: (context, state) => const DashboardDistribuicoesScreen(),
    ),
    GoRoute(
      path: '/distribuicoes/cadastro',
      builder: (context, state) => const CadastroSaidaScreen(),
    ),
    GoRoute(
      path: '/distribuicoes/visualizacao',
      builder: (context, state) => const VisualizacaoSaidaScreen(),
    ),
    GoRoute(
      path: '/denuncias_admin',
      builder: (context, state) => const DashboardDenunciasAdminScreen(),
    ),
    GoRoute(
      path: '/denuncias_admin/detalhes',
      builder: (context, state) => const VisualizacaoIndividualDenunciaScreen(),
    ),
  ],
);

class AppAdministrador extends StatelessWidget {
  const AppAdministrador({super.key});

  @override
  Widget build(BuildContext context) {
    // TenantCubit é provido na raiz (exceção deliberada à regra de
    // "BlocProvider escopado por rota" da Fase 3): ele guia o `redirect` do
    // GoRouter antes de qualquer tela existir, então precisa estar acima do
    // router. Os demais Blocs (auth, etc.) ficam escopados por rota, dentro
    // de cada `GoRoute.builder` acima.
    return BlocProvider.value(
      value: _tenantCubit,
      child: MaterialApp.router(
        title: 'GeoPrag - Admin',
        theme: GeopragTheme.light(),
        routerConfig: _router,
        builder: (context, child) => AdminNavigatorScope(
          navigator: AdminGoRouterNavigator(_router),
          child: child!,
        ),
      ),
    );
  }
}
