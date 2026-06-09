import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Supabase ──────────────────────────────────────────────────────────────────
const _kSbUrl     = 'https://fhcvwtaxjkdxkvwsbesz.supabase.co';
const _kSbAnonKey = 'sb_publishable_AOnCaJgd2GFgCO2TNzRcRw_mTNJYkFc';
SupabaseClient get _sb => Supabase.instance.client;

// ── Paleta ────────────────────────────────────────────────────────────────────
const _kSurface = Color(0xFF0A0A0A);
const _kCard    = Color(0xFF111111);
const _kG950    = Color(0xFF052E16);
const _kG900    = Color(0xFF14532D);
const _kG800    = Color(0xFF166534);
const _kG600    = Color(0xFF16A34A);
const _kWhite   = Colors.white;
const _kBorder  = Color(0xAAFFFFFF);
const _kGrey    = Color(0xFF9CA3AF);
const _kRed     = Color(0xFFDC2626);
const _kFont    = 'Arial Black';

const _kGrad = LinearGradient(
  colors: [_kG950, _kG800], begin: Alignment.topLeft, end: Alignment.bottomRight,
);
const _kBgGrad = LinearGradient(
  colors: [Color(0xFF181818), Color(0xFF000000)],
  begin: Alignment.topCenter, end: Alignment.bottomCenter,
);

// ── Status ────────────────────────────────────────────────────────────────────
// Flujo: recibido → aceptado → entregado
// Admin app actualiza el status; esta app lo recibe en tiempo real via StreamBuilder.
// Status strings — coinciden exactamente con lo que escribe menys_adminv10
const _statusLabels = <String, String>{
  'recibido':       'Enviado · En Preparación',
  'en_preparacion': 'En Preparación',
  'en_camino':      '¡Pedido Listo!',
  'entregado':      'Entregado',
  'cancelado':      'Pedido Cancelado',
};
const _statusColors = <String, Color>{
  'recibido':       Color(0xFFF59E0B),  // amber
  'en_preparacion': Color(0xFF7C3AED),  // morado
  'en_camino':      Color(0xFF0891B2),  // cian
  'entregado':      Color(0xFF16A34A),  // verde
  'cancelado':      Color(0xFFDC2626),  // rojo
};
const _statusIndex = <String, int>{
  'recibido': 0, 'en_preparacion': 1, 'en_camino': 2, 'entregado': 3,
};
const _statusNext = <String, String>{
  'recibido': 'en_preparacion', 'en_preparacion': 'en_camino', 'en_camino': 'entregado',
};
const _statusNextLabel = <String, String>{
  'recibido':       'Aceptado',
  'en_preparacion': 'En Camino',
  'en_camino':      'Marcar entregado',
};

// ── Fallbacks (si Supabase falla) ─────────────────────────────────────────────
const _fallbackColonias = <String, double>{
  'Santa Luz': 30,'PSA': 30,'Mirasur': 30,'Puerta del Sol': 30,
  'Brianzzas Milleto': 30,'Brianzzas Centauro': 30,
  'Rincón San Patricio': 30,'Balcones de San Patricio': 30,'Alebrijes': 30,
  'Mirador del Valle': 35,'Renacimiento': 35,'Mirasur 2': 35,
  'Hacienda el Vergel': 35,'Paseo Real': 35,'Hacienda los Ayala': 35,
  'Bosques': 35,'Providencia': 35,
  'Jardines de Escobedo': 40,'Centro de Escobedo': 40,
  'Girasoles 1er Sector': 40,'Girasoles 2do Sector': 40,
  'Flores Magón': 40,'Hacienda del Topo': 40,'Provileon': 40,
  'Lomas de San Genaro': 40,'Fome 9': 40,'Fome 36': 40,
  'Felipe Carrillo': 45,'Monterreal': 45,
  'Balcones de Anáhuac': 55,'Joyas de Anáhuac': 55,'Villa Castello': 65,
};
const _fallbackMetodos = <Map<String, dynamic>>[
  {'nombre': 'Efectivo',      'requiere_monto': true,  'es_transferencia': false},
  {'nombre': 'Tarjeta',       'requiere_monto': false, 'es_transferencia': false},
  {
    'nombre': 'Transferencia','requiere_monto': false, 'es_transferencia': true,
    'titular': 'Manuel Encinas','banco': 'Banorte','numero_cuenta': '5579070144521930',
  },
];

// ── Iconos de categoría ───────────────────────────────────────────────────────
const _catIconMap = <String, IconData>{
  'hamburguesas': Icons.lunch_dining, 'fritos': Icons.fastfood,
  'tacos': Icons.dinner_dining, 'ensaladas': Icons.eco,
  'bebidas': Icons.local_bar, 'postres': Icons.cake,
};
IconData _catIcon(String n) => _catIconMap[n.toLowerCase()] ?? Icons.restaurant;
Widget _silueta(String cat, {double size = 26}) => ShaderMask(
  shaderCallback: (b) => const LinearGradient(
    colors: [Color(0xFF9CA3AF), Color(0xFF374151)],
    begin: Alignment.topCenter, end: Alignment.bottomCenter,
  ).createShader(b),
  blendMode: BlendMode.srcIn,
  child: Icon(_catIcon(cat), size: size, color: Colors.white),
);
IconData _iconPago(String n) {
  switch (n) {
    case 'Efectivo': return Icons.payments_outlined;
    case 'Tarjeta':  return Icons.credit_card;
    default:         return Icons.account_balance;
  }
}

// ── Modelos ───────────────────────────────────────────────────────────────────
class Categoria {
  final String nombre; final List<Producto> items;
  Categoria({required this.nombre, required this.items});
  factory Categoria.fromJson(Map<String, dynamic> j) => Categoria(
    nombre: j['categoria'] as String,
    items: (j['items'] as List).map((e) => Producto.fromJson(e)).toList(),
  );
}
class Producto {
  final int id; final String nombre; final String? descripcion; final double precio;
  Producto({required this.id, required this.nombre, this.descripcion, required this.precio});
  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
    id: (j['id'] as num).toInt(), nombre: j['nombre'] as String,
    descripcion: j['descripcion'] as String?,
    precio: (j['precio'] as num).toDouble(),
  );
}
class CarritoItem {
  final Producto producto; final String categoria; int cantidad;
  CarritoItem({required this.producto, required this.categoria, this.cantidad = 1});
}

