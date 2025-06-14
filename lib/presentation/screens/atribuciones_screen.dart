import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AtribucionesScreen extends StatelessWidget {
  const AtribucionesScreen({super.key});

  final List<Map<String, String>> atribuciones = const [
    {
      'path': 'assets/icons/drugs.png',
      'title': 'medicine icons',
      'url': 'https://www.flaticon.com/free-icons/medicine',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/shopping-cart.png',
      'title': 'supermarket icons',
      'url': 'https://www.flaticon.com/free-icons/supermarket',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/pill-box.png',
      'title': 'pill box icons',
      'url': 'https://www.flaticon.com/free-icons/pill-box',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/evaluation.png',
      'title': 'compliance icons',
      'url': 'https://www.flaticon.com/free-icons/compliance',
      'creator': 'Dewi Sari',
    },
    {
      'path': 'assets/icons/risk.png',
      'title': 'supply icons',
      'url': 'https://www.flaticon.com/free-icons/supply',
      'creator': 'gravisio',
    },
    {
      'path': 'assets/icons/review.png',
      'title': 'document icons',
      'url': 'https://www.flaticon.com/free-icons/document',
      'creator': 'vectorspoint',
    },
    {
      'path': 'assets/icons/compliance.png',
      'title': 'risk icons',
      'url': 'https://www.flaticon.com/free-icons/risk',
      'creator': 'juicy_fish',
    },
    {
      'path': 'assets/icons/crisis.png',
      'title': 'warning icons',
      'url': 'https://www.flaticon.com/free-icons/warning',
      'creator': 'Hilmy Abiyyu A.',
    },
    {
      'path': 'assets/icons/settings.png',
      'title': 'settings icons',
      'url': 'https://www.flaticon.com/free-icons/settings',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/pencil.png',
      'title': 'edit icons',
      'url': 'https://www.flaticon.com/free-icons/edit',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/delete.png',
      'title': 'delete icons',
      'url': 'https://www.flaticon.com/free-icons/delete',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/add-user.png',
      'title': 'add user icons',
      'url': 'https://www.flaticon.com/free-icons/add-user',
      'creator': 'sonnycandra',
    },
    {
      'path': 'assets/icons/healthcare.png',
      'title': 'drug icons',
      'url': 'https://www.flaticon.com/free-icons/drug',
      'creator': 'vladimir-susakin',
    },
    {
      'path': 'assets/icons/notification.png',
      'title': 'notification icons',
      'url': 'https://www.flaticon.com/free-icons/notification',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/medical-file.png',
      'title': 'health icons',
      'url': 'https://www.flaticon.com/free-icons/health',
      'creator': 'Freepik',
    },
    {
      'path': 'assets/icons/check.png',
      'title': 'success icons',
      'url': 'https://www.flaticon.com/free-icons/success',
      'creator': 'hqrloveq',
    },
    {
      'path': 'assets/icons/clock.png',
      'title': 'postpone icons',
      'url': 'https://www.flaticon.com/free-icons/postpone',
      'creator': 'Icontive',
    },
  ];

  Future<void> _abrirURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 211, 211, 236),
      appBar: AppBar(title: const Text('Atribuciones de iconos')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: atribuciones.length,
        itemBuilder: (context, index) {
          final item = atribuciones[index];
          return Card(
            color: Colors.white,
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              leading: Image.asset(item['path']!, width: 36, height: 36),
              title: Text(item['title']!),
              subtitle: Text('Creado por ${item['creator']}'),
              trailing: const Icon(Icons.open_in_new, size: 20),
              onTap: () => _abrirURL(item['url']!),
            ),
          );
        },
      ),
    );
  }
}
