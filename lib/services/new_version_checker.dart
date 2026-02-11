import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// Helper to create an HTTP client that accepts self-signed certificates.
// Use just while the certification is not updated (to be removed)
class HttpHelper {
  static http.Client getUnsafeClient() {
    final HttpClient ioHttpClient = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioHttpClient);
  }
}

class UpdateInfo {
  final String latestVersion;
  final String? downloadUrl;
  final String? notes;
  final bool isRequired;

  UpdateInfo({required this.latestVersion, this.downloadUrl, this.notes, this.isRequired = false});
}

class NewVersionChecker {
  static const String defaultEndpoint = 'https://apk.proristo.it/procassa.json';
  static String _endpoint = defaultEndpoint;
  static bool _isChecking = false;

  static void setEndpoint(String url) {
    _endpoint = url;
  }

  static Future<UpdateInfo?> _fetchLatest() async {
    final httpsUri = Uri.parse(_endpoint);
    debugPrint('Trying HTTPS: $httpsUri');

    try {
      final client = HttpHelper.getUnsafeClient();
      final httpsResponse = await client.get(httpsUri).timeout(
        const Duration(seconds: 15),
      );

      if (httpsResponse.statusCode == 200) {
        return _parseResponse(httpsResponse.body);
      }

      debugPrint('HTTPS failed with status: ${httpsResponse.statusCode}');
      return null;

    } catch (e) {
      debugPrint('HTTPS Error: $e');

      if (_endpoint.startsWith('https://')) {
        final httpUri = Uri(
          scheme: 'http',
          host: httpsUri.host,
          path: httpsUri.path,
        );

        debugPrint('Trying HTTP: $httpUri');

        try {
          final httpResponse = await http.get(httpUri).timeout(
            const Duration(seconds: 10),
          );

          if (httpResponse.statusCode == 200) {
            return _parseResponse(httpResponse.body);
          }

          debugPrint('HTTP failed with status: ${httpResponse.statusCode}');
        } catch (e2) {
          debugPrint('HTTP Error: $e2');
          debugPrint('HTTP URL used: $httpUri');
        }
      }

      return null;
    }
  }

  static UpdateInfo? _parseResponse(String responseBody) {
    try {
      if (responseBody.isEmpty) {
        debugPrint('Empty response body');
        return null;
      }

      debugPrint('Response length: ${responseBody.length} characters');

      dynamic data;
      try {
        data = jsonDecode(responseBody);
      } catch (e) {
        debugPrint('JSON decode error: $e');
        final sanitized = responseBody
            .replaceAll(RegExp(r',\s*([}\]])'), r'$1')
            .replaceAll(RegExp(r',\s*$'), '');
        try {
          data = jsonDecode(sanitized);
          debugPrint('JSON decode successful after sanitization');
        } catch (e2) {
          debugPrint('JSON decode failed even after sanitization: $e2');
          return null;
        }
      }
      
      if (data is! Map<String, dynamic>) {
        debugPrint('Invalid JSON structure: expected Map but got ${data.runtimeType}');
        return null;
      }

      String latestVersion = '0.0.0';
      bool found = false;
      
      for (final key in data.keys) {
        if (RegExp(r'^\d+(?:\.\d+)*$').hasMatch(key)) {
          debugPrint('Found version: $key');
          if (!found || _compareVersions(key, latestVersion) > 0) {
            latestVersion = key;
            found = true;
          }
        }
      }

      if (!found) {
        debugPrint('No valid version found in response');
        return null;
      }

      final versionData = data[latestVersion];
      debugPrint('Latest version data: $versionData');

      if (versionData is Map<String, dynamic>) {
        return UpdateInfo(
          latestVersion: latestVersion,
          downloadUrl: versionData['Download'] as String?,
          notes: versionData['note'] as String?,
          isRequired: versionData['required'] as bool? ?? false,
        );
      }

      return UpdateInfo(latestVersion: latestVersion, isRequired: false);

    } catch (e) {
      debugPrint('Error parsing response: $e');
      return null;
    }
  }

  static Future<void> checkForUpdates(BuildContext context, {bool manual = false}) async {
    if (_isChecking) {
      if (manual) _showSnack(context, 'Controllo già in corso');
      return;
    }
    
    _isChecking = true;
    
    try {
      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = pkg.version;
      debugPrint('Current app version: $currentVersion');
      
      if (manual) {
        _showSnack(context, 'Controllo aggiornamenti in corso...', duration: const Duration(seconds: 2));
      }

      final info = await _fetchLatest();
      
      if (info == null) {
        if (manual) {
          _showSnack(context, 'Impossibile verificare gli aggiornamenti. Controlla la connessione.');
        }
        return;
      }

      debugPrint('Latest version available: ${info.latestVersion}');
      final comparison = _compareVersions(currentVersion, info.latestVersion);
      debugPrint('Version comparison result: $comparison');
      
      if (comparison < 0) {
        await _showUpdateDialog(context, currentVersion, info);
      } else if (manual) {
        _showSnack(context, 'Hai già l\'ultima versione: $currentVersion');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_app_version', currentVersion);
      await prefs.setString('latest_app_version', info.latestVersion);
      if (info.downloadUrl != null) {
        await prefs.setString('latest_app_url', info.downloadUrl!);
      }

    } catch (e) {
      debugPrint('Error in checkForUpdates: $e');
      if (manual) {
        _showSnack(context, 'Errore durante il controllo aggiornamenti');
      }
    } finally {
      _isChecking = false;
    }
  }

  static Future<void> _showUpdateDialog(
    BuildContext context,
    String current,
    UpdateInfo info,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: _UpdateDialogContent(
            currentVersion: current,
            updateInfo: info,
          ),
        );
      },
    );
  }

  static int _compareVersions(String v1, String v2) {
    try {
      final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (var i = 0; i < v1Parts.length; i++) {
        if (v2Parts.length <= i) return 1;
        if (v1Parts[i] > v2Parts[i]) return 1;
        if (v1Parts[i] < v2Parts[i]) return -1;
      }
      return 0;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return 0;
    }
  }

  static void _showSnack(BuildContext context, String msg, {Duration duration = const Duration(seconds: 3)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      )
    );
  }

  static Future<bool> shouldBlockApp() async {
    try {
      final pkg = await PackageInfo.fromPlatform();
      final currentVersion = pkg.version;

      final info = await _fetchLatest();
      if (info == null) return false;

      final comparison = _compareVersions(currentVersion, info.latestVersion);
      return comparison < 0 && info.isRequired;
    } catch (e) {
      debugPrint('Error checking if app should be blocked: $e');
      return false;
    }
  }
}