// ── AppState ──────────────────────────────────────────────────────────────────
class AppState {
  List<Categoria>          categorias  = [];
  Map<String, double>      colonias    = Map.of(_fallbackColonias);
  List<Map<String, dynamic>> metodosPago = List.of(_fallbackMetodos);
  final List<CarritoItem>  carrito     = [];

  /// Carga todo en paralelo
  Future<void> cargarDatos() async {
    await Future.wait([cargarMenu(), cargarColonias(), cargarMetodosPago()]);
  }

  Future<void> cargarMenu() async {
    try {
      final cats  = await _sb.from('categorias').select().eq('activo', true).order('orden');
      final prods = await _sb.from('productos').select().eq('activo', true).order('id');
      final grouped = <int, List<Producto>>{};
      for (final p in prods as List<dynamic>) {
        final catId = (p['categoria_id'] as num).toInt();
        grouped.putIfAbsent(catId, () => []).add(Producto.fromJson(p as Map<String, dynamic>));
      }
      categorias = (cats as List<dynamic>)
          .where((c) => grouped.containsKey((c['id'] as num).toInt()))
          .map((c) => Categoria(
                nombre: c['nombre'] as String,
                items: grouped[(c['id'] as num).toInt()]!,
              ))
          .toList();
    } catch (e) {
      debugPrint('cargarMenu fallback: $e');
      await _menuLocal();
    }
  }

  Future<void> _menuLocal() async {
    final raw  = await rootBundle.loadString('assets/menu.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    categorias = (data['categorias'] as List)
        .cast<Map<String, dynamic>>().map(Categoria.fromJson).toList();
  }

  Future<void> cargarColonias() async {
    try {
      final rows = await _sb.from('colonias').select('nombre,costo').eq('activo', true).order('nombre');
      colonias = {for (final r in rows as List<dynamic>)
        r['nombre'] as String: (r['costo'] as num).toDouble()};
    } catch (e) {
      debugPrint('cargarColonias fallback: $e');
    }
  }

  Future<void> cargarMetodosPago() async {
    try {
      final rows = await _sb.from('metodos_pago').select().eq('activo', true).order('id');
      if ((rows as List).isNotEmpty) {
        metodosPago = rows.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('cargarMetodosPago fallback: $e');
    }
  }

  Future<String?> guardarPedido({
    required String  orderId,
    required String  nombre,
    required String  telefono,
    required String  tipoPedido,
    required String  forma,
    required String? montoPago,
    required String? numeroCasa,
    required String? calle,
    required String? coloniaName,
    required String? referencias,
    required String  entregaInfo,
    required double  costoEnvio,
    required double  subtotal,
    required double  total,
    required List<CarritoItem> items,
  }) async {
    try {
      final itemsJson = items.map((i) => {
        'id': i.producto.id, 'nombre': i.producto.nombre,
        'precio': i.producto.precio, 'cantidad': i.cantidad,
        'categoria': i.categoria,
      }).toList();
      final resp = await _sb.from('pedidos').insert({
        'orden_id'    : orderId,
        'nombre'      : nombre,
        'telefono'    : telefono,
        'tipo_pedido' : tipoPedido,
        'forma_pago'  : forma,
        'monto_pago'  : montoPago,
        'numero_casa' : numeroCasa,
        'calle'       : calle,
        'colonia'     : coloniaName,
        'referencias' : referencias,
        'entrega_info': entregaInfo,
        'costo_envio' : costoEnvio,
        'subtotal'    : subtotal,
        'total'       : total,
        'items'       : itemsJson,
        'status'      : 'recibido',
      }).select('id').single();
      return resp['id'] as String;
    } catch (e) {
      debugPrint('guardarPedido error: $e');
      return null;
    }
  }

  void agregar(Producto p, String cat) {
    final idx = carrito.indexWhere((i) => i.producto.id == p.id);
    if (idx >= 0) carrito[idx].cantidad++; else carrito.add(CarritoItem(producto: p, categoria: cat));
  }
  void remover(int id) {
    final idx = carrito.indexWhere((i) => i.producto.id == id);
    if (idx < 0) return;
    if (carrito[idx].cantidad > 1) carrito[idx].cantidad--; else carrito.removeAt(idx);
  }
  double get total => carrito.fold(0, (s, i) => s + i.producto.precio * i.cantidad);
  int    get count => carrito.fold(0, (s, i) => s + i.cantidad);
  void   limpiar() => carrito.clear();
}

// ── +1 Animación ──────────────────────────────────────────────────────────────
class _PlusOne extends StatefulWidget {
  final Offset position; final VoidCallback onDone;
  const _PlusOne({required this.position, required this.onDone});
  @override State<_PlusOne> createState() => _PlusOneState();
}
class _PlusOneState extends State<_PlusOne> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(duration: const Duration(milliseconds: 950), vsync: this);
  late final Animation<double> _dy =
      Tween(begin: 0.0, end: -80.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  late final Animation<double> _op =
      Tween(begin: 1.0, end: 0.0).animate(
          CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)));
  @override void initState() { super.initState(); _ctrl.forward().then((_) => widget.onDone()); }
  @override void dispose()   { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Positioned(
      left: widget.position.dx - 16, top: widget.position.dy + _dy.value,
      child: IgnorePointer(
        child: Opacity(opacity: _op.value,
          child: Material(color: Colors.transparent,
            child: Text('+1', style: const TextStyle(
              color: _kRed, fontSize: 22, fontFamily: _kFont,
              fontWeight: FontWeight.bold, decoration: TextDecoration.none,
              shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
            )),
          ),
        ),
      ),
    ),
  );
}

// ── Main ──────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _kSbUrl, publishableKey: _kSbAnonKey);
  runApp(const MenuApp());
}

