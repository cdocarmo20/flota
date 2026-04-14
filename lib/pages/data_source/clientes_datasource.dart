import 'package:cargasuy/models/cliente.dart';
import 'package:flutter/material.dart';

class ClientesDataSource extends DataTableSource {
  final List<Cliente> clientes;
  final BuildContext context;

  // Recibimos los anchos fijos desde la página para que coincidan con el header
  final double wNombre;
  final double wEmail;
  final double wEstado;
  final double wAcciones;

  ClientesDataSource(
    this.clientes,
    this.context,
    this.wNombre,
    this.wEmail,
    this.wEstado,
    this.wAcciones,
  );

  @override
  DataRow? getRow(int index) {
    if (index >= clientes.length) return null;
    final cliente = clientes[index];

    return DataRow(
      cells: [
        // 1. Columna Nombre
        DataCell(
          SizedBox(
            width: wNombre,
            child: Text(
              cliente.nombre,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),

        // 2. Columna Email
        DataCell(
          SizedBox(
            width: wEmail,
            child: Text(cliente.email, overflow: TextOverflow.ellipsis),
          ),
        ),

        // 3. Columna Estado (Con el Badge)
        DataCell(
          SizedBox(
            width: wEstado,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(cliente.status),
            ),
          ),
        ),

        // 4. Columna Acciones
        DataCell(
          SizedBox(
            width: wAcciones,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _onEdit(cliente),
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _onDelete(cliente),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET AUXILIAR: BADGE DE ESTADO ---
  Widget _buildStatusBadge(String status) {
    final bool isActive = status.toLowerCase() == 'activo';
    final Color color = isActive ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- LÓGICA DE ACCIONES ---
  void _onEdit(Cliente cliente) {
    // Aquí puedes llamar a tu servicio de alertas o abrir un modal
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Editando a ${cliente.nombre}")));
  }

  void _onDelete(Cliente cliente) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Eliminando a ${cliente.nombre}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => clientes.length;

  @override
  int get selectedRowCount => 0;
}
