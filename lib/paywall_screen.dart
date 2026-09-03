import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 0; // 0: Anual, 1: Vitalicio
  bool _isLoadingOfferings = true;
  bool _isProcessingPurchase = false;

  Package? _annualPackage;
  Package? _lifetimePackage;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        final available = offerings.current!.availablePackages;

        for (var package in available) {
          if (package.packageType == PackageType.annual) {
            _annualPackage = package;
          } else if (package.packageType == PackageType.lifetime) {
            _lifetimePackage = package;
          }
        }
      }
    } catch (_) {
      // Si aún no hay conexión con RevenueCat, se mantienen los valores locales por defecto
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOfferings = false;
        });
      }
    }
  }

  Future<void> _makePurchase() async {
    final packageToBuy = _selectedPlan == 0 ? _annualPackage : _lifetimePackage;

    setState(() {
      _isProcessingPurchase = true;
    });

    try {
      if (packageToBuy != null) {
        final purchaseResult = await Purchases.purchase(
          PurchaseParams.package(packageToBuy),
        );
        final isProActive = purchaseResult.customerInfo.entitlements.all['pro']?.isActive ?? false;

        if (isProActive && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('¡Bienvenido a Videocomprime Pro!'),
            ),
          );
          Navigator.of(context).pop(true);
          return;
        }
      } else {
        // Modo simulado para pruebas locales antes de conectar la tienda
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Compra simulada con éxito (Modo local)'),
            ),
          );
          Navigator.of(context).pop(true);
          return;
        }
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error en la transacción: ${e.message}'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPurchase = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isProcessingPurchase = true;
    });

    try {
      final customerInfo = await Purchases.restorePurchases();
      final isProActive = customerInfo.entitlements.all['pro']?.isActive ?? false;

      if (mounted) {
        if (isProActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('Tus compras anteriores fueron restauradas con éxito.'),
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron suscripciones activas asociadas a tu cuenta.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No fue posible conectar con la tienda para restaurar.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPurchase = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final annualPriceString = _annualPackage?.storeProduct.priceString ?? '\$9.99 USD / año';
    final lifetimePriceString = _lifetimePackage?.storeProduct.priceString ?? '\$19.99 USD';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54, size: 28),
          onPressed: _isProcessingPurchase ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 56,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Desbloquea Videocomprime Pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Obtén la máxima calidad de exportación y procesa videos sin límites ni publicidad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 28),

              _buildBenefitRow(
                icon: Icons.high_quality_rounded,
                title: 'Exportación Full HD (1080p)',
                subtitle: 'Conserva el máximo detalle en tus tomas.',
              ),
              const SizedBox(height: 14),
              _buildBenefitRow(
                icon: Icons.block_rounded,
                title: 'Cero Publicidad',
                subtitle: 'Disfruta de una interfaz limpia y sin interrupciones.',
              ),
              const SizedBox(height: 14),
              _buildBenefitRow(
                icon: Icons.all_inclusive_rounded,
                title: 'Duración Ilimitada',
                subtitle: 'Comprime videos largos de cualquier peso.',
              ),
              const SizedBox(height: 28),

              _buildPlanCard(
                index: 0,
                title: 'Plan Anual',
                price: annualPriceString,
                detail: 'Facturación anual renovable automáticamente',
                badgeText: 'MÁS POPULAR',
              ),
              const SizedBox(height: 12),
              _buildPlanCard(
                index: 1,
                title: 'Acceso de por Vida',
                price: lifetimePriceString,
                detail: 'Un solo pago para siempre',
                badgeText: null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: (_isProcessingPurchase || _isLoadingOfferings) ? null : _makePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isProcessingPurchase
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Continuar',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _isProcessingPurchase ? null : _restorePurchases,
                    child: const Text(
                      'Restaurar compras',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Términos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Privacidad',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.indigo, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    required String detail,
    required String? badgeText,
  }) {
    final isSelected = _selectedPlan == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo.shade50.withValues(alpha: 0.5) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.indigo : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? Colors.indigo : Colors.grey.shade400,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        detail,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: -10,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