class MenuApp extends StatefulWidget {
  const MenuApp({super.key});
  @override State<MenuApp> createState() => _MenuAppState();
}
class _MenuAppState extends State<MenuApp> {
  final _appState = AppState();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Meny's Food Truck",
      debugShowCheckedModeBanner: false,
      builder: (ctx, child) =>
          Container(decoration: const BoxDecoration(gradient: _kBgGrad), child: child!),
      theme: ThemeData(
        brightness: Brightness.dark, useMaterial3: true, fontFamily: _kFont,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: _kG600, secondary: _kG800, surface: _kSurface,
          onPrimary: _kWhite, onSecondary: _kWhite, onSurface: _kWhite,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: _kSurface,
          labelStyle: const TextStyle(color: _kGrey, fontFamily: _kFont, fontSize: 11),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: _kBorder, width: 1)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(7),
              borderSide: const BorderSide(color: _kG600, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: _kWhite, unselectedLabelColor: _kGrey, indicatorColor: _kG600,
          labelStyle: TextStyle(fontFamily: _kFont, fontSize: 10, letterSpacing: 0.8),
          unselectedLabelStyle: TextStyle(fontFamily: _kFont, fontSize: 10),
        ),
        dividerColor: _kBorder,
        bottomAppBarTheme: const BottomAppBarThemeData(color: _kSurface),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _kG900,
          contentTextStyle: const TextStyle(color: _kWhite, fontFamily: _kFont, fontSize: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          behavior: SnackBarBehavior.floating, width: 320,
        ),
      ),
      routes: {
        '/': (_) => MenuPage(app: _appState),
        '/confirmar': (_) => ConfirmPage(app: _appState),
        '/admin': (_) => const AdminPage(),
      },
      initialRoute: '/',
    );
  }
}

// ── Página Menú ───────────────────────────────────────────────────────────────
class MenuPage extends StatefulWidget {
  final AppState app;
  const MenuPage({super.key, required this.app});
  @override State<MenuPage> createState() => _MenuPageState();
}
class _MenuPageState extends State<MenuPage> {
  bool _loading = true;
  RealtimeChannel? _rtChannel;

  @override
  void initState() {
    super.initState();
    widget.app.cargarDatos().then((_) {
      if (mounted) setState(() => _loading = false);
    });
    _suscribirRealtime();
  }

  void _suscribirRealtime() {
    _rtChannel = _sb.channel('menu_rt')
      .onPostgresChanges(
        event: PostgresChangeEvent.all, schema: 'public', table: 'productos',
        callback: (_) => widget.app.cargarMenu().then((_) { if (mounted) setState(() {}); }),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all, schema: 'public', table: 'colonias',
        callback: (_) => widget.app.cargarColonias().then((_) { if (mounted) setState(() {}); }),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.all, schema: 'public', table: 'metodos_pago',
        callback: (_) => widget.app.cargarMetodosPago().then((_) { if (mounted) setState(() {}); }),
      )
      .subscribe();
  }

  @override
  void dispose() { _rtChannel?.unsubscribe(); super.dispose(); }

  void _agregar(Producto item, String cat, Offset pos) {
    widget.app.agregar(item, cat);
    setState(() {});
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _PlusOne(position: pos, onDone: () { if (e.mounted) e.remove(); }),
    );
    Overlay.of(context).insert(e);
  }

  PreferredSizeWidget _appBar() => PreferredSize(
    preferredSize: const Size.fromHeight(100),
    child: Container(
      decoration: const BoxDecoration(gradient: _kGrad),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const SizedBox(width: 46),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("MENY'S FOOD TRUCK",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: _kFont, color: _kWhite,
                        fontSize: 19, letterSpacing: 2.2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Envíos a domicilio',
                      style: TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 9)),
                ),
                const SizedBox(height: 4),
                const Text('Catania #147, Puerta del Sol, Escobedo N.L.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: _kFont, color: Color(0xFF86EFAC), fontSize: 8.5)),
              ]),
            ),
            _CartBadge(count: widget.app.count,
                onTap: () => Navigator.pushNamed(context, '/confirmar')
                    .then((_) => setState(() {}))),
          ]),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: _appBar(),
      body: const Center(child: CircularProgressIndicator(color: _kG600)));

    return Scaffold(
      appBar: _appBar(),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        itemCount: widget.app.categorias.length,
        itemBuilder: (ctx, idx) {
          final cat  = widget.app.categorias[idx];
          final minP = cat.items.isEmpty ? 0.0
              : cat.items.map((e) => e.precio).reduce((a, b) => a < b ? a : b);
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _CatHeader(cat: cat, minPrice: minP),
              const SizedBox(height: 5),
              ...cat.items.map((item) => _ProductCard(
                item: item, categoria: cat.nombre,
                onAdd: (pos) => _agregar(item, cat.nombre, pos),
              )),
            ]),
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 48,
        decoration: const BoxDecoration(
          color: _kSurface,
          border: Border(top: BorderSide(color: _kBorder, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          const Icon(Icons.local_shipping, color: _kG600, size: 15),
          const SizedBox(width: 8),
          const Text('Delivery  •  Costo según colonia',
              style: TextStyle(color: _kGrey, fontFamily: _kFont, fontSize: 10)),
          const Spacer(),
          Text('\$${widget.app.total.toStringAsFixed(2)}',
              style: const TextStyle(color: _kG600, fontFamily: _kFont,
                  fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

// ── Widgets auxiliares del menú ───────────────────────────────────────────────
class _CartBadge extends StatelessWidget {
  final int count; final VoidCallback onTap;
  const _CartBadge({required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Stack(clipBehavior: Clip.none, children: [
      Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: const Icon(Icons.shopping_bag_outlined, size: 20, color: _kWhite),
      ),
      if (count > 0)
        Positioned(top: -6, right: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
            child: Text('$count', style: const TextStyle(
                color: _kWhite, fontFamily: _kFont, fontSize: 9, fontWeight: FontWeight.bold)),
          )),
    ]),
  );
}

class _CatHeader extends StatelessWidget {
  final Categoria cat; final double minPrice;
  const _CatHeader({required this.cat, required this.minPrice});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
          colors: [_kG950, Color(0xFF1B4D35)],
          begin: Alignment.centerLeft, end: Alignment.centerRight),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: _kBorder, width: 1),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: _kBorder, width: 1),
        ),
        child: Center(child: _silueta(cat.nombre, size: 22)),
      ),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(cat.nombre.toUpperCase(),
            style: const TextStyle(fontFamily: _kFont, color: _kWhite,
                fontSize: 12, letterSpacing: 1.4)),
        Text('${cat.items.length} opciones  ·  Desde \$${minPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontFamily: _kFont, color: Color(0xFF86EFAC), fontSize: 9)),
      ])),
    ]),
  );
}

