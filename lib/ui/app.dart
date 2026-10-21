import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../domain/models.dart';
import '../domain/incident_policy.dart';
import '../domain/dashboard_metrics.dart';
import '../state/app_state.dart';

const teal = Color(0xFF087F6D);
const navy = Color(0xFF102E2A);
const emulatorMode = bool.fromEnvironment('USE_EMULATORS');
const storageReady = bool.fromEnvironment(
  'STORAGE_ENABLED',
  defaultValue: false,
);

ThemeData campusTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: teal, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF12201F)
        : const Color(0xFFF4F7F5),
    fontFamily: 'Arial',
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF12201F) : const Color(0xFFF4F7F5),
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF1D302D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF233B36) : const Color(0xFFF8FAF9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: teal,
        foregroundColor: Colors.white,
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
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .5),
    ),
  );
}

String date(DateTime? value) => value == null
    ? 'Sincronizando…'
    : DateFormat('dd MMM yyyy · HH:mm', 'es').format(value.toLocal());
void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
Widget gap([double height = 20]) => SizedBox(height: height);
Text title(String text, [double size = 27]) => Text(
  text,
  style: TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w700,
    letterSpacing: -.7,
  ),
);

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.isAuthenticated) return const Workspace();
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.user != null && auth.profile == null) {
      return Scaffold(
        body: Center(
          child: SizedBox(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_outlined, size: 50),
                  gap(),
                  title('No se pudo cargar tu perfil', 22),
                  gap(),
                  Text(
                    auth.error ??
                        'La cuenta no tiene un perfil de CampusFix. Contacta al administrador.',
                  ),
                  gap(),
                  FilledButton(
                    onPressed: auth.logout,
                    child: const Text('Volver al acceso'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const AccessScreen();
  }
}

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key});
  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController();
  bool register = false, obscure = true;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final login = Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(wide ? 64 : 26),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Brand(),
                gap(55),
                Text(
                  register
                      ? 'UN CAMPUS MEJOR, JUNTOS'
                      : 'TU CAMPUS, EN BUENAS MANOS',
                  style: const TextStyle(
                    color: teal,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                  ),
                ),
                gap(15),
                title(register ? 'Crea tu cuenta' : 'Bienvenido de nuevo', 34),
                gap(12),
                Text(
                  register
                      ? 'Reporta, consulta y sigue cada solicitud desde un solo lugar.'
                      : 'Ingresa para dar seguimiento a lo que importa.',
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
                gap(32),
                if (register) ...[
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Escribe al menos 2 caracteres.'
                        : null,
                    maxLength: 100,
                  ),
                  gap(10),
                ],
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) =>
                      !RegExp(
                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                      ).hasMatch(v?.trim() ?? '')
                      ? 'Escribe un correo válido.'
                      : null,
                ),
                gap(),
                TextFormField(
                  controller: password,
                  obscureText: obscure,
                  autofillHints: [
                    register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: obscure
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: () => setState(() => obscure = !obscure),
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) => (v?.length ?? 0) < (register ? 8 : 1)
                      ? (register
                            ? 'Usa al menos 8 caracteres.'
                            : 'Escribe tu contraseña.')
                      : null,
                  onFieldSubmitted: (_) => submit(),
                ),
                if (!register)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: reset,
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                if (auth.error != null) ...[gap(12), ErrorNotice(auth.error!)],
                gap(22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: auth.isLoading ? null : submit,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      register ? 'Crear cuenta' : 'Ingresar a CampusFix',
                    ),
                  ),
                ),
                gap(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      register
                          ? '¿Ya tienes cuenta?'
                          : '¿Es tu primera visita?',
                    ),
                    TextButton(
                      onPressed: () {
                        auth.clearError();
                        setState(() => register = !register);
                      },
                      child: Text(register ? 'Inicia sesión' : 'Regístrate'),
                    ),
                  ],
                ),
                gap(35),
                const Text(
                  'UNIVERSIDAD DE COSTA RICA · SEDE DEL SUR',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.2),
                ),
                if (emulatorMode) ...[
                  gap(),
                  const Notice(
                    'Entorno local: usa las cuentas del manual. Los datos pertenecen a los emuladores.',
                    icon: Icons.science_outlined,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Scaffold(
      body: Row(
        children: [
          Expanded(child: login),
          if (wide)
            Expanded(
              child: Container(
                color: navy,
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'CUIDAMOS NUESTRO CAMPUS',
                          style: TextStyle(
                            color: Color(0xFF9AE3C8),
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      gap(35),
                      const Text(
                        'Pequeños reportes.\nGrandes mejoras.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 49,
                          height: 1.1,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -2,
                        ),
                      ),
                      gap(28),
                      const Text(
                        'Un espacio para transformar las incidencias\nen soluciones que se pueden seguir.',
                        style: TextStyle(
                          color: Color(0xFFBCD1C9),
                          fontSize: 17,
                          height: 1.7,
                        ),
                      ),
                      gap(45),
                      for (final item in [
                        (
                          Icons.add_task,
                          'Reporta con claridad',
                          'Ubicación, categoría y evidencia.',
                        ),
                        (
                          Icons.route_outlined,
                          'Sigue cada paso',
                          'Responsables e historial en un solo lugar.',
                        ),
                        (
                          Icons.verified_outlined,
                          'Cierra con confianza',
                          'Cada solución deja una huella.',
                        ),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.$1,
                                  color: const Color(0xFFA6E7CF),
                                ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.$2,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    gap(5),
                                    Text(
                                      item.$3,
                                      style: const TextStyle(
                                        color: Color(0xFFBCD1C9),
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
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
        ],
      ),
    );
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    if (register) {
      await auth.register(name.text.trim(), email.text.trim(), password.text);
    } else {
      await auth.login(email.text.trim(), password.text);
    }
  }

  Future<void> reset() async {
    if (!email.text.contains('@')) {
      toast(context, 'Primero escribe tu correo electrónico.');
      return;
    }
    final auth = context.read<AuthState>();
    final ok = await auth.resetPassword(email.text.trim());
    if (mounted) {
      toast(
        context,
        ok
            ? 'Si existe la cuenta, recibirás las instrucciones de recuperación.'
            : auth.error ?? 'No se pudo enviar el correo.',
      );
    }
  }
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 41,
        height: 41,
        decoration: BoxDecoration(
          color: light ? const Color(0xFF99DABD) : teal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.home_repair_service_outlined,
          color: light ? navy : Colors.white,
          size: 23,
        ),
      ),
      const SizedBox(width: 12),
      Text(
        'campusfix',
        style: TextStyle(
          fontSize: 25,
          letterSpacing: -.9,
          fontWeight: FontWeight.w800,
          color: light ? Colors.white : null,
        ),
      ),
    ],
  );
}

class Workspace extends StatefulWidget {
  const Workspace({super.key});
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  int page = 0;
  String? selected;
  void open(String id) => setState(() {
    selected = id;
    page = 1;
  });
  void navigate(int value) => setState(() {
    selected = null;
    page = value;
  });
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final profile = auth.profile!;
    final state = context.watch<IncidentState>();
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final menu = Container(
      width: 244,
      color: navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Brand(light: true),
              gap(10),
              const Padding(
                padding: EdgeInsets.only(left: 53),
                child: Text(
                  'SEDE DEL SUR',
                  style: TextStyle(
                    color: Color(0xFF9EBDB2),
                    fontSize: 9,
                    letterSpacing: 1.9,
                  ),
                ),
              ),
              gap(45),
              const Text(
                'ESPACIO DE TRABAJO',
                style: TextStyle(
                  color: Color(0xFF86A99D),
                  fontSize: 9,
                  letterSpacing: 1.4,
                ),
              ),
              gap(18),
              nav(0, Icons.space_dashboard_outlined, 'Vista general'),
              nav(
                1,
                Icons.inbox_outlined,
                profile.role == UserRole.reporter
                    ? 'Mis incidencias'
                    : profile.role == UserRole.technician
                    ? 'Mi trabajo'
                    : 'Incidencias',
              ),
              if (profile.role == UserRole.admin) ...[
                nav(2, Icons.bar_chart_outlined, 'Indicadores'),
                gap(25),
                const Text(
                  'ADMINISTRACIÓN',
                  style: TextStyle(
                    color: Color(0xFF86A99D),
                    fontSize: 9,
                    letterSpacing: 1.4,
                  ),
                ),
                gap(16),
                nav(3, Icons.category_outlined, 'Categorías'),
                nav(4, Icons.people_outline, 'Usuarios y roles'),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4138),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.eco_outlined, color: Color(0xFFB9E8C7)),
                    gap(10),
                    const Text(
                      'El campus lo cuidamos\nentre todos.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    gap(10),
                    Text(
                      profile.role.label,
                      style: const TextStyle(
                        color: Color(0xFFB9D4C9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              gap(24),
              InkWell(
                onTap: () => navigate(5),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFFCCE5D8),
                      foregroundColor: navy,
                      child: Text(
                        profile.name.isEmpty
                            ? 'U'
                            : profile.name[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          gap(3),
                          const Text(
                            'Mi perfil',
                            style: TextStyle(
                              color: Color(0xFFADCBBE),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFFADCBBE)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final selectedIncident = selected == null
        ? null
        : state.incidents.where((x) => x.id == selected).firstOrNull;
    final content = selected != null
        ? selectedIncident == null
              ? Column(
                  children: [
                    TextButton.icon(
                      onPressed: () => setState(() => selected = null),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver a incidencias'),
                    ),
                    const EmptyState(
                      icon: Icons.inbox_outlined,
                      heading: 'La incidencia no está disponible',
                      text:
                          'Puede estar sincronizándose o haber cambiado tu acceso al caso.',
                    ),
                  ],
                )
              : IncidentDetail(
                  key: ValueKey(selectedIncident.id),
                  incident: selectedIncident,
                  back: () => setState(() => selected = null),
                )
        : switch (page) {
            0 => Overview(open: open, all: () => navigate(1)),
            1 => IncidentList(open: open),
            2 => const Indicators(),
            3 => const CategoryAdmin(),
            4 => const UserAdmin(),
            _ => const ProfileScreen(),
          };
    return Scaffold(
      drawer: wide ? null : Drawer(width: 244, child: menu),
      appBar: wide
          ? null
          : AppBar(
              title: const Brand(),
              actions: [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: auth.logout,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
      body: Row(
        children: [
          if (wide) menu,
          Expanded(
            child: Column(
              children: [
                if (wide)
                  Container(
                    height: 81,
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'CampusFix',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 13),
                          child: Text('/'),
                        ),
                        Text(
                          [
                            'Vista general',
                            'Incidencias',
                            'Indicadores',
                            'Categorías',
                            'Usuarios y roles',
                            'Mi perfil',
                          ][page],
                        ),
                        const Spacer(),
                        const Icon(Icons.circle, color: teal, size: 7),
                        const SizedBox(width: 8),
                        Text(
                          emulatorMode
                              ? 'Emuladores locales'
                              : 'Firebase conectado',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          tooltip: 'Cambiar tema',
                          onPressed: context.read<ThemeState>().toggle,
                          icon: const Icon(Icons.contrast),
                        ),
                        IconButton(
                          tooltip: 'Cerrar sesión',
                          onPressed: auth.logout,
                          icon: const Icon(Icons.logout, size: 21),
                        ),
                      ],
                    ),
                  ),
                if (emulatorMode)
                  const Notice(
                    'Entorno de pruebas local · Authentication, Firestore y Storage emulados.',
                    icon: Icons.science_outlined,
                  ),
                if (state.isLoading)
                  const LinearProgressIndicator(minHeight: 2),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: ErrorNotice(state.error!, onClose: state.clearError),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(wide ? 36 : 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget nav(int index, IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Builder(
      builder: (ctx) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        selected: page == index,
        selectedTileColor: const Color(0xFF245347),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        leading: Icon(
          icon,
          color: page == index
              ? const Color(0xFFB5E8CD)
              : const Color(0xFF9EBEB0),
          size: 21,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: page == index ? Colors.white : const Color(0xFFBCD1C7),
            fontSize: 13,
            fontWeight: page == index ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (Scaffold.maybeOf(ctx)?.isDrawerOpen == true) Navigator.pop(ctx);
          navigate(index);
        },
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.heading, this.subtitle, {super.key, this.action});
  final String heading, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, bounds) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title(heading),
                  gap(8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (bounds.maxWidth > 650 && action != null) ...[
              const SizedBox(width: 20),
              action!,
            ],
          ],
        ),
        if (bounds.maxWidth <= 650 && action != null) ...[gap(), action!],
      ],
    ),
  );
}

class Overview extends StatelessWidget {
  const Overview({super.key, required this.open, required this.all});
  final ValueChanged<String> open;
  final VoidCallback all;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentState>(),
        auth = context.watch<AuthState>();
    final profile = auth.profile!;
    final metrics = context.watch<DashboardState>().metrics;
    final latest = state.incidents.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          'Un mejor campus empieza aquí.',
          'Hola, ${profile.name.split(' ').first}. Este es el estado de tus servicios.',
          action: profile.role == UserRole.technician
              ? null
              : FilledButton.icon(
                  onPressed: () => createIncident(context, open),
                  icon: const Icon(Icons.add, size: 19),
                  label: const Text('Nueva incidencia'),
                ),
        ),
        gap(28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CADA REPORTE CUENTA',
                      style: TextStyle(
                        color: Color(0xFFB8E1C8),
                        fontSize: 10,
                        letterSpacing: 1.7,
                      ),
                    ),
                    gap(13),
                    const Text(
                      'De una incidencia a una solución.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.5,
                      ),
                    ),
                    gap(9),
                    const Text(
                      'Consulta avances, conoce al responsable y sigue cada paso.',
                      style: TextStyle(
                        color: Color(0xFFB4CFC2),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (MediaQuery.sizeOf(context).width > 700)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: Icon(
                    Icons.handyman_outlined,
                    color: Color(0xFF9ECDB3),
                    size: 68,
                  ),
                ),
            ],
          ),
        ),
        gap(24),
        MetricsGrid(metrics: metrics),
        gap(28),
        LayoutBuilder(
          builder: (context, box) {
            final categories = CategoryChart(metrics: metrics);
            final summary = StatusSummary(metrics: metrics);
            return box.maxWidth > 850
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: categories),
                      const SizedBox(width: 22),
                      Expanded(flex: 4, child: summary),
                    ],
                  )
                : Column(children: [categories, gap(), summary]);
          },
        ),
        gap(28),
        Row(
          children: [
            title('Actividad reciente', 19),
            const Spacer(),
            TextButton(onPressed: all, child: const Text('Ver todas →')),
          ],
        ),
        gap(12),
        if (latest.isEmpty)
          const EmptyState(
            icon: Icons.inbox_outlined,
            heading: 'Todavía no hay incidencias',
            text: 'Los reportes que puedas consultar aparecerán aquí.',
          )
        else
          IncidentTable(items: latest, open: open),
        gap(24),
        const Text(
          'CampusFix · Universidad de Costa Rica, Sede del Sur',
          style: TextStyle(fontSize: 11, color: Color(0xFF75867D)),
        ),
      ],
    );
  }
}

class MetricsGrid extends StatelessWidget {
  const MetricsGrid({super.key, required this.metrics});
  final DashboardMetrics metrics;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final data = [
        (
          Icons.layers_outlined,
          'Total de reportes',
          metrics.total,
          const Color(0xFF597E76),
        ),
        (
          Icons.pending_actions_outlined,
          'Abiertas',
          metrics.open,
          const Color(0xFFC88B29),
        ),
        (
          Icons.engineering_outlined,
          'En atención',
          metrics.byStatus[IncidentStatus.inProgress] ?? 0,
          const Color(0xFF4C85A8),
        ),
        (Icons.task_alt_outlined, 'Resueltas', metrics.resolved, teal),
        (
          Icons.inventory_2_outlined,
          'Cerradas',
          metrics.closed,
          const Color(0xFF8879A8),
        ),
      ];
      final columns = box.maxWidth > 1050
          ? 5
          : box.maxWidth > 650
          ? 3
          : 2;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: data
            .map(
              (x) => SizedBox(
                width: (box.maxWidth - 14 * (columns - 1)) / columns,
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(x.$1, size: 20, color: x.$4),
                          const Spacer(),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: x.$4,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      gap(18),
                      Text(
                        '${x.$3}',
                        style: const TextStyle(
                          fontSize: 33,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      gap(6),
                      Text(
                        x.$2,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(23), child: child),
  );
}

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key, required this.metrics});
  final DashboardMetrics metrics;
  @override
  Widget build(BuildContext context) {
    final rows = metrics.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maximum = rows.isEmpty ? 1 : rows.first.value;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title('Incidencias por categoría', 18),
          gap(6),
          const Text(
            'Dónde concentramos los esfuerzos',
            style: TextStyle(fontSize: 12, color: Color(0xFF7C8980)),
          ),
          gap(24),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text('El resumen aparecerá con el primer reporte.'),
            ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.key,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${row.value}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  gap(9),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: row.value / maximum,
                      minHeight: 9,
                      color: teal,
                      backgroundColor: teal.withValues(alpha: .08),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class StatusSummary extends StatelessWidget {
  const StatusSummary({super.key, required this.metrics});
  final DashboardMetrics metrics;
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('Pulso operativo', 18),
        gap(6),
        const Text(
          'El trabajo, paso a paso',
          style: TextStyle(fontSize: 12, color: Color(0xFF7C8980)),
        ),
        gap(20),
        for (final status in [
          IncidentStatus.reported,
          IncidentStatus.inReview,
          IncidentStatus.assigned,
          IncidentStatus.inProgress,
          IncidentStatus.resolved,
          IncidentStatus.closed,
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor(status),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.label,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  '${metrics.byStatus[status] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class IncidentList extends StatelessWidget {
  const IncidentList({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentState>();
    final role = context.watch<AuthState>().profile!.role;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          role == UserRole.reporter
              ? 'Mis incidencias'
              : role == UserRole.technician
              ? 'Mi trabajo'
              : 'Incidencias',
          'Cada reporte tiene una historia. Encuentra y sigue la tuya.',
          action: role == UserRole.technician
              ? null
              : FilledButton.icon(
                  onPressed: () => createIncident(context, open),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva incidencia'),
                ),
        ),
        gap(28),
        Panel(
          child: Column(
            children: [
              TextFormField(
                key: ValueKey('search-${state.query.isEmpty}'),
                initialValue: state.query,
                onChanged: state.setQuery,
                decoration: const InputDecoration(
                  hintText:
                      'Buscar por consecutivo, título, ubicación o categoría…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              gap(14),
              LayoutBuilder(
                builder: (c, box) {
                  final width = box.maxWidth > 850
                      ? (box.maxWidth - 36) / 4
                      : box.maxWidth > 550
                      ? (box.maxWidth - 12) / 2
                      : box.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<IncidentStatus>(
                          key: ValueKey(state.statusFilter),
                          initialValue: state.statusFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos los estados'),
                            ),
                            ...IncidentStatus.values.map(
                              (x) => DropdownMenuItem(
                                value: x,
                                child: Text(x.label),
                              ),
                            ),
                          ],
                          onChanged: state.setStatusFilter,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<IncidentPriority>(
                          key: ValueKey(state.priorityFilter),
                          initialValue: state.priorityFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Prioridad',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todas las prioridades'),
                            ),
                            ...IncidentPriority.values.map(
                              (x) => DropdownMenuItem(
                                value: x,
                                child: Text(x.label),
                              ),
                            ),
                          ],
                          onChanged: state.setPriorityFilter,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('category-${state.categoryFilter}'),
                          initialValue: state.categoryFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todas las categorías'),
                            ),
                            ...state.categories.map(
                              (x) => DropdownMenuItem(
                                value: x.id,
                                child: Text(
                                  x.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: state.setCategoryFilter,
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('assignee-${state.assigneeFilter}'),
                          initialValue: state.assigneeFilter,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Responsable',
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Todos los responsables'),
                            ),
                            const DropdownMenuItem(
                              value: '',
                              child: Text('Sin asignar'),
                            ),
                            ...{
                              for (final x in state.incidents.where(
                                (x) => x.assignedTo != null,
                              ))
                                x.assignedTo!: x.assignedName ?? 'Técnico',
                            }.entries.map(
                              (x) => DropdownMenuItem(
                                value: x.key,
                                child: Text(
                                  x.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: state.setAssigneeFilter,
                        ),
                      ),
                    ],
                  );
                },
              ),
              gap(10),
              Row(
                children: [
                  Text(
                    '${state.filteredIncidents.length} resultados',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: state.clearFilters,
                    icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                    label: const Text('Limpiar filtros'),
                  ),
                ],
              ),
            ],
          ),
        ),
        gap(22),
        if (state.filteredIncidents.isEmpty)
          const EmptyState(
            icon: Icons.search_off_outlined,
            heading: 'No hay resultados',
            text: 'Cambia los filtros o registra una nueva incidencia.',
          )
        else
          IncidentTable(items: state.filteredIncidents, open: open),
      ],
    );
  }
}

Color statusColor(IncidentStatus status) => switch (status) {
  IncidentStatus.inProgress => const Color(0xFF4F82B2),
  IncidentStatus.resolved || IncidentStatus.closed => teal,
  IncidentStatus.rejected ||
  IncidentStatus.cancelled => const Color(0xFFB15A5A),
  IncidentStatus.reopened => const Color(0xFF8B6CA7),
  _ => const Color(0xFFB9862F),
};

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final IncidentStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: statusColor(status).withValues(alpha: .11),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      status.label,
      style: TextStyle(
        color: statusColor(status),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge(this.priority, {super.key});
  final IncidentPriority priority;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.flag_outlined,
        size: 15,
        color: priority.index >= 2
            ? const Color(0xFFC1734A)
            : const Color(0xFF7B9286),
      ),
      const SizedBox(width: 4),
      Text(priority.label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class IncidentTable extends StatelessWidget {
  const IncidentTable({super.key, required this.items, required this.open});
  final List<Incident> items;
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth < 760) {
          return Column(
            children: items
                .map(
                  (x) => InkWell(
                    onTap: () => open(x.id),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  x.number,
                                  style: const TextStyle(
                                    color: teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              StatusBadge(x.status),
                            ],
                          ),
                          gap(10),
                          Text(
                            x.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                          gap(7),
                          Text(
                            '${x.categoryName} · ${x.location}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          gap(12),
                          PriorityBadge(x.priority),
                          const Divider(height: 1),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 52,
            dataRowMinHeight: 76,
            dataRowMaxHeight: 88,
            horizontalMargin: 20,
            columnSpacing: 18,
            showCheckboxColumn: false,
            columns: const [
              DataColumn(
                label: Text(
                  'INCIDENCIA',
                  style: TextStyle(fontSize: 10, letterSpacing: 1),
                ),
              ),
              DataColumn(
                label: Text(
                  'CATEGORÍA',
                  style: TextStyle(fontSize: 10, letterSpacing: 1),
                ),
              ),
              DataColumn(
                label: Text(
                  'PRIORIDAD',
                  style: TextStyle(fontSize: 10, letterSpacing: 1),
                ),
              ),
              DataColumn(
                label: Text(
                  'ESTADO',
                  style: TextStyle(fontSize: 10, letterSpacing: 1),
                ),
              ),
            ],
            rows: items
                .map(
                  (x) => DataRow(
                    onSelectChanged: (_) => open(x.id),
                    cells: [
                      DataCell(
                        SizedBox(
                          width: box.maxWidth * .36,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                x.number,
                                style: const TextStyle(
                                  color: teal,
                                  fontSize: 10,
                                ),
                              ),
                              gap(7),
                              Text(
                                x.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              gap(5),
                              Text(
                                x.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF7F8E84),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          x.categoryName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(PriorityBadge(x.priority)),
                      DataCell(StatusBadge(x.status)),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      },
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.text,
  });
  final IconData icon;
  final String heading, text;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 37),
        child: Column(
          children: [
            Icon(icon, color: teal, size: 38),
            gap(16),
            title(heading, 19),
            gap(10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.6),
            ),
          ],
        ),
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: teal.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, color: teal, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5)),
        ),
      ],
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.text, {super.key, this.onClose});
  final String text;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5)),
        ),
        if (onClose != null)
          IconButton(
            tooltip: 'Cerrar aviso',
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 17),
          ),
      ],
    ),
  );
}

