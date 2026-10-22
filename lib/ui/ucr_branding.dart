import 'package:flutter/material.dart';

// Paleta principal del Manual de Identidad Visual de la UCR.
const ucrBlue = Color(0xFF005DA4);
const ucrSky = Color(0xFF00C0F3);
const ucrYellow = Color(0xFFFFE06A);
const ucrNavy = Color(0xFF07345A);
const ucrMist = Color(0xFFF4F8FC);

class CampusMark extends StatelessWidget {
  const CampusMark({super.key, this.color = Colors.white});
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: CustomPaint(painter: _CampusMarkPainter(color)),
  );
}

class _CampusMarkPainter extends CustomPainter {
  const _CampusMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final shape = Path()
      ..moveTo(3, 8)
      ..lineTo(12, 3)
      ..lineTo(21, 8)
      ..moveTo(4, 10)
      ..lineTo(20, 10)
      ..moveTo(6, 12)
      ..lineTo(6, 18)
      ..moveTo(12, 12)
      ..lineTo(12, 18)
      ..moveTo(18, 12)
      ..lineTo(18, 18)
      ..moveTo(4, 20)
      ..lineTo(20, 20)
      ..moveTo(2, 23)
      ..lineTo(22, 23);
    canvas.drawPath(shape, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CampusMarkPainter oldDelegate) =>
      color != oldDelegate.color;
}

ThemeData campusTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(seedColor: ucrBlue, brightness: brightness).copyWith(
        primary: dark ? ucrSky : ucrBlue,
        onPrimary: dark ? ucrNavy : Colors.white,
        secondary: dark ? ucrYellow : ucrBlue,
        surface: dark ? const Color(0xFF102B40) : Colors.white,
        onSurface: dark ? const Color(0xFFEAF4FC) : const Color(0xFF142F46),
        onSurfaceVariant: dark
            ? const Color(0xFFB4C9D9)
            : const Color(0xFF536B80),
        outlineVariant: dark
            ? const Color(0xFF2E4B63)
            : const Color(0xFFD9E5EF),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0A2032) : ucrMist,
    fontFamily: 'Arial',
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF0A2032) : ucrMist,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF19374E) : const Color(0xFFF8FBFE),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

/// La firma institucional se presenta completa, sin recolorear ni deformar.
class InstitutionalShell extends StatelessWidget {
  const InstitutionalShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    child: Column(
      children: [
        Semantics(
          header: true,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: ucrSky, width: 4)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                child: LayoutBuilder(
                  builder: (context, bounds) => Row(
                    children: [
                      Image.asset(
                        'assets/branding/ucr-firma-horizontal.png',
                        width: bounds.maxWidth < 500 ? 195 : 246,
                        height: 54,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        semanticLabel: 'Universidad de Costa Rica',
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            bounds.maxWidth < 500
                                ? 'SEDE\nDEL SUR'
                                : 'SEDE DEL SUR',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: ucrBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              height: 1.4,
                            ),
                          ),
                          if (bounds.maxWidth >= 650) ...[
                            const SizedBox(height: 5),
                            const Text(
                              'Servicios para nuestra comunidad universitaria',
                              style: TextStyle(
                                color: Color(0xFF536B80),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class CampusHero extends StatelessWidget {
  const CampusHero({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 25),
    decoration: BoxDecoration(
      color: ucrBlue,
      borderRadius: BorderRadius.circular(18),
    ),
    child: LayoutBuilder(
      builder: (context, bounds) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMUNIDAD UCR · SEDE DEL SUR',
                  style: TextStyle(
                    color: Color(0xFFAEEDFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Cuidemos la UCR,\nreporte a reporte.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cada mejora construye un mejor lugar para aprender y compartir.',
                  style: TextStyle(
                    color: Color(0xFFD9F0FF),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          if (bounds.maxWidth > 580) ...[
            const SizedBox(width: 30),
            const CampusIllustration(width: 240, height: 145),
          ],
        ],
      ),
    ),
  );
}

class AccessCampusPanel extends StatelessWidget {
  const AccessCampusPanel({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: ucrBlue,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 510),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 5,
                color: ucrSky,
                margin: const EdgeInsets.only(bottom: 26),
              ),
              const Text(
                'NUESTRA UNIVERSIDAD, NUESTRO COMPROMISO',
                style: TextStyle(
                  color: Color(0xFFAEEDFF),
                  fontSize: 10,
                  letterSpacing: 1.7,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Un mejor lugar\npara aprender.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  height: 1.12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cuidemos los espacios que compartimos en la Universidad de Costa Rica.',
                style: TextStyle(
                  color: Color(0xFFD9F0FF),
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: CampusIllustration(width: 310, height: 188)),
              const SizedBox(height: 26),
              for (final item in [
                (Icons.add_task, 'Reporta lo que necesita atención'),
                (Icons.route_outlined, 'Sigue el avance de tu solicitud'),
                (Icons.verified_outlined, 'Construyamos un campus mejor'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Icon(item.$1, color: ucrYellow, size: 21),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ilustración original del campus; no reproduce ni modifica el escudo UCR.
class CampusIllustration extends StatelessWidget {
  const CampusIllustration({super.key, this.width = 280, this.height = 170});
  final double width, height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _CampusPainter()),
    ),
  );
}

class _CampusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 170);
    final paint = Paint();
    canvas.drawCircle(const Offset(210, 51), 33, paint..color = ucrYellow);
    canvas.drawPath(
      Path()
        ..moveTo(6, 135)
        ..lineTo(84, 44)
        ..lineTo(156, 135)
        ..close(),
      paint..color = ucrSky.withValues(alpha: .3),
    );
    canvas.drawPath(
      Path()
        ..moveTo(93, 135)
        ..lineTo(164, 66)
        ..lineTo(235, 135)
        ..close(),
      paint..color = ucrSky.withValues(alpha: .45),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(59, 80, 156, 65),
        const Radius.circular(2),
      ),
      paint..color = const Color(0xFFE9F7FE),
    );
    canvas.drawRect(const Rect.fromLTWH(52, 75, 170, 8), paint..color = ucrSky);
    canvas.drawRect(
      const Rect.fromLTWH(68, 91, 138, 7),
      paint..color = ucrBlue.withValues(alpha: .18),
    );
    for (final x in [70.0, 94.0, 118.0, 154.0, 178.0]) {
      canvas.drawRect(Rect.fromLTWH(x, 108, 13, 20), paint..color = ucrBlue);
    }
    canvas.drawRect(
      const Rect.fromLTWH(133, 109, 13, 36),
      paint..color = ucrNavy,
    );
    canvas.drawRect(
      const Rect.fromLTWH(45, 145, 185, 4),
      paint..color = ucrSky,
    );
    for (final x in [26.0, 246.0]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 2, 117, 4, 30),
        paint..color = const Color(0xFFD9F0FF),
      );
      canvas.drawCircle(Offset(x, 110), 17, paint..color = ucrSky);
      canvas.drawCircle(
        Offset(x - 4, 99),
        12,
        paint..color = const Color(0xFF7BDFFF),
      );
    }
    canvas.drawLine(
      const Offset(7, 153),
      const Offset(270, 153),
      paint
        ..color = const Color(0xFF9FE4F7)
        ..strokeWidth = 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