class _ProductCard extends StatelessWidget {
  final Producto item; final String categoria; final void Function(Offset) onAdd;
  const _ProductCard({required this.item, required this.categoria, required this.onAdd});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (d) => onAdd(d.globalPosition),
    child: Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _kCard, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.nombre,
              style: const TextStyle(fontFamily: _kFont, color: _kWhite,
                  fontSize: 12, fontWeight: FontWeight.bold)),
          if (item.descripcion != null) ...[
            const SizedBox(height: 3),
            Text(item.descripcion!,
                style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 10)),
          ],
          const SizedBox(height: 5),
          const Text('Toca para agregar al carrito',
              style: TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 9)),
        ])),
        const SizedBox(width: 12),
        Text('\$${item.precio.toStringAsFixed(0)}',
            style: const TextStyle(fontFamily: _kFont, color: _kG600,
                fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

// ── Página Confirmar Pedido ───────────────────────────────────────────────────
class ConfirmPage extends StatefulWidget {
  final AppState app;
  const ConfirmPage({super.key, required this.app});
  @override State<ConfirmPage> createState() => _ConfirmPageState();
}
class _ConfirmPageState extends State<ConfirmPage> {
  String tipoPedido = ''; String nombre = ''; String telefono = '';
  String numeroCasa = ''; String calle   = ''; String colonia  = '';
  String referencias = ''; String forma  = ''; String montoPago = '';
  String error = ''; bool procesando = false;

  @override
  void initState() {
    super.initState();
    // Refresca colonias y métodos de pago al abrir la página
    Future.wait([
      widget.app.cargarColonias(),
      widget.app.cargarMetodosPago(),
    ]).then((_) { if (mounted) setState(() {}); });
  }

  double get _costoEnvio =>
      tipoPedido == 'domicilio' ? (widget.app.colonias[colonia] ?? 0.0) : 0.0;

  List<Map<String, dynamic>> get _metodos =>
      widget.app.metodosPago.isEmpty ? List.of(_fallbackMetodos) : widget.app.metodosPago;

  bool get _requiereMonto {
    if (forma.isEmpty) return false;
    final m = _metodos.firstWhere((x) => x['nombre'] == forma, orElse: () => {});
    return m['requiere_monto'] as bool? ?? (forma == 'Efectivo');
  }

  // ── helpers ──
  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontFamily: _kFont, color: _kWhite,
        fontSize: 10, letterSpacing: 1.3)));

  Widget _box(Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _kBorder, width: 1)),
    child: child,
  );

  Widget _field({required String label, required IconData icon,
      required ValueChanged<String> onChanged,
      TextInputType keyboard = TextInputType.text, int maxLines = 1, int minLines = 1}) =>
      TextField(
        style: const TextStyle(color: _kWhite, fontFamily: _kFont, fontSize: 12),
        keyboardType: keyboard, maxLines: maxLines, minLines: minLines,
        decoration: InputDecoration(labelText: label,
            prefixIcon: Icon(icon, color: _kGrey, size: 16),
            alignLabelWithHint: maxLines > 1),
        onChanged: onChanged,
      );

  Widget _toggle(String label, IconData icon, String value, String selected,
      VoidCallback onTap, {String? hint}) {
    final active = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () { onTap(); setState(() {}); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? _kG900 : _kSurface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: active ? _kG600 : _kBorder, width: active ? 1.5 : 1),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: active ? _kWhite : _kGrey),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(fontFamily: _kFont, fontSize: 9,
                    color: active ? _kWhite : _kGrey)),
            if (hint != null) ...[
              const SizedBox(height: 2),
              Text(hint, textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _kFont, fontSize: 8,
                      color: active ? const Color(0xFF86EFAC) : _kGrey)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _coloniaDropdown() => Container(
    height: 46,
    decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(7),
        border: Border.all(color: _kBorder, width: 1)),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(children: [
      const Icon(Icons.location_city, color: _kGrey, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: DropdownButton<String>(
          value: colonia.isEmpty ? null : colonia,
          isExpanded: true, underline: const SizedBox(), dropdownColor: _kCard,
          hint: const Text('Colonia *',
              style: TextStyle(color: _kGrey, fontFamily: _kFont, fontSize: 11)),
          style: const TextStyle(color: _kWhite, fontFamily: _kFont, fontSize: 11),
          items: widget.app.colonias.entries.map((e) => DropdownMenuItem<String>(
            value: e.key,
            child: Text('${e.key}  ·  \$${e.value.toStringAsFixed(0)}',
                style: const TextStyle(color: _kWhite, fontFamily: _kFont, fontSize: 11)),
          )).toList(),
          onChanged: (v) => setState(() => colonia = v ?? ''),
        ),
      ),
    ]),
  );

  Widget _bankBox() {
    final m = _metodos.firstWhere((x) => x['nombre'] == 'Transferencia',
        orElse: () => _fallbackMetodos.last);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DATOS PARA TRANSFERENCIA',
            style: TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 9, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        _bRow(Icons.person,          'Nombre',     m['titular']       as String? ?? ''),
        _bRow(Icons.account_balance, 'Banco',      m['banco']         as String? ?? ''),
        _bRow(Icons.credit_card,     'No. Cuenta', m['numero_cuenta'] as String? ?? ''),
      ]),
    );
  }

  Widget _bRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Icon(icon, size: 13, color: _kG600), const SizedBox(width: 8),
      Text('$label:  ', style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 10)),
      Expanded(child: SelectableText(value,
          style: const TextStyle(fontFamily: _kFont, color: _kWhite,
              fontSize: 10, fontWeight: FontWeight.bold))),
    ]),
  );

  Widget _leftPanel() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('DATOS DEL CLIENTE'),
      _field(label: 'Nombre completo *', icon: Icons.person, onChanged: (v) => nombre = v),
      const SizedBox(height: 8),
      _field(label: 'Teléfono *', icon: Icons.phone,
          keyboard: TextInputType.phone, onChanged: (v) => telefono = v),
    ])),
    const SizedBox(height: 10),
    _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('TIPO DE PEDIDO'),
      Row(children: [
        _toggle('Envío a\nDomicilio', Icons.delivery_dining,
            'domicilio', tipoPedido, () => tipoPedido = 'domicilio'),
        const SizedBox(width: 8),
        _toggle('Pasar a\nRecoger', Icons.storefront,
            'recoger', tipoPedido, () => tipoPedido = 'recoger', hint: '10-20 min. máx.'),
      ]),
      if (tipoPedido == 'domicilio') ...[
        const SizedBox(height: 10),
        _field(label: 'Número de Casa *', icon: Icons.home,
            keyboard: TextInputType.number, onChanged: (v) => numeroCasa = v),
        const SizedBox(height: 8),
        _field(label: 'Calle *', icon: Icons.signpost, onChanged: (v) => calle = v),
        const SizedBox(height: 8),
        _coloniaDropdown(),
        const SizedBox(height: 8),
        _field(label: 'Referencias (opcional)', icon: Icons.info_outline,
            minLines: 2, maxLines: 3, onChanged: (v) => referencias = v),
      ],
    ])),
    const SizedBox(height: 10),
    _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('MÉTODO DE PAGO'),
      Row(children: [
        for (int i = 0; i < _metodos.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _toggle(_metodos[i]['nombre'] as String,
              _iconPago(_metodos[i]['nombre'] as String),
              _metodos[i]['nombre'] as String, forma,
              () { forma = _metodos[i]['nombre'] as String; montoPago = ''; }),
        ],
      ]),
      if (_requiereMonto) ...[
        const SizedBox(height: 10),
        _field(label: '¿Con cuánto pagará? *', icon: Icons.money,
            keyboard: TextInputType.number, onChanged: (v) => montoPago = v),
      ],
      if (forma == 'Transferencia') _bankBox(),
    ])),
  ]);

  Widget _rightPanel() {
    final envio = _costoEnvio;
    final total = widget.app.total + envio;
    final envioLabel = colonia.isEmpty ? 'Costo de envío' : 'Envío ($colonia)';
    return _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('RESUMEN DEL PEDIDO'),
      if (widget.app.carrito.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('Carrito vacío',
              style: TextStyle(color: _kGrey, fontFamily: _kFont, fontSize: 11))))
      else
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: ListView.separated(
            shrinkWrap: true, physics: const ClampingScrollPhysics(),
            itemCount: widget.app.carrito.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
            itemBuilder: (_, i) {
              final ci = widget.app.carrito[i];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  _silueta(ci.categoria, size: 15), const SizedBox(width: 7),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ci.producto.nombre,
                        style: const TextStyle(color: _kWhite, fontFamily: _kFont, fontSize: 10)),
                    Text(ci.categoria,
                        style: const TextStyle(color: _kGrey, fontFamily: _kFont, fontSize: 9)),
                  ])),
                  Text('\$${(ci.producto.precio * ci.cantidad).toStringAsFixed(0)}',
                      style: const TextStyle(color: _kG600, fontFamily: _kFont,
                          fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  _QtyControl(cantidad: ci.cantidad,
                    onMinus: () => setState(() => widget.app.remover(ci.producto.id)),
                    onPlus:  () => setState(() => widget.app.agregar(ci.producto, ci.categoria)),
                  ),
                ]),
              );
            },
          ),
        ),
      const Divider(height: 18, color: _kBorder),
      _tRow('Subtotal', widget.app.total),
      if (tipoPedido == 'domicilio') _tRow(envioLabel, envio),
      const SizedBox(height: 4),
      _tRow('TOTAL', total, bold: true, green: true),
    ]));
  }

  Widget _tRow(String label, double value, {bool bold = false, bool green = false}) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Flexible(child: Text(label, style: TextStyle(fontFamily: _kFont,
              color: bold ? _kWhite : _kGrey, fontSize: bold ? 12 : 10))),
          Text('\$${value.toStringAsFixed(2)}', style: TextStyle(fontFamily: _kFont,
              color: green ? _kG600 : _kWhite, fontSize: bold ? 14 : 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ]),
      );

  bool _validar() {
    if (nombre.trim().isEmpty)   { error = 'Ingresa tu nombre completo';    return false; }
    if (telefono.trim().isEmpty) { error = 'Ingresa tu número de teléfono'; return false; }
    if (tipoPedido.isEmpty)      { error = 'Selecciona el tipo de pedido';  return false; }
    if (tipoPedido == 'domicilio') {
      if (numeroCasa.trim().isEmpty) { error = 'Ingresa el número de casa';     return false; }
      if (calle.trim().isEmpty)      { error = 'Ingresa el nombre de la calle'; return false; }
      if (colonia.isEmpty)           { error = 'Selecciona la colonia';         return false; }
    }
    if (forma.isEmpty) { error = 'Selecciona un método de pago'; return false; }
    if (_requiereMonto && montoPago.trim().isEmpty) {
      error = 'Ingresa el monto con el que pagará'; return false;
    }
    error = ''; return true;
  }

  Future<void> _confirmar() async {
    setState(() => error = '');
    if (!_validar()) { setState(() {}); return; }
    setState(() => procesando = true);

    final orderId = 'MFT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final envio   = _costoEnvio;
    final sub     = widget.app.total;
    final total   = sub + envio;
    final items   = List<CarritoItem>.from(widget.app.carrito);

    final entregaInfo = tipoPedido == 'domicilio'
        ? 'Calle $calle #$numeroCasa, $colonia'
            '${referencias.trim().isNotEmpty ? '\n${referencias.trim()}' : ''}'
        : 'Pasar a recoger  •  10-20 min. máx.';

    final formaDisplay = _requiereMonto && montoPago.trim().isNotEmpty
        ? '$forma  ·  Paga con \$$montoPago'
        : forma;

    final pedidoUuid = await widget.app.guardarPedido(
      orderId: orderId, nombre: nombre, telefono: telefono,
      tipoPedido: tipoPedido, forma: formaDisplay,
      montoPago: montoPago.trim().isEmpty ? null : montoPago.trim(),
      numeroCasa: numeroCasa.trim().isEmpty ? null : numeroCasa.trim(),
      calle: calle.trim().isEmpty ? null : calle.trim(),
      coloniaName: colonia.isEmpty ? null : colonia,
      referencias: referencias.trim().isEmpty ? null : referencias.trim(),
      entregaInfo: entregaInfo,
      costoEnvio: envio, subtotal: sub, total: total, items: items,
    );

    widget.app.limpiar();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
      builder: (_) => OrderStatusPage(
        orderId: orderId, pedidoUuid: pedidoUuid, tipoPedido: tipoPedido,
        total: total, items: items, nombre: nombre, entregaInfo: entregaInfo,
        forma: formaDisplay, costoEnvio: envio, colonia: colonia,
      ),
    ), (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.app.total + _costoEnvio;
    final confirmBtn = Column(children: [
      if (error.isNotEmpty)
        Container(margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF3B0000),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.red.shade900)),
          child: Row(children: [
            const Icon(Icons.error, color: Colors.redAccent, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(error, style: const TextStyle(
                fontFamily: _kFont, color: Colors.redAccent, fontSize: 10))),
          ])),
      SizedBox(width: double.infinity, height: 46,
        child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _kG600, foregroundColor: _kWhite,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: procesando ? null : _confirmar,
          child: procesando
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: _kWhite, strokeWidth: 2))
              : Text('CONFIRMAR PEDIDO  ·  \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: _kFont, fontSize: 11, letterSpacing: 0.8)),
        )),
    ]);

    return Scaffold(
      appBar: PreferredSize(preferredSize: const Size.fromHeight(56),
        child: Container(decoration: const BoxDecoration(gradient: _kGrad),
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: _kWhite, size: 18),
                  onPressed: () => Navigator.pop(context)),
              const Expanded(child: Text('CONFIRMAR PEDIDO',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: _kFont, fontSize: 13,
                      color: _kWhite, letterSpacing: 1.6))),
              const SizedBox(width: 48),
            ]),
          )))),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 20 : 14),
          child: isWide
              ? Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _leftPanel()), const SizedBox(width: 16),
                    Expanded(child: _rightPanel()),
                  ]),
                  const SizedBox(height: 14), confirmBtn, const SizedBox(height: 16),
                ])
              : Column(children: [
                  _leftPanel(), const SizedBox(height: 10),
                  _rightPanel(), const SizedBox(height: 10),
                  confirmBtn, const SizedBox(height: 16),
                ]),
        );
      }),
    );
  }
}

