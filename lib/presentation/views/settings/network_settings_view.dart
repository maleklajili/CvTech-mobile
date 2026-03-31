import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cv_tech/core/config/network_config.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';

/// Vue des paramètres réseau
/// Permet de configurer l'URL du backend dynamiquement
class NetworkSettingsView extends StatefulWidget {
  const NetworkSettingsView({super.key});

  @override
  State<NetworkSettingsView> createState() => _NetworkSettingsViewState();
}

class _NetworkSettingsViewState extends State<NetworkSettingsView> {
  final TextEditingController _urlController = TextEditingController();
  bool _useCustomUrl = false;
  bool _isLoading = false;
  String? _currentUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final useCustom = await NetworkConfig.isUsingCustomUrl();
      final savedUrl = await NetworkConfig.getSavedCustomUrl();
      final currentUrl = await NetworkConfig.getBackendUrl();
      
      setState(() {
        _useCustomUrl = useCustom;
        _currentUrl = currentUrl;
        if (savedUrl != null) {
          _urlController.text = savedUrl;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_useCustomUrl && !NetworkConfig.isValidUrl(_urlController.text)) {
      setState(() {
        _errorMessage = 'URL invalide. Format: http://192.168.1.120:9000';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_useCustomUrl) {
        await NetworkConfig.setCustomBackendUrl(_urlController.text);
      } else {
        await NetworkConfig.resetToDefault();
      }
      
      // Effacer le cache de l'API client pour forcer la reconnexion
      NetworkConfig.clearCache();
      
      if (mounted) {
        CustomToast.success(context, 'Configuration enregistrée ! Redémarrez l\'application.');
      }
      
      await _loadSettings();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de sauvegarde: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = _useCustomUrl ? _urlController.text : _currentUrl ?? '';
      
      if (!NetworkConfig.isValidUrl(url)) {
        throw Exception('URL invalide');
      }

      // Tester la connexion avec un Dio temporaire
      final testDio = Dio(
        BaseOptions(
          baseUrl: url,
          receiveTimeout: const Duration(seconds: 5),
          connectTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await testDio.get('/');

      if (mounted) {
        if (response.statusCode == 200) {
          CustomToast.success(context, '✅ Connexion réussie au backend !');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, '❌ Échec de connexion: ${e.toString()}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Réseau'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Information actuelle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'URL Backend Actuelle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUrl ?? 'Non définie',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // URL personnalisée
                SwitchListTile(
                  title: const Text('Utiliser une URL personnalisée'),
                  subtitle: const Text(
                    'Activez pour utiliser votre propre IP backend',
                  ),
                  value: _useCustomUrl,
                  onChanged: (value) {
                    setState(() => _useCustomUrl = value);
                  },
                ),
                
                if (_useCustomUrl) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL du Backend',
                      hintText: NetworkConfig.getLocalIPHint(),
                      prefixIcon: const Icon(Icons.link),
                      border: const OutlineInputBorder(),
                      helperText: 'Format: http://IP:PORT',
                      errorText: _errorMessage,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.blue.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Comment trouver l\'IP de votre PC ?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('1. Ouvrez PowerShell/Terminal sur votre PC'),
                          Text('2. Tapez: ipconfig (Windows) ou ifconfig (Mac/Linux)'),
                          Text('3. Cherchez "IPv4 Address" ou "inet"'),
                          Text('4. Exemple: 192.168.1.120'),
                          SizedBox(height: 8),
                          Text(
                            '⚠️ Votre téléphone et PC doivent être sur le même Wi-Fi',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testConnection,
                        icon: const Icon(Icons.wifi_find),
                        label: const Text('Tester'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Sauvegarder'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Configurations rapides
                const Text(
                  'Configurations Rapides',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                _buildQuickConfig(
                  'Android Emulator',
                  NetworkConfig.defaultAndroidEmulatorUrl,
                  Icons.phone_android,
                ),
                _buildQuickConfig(
                  'PC / Web',
                  NetworkConfig.defaultWebUrl,
                  Icons.computer,
                ),
                _buildQuickConfig(
                  'iOS Simulator',
                  NetworkConfig.defaultIOSUrl,
                  Icons.phone_iphone,
                ),
              ],
            ),
    );
  }

  Widget _buildQuickConfig(String title, String url, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(url, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: () {
            setState(() {
              _useCustomUrl = true;
              _urlController.text = url;
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