Future<void> createIncident(
  BuildContext context,
  ValueChanged<String> open,
) async {
  final id = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const CreateIncidentDialog(),
  );
  if (id != null) open(id);
}

class CreateIncidentDialog extends StatefulWidget {
  const CreateIncidentDialog({super.key});
  @override
  State<CreateIncidentDialog> createState() => _CreateIncidentDialogState();
}

class _CreateIncidentDialogState extends State<CreateIncidentDialog> {
  final form = GlobalKey<FormState>();
  final heading = TextEditingController(),
      description = TextEditingController(),
      location = TextEditingController();
  String? category;
  IncidentPriority priority = IncidentPriority.medium;
  bool busy = false;
  @override
  void dispose() {
    heading.dispose();
    description.dispose();
    location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentState>();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 630),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: title('Nueva incidencia', 25)),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: busy ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                gap(8),
                const Text(
                  'Cuéntanos qué sucede. Tu reporte inicia en estado Reportada.',
                  style: TextStyle(height: 1.6),
                ),
                gap(24),
                TextFormField(
                  controller: heading,
                  decoration: const InputDecoration(
                    labelText: 'Título del reporte',
                    hintText: 'Ej. Fuga de agua en el laboratorio',
                  ),
                  maxLength: 140,
                  validator: (v) => (v?.trim().length ?? 0) < 5
                      ? 'Escribe un título de al menos 5 caracteres.'
                      : null,
                ),
                gap(8),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  maxLength: 4000,
                  validator: (v) => (v?.trim().length ?? 0) < 15
                      ? 'Describe el problema con al menos 15 caracteres.'
                      : null,
                ),
                gap(8),
                TextFormField(
                  controller: location,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación exacta',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  maxLength: 200,
                  validator: (v) => (v?.trim().length ?? 0) < 3
                      ? 'Indica el edificio, aula o zona.'
                      : null,
                ),
                gap(8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: state.activeCategories
                      .map(
                        (x) =>
                            DropdownMenuItem(value: x.id, child: Text(x.name)),
                      )
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => category = v),
                  validator: (v) =>
                      v == null ? 'Selecciona una categoría.' : null,
                ),
                gap(),
                DropdownButtonFormField<IncidentPriority>(
                  initialValue: priority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad sugerida',
                  ),
                  items: IncidentPriority.values
                      .map(
                        (x) => DropdownMenuItem(value: x, child: Text(x.label)),
                      )
                      .toList(),
                  onChanged: busy ? null : (v) => setState(() => priority = v!),
                ),
                gap(),
                if (state.activeCategories.isEmpty)
                  const ErrorNotice(
                    'No hay categorías activas. El administrador debe crear al menos una en Categorías.',
                  ),
                const Notice(
                  'Después de registrar el reporte podrás adjuntar fotografías desde el detalle.',
                ),
                if (state.error != null) ...[gap(), ErrorNotice(state.error!)],
                gap(24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_task),
                    label: Text(busy ? 'Registrando…' : 'Registrar incidencia'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    final id = await context.read<IncidentState>().createIncident(
      title: heading.text,
      description: description.text,
      categoryId: category!,
      location: location.text,
      priority: priority,
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (id != null) Navigator.pop(context, id);
  }
}