// ── Control de cantidad ───────────────────────────────────────────────────────
class _QtyControl extends StatelessWidget {
  final int cantidad; final VoidCallback onMinus; final VoidCallback onPlus;
  const _QtyControl({required this.cantidad, required this.onMinus, required this.onPlus});
  Widget _btn(IconData icon, VoidCallback fn, bool primary) => GestureDetector(
    onTap: fn,
    child: Container(width: 20, height: 20,
      decoration: BoxDecoration(
        color: primary ? _kG800 : _kSurface, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: primary ? _kG600 : _kBorder, width: 1)),
      child: Icon(icon, size: 11, color: _kWhite)),
  );
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    _btn(Icons.remove, onMinus, false),
    SizedBox(width: 24, child: Text('$cantidad', textAlign: TextAlign.center,
        style: const TextStyle(color: _kWhite, fontFamily: _kFont, fontSize: 10))),
    _btn(Icons.add, onPlus, true),
  ]);
}

// ── Página Status del Pedido (Realtime) ───────────────────────────────────────
class OrderStatusPage extends StatelessWidget {
  final String orderId; final String? pedidoUuid;
  final String tipoPedido; final double total; final double costoEnvio;
  final List<CarritoItem> items; final String nombre;
  final String entregaInfo; final String forma; final String colonia;

