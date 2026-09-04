import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 1. MAGIC PRODUCT CARD
/// Memberikan efek 3D Parallax Tilt saat di-hover (di Web/Desktop)
/// dan efek scale memantul (bouncy) saat ditekan (di Mobile).
class MagicProductCard extends StatefulWidget {
  final String title;
  final String price;
  final String? imageUrl;
  final VoidCallback onTap;

  const MagicProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.onTap,
    this.imageUrl,
  });

  @override
  State<MagicProductCard> createState() => _MagicProductCardState();
}

class _MagicProductCardState extends State<MagicProductCard>
    with SingleTickerProviderStateMixin {
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isHovered = false;

  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    // Efek mengecil sedikit saat ditekan (memberikan kesan fisik pada UI)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _tiltX = 0.0;
        _tiltY = 0.0;
      }),
      onHover: (event) {
        if (mounted) {
          final size = context.size;
          if (size != null && size.width > 0 && size.height > 0) {
            final centerX = size.width / 2;
            final centerY = size.height / 2;
            // Hitung rotasi perspektif 3D berdasarkan posisi kursor (mouse)
            setState(() {
              _tiltX = (centerY - event.localPosition.dy) / centerY * 0.08;
              _tiltY = (event.localPosition.dx - centerX) / centerX * 0.08;
            });
          }
        }
      },
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          _pressController.forward();
        },
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          _pressController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015) // Perspektif 3D
                  ..rotateX(_isHovered ? _tiltX : 0.0)
                  ..rotateY(_isHovered ? _tiltY : 0.0),
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _isHovered
                      ? Colors.blue.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: _isHovered ? 24 : 10,
                  spreadRadius: _isHovered ? 4 : 0,
                  offset: _isHovered ? const Offset(0, 12) : const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _isHovered ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Area Gambar Produk
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                          ),
                          child: widget.imageUrl != null
                              ? Image.network(widget.imageUrl!, fit: BoxFit.cover)
                              : Icon(Icons.fastfood_rounded,
                                  size: 48, color: Colors.blue[200]),
                        ),
                      ),
                      // Area Teks Detail
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.price,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Lapisan Kilap (Glass Shimmer Highlight) saat di Hover Web
                  if (_isHovered)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.6),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.4],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 2. MAGIC HOLD-TO-PAY BUTTON
/// Tombol Checkout/Bayar yang modern. Meminta user untuk menahan (hold) tombol
/// untuk menghindari ketidaksengajaan. Terdapat animasi cairan pengisi (liquid fill)
/// dan morphing saat pembayaran sukses. Sangat memukau untuk demo presentasi.
class MagicHoldToPayButton extends StatefulWidget {
  final VoidCallback onCompleted;
  final String label;

  const MagicHoldToPayButton({
    super.key,
    required this.onCompleted,
    this.label = "Tahan untuk Bayar",
  });

  @override
  State<MagicHoldToPayButton> createState() => _MagicHoldToPayButtonState();
}

class _MagicHoldToPayButtonState extends State<MagicHoldToPayButton>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _successController;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Waktu menahan tombol
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isSuccess = true);
        HapticFeedback.heavyImpact(); // Getaran saat penuh
        _successController.forward();
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isSuccess) {
      HapticFeedback.lightImpact();
      _progressController.forward();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isSuccess) {
      _progressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      child: AnimatedBuilder(
        animation: Listenable.merge([_progressController, _successController]),
        builder: (context, child) {
          final progress = _progressController.value;
          final success = _successController.value;

          return Transform.scale(
            // Tombol sedikit mengecil saat ditekan, lalu membesar/bounce saat sukses
            scale: _isSuccess ? 1.0 + (success * 0.05) : 1.0 - (progress * 0.03),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: _isSuccess ? Colors.green : Colors.grey[200],
                boxShadow: _isSuccess
                    ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ]
                    : [
                        if (progress > 0)
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: progress * 0.3),
                            blurRadius: 15 * progress,
                            offset: Offset(0, 5 * progress),
                          )
                      ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Latar Belakang Animasi (Filling bar)
                  if (!_isSuccess)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      right: 0,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[400]!, Colors.blue[700]!],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Teks & Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSuccess)
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 32)
                      else ...[
                        Icon(
                          Icons.fingerprint,
                          color: progress > 0.4
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: progress > 0.4
                                ? Colors.white
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
