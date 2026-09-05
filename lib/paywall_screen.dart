import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'translations.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
            _selectedPackage = offerings.current!.availablePackages.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makePurchase() async {
    if (_selectedPackage == null) return;
    setState(() => _isLoading = true);
    
    try {
      final customerInfo = await Purchases.purchasePackage(_selectedPackage!);
      if (customerInfo.entitlements.all['pro']?.isActive ?? false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppText.get('success_purchase')), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // El usuario canceló el pago o hubo un error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      final customerInfo = await Purchases.restorePurchases();
      if (customerInfo.entitlements.all['pro']?.isActive ?? false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppText.get('success_restore')), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppText.get('no_restore'))),
          );
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchURL() async {
    final url = Uri.parse('https://juheag.github.io/video-compressor-flutter/privacidad.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
                    const SizedBox(height: 16),
                    Text(
                      AppText.get('paywall_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppText.get('paywall_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.indigo.shade200),
                    ),
                    const SizedBox(height: 32),
                    
                    _buildFeatureRow(Icons.block, AppText.get('feature_ads')),
                    _buildFeatureRow(Icons.high_quality, AppText.get('feature_1080p')),
                    _buildFeatureRow(Icons.speed, AppText.get('feature_support')),
                    
                    const Spacer(),

                    if (_offerings?.current != null && _offerings!.current!.availablePackages.isNotEmpty)
                      ..._offerings!.current!.availablePackages.map((package) {
                        final isSelected = _selectedPackage?.identifier == package.identifier;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPackage = package;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo.shade600 : Colors.indigo.shade800,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.amber : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      package.storeProduct.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      package.storeProduct.priceString,
                                      style: TextStyle(color: Colors.amber.shade200, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Colors.amber),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      Text(
                        AppText.get('no_plans'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),

                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      onPressed: _selectedPackage == null ? null : _makePurchase,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.indigo.shade900,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppText.get('continue_btn'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: _restorePurchases,
                          child: Text(AppText.get('restore'), style: const TextStyle(color: Colors.white70)),
                        ),
                        TextButton(
                          onPressed: _launchURL,
                          child: Text(AppText.get('terms_privacy'), style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