  const OrderStatusPage({
    super.key, required this.orderId, required this.pedidoUuid,
    required this.tipoPedido, required this.total, required this.costoEnvio,
    required this.items, required this.nombre, required this.entregaInfo,
    required this.forma, required this.colonia,
  });

  List<(IconData, String, String)> get _stages => [
    (Icons.receipt_long,    'Enviado · En Preparación',
        'Tu pedido fue recibido, en breve lo prepararemos'),
    (Icons.restaurant,      'En Preparación',
        'Estamos preparando tu pedido'),
    (Icons.done_all,        '¡Pedido Listo!',
        tipoPedido == 'domicilio' ? 'Tu pedido está en camino' : 'Listo para recoger en tienda'),
    (Icons.verified,        'Entregado', '¡Que lo disfrutes!'),
  ];

  Widget _box(Widget child) => Container(
    padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _kBorder, width: 1)),
    child: child,
  );
  Widget _slbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(fontFamily: _kFont, color: _kWhite,
        fontSize: 10, letterSpacing: 1.3)));
  Widget _drow(IconData icon, String lbl, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 13, color: _kG600)),
      const SizedBox(width: 8),
      Text('$lbl  ', style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 10)),
      Expanded(child: Text(val,
          style: const TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 10))),
    ]),
  );

  Widget _tracker(int idx) {
    final stages = _stages;
    return _box(Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slbl('ESTADO DEL PEDIDO'),
        ...stages.asMap().entries.map((e) {
          final i = e.key; final s = e.value;
          final done = i < idx; final curr = i == idx; final last = i == stages.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(width: 30, height: 30,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: done || curr ? _kG800 : _kSurface,
                  border: Border.all(color: done || curr ? _kG600 : _kBorder,
                      width: curr ? 2 : 1)),
                child: Icon(s.$1, size: 14, color: done || curr ? _kWhite : _kGrey)),
              if (!last) Container(width: 2, height: 30, color: done ? _kG600 : _kBorder),
            ]),
            const SizedBox(width: 11),
            Expanded(child: Padding(
              padding: EdgeInsets.only(top: 6, bottom: last ? 0 : 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.$2, style: TextStyle(fontFamily: _kFont,
                    color: curr ? _kWhite : _kGrey, fontSize: 11,
                    fontWeight: curr ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(height: 2),
                Text(s.$3, style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 9)),
              ]),
            )),
          ]);
        }),
      ],
    ));
  }

  Widget _detail() => Column(children: [
    _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _slbl('DETALLES DEL PEDIDO'),
      _drow(Icons.receipt_long, 'Pedido', '# $orderId'),
      _drow(Icons.person, 'Cliente', nombre),
      _drow(tipoPedido == 'domicilio' ? Icons.delivery_dining : Icons.storefront,
          'Entrega', entregaInfo),
      _drow(Icons.payments_outlined, 'Pago', forma),
      _drow(Icons.access_time, 'Tiempo estimado',
          tipoPedido == 'domicilio' ? '40-50 min' : '10-20 min'),
      const Divider(color: _kBorder, height: 16),
      if (tipoPedido == 'domicilio' && costoEnvio > 0) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(colonia.isEmpty ? 'Costo envío' : 'Envío ($colonia)',
              style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 10)),
          Text('\$${costoEnvio.toStringAsFixed(2)}',
              style: const TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 11)),
        ]),
        const SizedBox(height: 4),
      ],
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('TOTAL A PAGAR', style: TextStyle(fontFamily: _kFont, color: _kGrey,
            fontSize: 10, letterSpacing: 1)),
        Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontFamily: _kFont,
            color: _kG600, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
    ])),
    _box(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _slbl('PRODUCTOS'),
      ...items.map((ci) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          _silueta(ci.categoria, size: 13), const SizedBox(width: 8),
          Expanded(child: Text(ci.producto.nombre,
              style: const TextStyle(color: _kWhite, fontFamily: _kFont, fontSize: 10))),
          Text('x${ci.cantidad}',
              style: const TextStyle(color: _kGrey, fontFamily: _kFont, fontSize: 10)),
          const SizedBox(width: 8),
          Text('\$${(ci.producto.precio * ci.cantidad).toStringAsFixed(0)}',
              style: const TextStyle(color: _kG600, fontFamily: _kFont,
                  fontSize: 10, fontWeight: FontWeight.bold)),
        ]),
      )),
    ])),
  ]);

  static const _stageColors = [
    Color(0xFFF59E0B), Color(0xFF7C3AED), Color(0xFF0891B2), Color(0xFF16A34A),
  ];
  static const _stageLabels = [
    'Enviado · En Preparación', 'En Preparación', '¡Pedido Listo!', 'Entregado',
  ];

  Widget _buildContent(BuildContext context, int stageIdx) {
    final si = stageIdx.clamp(0, 3);
    final badgeColor = _stageColors[si];
    final badgeLabel = _stageLabels[si];
    return Scaffold(
    body: SingleChildScrollView(child: Column(children: [
      Container(width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
        decoration: const BoxDecoration(gradient: _kGrad),
        child: Column(children: [
          Container(width: 68, height: 68,
            decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: _kG600, width: 2),
              color: Colors.black.withValues(alpha: 0.3)),
            child: const Icon(Icons.check, color: _kG600, size: 34)),
          const SizedBox(height: 14),
          const Text('¡PEDIDO ENVIADO!', style: TextStyle(fontFamily: _kFont,
              color: _kWhite, fontSize: 22, letterSpacing: 2.5)),
          const SizedBox(height: 6),
          Text('# $orderId', style: const TextStyle(fontFamily: _kFont,
              color: Color(0xFF86EFAC), fontSize: 11)),
          const SizedBox(height: 3),
          Text('Cliente: $nombre', style: const TextStyle(
              fontFamily: _kFont, color: _kGrey, fontSize: 11)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor, width: 1),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (si < 3) ...[
                const SizedBox(width: 10, height: 10,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: _kWhite)),
                const SizedBox(width: 6),
              ],
              Text(badgeLabel,
                  style: const TextStyle(fontFamily: _kFont, color: _kWhite,
                      fontSize: 9, letterSpacing: 0.5)),
            ]),
          ),
        ]),
      ),
      Padding(padding: const EdgeInsets.all(18),
        child: LayoutBuilder(builder: (ctx, c) {
          return c.maxWidth > 600
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _tracker(si)), const SizedBox(width: 16),
                  Expanded(child: _detail()),
                ])
              : Column(children: [_tracker(si), _detail()]);
        }),
      ),
      Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
        child: SizedBox(width: double.infinity, height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: _kWhite,
                side: const BorderSide(color: _kBorder, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () =>
                Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false),
            child: const Text('VOLVER AL MENÚ', style: TextStyle(
                fontFamily: _kFont, fontSize: 11, letterSpacing: 1.2)),
          ))),
    ])),
  );
  }

  @override
  Widget build(BuildContext context) {
    if (pedidoUuid == null) return _buildContent(context, 0);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _sb.from('pedidos').stream(primaryKey: ['id']).eq('id', pedidoUuid!),
      builder: (ctx, snap) {
        int idx = 0;
        if (snap.hasData && snap.data!.isNotEmpty) {
          final st = snap.data!.first['status'] as String? ?? 'recibido';
          idx = _statusIndex[st] ?? 0;
        }
        return _buildContent(ctx, idx);
      },
    );
  }
}

