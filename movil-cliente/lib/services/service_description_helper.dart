class ServiceDescriptionHelper {
  static const Map<int, String> _descriptionById = {
    1: 'Primera sesión de evaluación',
    2: 'Múltiples consultas para desarrollar software',
    8: 'Corte completo según el pedido de cliente',
    11: 'Cortamos greña ola',
  };

  static const Map<String, String> _descriptionByName = {
    'consulta inicial': 'Primera sesión de evaluación',
    'consulta de software': 'Múltiples consultas para desarrollar software',
    'corte de greña': 'Corte completo según el pedido de cliente',
  };

  static String resolve({
    Map<String, dynamic>? raw,
    int? serviceId,
    String? serviceName,
    String? currentDescription,
  }) {
    if (raw != null) {
      final nestedService = raw['servicio'] is Map<String, dynamic>
          ? raw['servicio'] as Map<String, dynamic>
          : null;

      final candidate =
          raw['descripcion'] ??
          raw['description'] ??
          raw['detalle'] ??
          nestedService?['descripcion'] ??
          nestedService?['description'];

      if (candidate != null) {
        final cleaned = candidate.toString().trim();
        if (cleaned.isNotEmpty && cleaned.toLowerCase() != 'null') {
          return cleaned;
        }
      }
    }

    if (currentDescription != null) {
      final cleanedCurrent = currentDescription.trim();
      final lowerCurrent = cleanedCurrent.toLowerCase();
      if (cleanedCurrent.isNotEmpty &&
          lowerCurrent != 'null' &&
          lowerCurrent != 'sin descripción' &&
          lowerCurrent != 'sin descripción disponible.') {
        return cleanedCurrent;
      }
    }

    if (serviceId != null && _descriptionById.containsKey(serviceId)) {
      return _descriptionById[serviceId]!;
    }

    if (serviceName != null) {
      final normalizedName = serviceName.trim().toLowerCase();
      if (_descriptionByName.containsKey(normalizedName)) {
        return _descriptionByName[normalizedName]!;
      }
    }

    return 'Sin descripción disponible.';
  }
}
