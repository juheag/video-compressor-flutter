import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'paywall_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await MobileAds.instance.initialize();

  if (Platform.isIOS) {
    await Purchases.configure(PurchasesConfiguration('appl_placeholder_api_key'));
  }

  runApp(const MaterialApp(
    home: VideoCompressorScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class VideoCompressorScreen extends StatefulWidget {
  const VideoCompressorScreen({super.key});

  @override
  State<VideoCompressorScreen> createState() => _VideoCompressorScreenState();
}

class _VideoCompressorScreenState extends State<VideoCompressorScreen> {
  File? _selectedFile;
  String? _outputPath;
  bool _isCompressing = false;
  bool _isLoadingFile = false;
  String _selectedQuality = 'Equilibrada';
  bool _isPro = false;

  double? _originalSizeMb;
  double? _compressedSizeMb;
  double _progress = 0.0;

  VideoPlayerController? _videoController;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  InterstitialAd? _interstitialAd;

  final String _bannerTestId = 'ca-app-pub-3940256099942544/2934735716';
  final String _interstitialTestId = 'ca-app-pub-3940256099942544/4411468910';

  @override
  void initState() {
    super.initState();
    _checkInitialProStatus();
    _loadBanner();
    _loadInterstitial();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<void> _checkInitialProStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all['pro']?.isActive ?? false) {
        setState(() {
          _isPro = true;
          _selectedQuality = 'Alta Calidad';
          _bannerAd?.dispose();
          _bannerAd = null;
          _isBannerLoaded = false;
        });
      }
    } catch (_) {}
  }

  void _loadBanner() {
    if (_isPro) return;

    _bannerAd = BannerAd(
      adUnitId: _bannerTestId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadInterstitial() {
    if (_isPro) return;

    InterstitialAd.load(
      adUnitId: _interstitialTestId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialIfAvailable() {
    if (_isPro) return;

    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitial();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  void _openPaywall() async {
    final purchased = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const PaywallScreen(),
      ),
    );

    if (purchased == true) {
      setState(() {
        _isPro = true;
        _selectedQuality = 'Alta Calidad';
        _bannerAd?.dispose();
        _bannerAd = null;
        _isBannerLoaded = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    setState(() {
      _isLoadingFile = true;
    });

    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.video,
      );

      if (result.isNotEmpty && result.first.path != null) {
        final file = File(result.first.path!);
        final bytes = await file.length();

        await _videoController?.dispose();

        setState(() {
          _selectedFile = file;
          _outputPath = null;
          _compressedSizeMb = null;
          _progress = 0.0;
          _videoController = null;
          _originalSizeMb = bytes / (1024 * 1024);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al acceder al archivo.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFile = false;
        });
      }
    }
  }

  String _getFfmpegFlags() {
    switch (_selectedQuality) {
      case 'Alta Calidad':
        return '-c:v libx264 -crf 26 -preset fast -vf "scale=trunc(min(iw\\,1280)/2)*2:-2" -b:a 128k';
      case 'Máximo Ahorro':
        return '-c:v libx264 -crf 34 -preset fast -vf "scale=trunc(min(iw\\,640)/2)*2:-2" -b:a 64k';
      case 'Equilibrada':
      default:
        return '-c:v libx264 -crf 30 -preset fast -vf "scale=trunc(min(iw\\,960)/2)*2:-2" -b:a 96k';
    }
  }

  Future<void> _cancelCompression() async {
    await FFmpegKit.cancel();

    setState(() {
      _isCompressing = false;
      _progress = 0.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compresión cancelada')),
      );
    }
  }

  Future<void> _compressVideo() async {
    if (_selectedFile == null) return;

    await _videoController?.dispose();

    setState(() {
      _isCompressing = true;
      _progress = 0.0;
      _videoController = null;
      _outputPath = null;
    });

    final mediaInfoSession = await FFprobeKit.getMediaInformation(_selectedFile!.path);
    final mediaInformation = mediaInfoSession.getMediaInformation();
    final durationStr = mediaInformation?.getDuration();
    final totalDurationSec = double.tryParse(durationStr ?? '0') ?? 0.0;
    final totalDurationMs = totalDurationSec * 1000;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${tempDir.path}/video_comprimido_$timestamp.mp4';
    final flags = _getFfmpegFlags();

    final command = "-y -i '${_selectedFile!.path}' $flags '$outPath'";

    await FFmpegKit.executeAsync(
      command,
      (session) async {
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          final compressedFile = File(outPath);
          final bytes = await compressedFile.length();

          VideoPlayerController? controller;
          try {
            controller = VideoPlayerController.file(compressedFile);
            await controller.initialize();
            controller.setLooping(true);
            controller.play();
          } catch (_) {
            controller = null;
          }

          if (mounted) {
            setState(() {
              _outputPath = outPath;
              _compressedSizeMb = bytes / (1024 * 1024);
              _isCompressing = false;
              _progress = 1.0;
              _videoController = controller;
            });

            _showInterstitialIfAvailable();
          }
        } else if (ReturnCode.isCancel(returnCode)) {
          final partialFile = File(outPath);
          if (await partialFile.exists()) {
            await partialFile.delete();
          }

          if (mounted) {
            setState(() {
              _isCompressing = false;
              _progress = 0.0;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isCompressing = false;
              _progress = 0.0;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al procesar el video')),
            );
          }
        }
      },
      null,
      (statistics) {
        if (totalDurationMs > 0 && mounted) {
          final timeInMs = statistics.getTime();
          final calculatedProgress = (timeInMs / totalDurationMs).clamp(0.0, 1.0);

          setState(() {
            _progress = calculatedProgress;
          });
        }
      },
    );
  }

  Future<void> _shareVideo() async {
    if (_outputPath != null) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(_outputPath!)],
          text: 'Video comprimido con Videocomprime',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videocomprime'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isPro ? Icons.verified : Icons.workspace_premium,
              color: _isPro ? Colors.lightGreenAccent : Colors.amber,
            ),
            tooltip: _isPro ? 'Pro Activo' : 'Hazte Pro',
            onPressed: _openPaywall,
          ),
        ],
      ),
      bottomNavigationBar: (!_isPro && _isBannerLoaded && _bannerAd != null)
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: (_isCompressing || _isLoadingFile) ? null : _pickVideo,
              icon: _isLoadingFile
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                      ),
                    )
                  : const Icon(Icons.video_library),
              label: Text(_isLoadingFile ? 'Cargando archivo...' : 'Seleccionar Video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo.shade50,
                foregroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nivel de compresión deseado:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'Alta Calidad',
                  label: Text(_isPro ? 'Alta (1080p)' : 'Alta (1080p) 👑'),
                ),
                const ButtonSegment(value: 'Equilibrada', label: Text('Media (720p)')),
                const ButtonSegment(value: 'Máximo Ahorro', label: Text('Ahorro (480p)')),
              ],
              selected: {_selectedQuality},
              onSelectionChanged: _isCompressing
                  ? null
                  : (newSelection) {
                      final selected = newSelection.first;
                      if (selected == 'Alta Calidad' && !_isPro) {
                        _openPaywall();
                      } else {
                        setState(() {
                          _selectedQuality = selected;
                        });
                      }
                    },
            ),
            const SizedBox(height: 24),

            if (_selectedFile != null) ...[
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Archivo: ${_selectedFile!.path.split('/').last}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tamaño original: ${_originalSizeMb?.toStringAsFixed(2)} MB',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_isCompressing) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 10,
                    backgroundColor: Colors.indigo.shade100,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _progress > 0
                      ? 'Procesando: ${(_progress * 100).toInt()}%'
                      : 'Iniciando compresión...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: _cancelCompression,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text(
                    'Cancelar compresión',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: _compressVideo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Comprimir Ahora',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Selecciona un video arriba para habilitar el procesamiento',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],

            if (_outputPath != null && !_isCompressing) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      '¡Video Comprimido con Éxito!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tamaño final: ${_compressedSizeMb?.toStringAsFixed(2)} MB'),
                    if (_originalSizeMb != null && _compressedSizeMb != null)
                      Text(
                        'Ahorro: ${((1 - (_compressedSizeMb! / _originalSizeMb!)) * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    const SizedBox(height: 16),

                    if (_videoController != null && _videoController!.value.isInitialized) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          color: Colors.black,
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                VideoPlayer(_videoController!),
                                Center(
                                  child: IconButton(
                                    iconSize: 48,
                                    icon: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _videoController!.value.isPlaying
                                            ? _videoController!.pause()
                                            : _videoController!.play();
                                      });
                                    },
                                  ),
                                ),
                                VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.green,
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton.icon(
                      onPressed: _shareVideo,
                      icon: const Icon(Icons.share),
                      label: const Text('Guardar o Compartir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