// ── Panel de Administración ───────────────────────────────────────────────────
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(decoration: const BoxDecoration(gradient: _kGrad),
          child: SafeArea(child: Column(children: [
            Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: _kWhite, size: 18),
                    onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('PANEL ADMIN', textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: _kFont, color: _kWhite,
                        fontSize: 13, letterSpacing: 1.5))),
                const SizedBox(width: 48),
              ])),
            const TabBar(tabs: [
              Tab(text: 'ACTIVOS'), Tab(text: 'TODOS'), Tab(text: 'ENTREGADOS'),
            ]),
          ]))),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _sb.from('pedidos').stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(
              child: CircularProgressIndicator(color: _kG600));
          final all       = snap.data!;
          final activos   = all.where((p) => p['status'] != 'entregado').toList();
          final entregados = all.where((p) => p['status'] == 'entregado').toList();
          return TabBarView(children: [
            _OrderList(orders: activos,    emptyMsg: 'Sin pedidos activos'),
            _OrderList(orders: all,        emptyMsg: 'Sin pedidos aún'),
            _OrderList(orders: entregados, emptyMsg: 'Sin pedidos entregados'),
          ]);
        },
      ),
    ),
  );
}

class _OrderList extends StatelessWidget {
  final List<Map<String, dynamic>> orders; final String emptyMsg;
  const _OrderList({required this.orders, required this.emptyMsg});
  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.receipt_long, color: _kGrey, size: 36),
      const SizedBox(height: 10),
      Text(emptyMsg, style: const TextStyle(color: _kGrey, fontFamily: _kFont, fontSize: 11)),
    ]));
    return ListView.builder(
      padding: const EdgeInsets.all(14), itemCount: orders.length,
      itemBuilder: (_, i) => _AdminOrderCard(order: orders[i]),
    );
  }
}

