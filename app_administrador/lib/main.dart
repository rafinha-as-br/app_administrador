import 'package:flutter/material.dart';
import 'package:geoprag_modules/geoprag_modules.dart';

void main() {
  runApp(const AppAdministrador());
}

class AppAdministrador extends StatelessWidget {
  const AppAdministrador({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoPrag - Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreenWeb(),
        '/dashboard': (context) => const DashboardGeralScreen(),
        '/mapa': (context) => const MapMonitoringScreen(),
        '/aplicadores': (context) => const DashboardAplicadoresScreen(),
        '/aplicadores/detalhes': (context) => const VisualizacaoIndividualScreen(),
        '/estoque': (context) => const DashboardEstoqueScreen(),
        '/estoque/formula': (context) => const CadastroFormulaScreen(),
        '/estoque/licitacao': (context) => const CadastroLicitacaoScreen(),
        '/estoque/produto': (context) => const CadastroProdutoScreen(),
        '/estoque/visualizacao': (context) => const VisualizacaoProdutoScreen(),
        '/distribuicoes': (context) => const DashboardDistribuicoesScreen(),
        '/distribuicoes/cadastro': (context) => const CadastroSaidaScreen(),
        '/distribuicoes/visualizacao': (context) => const VisualizacaoSaidaScreen(),
        '/denuncias_admin': (context) => const DashboardDenunciasAdminScreen(),
        '/denuncias_admin/detalhes': (context) => const VisualizacaoIndividualDenunciaScreen(),
      },
    );
  }
}
