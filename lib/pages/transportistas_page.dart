import 'package:demos/models/vehiculo.dart';
import 'package:demos/services/app_state.dart';
import 'package:demos/services/db/transportista_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/transportista.dart';
import '../widgets/page_layout.dart';

class TransportistasPage extends StatefulWidget {
  const TransportistasPage({super.key});

  @override
  State<TransportistasPage> createState() => _TransportistasPageState();
}

class _TransportistasPageState extends State<TransportistasPage> {
  Transportista? _seleccionado;
  bool _showPanel = false;
  int _rowsPerPage = 10; // Cuántas filas ver por página
  int _currentPage = 0; // Página actual (empieza en 0)
  late List<Transportista> _filtrados;
  late List<Transportista> _listaTransportistas;
  String _query = "";
  final TextEditingController _vehiculoController = TextEditingController();
  double _capacidadMinima = 0;
  final _serviceTransportista = TransportistaService();
  bool _isLoading = true;
  final List<Vehiculo> _flotaTemporal = [];
  List<String> _tiposDisponibles = [];
  bool _loadingTipos = true;

  // Future<void> _cargarDatos() async {
  //   setState(() => _isLoading = true);
  //   try {
  //     final datos = await _serviceTransportista.fetchTransportistas();
  //     setState(() {
  //       _listaTransportistas = datos;
  //       _filtrados = datos;
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() => _isLoading = false);
  //     AppService.showAlert("Error al conectar con la base de datos");
  //   }
  // }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final datos = await _serviceTransportista.fetchTransportistas();
      setState(() {
        _listaTransportistas = datos;
        _filtrados = datos;
        _isLoading = false;
      });

      // --- AQUÍ LA SOLUCIÓN ---
      // Verificamos si hay un nombre en la URL después de cargar los datos
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _procesarParametroUrl();
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _procesarParametroUrl() {
    // Extraemos el nombre de la URL: /transportistas?nombre=Juan
    final String? nombreBuscado =
        GoRouterState.of(context).uri.queryParameters['nombre'];

    if (nombreBuscado != null && _listaTransportistas.isNotEmpty) {
      try {
        // Buscamos el transportista exacto en la lista que bajó de Supabase
        final t = _listaTransportistas.firstWhere(
          (item) => item.nombre.toLowerCase() == nombreBuscado.toLowerCase(),
        );

        // Abrimos el panel con sus datos
        setState(() {
          _seleccionado = t;
          _showPanel = true;
        });
      } catch (e) {
        print("No se encontró el transportista: $nombreBuscado");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarTipos();
    _cargarDatos();
    // _filtrados = _listaTransportistas;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chequearParametrosDeRuta();
    });
  }

  Future<void> _cargarTipos() async {
    try {
      final tipos = await TransportistaService().fetchTiposVehiculo();
      setState(() {
        _tiposDisponibles = tipos;
        _loadingTipos = false;
      });
    } catch (e) {
      AppService.showAlert("Error al cargar tipos de vehículo");
    }
  }

  void _chequearParametrosDeRuta() {
    // Obtenemos el parámetro 'nombre' de la URL (usando GoRouter)
    final String? nombreBuscado =
        GoRouterState.of(context).uri.queryParameters['nombre'];

    if (nombreBuscado != null) {
      // Buscamos al transportista en la lista
      final t = _listaTransportistas.firstWhere(
        (item) => item.nombre == nombreBuscado,
        orElse: () => _listaTransportistas.first,
      );

      setState(() {
        _seleccionado = t;
        _showPanel = true; // ABRIMOS EL PANEL AUTOMÁTICAMENTE
      });
    }
  }

  double _extraerNumero(String texto) {
    final RegExp regExp = RegExp(r"(\d+(\.\d+)?)"); // Busca números
    final match = regExp.firstMatch(texto);
    return match != null ? double.parse(match.group(0)!) : 0.0;
  }

  Widget _buildFiltroCapacidad() {
    return Row(
      children: [
        const Icon(Icons.fitness_center, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        DropdownButton<double>(
          value: _capacidadMinima,
          underline: const SizedBox(),
          items:
              [0.0, 1.0, 5.0, 10.0, 20.0].map((double val) {
                return DropdownMenuItem<double>(
                  value: val,
                  child: Text(
                    val == 0 ? "Todas las capacidades" : "+ $val Ton",
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
          onChanged: (val) {
            setState(() => _capacidadMinima = val!);
            _ejecutarBusqueda(
              _query,
            ); // Re-ejecutar búsqueda con el nuevo filtro
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => context.go(
              '/nuevo-transportista',
            ), // Ruta que definimos en GoRouter
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text("Nuevo Transportista"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              _buildBuscadorTransportista(),
              const SizedBox(width: 20),
              _buildFiltroCapacidad(), // <--- Selector de Toneladas
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildLista()),
                // Panel lateral para ver datos y lista de vehículos
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _showPanel ? 400 : 0,
                  child:
                      _showPanel ? _buildSidePanel() : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscadorTransportista() {
    return Container(
      width: 450,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: _ejecutarBusqueda,
        decoration: InputDecoration(
          hintText: "Buscar por nombre, razón social o patente...",
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          // Mostramos un icono diferente si está buscando un vehículo
          suffixIcon:
              _query.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _ejecutarBusqueda(""),
                  )
                  : null,
        ),
      ),
    );
  }

  void _ejecutarBusqueda(String query) {
    setState(() {
      _query = query.toLowerCase();
      _filtrados =
          _listaTransportistas.where((t) {
            // Filtro por texto (Nombre/Patente)
            final matchTexto =
                t.nombre.toLowerCase().contains(_query) ||
                t.vehiculos.any(
                  (v) => v.patente.toLowerCase().contains(_query),
                ) ||
                t.vehiculos.any((v) => v.modelo.toLowerCase().contains(_query));

            // Filtro por capacidad (Cualquier vehículo que supere el mínimo)
            final matchCapacidad =
                _capacidadMinima == 0 ||
                t.vehiculos.any(
                  (v) => _extraerNumero(v.capacidad) >= _capacidadMinima,
                );

            return matchTexto && matchCapacidad;
          }).toList();
    });
  }

  Widget _buildLista() {
    final String? highlightingId =
        GoRouterState.of(context).uri.queryParameters['newId'];

    return ListView.builder(
      itemCount: _filtrados.length,
      itemBuilder: (context, index) {
        final t = _filtrados[index];
        final bool isNew = t.id == highlightingId;
        // Lógica para resaltar si la búsqueda coincidió con una patente o modelo
        String? vehiculoEncontrado;
        if (_query.isNotEmpty) {
          for (var v in t.vehiculos) {
            // AHORA accedemos a v.patente o v.modelo (no a v directamente)
            if (v.patente.toLowerCase().contains(_query) ||
                v.modelo.toLowerCase().contains(_query)) {
              vehiculoEncontrado = "${v.patente} (${v.modelo})";
              break;
            }
          }
        }

        return _AnimateNewRow(
          isNew: isNew,
          child: Card(
            color: isNew ? Colors.indigo.withOpacity(0.1) : null,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.indigo,
                child: Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                t.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.razonSocial, style: const TextStyle(fontSize: 13)),
                  if (vehiculoEncontrado != null)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search,
                            size: 12,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Encontrado: $vehiculoEncontrado",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap:
                  () => setState(() {
                    _seleccionado = t;
                    _showPanel = true;
                  }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabla() {
    return ListView.builder(
      itemCount: _filtrados.length,
      itemBuilder: (context, index) {
        final t = _filtrados[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(t.nombre),
          subtitle: Text(t.razonSocial),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap:
              () => setState(() {
                _seleccionado = t;
                _showPanel = true;
              }),
        );
      },
    );
  }

  Widget _buildSidePanel() {
    if (_seleccionado == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(left: BorderSide(color: Colors.black)),
      ),
      child: Column(
        children: [
          _buildPanelHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _infoSection("Datos de Contacto", [
                  _infoItem("Razón Social", _seleccionado!.razonSocial),
                  _infoItem("Dirección", _seleccionado!.direccion),
                  _infoItem("Teléfono", _seleccionado!.telefono),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _seleccionado!.localidadNombre ?? "Desconocida",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ]),
                const Divider(),

                const SizedBox(height: 15),
                const Text(
                  "Flota de Vehículos",
                  style: TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 15),

                // LISTA DE VEHÍCULOS DETALLADA
                ..._seleccionado!.vehiculos.map(
                  (v) => Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withOpacity(0.5)),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                v.patente,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              _badgeTipo(v.tipo), // El badge que hicimos antes
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Modelo: ${v.modelo}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Carga: ${v.capacidad}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Botón para añadir un vehículo con todos los datos
                OutlinedButton.icon(
                  onPressed: _abrirModalNuevoVehiculo,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text("Añadir Vehiculo"),
                ),
                const Divider(),
                _infoItem("Observaciones", _seleccionado!.observaciones),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _abrirModalNuevoVehiculo() {
    final formKey = GlobalKey<FormState>();
    final patenteCtrl = TextEditingController();
    final modeloCtrl = TextEditingController();
    final capacidadCtrl = TextEditingController();
    String? tipoSeleccionado = _tiposDisponibles.first;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Nueva Unidad para ${_seleccionado!.nombre}"),
            content: SizedBox(
              width: 500, // Tamaño optimizado para Web
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInput(
                      patenteCtrl,
                      "Patente",
                      Icons.badge,
                      caps: true,
                    ),
                    const SizedBox(height: 15),
                    _buildInput(modeloCtrl, "Modelo", Icons.local_shipping),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            capacidadCtrl,
                            "Capacidad (Ton)",
                            Icons.fitness_center,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: tipoSeleccionado,
                            items:
                                _tiposDisponibles
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => tipoSeleccionado = v,
                            decoration: const InputDecoration(
                              labelText: "Tipo",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final nuevoV = Vehiculo(
                      id: "",
                      patente: patenteCtrl.text.toUpperCase(),
                      modelo: modeloCtrl.text,
                      capacidad: "${capacidadCtrl.text} Ton",
                      tipo: tipoSeleccionado!,
                    );

                    // GUARDADO REAL EN SUPABASE
                    AppService.runWithLoading(() async {
                      await TransportistaService().agregarVehiculoIndividual(
                        _seleccionado!.id,
                        nuevoV,
                      );

                      // Actualizamos la interfaz local
                      setState(() {
                        _seleccionado!.vehiculos.add(nuevoV);
                      });

                      Navigator.pop(context);
                      AppService.showAlert("Vehículo registrado y vinculado");
                    });
                  }
                },
                child: const Text("Guardar en Base de Datos"),
              ),
            ],
          ),
    );
  }

  // Widget auxiliar para inputs limpios
  Widget _buildInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool caps = false,
  }) {
    return TextFormField(
      controller: ctrl,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v!.isEmpty ? "Requerido" : null,
    );
  }

  void _dialogoNuevoTipo() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Nuevo Tipo de Vehículo"),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: "Ej: Mosquito, Tanque...",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty) {
                    setState(
                      () => _tiposDisponibles.add(ctrl.text),
                    ); // Agrega a la lista local
                    Navigator.pop(context);
                  }
                },
                child: const Text("Añadir"),
              ),
            ],
          ),
    );
  }

  Widget _badgeTipo(String tipo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tipo,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _datoVehiculo(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildPanelHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _seleccionado!.nombre,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _showPanel = false),
          ),
        ],
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text("$label: $value"),
    );
  }

  void _agregarVehiculo() {
    if (_vehiculoController.text.isNotEmpty && _seleccionado != null) {
      setState(() {
        // Agregamos el nuevo vehículo a la lista del transportista seleccionado
        // _seleccionado!.vehiculos.add(_vehiculoController.text);
        _vehiculoController.clear(); // Limpiamos el campo
      });
      AppService.showAlert("Vehículo añadido correctamente");
    }
  }
}

class _AnimateNewRow extends StatefulWidget {
  final Widget child;
  final bool isNew;
  const _AnimateNewRow({required this.child, required this.isNew});

  @override
  State<_AnimateNewRow> createState() => _AnimateNewRowState();
}

class _AnimateNewRowState extends State<_AnimateNewRow> {
  late bool _highlight;

  @override
  void initState() {
    super.initState();
    _highlight = widget.isNew;
    if (_highlight) {
      // Quitamos el resaltado después de 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _highlight = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
      color: _highlight ? Colors.indigo.withOpacity(0.05) : Colors.transparent,
      child: widget.child,
    );
  }
}