// Modern minimalist update dialog widget
class _UpdateDialogContent extends StatefulWidget {
  final String currentVersion;
  final UpdateInfo updateInfo;

  const _UpdateDialogContent({
    required this.currentVersion,
    required this.updateInfo,
  });

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  double _downloadProgress = 0;
  bool _isDownloading = false;
  bool _showReleaseNotes = false;

  Future<void> _handleUpdate() async {
    if (widget.updateInfo.downloadUrl == null) {
      NewVersionChecker._showSnack(context, 'Nessun link di download disponibile');
      return;
    }

    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      final dio = Dio();
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };

      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/app_update.apk";

      await dio.download(
        widget.updateInfo.downloadUrl!.trim(),
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
      });

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        NewVersionChecker._showSnack(context, 'Errore nell\'apertura del file: ${result.message}');
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      debugPrint('Error in download/install process: $e');
      NewVersionChecker._showSnack(context, 'Errore durante l\'aggiornamento');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Color(0xFF0066CC);
    final surfaceColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.grey[900];
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return WillPopScope(
      onWillPop: () async => !_isDownloading,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 32,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update_rounded,
                      color:  primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.updateInfo.isRequired 
                            ? 'Aggiornamento richiesto'
                            : 'Nuova versione disponibile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Scarica la versione più recente dell\'app',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Version badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                 _buildVersionBadge(
                  label: 'Attuale',
                  version: widget.currentVersion,
                  isCurrent: true,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                _buildVersionBadge(
                  label: 'Nuova',
                  version: widget.updateInfo.latestVersion,
                  isCurrent: false,
                ),
                ],
              ),
            ),

          // Release notes toggle
          // if (widget.updateInfo.notes != null && widget.updateInfo.notes!.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          //     child: InkWell(
          //       onTap: () {
          //         setState(() {
          //           _showReleaseNotes = !_showReleaseNotes;
          //         });
          //       },
          //       borderRadius: BorderRadius.circular(12),
          //       child: Container(
          //         padding: const EdgeInsets.all(12),
          //         decoration: BoxDecoration(
          //           color: secondaryTextColor?.withOpacity(0.05),
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         // child: Row(
          //         //   children: [
          //         //     Icon(
          //         //       _showReleaseNotes
          //         //         ? Icons.arrow_drop_up_rounded
          //         //         : Icons.arrow_drop_down_rounded,
          //         //       color: primaryColor,
          //         //     ),
          //         //     const SizedBox(width: 8),
          //         //     Text(
          //         //       'Note di rilascio',
          //         //       style: TextStyle(
          //         //         fontSize: 14,
          //         //         fontWeight: FontWeight.w600,
          //         //         color: primaryColor,
          //         //       ),
          //         //     ),
          //         //   ],
          //         // ),
          //       ),
          //     ),
          //   ),

          // Release notes content
          // if (_showReleaseNotes && widget.updateInfo.notes != null && widget.updateInfo.notes!.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          //     child: Container(
          //       padding: const EdgeInsets.all(16),
          //       decoration: BoxDecoration(
          //         color: secondaryTextColor?.withOpacity(0.05),
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: Text(
          //         widget.updateInfo.notes!,
          //         style: TextStyle(
          //           fontSize: 14,
          //           color: secondaryTextColor,
          //           height: 1.5,
          //         ),
          //       ),
          //     ),
          //   ),

          // Progress bar (only visible during download)
          if (_isDownloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    // ignore: deprecated_member_use
                    backgroundColor: primaryColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    borderRadius: BorderRadius.circular(4),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}% scaricato',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildOptionalUpdateActions(),
          ),
        ],
      ),
      ),
    );
  }

Widget _buildVersionBadge({
    required String label,
    required String version,
    required bool isCurrent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.grey[50] : const Color(0xFFE0EFFD), // #e0effd background
        borderRadius: BorderRadius.circular(20), // 20px border radius
        border: Border.all(
          color: isCurrent ? Colors.grey[200]! : const Color(0xFF0066CC).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label (minimalist)
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isCurrent ? Colors.grey[600] : const Color(0xFF0066CC).withOpacity(0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          // Version number
          Text(
            version,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isCurrent ? Colors.grey[900] : const Color(0xFF0066CC), // #0066CC color
              height: 1,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRequiredUpdateActions() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isDownloading ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor:  Color(0xFF0066CC),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isDownloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Aggiorna ora',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOptionalUpdateActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isDownloading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            child: Text(
              'Ricordamelo più tardi',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isDownloading ? null : _handleUpdate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Installa',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}