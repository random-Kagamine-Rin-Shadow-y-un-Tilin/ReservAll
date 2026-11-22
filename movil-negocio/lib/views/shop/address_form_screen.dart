import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../controllers/location_controller.dart';
import '../../controllers/shop_controller.dart';
import '../../models/address_model.dart';
import '../../models/location_model.dart';

class AddressFormScreen extends StatefulWidget {
  final int shopId;
  final ShopAddress? address;

  const AddressFormScreen({
    super.key,
    required this.shopId,
    this.address,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busquedaCtrl = TextEditingController();
  final _calleCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  final _paisCtrl = TextEditingController(text: 'México');
  final _numeroCtrl = TextEditingController();
  final _interiorCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  String _osmId = '';

  bool get _esEdicion => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    if (a != null) {
      _calleCtrl.text = a.direccionCalle;
      _ciudadCtrl.text = a.ciudad;
      _estadoCtrl.text = a.estado;
      _cpCtrl.text = a.codigoPostal;
      _paisCtrl.text = a.pais;
      _numeroCtrl.text = a.numeroLocal;
      _interiorCtrl.text = a.numeroInterior ?? '';
      _latCtrl.text = a.latitud.toString();
      _lngCtrl.text = a.longitud.toString();
      _osmId = a.osmId;
    }
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _calleCtrl.dispose();
    _ciudadCtrl.dispose();
    _estadoCtrl.dispose();
    _cpCtrl.dispose();
    _paisCtrl.dispose();
    _numeroCtrl.dispose();
    _interiorCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _aplicarResultado(GeocodeResult r) {
    setState(() {
      _calleCtrl.text = r.direccionCalle;
      _ciudadCtrl.text = r.ciudad;
      _estadoCtrl.text = r.estado;
      _cpCtrl.text = r.codigoPostal;
      _paisCtrl.text = r.pais.isNotEmpty ? r.pais : _paisCtrl.text;
      _numeroCtrl.text = r.numeroLocal;
      _interiorCtrl.text = r.numeroInterior;
      _latCtrl.text = r.latitud.toString();
      _lngCtrl.text = r.longitud.toString();
      _osmId = r.osmId;
    });
    context.read<LocationController>().limpiar();
  }

  Future<void> _buscarDireccion() async {
    final q = _busquedaCtrl.text.trim();
    if (q.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe al menos 3 caracteres'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await context.read<LocationController>().buscar(q);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Latitud y longitud deben ser números'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final controller = context.read<ShopController>();
    final bool ok;
    if (_esEdicion) {
      ok = await controller.editAddress(
        widget.shopId,
        ShopAddressUpdateRequest(
          direccionCalle: _calleCtrl.text.trim(),
          ciudad: _ciudadCtrl.text.trim(),
          estado: _estadoCtrl.text.trim(),
          codigoPostal: _cpCtrl.text.trim(),
          pais: _paisCtrl.text.trim(),
          latitud: lat,
          longitud: lng,
          osmId: _osmId,
          numeroLocal: _numeroCtrl.text.trim(),
          numeroInterior: _interiorCtrl.text.trim().isEmpty
              ? null
              : _interiorCtrl.text.trim(),
        ),
      );
    } else {
      ok = await controller.registerAddress(
        widget.shopId,
        ShopAddressCreateRequest(
          direccionCalle: _calleCtrl.text.trim(),
          ciudad: _ciudadCtrl.text.trim(),
          estado: _estadoCtrl.text.trim(),
          codigoPostal: _cpCtrl.text.trim(),
          pais: _paisCtrl.text.trim(),
          latitud: lat,
          longitud: lng,
          osmId: _osmId,
          numeroLocal: _numeroCtrl.text.trim(),
          numeroInterior: _interiorCtrl.text.trim().isEmpty
              ? null
              : _interiorCtrl.text.trim(),
        ),
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar dirección' : 'Registrar dirección'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _busquedaCtrl,
              textInputAction: TextInputAction.search,
              onFieldSubmitted: (_) => _buscarDireccion(),
              decoration: InputDecoration(
                labelText: 'Buscar dirección',
                hintText: 'Calle, ciudad, estado o código postal',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.travel_explore),
                  onPressed: _buscarDireccion,
                ),
              ),
            ),
            Consumer<LocationController>(
              builder: (context, loc, _) {
                if (loc.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (loc.results.isEmpty) return const SizedBox.shrink();
                return Card(
                  margin: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: loc.results
                        .map(
                          (r) => ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.primary,
                            ),
                            title: Text(
                              r.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _aplicarResultado(r),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _campo(_calleCtrl, 'Calle'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo(_numeroCtrl, 'Número exterior')),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    _interiorCtrl,
                    'Número interior',
                    requerido: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _campo(_ciudadCtrl, 'Ciudad'),
            const SizedBox(height: 12),
            _campo(_estadoCtrl, 'Estado'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo(_cpCtrl, 'Código postal')),
                const SizedBox(width: 12),
                Expanded(child: _campo(_paisCtrl, 'País')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _campo(_latCtrl, 'Latitud', numero: true)),
                const SizedBox(width: 12),
                Expanded(child: _campo(_lngCtrl, 'Longitud', numero: true)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Busca una dirección para rellenar las coordenadas automáticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save),
              label: Text(_esEdicion ? 'Guardar cambios' : 'Registrar dirección'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    TextEditingController ctrl,
    String label, {
    bool numero = false,
    bool requerido = true,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: numero
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return requerido ? 'Requerido' : null;
        }
        if (numero && double.tryParse(v.trim()) == null) return 'Número inválido';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