class _AdminOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _AdminOrderCard({required this.order});
  @override State<_AdminOrderCard> createState() => _AdminOrderCardState();
}
class _AdminOrderCardState extends State<_AdminOrderCard> {
  bool _advancing = false;

  Future<void> _advance() async {
    final next = _statusNext[widget.order['status'] as String? ?? 'recibido'];
    if (next == null) return;
    setState(() => _advancing = true);
    try {
      await _sb.from('pedidos').update({'status': next})
          .eq('id', widget.order['id'] as String);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  String _fdt(String? iso) {
    if (iso == null) return '';
    final l = DateTime.tryParse(iso)?.toLocal();
    if (l == null) return '';
    return '${l.day}/${l.month}  ${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final o        = widget.order;
    final status   = o['status']   as String? ?? 'recibido';
    final color    = _statusColors[status]    ?? _kGrey;
    final label    = _statusLabels[status]    ?? status;
    final nxtLabel = _statusNextLabel[status];
    final items    = (o['items'] as List<dynamic>? ?? []);
    final total    = (o['total'] as num).toDouble();
    final envio    = (o['costo_envio'] as num? ?? 0).toDouble();
    final tipo     = o['tipo_pedido'] as String? ?? '';
    final col      = o['colonia'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kBorder, width: 1)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 1)),
            child: Text(label, style: TextStyle(fontFamily: _kFont, color: color, fontSize: 9))),
          const SizedBox(width: 8),
          Expanded(child: Text(o['orden_id'] as String? ?? '',
              style: const TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 10))),
          Text(_fdt(o['created_at'] as String?),
              style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 9)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.person, size: 13, color: _kGrey), const SizedBox(width: 5),
          Text(o['nombre'] as String? ?? '',
              style: const TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 11)),
          const SizedBox(width: 10),
          const Icon(Icons.phone, size: 11, color: _kGrey), const SizedBox(width: 4),
          Text(o['telefono'] as String? ?? '',
              style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 10)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Icon(tipo == 'domicilio' ? Icons.delivery_dining : Icons.storefront,
              size: 13, color: _kGrey), const SizedBox(width: 5),
          Expanded(child: Text(o['entrega_info'] as String? ?? '',
              style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 9),
              maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.payments_outlined, size: 13, color: _kGrey), const SizedBox(width: 5),
          Text(o['forma_pago'] as String? ?? '',
              style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 9)),
        ]),
        const SizedBox(height: 8),
        const Divider(color: _kBorder, height: 1),
        const SizedBox(height: 6),
        ...items.map((item) {
          final i = item as Map<String, dynamic>;
          final cant  = (i['cantidad'] as num).toInt();
          final precio = (i['precio'] as num).toDouble();
          return Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Row(children: [
              Text('${cant}x ', style: const TextStyle(fontFamily: _kFont,
                  color: _kG600, fontSize: 10, fontWeight: FontWeight.bold)),
              Expanded(child: Text(i['nombre'] as String? ?? '',
                  style: const TextStyle(fontFamily: _kFont, color: _kWhite, fontSize: 10))),
              Text('\$${(precio * cant).toStringAsFixed(0)}',
                  style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 10)),
            ]));
        }),
        const SizedBox(height: 6),
        const Divider(color: _kBorder, height: 1),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (envio > 0 && col.isNotEmpty)
              Text('Envío $col: \$${envio.toStringAsFixed(0)}',
                  style: const TextStyle(fontFamily: _kFont, color: _kGrey, fontSize: 9)),
            Text('TOTAL  \$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontFamily: _kFont, color: _kWhite,
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
          if (nxtLabel != null)
            _advancing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: _kG600, strokeWidth: 2))
                : TextButton(
                    style: TextButton.styleFrom(backgroundColor: _kG900,
                        foregroundColor: _kWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6),
                            side: const BorderSide(color: _kG600))),
                    onPressed: _advance,
                    child: Text(nxtLabel, style: const TextStyle(
                        fontFamily: _kFont, fontSize: 9, letterSpacing: 0.5)))
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _kG600.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kG600)),
              child: const Text('✓ Completado', style: TextStyle(
                  fontFamily: _kFont, color: _kG600, fontSize: 9))),
        ]),
      ]),
    );
  }
}