class IncidentDetail extends StatefulWidget {
  const IncidentDetail({super.key, required this.incident, required this.back});
  final Incident incident;
  final VoidCallback back;
  @override
  State<IncidentDetail> createState() => _IncidentDetailState();
}

class _IncidentDetailState extends State<IncidentDetail> {
  final comment = TextEditingController();
  late Stream<List<IncidentEvent>> events;
  late Stream<List<IncidentComment>> comments;
  late Stream<List<IncidentEvidence>> evidence;
  @override
  void initState() {
    super.initState();
    bind();
  }

  void bind() {
    final state = context.read<IncidentState>();
    events = state.eventsFor(widget.incident.id);
    comments = state.commentsFor(widget.incident.id);
    evidence = state.evidenceFor(widget.incident.id);
  }

  @override
  void didUpdateWidget(IncidentDetail old) {
    super.didUpdateWidget(old);
    if (old.incident.id != widget.incident.id) bind();
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.incident;
    final state = context.watch<IncidentState>();
    final actor = context.watch<AuthState>().profile!;
    final allowed = IncidentPolicy.allowedTransitions(item, actor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: widget.back,
          icon: const Icon(Icons.arrow_back, size: 17),
          label: const Text('Volver a incidencias'),
        ),
        gap(14),
        Text(
          item.number,
          style: const TextStyle(
            color: teal,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        gap(9),
        title(item.title, 28),
        gap(15),
        Wrap(
          spacing: 15,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StatusBadge(item.status),
            PriorityBadge(item.priority),
            Text(
              'Creada ${date(item.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        gap(26),
        LayoutBuilder(
          builder: (c, box) {
            final description = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title('Sobre el reporte', 18),
                  gap(20),
                  SelectableText(
                    item.description,
                    style: const TextStyle(height: 1.8, fontSize: 14),
                  ),
                  gap(22),
                  const Divider(),
                  gap(12),
                  meta(Icons.place_outlined, 'Ubicación', item.location),
                  meta(Icons.category_outlined, 'Categoría', item.categoryName),
                  meta(Icons.person_outline, 'Reportante', item.reporterName),
                  meta(
                    Icons.engineering_outlined,
                    'Responsable',
                    item.assignedName ?? 'Pendiente de asignación',
                  ),
                  meta(
                    Icons.update,
                    'Última actualización',
                    date(item.updatedAt),
                  ),
                ],
              ),
            );
            final actions = Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title('Gestión del caso', 18),
                  gap(15),
                  if (IncidentPolicy.canClassify(item, actor)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.isSaving ? null : classify,
                        icon: const Icon(Icons.tune, size: 17),
                        label: const Text('Clasificar'),
                      ),
                    ),
                    gap(10),
                  ],
                  if (IncidentPolicy.canAssign(item, actor)) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: state.isSaving ? null : assign,
                        icon: const Icon(Icons.person_add_alt, size: 17),
                        label: const Text('Asignar técnico'),
                      ),
                    ),
                    gap(10),
                  ],
                  for (final next in allowed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: state.isSaving
                              ? null
                              : () => transition(next),
                          icon: Icon(switch (next) {
                            IncidentStatus.inProgress => Icons.play_arrow,
                            IncidentStatus.resolved => Icons.task_alt,
                            IncidentStatus.closed => Icons.inventory_2_outlined,
                            IncidentStatus.reopened => Icons.replay,
                            IncidentStatus.cancelled => Icons.close,
                            _ => Icons.arrow_forward,
                          }, size: 17),
                          label: Text(switch (next) {
                            IncidentStatus.inProgress => 'Iniciar atención',
                            IncidentStatus.resolved => 'Registrar solución',
                            IncidentStatus.closed => 'Cerrar incidencia',
                            IncidentStatus.reopened => 'Reabrir incidencia',
                            IncidentStatus.inReview => 'Pasar a revisión',
                            IncidentStatus.rejected => 'Rechazar reporte',
                            IncidentStatus.cancelled => 'Cancelar reporte',
                            _ => next.label,
                          }),
                        ),
                      ),
                    ),
                  if (allowed.isEmpty &&
                      !IncidentPolicy.canAssign(item, actor) &&
                      !IncidentPolicy.canClassify(item, actor))
                    const Text(
                      'El caso está actualizado. Aquí aparecerán las acciones disponibles para tu rol.',
                      style: TextStyle(fontSize: 13, height: 1.7),
                    ),
                  gap(10),
                  const Text(
                    'Cada cambio registra quién lo realizó, cuándo y por qué.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.6,
                      color: Color(0xFF7E8D82),
                    ),
                  ),
                ],
              ),
            );
            return box.maxWidth > 850
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: description),
                      const SizedBox(width: 22),
                      Expanded(flex: 4, child: actions),
                    ],
                  )
                : Column(children: [description, gap(), actions]);
          },
        ),
        gap(24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: title('Fotografías y evidencias', 18)),
                  if (emulatorMode || storageReady)
                    OutlinedButton.icon(
                      onPressed: state.isSaving ? null : upload,
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 17,
                      ),
                      label: const Text('Adjuntar'),
                    ),
                ],
              ),
              gap(16),
              if (!emulatorMode && !storageReady) ...[
                const Notice(
                  'Las fotografías están pendientes en producción: este proyecto utiliza el plan gratuito Spark. En los emuladores puedes probar Cloud Storage completo.',
                ),
                gap(),
              ],
              StreamBuilder<List<IncidentEvidence>>(
                stream: evidence,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const ErrorNotice(
                      'No se pudo consultar la evidencia. Revisa los permisos.',
                    );
                  }
                  if (!snap.hasData) return const LinearProgressIndicator();
                  final files = snap.data!;
                  if (files.isEmpty) {
                    return const Text(
                      'Todavía no se han adjuntado fotografías.',
                      style: TextStyle(fontSize: 13),
                    );
                  }
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: files
                        .map(
                          (x) => SizedBox(
                            width: 190,
                            child: EvidenceTile(
                              key: ValueKey(x.id),
                              evidence: x,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        gap(24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('Seguimiento y avances', 18),
              gap(),
              if (IncidentPolicy.canComment(item, actor)) ...[
                TextField(
                  controller: comment,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Agrega un comentario o avance',
                    alignLabelWithHint: true,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: state.isSaving ? null : sendComment,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Publicar comentario'),
                  ),
                ),
                gap(22),
              ],
              StreamBuilder<List<IncidentComment>>(
                stream: comments,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const ErrorNotice(
                      'No se pudieron cargar los comentarios.',
                    );
                  }
                  if (!snap.hasData) return const LinearProgressIndicator();
                  if (snap.data!.isEmpty) {
                    return const Text('Aún no hay comentarios.');
                  }
                  return Column(
                    children: snap.data!
                        .map(
                          (x) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 17,
                                  backgroundColor: Color(0xFFE1F0E8),
                                  child: Icon(
                                    Icons.person_outline,
                                    size: 18,
                                    color: teal,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        x.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      gap(5),
                                      Text(
                                        date(x.createdAt),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      gap(10),
                                      SelectableText(
                                        x.text,
                                        style: const TextStyle(height: 1.7),
                                      ),
                                      gap(12),
                                      const Divider(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
        gap(24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('Historial del caso', 18),
              gap(8),
              const Text(
                'Trazabilidad cronológica de estados, clasificación y asignaciones.',
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
              gap(20),
              StreamBuilder<List<IncidentEvent>>(
                stream: events,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const ErrorNotice('No se pudo cargar el historial.');
                  }
                  if (!snap.hasData) return const LinearProgressIndicator();
                  return Column(
                    children: snap.data!
                        .map(
                          (x) => Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: teal.withValues(alpha: .1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: teal,
                                    size: 17,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        x.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      gap(6),
                                      Text(
                                        '${x.actorName} · ${date(x.createdAt)}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      gap(10),
                                      Text(
                                        x.message,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.6,
                                        ),
                                      ),
                                      gap(7),
                                      Text(
                                        '${x.fromStatus?.label ?? 'Inicio'} → ${x.toStatus.label}',
                                        style: const TextStyle(
                                          color: teal,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget meta(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF7F8F85)),
              ),
              gap(4),
              Text(value, style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ),
        ),
      ],
    ),
  );
  Future<void> transition(IncidentStatus next) async {
    final note = await askNote(
      context,
      next == IncidentStatus.resolved
          ? 'Describe la solución aplicada'
          : 'Confirmar: ${next.label}',
      'La explicación se guardará en el historial.',
    );
    if (note == null || !mounted) return;
    final state = context.read<IncidentState>();
    final ok = await state.transitionIncident(
      widget.incident,
      next,
      note: note,
    );
    if (mounted) {
      toast(
        context,
        ok ? 'Estado actualizado.' : state.error ?? 'No se pudo actualizar.',
      );
    }
  }

  Future<void> classify() async {
    final state = context.read<IncidentState>();
    var category = widget.incident.categoryId;
    var priority = widget.incident.priority;
    final note = TextEditingController();
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: const Text('Clasificar incidencia'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue:
                        state.activeCategories.any((x) => x.id == category)
                        ? category
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: state.activeCategories
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.id,
                            child: Text(x.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => update(() => category = v!),
                    validator: (v) =>
                        v == null ? 'Selecciona una categoría activa.' : null,
                  ),
                  gap(),
                  DropdownButtonFormField<IncidentPriority>(
                    initialValue: priority,
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    items: IncidentPriority.values
                        .map(
                          (x) =>
                              DropdownMenuItem(value: x, child: Text(x.label)),
                        )
                        .toList(),
                    onChanged: (v) => update(() => priority = v!),
                  ),
                  gap(),
                  TextFormField(
                    controller: note,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de la clasificación',
                    ),
                    maxLength: 1000,
                    validator: noteValidator,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(c, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    final text = note.text;
    note.dispose();
    if (ok != true || !mounted) return;
    final saved = await state.classifyIncident(
      widget.incident,
      categoryId: category,
      priority: priority,
      note: text,
    );
    if (mounted) {
      toast(
        context,
        saved
            ? 'Clasificación actualizada.'
            : state.error ?? 'No se pudo guardar.',
      );
    }
  }

  Future<void> assign() async {
    final state = context.read<IncidentState>();
    if (state.technicians.isEmpty) {
      toast(
        context,
        'Primero asigna el rol Técnico a un usuario activo en Usuarios y roles.',
      );
      return;
    }
    UserProfile? technician;
    final form = GlobalKey<FormState>();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Asignar responsable'),
        content: SizedBox(
          width: 450,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UserProfile>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Técnico activo',
                  ),
                  items: state.technicians
                      .map(
                        (x) => DropdownMenuItem(value: x, child: Text(x.name)),
                      )
                      .toList(),
                  onChanged: (v) => technician = v,
                  validator: (v) => v == null ? 'Selecciona un técnico.' : null,
                ),
                gap(),
                TextFormField(
                  controller: note,
                  decoration: const InputDecoration(
                    labelText: 'Instrucciones de asignación',
                  ),
                  maxLength: 1000,
                  validator: noteValidator,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
    final text = note.text;
    note.dispose();
    if (ok != true || !mounted) return;
    final saved = await state.assignIncident(
      widget.incident,
      technician!,
      note: text,
    );
    if (mounted) {
      toast(
        context,
        saved ? 'Responsable asignado.' : state.error ?? 'No se pudo asignar.',
      );
    }
  }

  Future<void> sendComment() async {
    if (comment.text.trim().length < 3) {
      toast(context, 'Escribe un comentario de al menos 3 caracteres.');
      return;
    }
    final state = context.read<IncidentState>();
    final ok = await state.addComment(widget.incident, comment.text);
    if (mounted) {
      if (ok) comment.clear();
      toast(
        context,
        ok ? 'Comentario registrado.' : state.error ?? 'No se pudo publicar.',
      );
    }
  }

  Future<void> upload() async {
    final state = context.read<IncidentState>();
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (picked == null || !mounted) return;
      final file = picked.files.single;
      if (file.bytes == null || file.size > 5 * 1024 * 1024) {
        toast(context, 'Elige una fotografía JPG, PNG o WebP de hasta 5 MB.');
        return;
      }
      final mime = switch (file.extension?.toLowerCase()) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final ok = await state.uploadEvidence(
        widget.incident,
        name: file.name,
        bytes: file.bytes!,
        contentType: mime,
      );
      if (mounted) {
        toast(
          context,
          ok ? 'Fotografía guardada.' : state.error ?? 'No se pudo adjuntar.',
        );
      }
    } catch (_) {
      if (mounted) {
        toast(context, 'No se pudo abrir el archivo. Intenta con otra imagen.');
      }
    }
  }
}

String? noteValidator(String? value) =>
    (value?.trim().length ?? 0) < 5 ? 'Escribe al menos 5 caracteres.' : null;
Future<String?> askNote(
  BuildContext context,
  String heading,
  String description,
) async {
  final control = TextEditingController();
  final form = GlobalKey<FormState>();
  final result = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(heading),
      content: SizedBox(
        width: 450,
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description, style: const TextStyle(height: 1.6)),
              gap(),
              TextFormField(
                controller: control,
                maxLines: 4,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
                validator: noteValidator,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(c, control.text.trim());
            }
          },
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  control.dispose();
  return result;
}

class EvidenceTile extends StatefulWidget {
  const EvidenceTile({super.key, required this.evidence});
  final IncidentEvidence evidence;
  @override
  State<EvidenceTile> createState() => _EvidenceTileState();
}

class _EvidenceTileState extends State<EvidenceTile> {
  late Future<Uint8List?> bytes;
  @override
  void initState() {
    super.initState();
    bytes = context.read<IncidentState>().evidenceBytes(widget.evidence);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: bytes,
    builder: (context, snap) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 130,
            width: 190,
            child: snap.connectionState != ConnectionState.done
                ? const Center(child: CircularProgressIndicator())
                : snap.hasError || snap.data == null
                ? const Center(child: Text('No se pudo cargar'))
                : InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (c) => Dialog(
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              child: Image.memory(
                                snap.data!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: IconButton.filled(
                                tooltip: 'Cerrar imagen',
                                onPressed: () => Navigator.pop(c),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: Image.memory(
                      snap.data!,
                      fit: BoxFit.cover,
                      semanticLabel: widget.evidence.name,
                      errorBuilder: (_, error, stack) =>
                          const Center(child: Text('Imagen no válida')),
                    ),
                  ),
          ),
        ),
        gap(8),
        Text(
          widget.evidence.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        gap(5),
        Text(
          widget.evidence.uploaderName,
          style: const TextStyle(fontSize: 10, color: Color(0xFF7F8F85)),
        ),
      ],
    ),
  );
}

class Indicators extends StatelessWidget {
  const Indicators({super.key});
  @override
  Widget build(BuildContext context) {
    final m = context.watch<DashboardState>().metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          'Indicadores del campus',
          'Resumen operativo de todas las incidencias autorizadas.',
          action: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      'CampusFix | ${date(DateTime.now())}\nTotal: ${m.total}\nAbiertas: ${m.open}\nEn atención: ${m.byStatus[IncidentStatus.inProgress]}\nResueltas: ${m.resolved}\nCerradas: ${m.closed}\nCríticas abiertas: ${m.critical}\n\nPor categoría\n${m.byCategory.entries.map((x) => '${x.key}: ${x.value}').join('\n')}',
                ),
              );
              if (context.mounted) {
                toast(context, 'Resumen copiado al portapapeles.');
              }
            },
            icon: const Icon(Icons.copy_outlined, size: 17),
            label: const Text('Copiar resumen'),
          ),
        ),
        gap(28),
        MetricsGrid(metrics: m),
        gap(24),
        CategoryChart(metrics: m),
        gap(24),
        StatusSummary(metrics: m),
        gap(24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('Tiempo de resolución', 18),
              gap(18),
              Text(
                m.averageResolutionHours == null
                    ? 'Sin casos resueltos con fechas completas.'
                    : '${m.averageResolutionHours!.toStringAsFixed(1)} horas de promedio',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                ),
              ),
              gap(10),
              const Text(
                'Desde la creación hasta la solución registrada. Un caso reabierto deja de contar hasta que se resuelve de nuevo.',
                style: TextStyle(fontSize: 12, height: 1.7),
              ),
              gap(),
              Text(
                '${m.critical} incidencias críticas abiertas',
                style: const TextStyle(
                  color: Color(0xFFC1734A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CategoryAdmin extends StatelessWidget {
  const CategoryAdmin({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          'Categorías de servicio',
          'Organiza los reportes y conserva el historial al desactivar categorías.',
          action: FilledButton.icon(
            onPressed: state.isSaving ? null : () => edit(context),
            icon: const Icon(Icons.add),
            label: const Text('Nueva categoría'),
          ),
        ),
        gap(26),
        if (state.categories.isEmpty)
          const EmptyState(
            icon: Icons.category_outlined,
            heading: 'Crea la primera categoría',
            text:
                'Ejemplos: Infraestructura, Conectividad, Limpieza o Accesibilidad.',
          ),
        for (final x in state.categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, color: teal),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          x.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        gap(6),
                        Text(
                          x.description,
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                        gap(6),
                        Text(
                          x.active ? 'Activa' : 'Desactivada',
                          style: TextStyle(
                            fontSize: 11,
                            color: x.active ? teal : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar categoría',
                    onPressed: state.isSaving ? null : () => edit(context, x),
                    icon: const Icon(Icons.edit_outlined, size: 19),
                  ),
                  Switch(
                    value: x.active,
                    onChanged: state.isSaving
                        ? null
                        : (v) async {
                            final ok = await state.setCategoryActive(x, v);
                            if (context.mounted) {
                              toast(
                                context,
                                ok
                                    ? 'Categoría actualizada.'
                                    : state.error ?? 'No se pudo guardar.',
                              );
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> edit(BuildContext context, [Category? item]) async {
    final state = context.read<IncidentState>();
    final name = TextEditingController(text: item?.name),
        description = TextEditingController(text: item?.description);
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(item == null ? 'Nueva categoría' : 'Editar categoría'),
        content: SizedBox(
          width: 450,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  maxLength: 80,
                  validator: (v) => (v?.trim().length ?? 0) < 2
                      ? 'Escribe al menos 2 caracteres.'
                      : null,
                ),
                gap(),
                TextFormField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                  maxLength: 500,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    final nameText = name.text, descriptionText = description.text;
    name.dispose();
    description.dispose();
    if (ok != true) return;
    final saved = await state.saveCategory(
      id: item?.id,
      name: nameText,
      description: descriptionText,
      active: item?.active ?? true,
    );
    if (context.mounted) {
      toast(
        context,
        saved ? 'Categoría guardada.' : state.error ?? 'No se pudo guardar.',
      );
    }
  }
}

class UserAdmin extends StatelessWidget {
  const UserAdmin({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<IncidentState>();
    final me = context.watch<AuthState>().profile!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          'Usuarios y roles',
          'Cada persona tiene el acceso que necesita para contribuir.',
        ),
        gap(25),
        const Notice(
          'Los nuevos usuarios se registran como reportantes. Solo un administrador puede asignar otros roles. Tu propia cuenta no se puede desactivar ni cambiar de rol desde aquí.',
        ),
        gap(22),
        for (final user in state.users)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Panel(
              child: LayoutBuilder(
                builder: (c, box) {
                  final data = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      gap(6),
                      SelectableText(
                        user.email,
                        style: const TextStyle(fontSize: 12),
                      ),
                      gap(6),
                      Text(
                        user.active ? 'Cuenta activa' : 'Acceso desactivado',
                        style: TextStyle(
                          fontSize: 11,
                          color: user.active ? teal : Colors.grey,
                        ),
                      ),
                    ],
                  );
                  final actions = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 175,
                        child: DropdownButtonFormField<UserRole>(
                          key: ValueKey('${user.uid}-${user.role}'),
                          initialValue: user.role,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Rol'),
                          items: UserRole.values
                              .map(
                                (x) => DropdownMenuItem(
                                  value: x,
                                  child: Text(
                                    x.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: user.uid == me.uid || state.isSaving
                              ? null
                              : (role) async {
                                  if (role == null || role == user.role) return;
                                  final note = await askNote(
                                    context,
                                    'Cambiar rol de ${user.name}',
                                    'Nuevo acceso: ${role.label}. Confirma el motivo antes de continuar.',
                                  );
                                  if (note == null) return;
                                  final ok = await state.setUserRole(
                                    user,
                                    role,
                                  );
                                  if (context.mounted) {
                                    toast(
                                      context,
                                      ok
                                          ? 'Rol actualizado.'
                                          : state.error ??
                                                'No se pudo actualizar.',
                                    );
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: user.active,
                        onChanged: user.uid == me.uid || state.isSaving
                            ? null
                            : (v) async {
                                final note = await askNote(
                                  context,
                                  v
                                      ? 'Restablecer acceso'
                                      : 'Desactivar acceso',
                                  'Usuario: ${user.name}. Confirma el motivo de esta acción.',
                                );
                                if (note == null) return;
                                final ok = await state.setUserActive(user, v);
                                if (context.mounted) {
                                  toast(
                                    context,
                                    ok
                                        ? 'Acceso actualizado.'
                                        : state.error ??
                                              'No se pudo actualizar.',
                                  );
                                }
                              },
                      ),
                    ],
                  );
                  return box.maxWidth > 650
                      ? Row(
                          children: [
                            Expanded(child: data),
                            actions,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [data, gap(), actions],
                        );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final form = GlobalKey<FormState>();
  late TextEditingController name;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: context.read<AuthState>().profile!.name);
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final profile = auth.profile!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          'Mi perfil',
          'Mantén tus datos actualizados para facilitar el seguimiento.',
        ),
        gap(26),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Panel(
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.role.label.toUpperCase(),
                    style: const TextStyle(
                      color: teal,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  gap(24),
                  TextFormField(
                    controller: name,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Escribe al menos 2 caracteres.'
                        : null,
                  ),
                  gap(),
                  TextFormField(
                    initialValue: profile.email,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      suffixIcon: Icon(Icons.lock_outline, size: 18),
                    ),
                  ),
                  gap(24),
                  FilledButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            if (!form.currentState!.validate()) return;
                            final ok = await auth.updateProfile(name.text);
                            if (context.mounted) {
                              toast(
                                context,
                                ok
                                    ? 'Perfil actualizado.'
                                    : auth.error ?? 'No se pudo guardar.',
                              );
                            }
                          },
                    child: const Text('Guardar cambios'),
                  ),
                  gap(),
                  OutlinedButton.icon(
                    onPressed: context.read<ThemeState>().toggle,
                    icon: const Icon(Icons.contrast),
                    label: const Text('Cambiar tema claro / oscuro'),
                  ),
                  gap(),
                  TextButton.icon(
                    onPressed: () async {
                      final ok = await auth.resetPassword(profile.email);
                      if (context.mounted) {
                        toast(
                          context,
                          ok
                              ? 'Se enviaron instrucciones a tu correo.'
                              : auth.error ?? 'No se pudo enviar.',
                        );
                      }
                    },
                    icon: const Icon(Icons.password),
                    label: const Text('Cambiar mi contraseña'),
                  ),
                  gap(),
                  TextButton.icon(
                    onPressed: auth.logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
